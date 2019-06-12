function [BBoxes] = run(file_images,show,saveOutputImage)
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
    image_ids=file_images;
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

if ~exist('saveOutputImage','var') || isempty(saveOutputImage)
    saveOutputImage = 0;
end

% Specify folders for input/output
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/results';
folder_out = [folder_out,filesep,datestr(datetime('now'),'YYYY-mm-DD-HH-MM-SS') ];

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
% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    ticID = tic();
    % Run detector
    [~, BBfull, BW] = findROI(imagePath,param,show);
    
    BBox_image=[];
    for b_i=1:size(BBfull,1)
        BBox=bbox2points(BBfull(b_i,:));
        BBox=reshape(BBox',[1,numel(BBox)]);
        BBox_image=[BBox_image, BBox];
    end
    BBoxes{image_i}.BBox=BBox_image;
    BBoxes{image_i}.id=image_ids(image_i);
    
    t = toc(ticID);
    totalTime = totalTime + t;
    
    if saveOutputImage
        RGB = imread(imagePath);
        I = imfuse(BW,RGB,'blend');
        f = figure('visible','off');
        hold on;
        imshow(I, 'InitialMagnification',80);
        K = size(BBfull,1);
        for k = 1: K
            rectangle('Position',BBfull(k,:),'EdgeColor','m','LineWidth',2);
        end
        
        % Save
        savePath = [folder_out,filesep,file_image];
        %imwrite(RGBcc, savePath);
        saveas(f,savePath,'jpg');
    end
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
     
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);