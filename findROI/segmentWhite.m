function segmentWhite(file_images)
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

show = 0; % interactive plots

% Specify folders for input/output
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/segmentWhite';

%--------------------------------------------------------------------------
% Parameters
histEqMethod = 'local'; % 'global', 'local', 'none'
colConstMethod = 'gray'; % 'white', 'gray', 'none'

% Thresholds for "white" in HSV color space
thrHSV = struct();
thrHSV.white.Hmin = 0.00;
thrHSV.white.Hmax = 1.00;
thrHSV.white.Smin = 0.00;
thrHSV.white.Smax = 0.25;
thrHSV.white.Vmin = 0.80;
thrHSV.white.Vmax = 1.00;

% Connected components filter
% Size of an area we want to filter out (in pixels)
thrCC = struct();
thrCC.AreaMin = 700;
thrCC.AreaMax = 30000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.75;
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

% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    % Read file
    RGB = imread(imagePath);
    
    % Preprocess
    RGB = preprocessColorConstancy(RGB,colConstMethod);
    RGB = preprocessHistogramEq(RGB,histEqMethod);
    RGB = imadjust(RGB, [0.4 0.4 0.4; 0.7 0.7 0.7],[]);
    
    
    % Otsu thresholding
    % IDEA: imbinarize each of RGB channels: 
    %BW1 = imbinarize(RGB);
    %BW1 = imbinarize(rgb2gray(RGB));
    
    %HSV = rgb2hsv(RGB);
    %BW1 = imbinarize(HSV(:,:,3));
    
    % HSV thresholding    
    BW1 = thresholdsHSV(RGB, thrHSV);
    
    % Filter
    BW2 = filterMask(BW1, {'close_1','fill','open_5'});
    
    % Connected components    
    [~, BW3, CC] = filterConnComp(BW2,thrCC);
    
    if show
        figure;
        montage({RGB, BW1, BW2, BW3},'BorderSize',10,'BackgroundColor','b');
        fprintf(1,'Click on image to proceed.\n');
        waitforbuttonpress;
        close;
    end
    
    [filepath,name,ext] = fileparts(file_image);
    imwrite(BW3,[folder_out,filesep,name,'.png']);
    fprintf(1,'Done %d of %d\n',image_i,numImages);
    
end