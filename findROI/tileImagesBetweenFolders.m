% Tile images from different folders for easier comparison of preprocessing
% steps.


format = 'jpg';
%folders_in = {'../data/original', '../data/preprocessed_heq', '../data/preprocessed_heq_cc', '../data/preprocessed_cc_heq'};
%folder_out = '../data/tileImagesBetweenFolders/v2';

folders_in = {'../data/results/white_cc_none', '../data/results/white_cc_gray'};
folder_out = '../data/results/compare';


% leave empty to process all in folder_in folder.
%file_images = {'0000118.jpg'}; 
file_images = {};

if isempty(file_images)
    file_images = dir([folders_in{1},'/*.',format]);
    file_images = {file_images.name};
end

[~,~,~] = mkdir(folder_out);

numImages = numel(file_images);
numFolders = numel(folders_in);

% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    
    files = strcat(folders_in,filesep,file_image);
    
    img = imtile(files);
    
    savePath = [folder_out,filesep,file_image];
    imwrite(img, savePath, 'Quality',100);
    fprintf(1,'Done %s.\n', file_image);
end