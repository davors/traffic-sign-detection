function [A,imageFiles] = annotationsGetByCategory(annotStruct,category, filterFilename, filterIgnore, filterHeight)

% category - if scalar then search by categories.id otherwise ny
% categories.name

if ~exist('filterFilename','var') || isempty(filterFilename)
    filterFilename = [];
end

if ~exist('filterIgnore','var') || isempty(filterIgnore)
    filterIgnore = 0;
end

if ~exist('filterHeight','var') || isempty(filterHeight)
    filterHeight = 0;
end


if ischar(category)
    % Find ID of category in the 'categories' field
    index = strcmpi({annotStruct.categories.name}, category);
    categoryID = annotStruct.categories(index).id;
else
    categoryID = category;
end


% Find all annotations for categoryID
index = [annotStruct.annotations.category_id] == categoryID;
A = annotStruct.annotations(index);

% Sort by image_id
[~,sortIndex] = sortrows([A.image_id].'); 
A = A(sortIndex);

maskFilename = true(numel([A.image_id]),1);
maskIgnore = maskFilename;
maskHeight = maskFilename;

if ~isempty(filterFilename)
    [~,allowedInd] = ismember(filterFilename,{annotStruct.images.file_name});
    allowedIDs = [annotStruct.images(allowedInd).id];
    maskFilename = ismember([A.image_id], allowedIDs);
end

% Filter by ignore
if filterIgnore
    maskIgnore = [A.ignore] == 0;
end


% Filter by image height
if filterHeight
    [~,index] = ismember([A.image_id], [annotStruct.images.id]);
    maskHeight = ([annotStruct.images(index).height] == filterHeight);
end

mask = maskFilename(:) & maskIgnore(:) & maskHeight(:);
A = A(mask);

validImageIDs = unique([A.image_id]);

% Return also filenames of images that contain signs from specified category
[~,imageIDind] = ismember(validImageIDs, [annotStruct.images.id]);
imageFiles = {annotStruct.images(imageIDind).file_name};









    