% Input data viewer
% Displays original image and its mask (made by Aleksej's
% SaliencyDetection)

path_mask = '../data/masks/';
path_orig = '../data/original/';
%file_images = {'0000004.jpg'}; % leave empty to process all in path_mask folder.
file_images = {};

if isempty(file_images)
    % Scan data folder for files
    file_images = dir([path_mask,'*.jpg']);
    file_images = {file_images.name};
end

numImages = numel(file_images);

for image_i = 1:numImages
    file_image = file_images{image_i};
    
    Iorig = imread([path_orig,file_image]);
    Imask = imread([path_mask,file_image]);
    
    imshowpair(Iorig, Imask, 'montage');
    title(file_image);
    w = waitforbuttonpress;
end