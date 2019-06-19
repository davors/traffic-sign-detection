function [BBtight, BBfull, BWmerged, CC] = findROI(imageFile,param,showResults)

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end


% Read file
RGB = imread(imageFile);

if strcmpi(param.general.colorMode,'HSV')
    I = rgb2hsv(RGB);
else
    I = RGB;
end

% =========== WHITE ======================================================
% Initial preprocessing
I_white = preprocess(I, param.white.initPipeline, param.white.initMethods, param.general.colorMode);

% HSV thresholding
BWmasks = thresholdsHSV(I_white, param.white.thrHSV, param.general.colorMode);
BWmasks_old_1 = BWmasks; % layer masks - for plotting only

% Filter masks
[BWmasks] = filterMask(BWmasks, param.white.maskFilters);
BWmasks_old_2 = BWmasks;

% Connected components on masks + filtering
[~, BWmerged_white] = filterConnComp(BWmasks, param.white.thrCC);

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BWmasks_old_1,BWmasks_old_2,BWmerged_white),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
    waitforbuttonpress;
    close();
end


% =========== COLORS ======================================================
% Initial preprocessing
I_col = preprocess(I, param.colors.initPipeline, param.colors.initMethods, param.general.colorMode);

% HSV thresholding
BWmasks = thresholdsHSV(I_col,param.colors.thrHSV, param.general.colorMode);

BW = any(BWmasks,3); % composite mask - for plotting only
BWmasks_old_1 = BWmasks; % layer masks - for plotting only

% Filter masks
[BWmasks] = filterMask(BWmasks, param.colors.maskFilters);
BWmasks_old_2 = BWmasks;
BWfilt1 = any(BWmasks,3);

% Connected components on masks + filtering
[BWmasks, BWmerged_color, CC_color] = filterConnComp(BWmasks, param.colors.thrCC);

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BWmasks_old_1,BW,BWmasks_old_2,BWfilt1,BWmasks,BWmerged_color),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
    waitforbuttonpress;
    close();
end


% =========== FUSION ================================================
% Add white objects to color ones if they have centroids close enough.
% CCprop_white = regionprops(CC_white, 'Centroid');
% CCprop_color = regionprops(CC_color, 'Centroid');
% numBlobsWhite = CC_white.NumObjects;
% numBlobsColor = CC_color.NumObjects;
% 
% centroids_white = reshape([CCprop_white.Centroid],2,numBlobsWhite)';
% centroids_color = reshape([CCprop_color.Centroid],2,numBlobsColor)';
% 
% D = pdist2(centroids_color, centroids_white, 'euclidean');
% TODO ...

%BW_white_color = BWmerged_color | BWmerged_white;
%CC = bwconncomp(BW_white_color);

% Weight pixels - color ones are more valuable
BWmerged = BWmerged_white | BWmerged_color;
BW_white_only = BWmerged_white & ~BWmerged_color;
CC_white_only = bwconncomp(BW_white_only);


weightWhite = param.white.weight;
weightColor = param.colors.weight;

CC = struct();
CC.ImageSize = CC_white_only.ImageSize;
CC.Connectivity = CC_white_only.Connectivity;
CC.NumObjects = CC_white_only.NumObjects + CC_color.NumObjects;
CC.PixelIdxList = [CC_white_only.PixelIdxList, CC_color.PixelIdxList];
CC.Weights = [ones(1,CC_white_only.NumObjects)*weightWhite, ones(1,CC_color.NumObjects)*weightColor];




% =========== RECTANGLE COVERING ==========================================
% Check for image size
[imHeight, imWidth, ~] = size(RGB);
sizeInd = cellfun(@(x) (all(x==[imHeight, imWidth])), param.roi.default.imageSize, 'UniformOutput', 1);
if any(sizeInd)
    param.roi.default.pos = param.roi.default.pos{sizeInd};
else
    param.roi.default.pos = [];
end

[BBtight, BBfull, areaLeft] = coverWithRectangles(CC, param.roi);
% see also: findClusters, placeBoxes

if showResults
    Kreal = size(BBtight,1);
    % Visualize
    L = labelmatrix(CC);
    Icc = label2rgb(L,repmat([1 1 1],CC.NumObjects,1),'black');
    Im_fused = imfuse(Icc, RGB, 'blend');
    figure('units','normalized','OuterPosition',[0 0 1 1]);
    imshow(Im_fused, 'InitialMagnification','fit');
    for k = 1: Kreal
        rectangle('Position',BBtight(k,:),'EdgeColor','g','LineWidth',2);
        rectangle('Position',BBfull(k,:),'EdgeColor','m','LineWidth',2);
    end
    title(sprintf('Objects covered with %d rectangle(s). Remained pixels: %d',Kreal,areaLeft));
    waitforbuttonpress;
    close;
end
