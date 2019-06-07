function A = annotationsGetByFilename(annotStruct,imageFiles, filterIgnore)

if ~exist('filterIgnore','var') || isempty(filterIgnore)
    filterIgnore = 0;
end

if ischar(imageFiles)
    imageFiles = {imageFiles};
end

numFiles = numel(imageFiles);
A = cell(numFiles,1);

for fi = 1:numFiles
    imageFile = imageFiles{fi};

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
    