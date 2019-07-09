function [BBtight, BBfull, BWmerged, CC] = findROIcolor2(imageFile,param,showResults)

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end


% Read file
RGB = imread(imageFile);
[imHeight, imWidth, ~] = size(RGB);

if strcmpi(param.general.colorMode,'HSV')
    I = rgb2hsv(RGB);
else
    I = RGB;
end

% =========== COLORS ======================================================
% Initial preprocessing
I_col = preprocess(I, param.colors.initPipeline, param.colors.initMethods, param.general.colorMode);

% HSV thresholding
BWmasks = thresholdsHSV(I_col,param.colors.thrHSV, param.general.colorMode);
BW = any(BWmasks,3);

% Filter merged masks
filters = param.colors2.maskFilters;
BWfilt = filterMask(BW, filters);

% Connected components on masks + filtering
[~, BWmerged_color, CC_color] = filterConnComp(BWfilt, param.colors.thrCC);

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BW,BWfilt,BWmerged_color),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
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
%BWmerged = BWmerged_white | BWmerged_color;
%BW_white_only = BWmerged_white & ~BWmerged_color;
%CC_white_only = bwconncomp(BW_white_only);


% weightWhite = param.white.weight;
% weightColor = param.colors.weight;
% 
% CC = struct();
% CC.ImageSize = CC_white_only.ImageSize;
% CC.Connectivity = CC_white_only.Connectivity;
% CC.NumObjects = CC_white_only.NumObjects + CC_color.NumObjects;
% CC.PixelIdxList = [CC_white_only.PixelIdxList, CC_color.PixelIdxList];
% CC.Weights = [ones(1,CC_white_only.NumObjects)*weightWhite, ones(1,CC_color.NumObjects)*weightColor];

CC = CC_color;
BWmerged = BWmerged_color;


% =========== RECTANGLE COVERING ==========================================
% Check for image size
sizeInd = cellfun(@(x) (all(x==[imHeight, imWidth])), param.roi.default.imageSize, 'UniformOutput', 1);
if any(sizeInd)
    param.roi.default.pos = param.roi.default.pos{sizeInd};
else
    param.roi.default.pos = [];
end

if param.roi.disableHorizontalMove && ~param.roi.allowLeftRightFloat
    [BBtight, BBfull, areaLeft] = coverWithRectanglesVertical(CC, param.roi);
elseif param.roi.disableHorizontalMove && param.roi.allowLeftRightFloat && param.roi.allowMiddleFloat
    [BBtight, BBfull, areaLeft] = coverWithRectanglesVerticalFloatAll(CC, param.roi);
else
    [BBtight, BBfull, areaLeft] = coverWithRectangles(CC, param.roi);
end

if showResults
    Kreal = size(BBtight,1);
    % Visualize
    L = labelmatrix(CC);
    if CC.NumObjects == 0
        Icc = L;
    else
        Icc = label2rgb(L,repmat([1 1 1],CC.NumObjects,1),'black');
    end
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
