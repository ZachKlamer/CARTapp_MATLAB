function error = predictTree(treeObject,datastruct)
classes = datastruct.targetClasses;
treeClasses =treeObject(1).nodeData.targetClasses;
if length(classes)~=length(treeClasses) || ~all(strcmp(classes,treeClasses)) || size(datastruct.featureCalls,2) ~= size(treeObject(1).nodeData.featureCalls,2)
    disp('Invalid tree for test dataset');
    return
end
%Get predictions
if strcmp(datastruct.targetClasses{1},'continuous')
    predictions = zeros(datastruct.numObs,length(treeObject));
else
    predictions = cell(datastruct.numObs,length(treeObject));
end

for x = 1:length(treeObject)
    predictions(:,x) = treeObject(x).predictData(datastruct);
end
if length(treeObject) > 1
    %Aggregate
    if strcmp(datastruct.targetClasses{1},'continuous')
        %Average predictions
        predictions = mean(predictions,2);
    else
        %Majority rule
        classCounts = zeros(size(predictions,1),length(classes));
        for x = 1:length(classes)
            hasClass = strcmp(classes(x),predictions);
            classCounts(:,x) = sum(hasClass,2);
        end
        maxes = max(classCounts,[],2);
        calls = classCounts == maxes;
        predictions = cell(datastruct.numObs,1);
        for y = 1:size(predictions,1)
            predictions(y) = classes(find(calls(y,:),1));
        end
    end
end
%Calculate and output statistics
truth = datastruct.targetCalls;
if nargout ~= 1%No output is requested so send to command line
    if ~strcmp(datastruct.targetClasses{1},'continuous')
        fprintf('Number of trees: %i\n',length(treeObject));
        accuracy = mean(strcmp(truth,predictions));
        fprintf('Accuracy: %3.2f%%\n',accuracy*100);
        confusionMatrix = cell(length(classes)+1);
        confusionMatrix(2:end,1) = classes;
        confusionMatrix(1,2:end) = classes;
        confusionMatrix(1) = {''};
        %Build up confusion matrix
        for y = 1:length(classes)
            for x = 1:length(classes)
                confusionMatrix{y+1,x+1} = sprintf('%4.0f',sum(strcmp(truth,classes(y))&strcmp(predictions,classes(x))));
            end
        end
        disp(confusionMatrix)
    else
        fprintf('Number of trees: %i\n',length(treeObject));
        SSTOT = sum((mean(truth)-truth).^2);
        SSE = sum((predictions-truth).^2);
        rsquare = 1-SSE./SSTOT;
        fprintf('R-Squared: %1.2f\n',rsquare);
        figure();scatter(predictions,truth);refline(1,0);title('Truth over Predicted Value');
    end
else
    %Just return "fit" ie r-square or accuracy
    if ~strcmp(datastruct.targetClasses{1},'continuous')
        error = 1-mean(strcmp(truth,predictions));%missclassification error
    else
        SSE = sum((predictions-truth).^2);
        error = SSE;
    end
end
end