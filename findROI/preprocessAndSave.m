% Script for batch image preprocessing

% Specify folder with input images
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/preprocessed_cc_heq';

show = 0; % 0 - run silently

histogramEqualizationMethod = 'local'; % 'global', 'local', 'none'
colorConstancyMethod = 'gray'; % 'white', 'gray', 'none'

% leave empty to process all in folder_in folder.
%file_images = {'0000118.jpg'}; 
file_images = {};

%--------------------------------------------------------------------------

% Scan data folder for files
if isempty(file_images)
    file_images = dir([folder_in,'/*.',format]);
    file_images = {file_images.name};
end

% Create output folder if it does not exist already.
[~,~,~] = mkdir(folder_out);

numImages = numel(file_images);

totalTime = 0;
% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    
    tic();
    % Read file
    RGB = imread([folder_in, filesep, file_image]);
    
    % Preprocess
    RGBcc = preprocessColorConstancy(RGB,colorConstancyMethod);
    RGBheq = preprocessHistogramEq(RGBcc,histogramEqualizationMethod);
    
    
    % Save
    savePath = [folder_out,filesep,file_image];
    imwrite(RGBheq, savePath, 'Quality',100);
    
    t = toc();
    totalTime = totalTime + t;
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
    
    % Show results if in interactive mode
    if show
        montage({RGB, RGBcc, RGBheq},'BorderSize',11,'BackgroundColor','w');
        fprintf(1, 'File %s | hist. eq. (%s) | Color Constancy (%s)', file_image, histogramEqualizationMethod, colorConstancyMethod);
        if image_i < numImages
            waitforbuttonpress();
        end
    end   
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);