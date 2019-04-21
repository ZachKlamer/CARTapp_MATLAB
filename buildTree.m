function trees = buildTree(datastruct,options)
%Given data "datastruct" and options create a node and recursively split
%tree by exploring all fits at each node
makeNTrees = options.maxtree;
n=1;
make = true;
trees =[];
if datastruct.numObs > 50 && makeNTrees > 5
    numObs = datastruct.numObs;
    %Split the dataset 75/25 into train and validation
    valid = round(numObs*0.25);
    split = [ones(valid,1);zeros(numObs-valid,1)];
    split = logical(split(randperm(length(split))));%Shuffle w/o replacement
    validationStruct = datastruct;
    validationStruct.targetCalls = validationStruct.targetCalls(split,:);
    validationStruct.featureCalls = validationStruct.featureCalls(split,:);
    validationStruct.numObs = sum(split);
    datastruct.targetCalls = datastruct.targetCalls(~split,:);
    datastruct.featureCalls = datastruct.featureCalls(~split,:);
    datastruct.numObs = sum(~split);
else
    validationStruct = [];
end
upwards = 0;%Number of times that validation error increased
fiterrors = zeros(makeNTrees,1);
validationerrors = zeros(makeNTrees,1);
while n <= makeNTrees && make
    if makeNTrees > 1
        inputStruct = datastruct;
        %Randomly set half of the features to zero (instead of dropping
        %since we index by location)
        nFeat = length(inputStruct.features);
        selected = randperm(nFeat,floor(nFeat./2));
        inputStruct.featureCalls(:,selected) = 0;%Set to zero so it won't be selected
        %Bootstrap the samples (Sample w/ replacement to 100% sample size)
        numObs = inputStruct.numObs;
        inBag = randi(numObs,numObs,1);
        inputStruct.targetCalls = inputStruct.targetCalls(inBag,:);
        inputStruct.featureCalls = inputStruct.featureCalls(inBag,:);
    else
        inputStruct = datastruct;
    end
    treeObject = treeNode(inputStruct,options);
    if options.maxsplits <= 0
        %Split recursively
        splitTree(treeObject);
    else
        %Only make the best splits, so get all possible splits and make the
        %best one
        nsplits = options.maxsplits;
        for s = 1:nsplits
            leaves = treeObject.getLeaves();
            gains = zeros(size(leaves));
            for L = 1:length(leaves)
                gains(L) = splitTree(leaves(L),false);%Get value of best split at leaf
                leaves(L).mergeNode();%Undo
            end
            bestLeaf = find(gains==max(gains));
            if gains(bestLeaf) > 0
                splitTree(leaves(bestLeaf),false);
            else
                break%leave loop early
            end
        end
    end
    if n == 1
        trees = treeObject;
    else
        trees = [trees,treeObject];
    end
    if ~isempty(validationStruct)
        fiterrors(n) = predictTree(trees,inputStruct);
        if n > 1
            newError = predictTree(trees,validationStruct);
            validationerrors(n) = newError;
            if newError <= oldError
                oldError = newError;
            else
                if upwards > 3%Wait for a trend
                    make = false;%End loop early
                    trees = trees(1:end-3);
                else
                    upwards = upwards+1;
                    oldError = newError;
                end
            end
        else
            oldError = predictTree(trees(n),validationStruct);
            validationerrors(n) = oldError;
        end
    end
    n = n+1;
end
end

function maxGain = splitTree(node,isRecursive)
if nargin < 2
    isRecursive = true;
end
%Unpack node for convenience
features = node.nodeData.features;
featuretypes = node.nodeData.featuretypes;
featureCalls = node.nodeData.featureCalls;
targetCalls = node.nodeData.targetCalls;
informationGain = zeros(size(features));
levels = informationGain;
for x = 1:length(features)
    if ~all(featureCalls(:,x)==0)
        if strncmp(featuretypes{x},'categorical',2)
            node.splitNode(features{x});%Options are checked in treeNode
            informationGain(x) = node.nodeInformationGain;
            node.mergeNode();%Does nothing if node was not split
        else
            %Sort by x calls, for each interface between y classes get
            %information gain, use maximum information gain
            if ~isnumeric(targetCalls(1))
                xCalls = featureCalls(:,x);
                yCalls = targetCalls;
                [xCalls,ind] = sort(xCalls);
                yCalls = yCalls(ind);
                thisGain = zeros(size(yCalls));
                thisLevel = thisGain;
                for y = 2:length(yCalls)
                    if ~strcmp(yCalls(y),yCalls(y-1))
                        thisLevel(y) = mean([xCalls(y),xCalls(y-1)]);
                        node.splitNode(features{x},thisLevel(y));
                        thisGain(y) = node.nodeInformationGain;
                        node.mergeNode();
                    end
                end
                bestScore = find(thisGain==max(thisGain));
                if ~isempty(bestScore)
                    bestScore = bestScore(1);%in case of ties simple break
                    levels(x) = thisLevel(bestScore);
                    informationGain(x) = thisGain(bestScore);
                end
            else
                %If x and y are continuous then best x split is found using
                %simple linear regression to solve for xb1+b0=mean(y)
                %Theres actually many possible solutions for this
                xCalls = featureCalls(:,x);
                dropped = isnan(xCalls);
                xCalls = xCalls(~dropped);
                yCalls = targetCalls(~dropped);
                design = [ones(size(xCalls)),xCalls];
                if rank(design) < 2%x is unchanging
                    continue
                end
                betas = regress(yCalls,design);
                if strncmp(lastwarn(),'X is rank',8)
                    warning('')
                end
                levels(x) = (mean(yCalls)-betas(1))./betas(2);
                node.splitNode(features{x},levels(x));
                informationGain(x) = node.nodeInformationGain;
                node.mergeNode();
            end
        end
    end
end
%Finally split by the best information gain feature
maxGain =max(informationGain);
bestScore = find(informationGain==maxGain&informationGain > 0);
if ~isempty(bestScore) 
    bestScore = bestScore(1);%Break ties simply
    node.splitNode(features{bestScore},levels(bestScore));
    if ~node.nodeIsLeaf && isRecursive%end condition
        splitTree(node.nodeChildren(1));
        splitTree(node.nodeChildren(2));
    end
end
end
