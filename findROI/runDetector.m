function [BBoxes, file_images, param, folder_out, ANNOT] = runDetector(file_images,show,saveImage,saveResults)
% Pipeline for traffic signs detection and ROI extraction
% file_images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder
% show:  0 - do not display anything
%        1 - display final results
%        2 - display intermediate results

if ~exist('file_images','var')
    file_images = [];
elseif isnumeric(file_images)
    %image_ids = file_images;
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

if ~exist('saveImage','var') || isempty(saveImage)
    saveImage = 0;
end
if ~exist('saveResults','var') || isempty(saveResults)
    saveResults = 0;
end

%--------------------------------------------------------------------------
% Load parameters configuration
param = config();

algorithm = param.general.findROIalgorithm;

% Specify folders for input/output
format = param.general.imageFormat;
folder_in = param.general.folderSource;
folder_out = param.general.folderResults;
folder_out = [folder_out,filesep,[algorithm,'-',datestr(datetime('now'),'YYYY-mm-DD-HH-MM-SS')] ];

%--------------------------------------------------------------------------

% Scan data folder for files
if isempty(file_images)
    file_images = dir([folder_in,'/*.',format]);
    file_images = {file_images.name};
end

isFilterImageSize = ~isempty(param.general.imageSize);
isFilterOnlyAnnotated = param.general.keepOnlyAnnotated;
isOracle = strcmpi(algorithm,'oracle');

loadAnnotations = isFilterImageSize | isFilterOnlyAnnotated | isOracle;

if loadAnnotations
    annot = load(param.general.annotations);
    annot = annot.ANNOT;
end

if isFilterOnlyAnnotated || isFilterImageSize
    [keepMask,validInd] = ismember(file_images, {annot.images.file_name});    
    if isFilterImageSize
        % Filter by image size
        sizeMask = true(1,numel(validInd));
        for v = 1:numel(validInd)
            if validInd(v) == 0
                continue;
            end
            sizeMask(v) = ([annot.images(validInd(v)).height] == param.general.imageSize(1)) & ...
            ([annot.images(validInd(v)).width] == param.general.imageSize(2));        
        end    
        keepMask = keepMask & sizeMask;
    end
    file_images = file_images(keepMask);
end

% Load annotations for Oracle
ANNOT = [];
if isOracle    
    ANNOT = annotationsGetByFilename(annot,file_images, param.general.filterIgnore);
end

if saveImage || saveResults
    % Create output folder if it does not exist already.
    [~,~,~] = mkdir(folder_out);
end

numImages = numel(file_images);
BBoxes = cell(numImages,1);

% Loop over all files with images
ticID2 = tic();
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    ticID = tic();
    % Run detector
    if isOracle
        [BBtight, BBfull, BW] = findROIoracle(imagePath,param,show,ANNOT{image_i});    
    
    elseif strcmpi(algorithm,'dummy')
        [BBtight, BBfull, BW] = findROIdummy(imagePath,param,show);
        
    elseif strcmpi(algorithm,'smarty')
        [BBtight, BBfull, BW] = findROI(imagePath,param,show);
    
    elseif strcmpi(algorithm,'smarty2')
        [BBtight, BBfull, BW] = findROIv2(imagePath,param,show);
            
    elseif strcmpi(algorithm,'smartyColor')
        [BBtight, BBfull, BW] = findROIcolor(imagePath,param,show);
    
    else
        error('Wrong findROI algorithm %s.\n',algorithm);
    end
    
    BBox_image_tight=[];
    BBox_image_full=[];
    for b_i=1:size(BBfull,1)
        BBox=bbox2points(BBfull(b_i,:));
        BBox=reshape(BBox',[1,numel(BBox)]);
        BBox_image_full=[BBox_image_full, BBox];
        
        BBox=bbox2points(BBtight(b_i,:));
        BBox=reshape(BBox',[1,numel(BBox)]);
        BBox_image_tight=[BBox_image_tight, BBox];
    end
    BBoxes{image_i}.BBox = BBox_image_full;
    BBoxes{image_i}.BBoxTight = BBox_image_tight;
    BBoxes{image_i}.file_name = file_image;
    
    t = toc(ticID);
    
    if saveImage
        RGB = imread(imagePath);
        I = imfuse(BW,RGB,'blend');
        f = figure('visible','off');
        hold on;
        imshow(I, 'InitialMagnification',80);
        K = size(BBfull,1);
        for k = 1: K
            rectangle('Position',BBtight(k,:),'EdgeColor','g','LineWidth',1);
            rectangle('Position',BBfull(k,:),'EdgeColor','m','LineWidth',2);
        end        
        % Save figure
        savePath = [folder_out,filesep,file_image];
        saveas(f,savePath,'jpg');
    end
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
     
end
timeDetection = toc(ticID2);
% Save results in MAT file
if saveResults
    save([folder_out,filesep,'results.mat'], 'BBoxes', 'file_images', 'param', 'timeDetection');
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, timeDetection);