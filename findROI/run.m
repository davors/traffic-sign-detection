function [allCentroidsROI]=run(file_images)
% Pipeline for traffic signs detection and ROI extraction
% file_images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder

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

% Specify folders for input/output
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/results';

%--------------------------------------------------------------------------
% Parameters
histEqMethod = 'local'; % 'global', 'local', 'none'
colConstMethod = 'gray'; % 'white', 'gray', 'none'
roiSize = [704, 704];
roiNum = 3;
show = 1; % 0 - run silently

% Color thresholds 
thrColor.red.Hmin = 0.93;
thrColor.red.Hmax = 0.03;
thrColor.red.Smin = 0.50;
thrColor.red.Smax = 1.00;
thrColor.red.Vmin = 0.20;
thrColor.red.Vmax = 1.00;

thrColor.blue.Hmin = 0.52;
thrColor.blue.Hmax = 0.70;
thrColor.blue.Smin = 0.60;
thrColor.blue.Smax = 1.00;
thrColor.blue.Vmin = 0.20;
thrColor.blue.Vmax = 1.00;

thrColor.yellowDark.Hmin = 0.05;
thrColor.yellowDark.Hmax = 0.13;
thrColor.yellowDark.Smin = 0.64;
thrColor.yellowDark.Smax = 1.00;
thrColor.yellowDark.Vmin = 0.20;
thrColor.yellowDark.Vmax = 1.00;

thrColor.yellowLight.Hmin = 0.13;
thrColor.yellowLight.Hmax = 0.18;
thrColor.yellowLight.Smin = 0.64;
thrColor.yellowLight.Smax = 1.00;
thrColor.yellowLight.Vmin = 0.20;
thrColor.yellowLight.Vmax = 1.00;

thrColor.green.Hmin = 0.36;
thrColor.green.Hmax = 0.47;
thrColor.green.Smin = 0.50;
thrColor.green.Smax = 1.00;
thrColor.green.Vmin = 0.20;
thrColor.green.Vmax = 1.00;

thrColor.greenFluor.Hmin = 0.16;
thrColor.greenFluor.Hmax = 0.22;
thrColor.greenFluor.Smin = 0.70;
thrColor.greenFluor.Smax = 1.00;
thrColor.greenFluor.Vmin = 0.50;
thrColor.greenFluor.Vmax = 1.00;

thrColor.brown.Hmin = 0.00;
thrColor.brown.Hmax = 0.08;
thrColor.brown.Smin = 0.60;
thrColor.brown.Smax = 1.00;
thrColor.brown.Vmin = 0.20;
thrColor.brown.Vmax = 1.00;

% Connected components (blobs) thresholds
% Size of an area we want to filter out (in pixels)
thrCC.AreaMin = 300;
thrCC.AreaMax = 100000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.5;
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.16;
thrCC.AspectMax = 1;


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
Centroids=[];
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    tic();
    % Run detector
    [BBtight, BBfull] = findROI(imagePath,histEqMethod,colConstMethod,thrColor,thrCC,roiNum,roiSize,show);
    
    centroidsROI=BBfull(:,1:2)+BBfull(:,3:4)/2;
    centroidsROI=reshape(centroidsROI',[1,6]);
    allCentroidsROI(image_i,:)=centroidsROI;
    % Save
    %savePath = [folder_out,filesep,file_image];
    %imwrite(RGBcc, savePath, 'Quality',100);
    
    t = toc();
    totalTime = totalTime + t;
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
     
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);