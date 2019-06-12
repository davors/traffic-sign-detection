function A = annotationsGetByFilename(annotStruct,file_images, filterIgnore)

if ~exist('filterIgnore','var') || isempty(filterIgnore)
    filterIgnore = 0;
end

if ~exist('file_images','var') || isempty(file_images)
    file_images = [];
elseif isnumeric(file_images)
    numIDs = numel(file_images);
    tmp = cell(1,numIDs);
    for i=1:numIDs
        tmp{i} = sprintf('%07.0f.jpg',file_images(i));
    end
    file_images = tmp;
end


numFiles = numel(file_images);
A = cell(numFiles,1);

for fi = 1:numFiles
    imageFile = file_images{fi};

    % Find ID of filename in the 'images' field
    index = strcmpi({annotStruct.images.file_name}, imageFile);
    imageID = annotStruct.images(index).id;

    % Find all annotations for imageID
    index = [annotStruct.annotations.image_id] == imageID;
    a = annotStruct.annotations(index);
    if filterIgnore
        notIgnored = [a.ignore] == 0;
        a = a(notIgnored);
    end
    
    A{fi} = a;
end
    