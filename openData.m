function datastruct = openData(filename)
%Grab lines
lines = getLines(filename);
datastruct = struct('filename',filename,'targetClasses',[],'targetCalls',[],...
    'features',[],'featuretypes',[],'featureCalls',[],'numObs',[]);
elements = split(lines{2},',');
isem = cellfun(@isempty,elements);
if all(isem)
    datastruct.targetClasses = {'continuous'};
else
    datastruct.targetClasses = elements(~isem);
end

%Pull out feature count and observations
numfeatures = str2double(lines{3});
numObs = str2double(lines(4+numfeatures));
%Convert cell array to cell matrix with data split out
matrixlines = lines(5+numfeatures:end);
matrix = cell(numObs,numfeatures +1);
for y = 1:length(matrixlines)
    elements = split(matrixlines(y),',');
    matrix(y,:) = elements(1:(numfeatures+1));
end
if (strcmp(datastruct.targetClasses{1},'continuous'))
    datastruct.targetCalls = str2double(matrix(:,end));
else
    datastruct.targetCalls = matrix(:,end);%target is the last row
end
matrix = matrix(:,1:end-1);
featurelines = lines(4:3+numfeatures);
%Loop through features, use featurelines to find out the type of feature.
%if it is a categorical feature convert it into n binary variables where n
%is the number of categories, this allows us to make a strictly binary tree
datamatrix = [];
featurenames = {};
featuretypes = {};
for x = 1:size(matrix,2)
    elements = split(featurelines{x},',');
    isem = cellfun(@isempty,elements);
    featuredata = elements(~isem);
    if strcmpi(featuredata{2},'real')
        datamatrix = [datamatrix,str2double(matrix(:,x))];%str2double parses numbers and makes a numeric matrix
        featurenames = [featurenames,featuredata(1)];
        featuretypes = [featuretypes,'continuous'];
    else
        numCat = str2double(featuredata{2});
        for c = 1:numCat
            name = [featuredata{1},'_is_',featuredata{2+c}];
            calls = double(strcmp(matrix(:,x),featuredata(2+c)));%1 is true, 0 is false
            datamatrix = [datamatrix,calls];
            featurenames = [featurenames,name];
            featuretypes = [featuretypes,'categorical'];
        end
    end
end
datastruct.features = featurenames;
datastruct.featuretypes = featuretypes;
datastruct.featureCalls = datamatrix;
datastruct.numObs = numObs;
end

function alllines = getLines(file)
fid = fopen(file);
alllines = cell(0,1);
line = fgetl(fid);
while ischar(line)
    if ~isempty(line)%Some have empty lines at the end
        alllines{end+1} = line;
    end
    line = fgetl(fid);
end
fclose(fid);
end
