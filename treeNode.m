classdef treeNode < handle
    properties
        nodeData
        nodeCall
        nodeCallProbability
        nodeEntropy
        treeError
        nodeInformationGain
        nodeParent
        nodeSplit
        nodeSplitString
        nodeChildren
        nodeIsLeaf
        nodeDepth
        nodeOptions
    end
    methods
        function obj = treeNode(nData,nOptions,nParent)
            if nargin < 3
                obj.nodeParent = [];
                obj.nodeDepth = 0;
            else
                obj.nodeParent=nParent;
                obj.nodeDepth = nParent.nodeDepth+1;
            end
            obj.nodeData = nData;
            obj.nodeOptions = nOptions;
            obj.getEntropy();
            obj.nodeIsLeaf = true;
            obj.nodeInformationGain = 0;
            if isempty(obj.nodeParent)%Carry initial SSTOT
                obj.treeError = obj.nodeEntropy;
            else
                obj.treeError = obj.nodeParent.treeError;
            end
        end
        function splitNode(obj,feature,level)
            if nargin<3 || level == 0
                iscat = true;
                level = 0;
            else
                iscat = false;
            end
            obj.nodeSplit = {feature,level};
            if iscat
                obj.nodeSplitString = feature;
            else
                obj.nodeSplitString = [feature,' > ',num2str(level)];
            end
            %Get how to split data
            featureDataLoc = strcmp(obj.nodeData.features,feature);
            featureData = obj.nodeData.featureCalls(:,featureDataLoc);
            hasSplit = featureData > level;
            %Split the dfata
            if ~any([sum(hasSplit),sum(~hasSplit)]==0)
                overLevel = obj.nodeData;
                overLevel.targetCalls = overLevel.targetCalls(hasSplit);
                overLevel.featureCalls = overLevel.featureCalls(hasSplit,:);
                overLevel.numObs = sum(hasSplit);
                underLevel = obj.nodeData;
                underLevel.targetCalls = underLevel.targetCalls(~hasSplit);
                underLevel.featureCalls = underLevel.featureCalls(~hasSplit,:);
                underLevel.numObs = sum(~hasSplit);
                obj.nodeChildren = [treeNode(overLevel,obj.nodeOptions,obj),treeNode(underLevel,obj.nodeOptions,obj)];
                childrenN=[obj.nodeChildren(1).nodeData.numObs,obj.nodeChildren(2).nodeData.numObs];
                obj.getInformatinGain();
                obj.nodeIsLeaf = false;
                %Check if split passes options
                if obj.nodeInformationGain < obj.nodeOptions.cpthresh || ~all(childrenN>obj.nodeOptions.minsplit)
                    mergeNode(obj);%undo split
                end
            else
                obj.nodeSplit = [];
                obj.nodeSplitString = [];
            end
        end
        function mergeNode(obj)
            if ~obj.nodeIsLeaf && all(obj.nodeChildren.nodeIsLeaf)
                obj.nodeChildren = [];%Remove children
                obj.nodeSplitString = [];
                obj.nodeInformationGain = 0;
                obj.nodeSplit = [];
                obj.nodeIsLeaf = true;
            end
        end
        function getEntropy(obj)
            if ~strcmp(obj.nodeData.targetClasses{1},'continuous')
                targets = obj.nodeData.targetClasses;
                targetCalls = obj.nodeData.targetCalls;
                entropy = zeros(size(targets));
                probability = entropy;%all zeros still
                for x = 1:length(targets)
                    probability(x) = sum(strcmp(targetCalls,targets{x}))/obj.nodeData.numObs;
                    entropy(x) = -probability(x)*log2(probability(x));
                end
                obj.nodeEntropy = sum(entropy,'omitnan');
                obj.nodeCall = targets(probability==max(probability));
                obj.nodeCall = obj.nodeCall(1);
                obj.nodeCallProbability = probability(probability==max(probability));
                obj.nodeCallProbability = obj.nodeCallProbability(1);
            else
                %Local Sum of Squared error
                localMean = mean(obj.nodeData.targetCalls);
                obj.nodeEntropy = sum((obj.nodeData.targetCalls - localMean).^2);
                obj.nodeCall = localMean;
                obj.nodeCallProbability = 1;
            end
        end
        function getInformatinGain(obj)
            if ~strcmp(obj.nodeData.targetClasses{1},'continuous')
                childrenN=[obj.nodeChildren(1).nodeData.numObs,obj.nodeChildren(2).nodeData.numObs];
                obj.nodeInformationGain = obj.nodeEntropy - sum([obj.nodeChildren.nodeEntropy].*(childrenN./obj.nodeData.numObs));
            else
                %Entropy is sum squared error
                %Information gain is delta-R^2
                %This simplifies to delta-SSE / SSTOT
                obj.nodeInformationGain = (obj.nodeEntropy - sum([obj.nodeChildren.nodeEntropy]))./obj.treeError;
            end
        end
        function [text,centerPos] = printTree(obj)
            if obj.nodeIsLeaf
                if ~isnumeric(obj.nodeCall)
                    text = sprintf('- %3.0f%% %s',obj.nodeCallProbability*100,obj.nodeCall{1});
                else
                    text = sprintf('- %g',obj.nodeCall);
                end
                centerPos = 1;
            else
                [wSplitText,wPos] = obj.nodeChildren(1).printTree;
                [woSplitText,woPos] = obj.nodeChildren(2).printTree;
                if size(wSplitText,2) > size(woSplitText,2)
                    diff = size(wSplitText,2) - size(woSplitText,2);
                    woSplitText = [woSplitText,repmat(' ',size(woSplitText,1),diff)];
                elseif size(woSplitText,2) > size(wSplitText,2)
                    diff = size(woSplitText,2) - size(wSplitText,2);
                    wSplitText = [wSplitText,repmat(' ',size(wSplitText,1),diff)];
                end
                allSplitText = [wSplitText;repmat(' ',1,size(wSplitText,2));woSplitText];
                appendText = repmat(' ',size(allSplitText,1),length(obj.nodeSplitString)+2);
                centerPos = size(wSplitText,1)+1;
                appendText(wPos:centerPos+woPos,end) = repmat('|',centerPos+woPos-wPos+1,1);
                appendText(centerPos,1:size(appendText,2)) = ['-',obj.nodeSplitString,'-'];
                appendText([centerPos-1,centerPos+1],end-1) = ['Y';'N'];
                text = [appendText,allSplitText];
            end
        end
        function predictions = predictData(obj,newData)
            if obj.nodeIsLeaf
                predictions=repmat(obj.nodeCall,newData.numObs,1);
            else
                %Get how to split data
                feature = obj.nodeSplit{1};
                level = obj.nodeSplit{2};
                featureDataLoc = strcmp(obj.nodeData.features,feature);
                featureData = newData.featureCalls(:,featureDataLoc);
                hasSplit = featureData > level;
                %Split the data
                overLevel = newData;
                overLevel.targetCalls = overLevel.targetCalls(hasSplit);
                overLevel.featureCalls = overLevel.featureCalls(hasSplit,:);
                overLevel.numObs = sum(hasSplit);
                underLevel = newData;
                underLevel.targetCalls = underLevel.targetCalls(~hasSplit);
                underLevel.featureCalls = underLevel.featureCalls(~hasSplit,:);
                underLevel.numObs = sum(~hasSplit);
                overPred = obj.nodeChildren(1).predictData(overLevel);
                underPred = obj.nodeChildren(2).predictData(underLevel);
                if ~isnumeric(overPred)
                    predictions = cell(newData.numObs,1);
                else
                    predictions = zeros(newData.numObs,1);
                end
                predictions(hasSplit) = overPred;
                predictions(~hasSplit) = underPred;
            end
        end
        function leaves = getLeaves(obj)
            if obj.nodeIsLeaf
                leaves = obj;
            else
                leavesW = obj.nodeChildren(1).getLeaves();
                leavesWo = obj.nodeChildren(2).getLeaves();
                leaves = [leavesW,leavesWo];
            end
        end
    end
end