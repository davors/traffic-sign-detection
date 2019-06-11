function [allCentroidsROI] = run(file_images,show)
% Pipeline for traffic signs detection and ROI extraction
% file_images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder
% show:  0 - do not display anything
%        1 - display final results
%        2 - display intermediate results

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

if ~exist('show','var') || isempty(show)
    show = 0;
end

% Specify folders for input/output
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/results';



%--------------------------------------------------------------------------
% Load parameters configuration
param = config();


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
allCentroidsROI = zeros(numImages,param.roi.num*2);
% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    tic();
    % Run detector
    [~, BBfull] = findROI(imagePath,param,show);
    
    centroidsROI=BBfull(:,1:2)+BBfull(:,3:4)/2;
    centroidsROI=reshape(centroidsROI',[1,param.roi.num*2]);
    allCentroidsROI(image_i,:)=centroidsROI;
    
    % Save
    %savePath = [folder_out,filesep,file_image];
    %imwrite(RGBcc, savePath, 'Quality',100);
    
    t = toc();
    totalTime = totalTime + t;
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
     
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);