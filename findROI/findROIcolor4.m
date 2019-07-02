function [BBtight, BBfull, BWmerged, CC] = findROIcolor4(imageFile,param,showResults)

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
[BWmasks, colors] = thresholdsHSV(I_col,param.colors.thrHSV, param.general.colorMode);


% Filter masks by color: clear blue sky, bottom particles, and small particles
% Filter sky: blue regions that touch the upper border
blueInd = strcmpi(colors,'blue');
blueBW = BWmasks(:,:,blueInd);
blueBW_old = blueBW;
% erode a little
blueBW = filterMask(blueBW,{'fill','erode_2'});
blueCC = bwconncomp(blueBW);
blueCCprops = regionprops(blueCC,'BoundingBox');
blueBBoxes = reshape([blueCCprops.BoundingBox],4,blueCC.NumObjects)';
blueSkyInd = blueBBoxes(:,2) <= 1;
blueBW(vertcat(blueCC.PixelIdxList{blueSkyInd})) = 0;
blueBW = filterMask(blueBW,{'dilate_2'});
BWmasks(:,:,blueInd) = blueBW;


% Filter small particles on every color mask on whole image
% Filter regions that touches bottom border
thrSmallCC = [];
thrSmallCC.AreaMin = 300;
thrSmallCC.WidthMin = 10;
thrSmallCC.HeightMin = 10;
thrSmallCC.ExtentMin = 0.10;
thrSmallCC.ClearBandYMin = imHeight - 40;
thrSmallCC.ClearBandYMax = Inf;
BWmasks = filterConnComp(BWmasks, thrSmallCC);
BW_smallParts = any(BWmasks,3);

% Lower band processing
lowerBand = (704 + 50); %floor(imHeight*0.667);

% Filter all colors except red and yellows
colorSelInd = ~ismember(colors,{'red','yellowLight','yellowDark'});

BWmasksSel = any(BWmasks(lowerBand:end,:,colorSelInd),3);
thrSmallCC = [];
thrSmallCC.AreaMin = 800;
thrSmallCC.AreaMax = 30000;
thrSmallCC.WidthMin = 50;
thrSmallCC.HeightMin = 50;
thrSmallCC.ExtentMin = 0.3;
thrSmallCC.A2PSqMin = 0.021;
BW_lowerBand = filterConnComp(BWmasksSel, thrSmallCC);

% Get whole image (all colors in upper and selected in lower band)
BW_oth = any(BWmasks,3);
BW_oth(lowerBand:end,:) = BW_lowerBand;

% Process red and yellow separately
BWmasks_RY = any(BWmasks(lowerBand:end,:,~colorSelInd),3);
thrSmallCC = [];
thrSmallCC.AreaMin = 500;
thrSmallCC.AreaMax = 20000;
thrSmallCC.WidthMin = 30;
thrSmallCC.HeightMin = 30;
thrSmallCC.ExtentMin = 0.3;
thrSmallCC.A2PSqMin = 0.021;
BWmasks_RY_filt = filterConnComp(BWmasks_RY, thrSmallCC);

% Get whole image (red and yellow)
BW_RY = any(BWmasks(:,:,~colorSelInd),3);
BW_RY(lowerBand:end,:) = BWmasks_RY_filt;


if showResults > 1
    figure();
    montage({blueBW_old, blueBW, any(BWmasks,3), BW_smallParts, BW_oth, BWmasks_RY, BW_RY, RGB},'BorderSize',10,'BackgroundColor','w');
    waitforbuttonpress;
    close();
end

% Filter again
filters = param.colors2.maskFilters;
BWfilt = filterMask(BW_oth, filters);

% Connected components on masks + filtering
BWmerged_color = filterConnComp(BWfilt, param.colors.thrCC);

% Retain red and yellow blobs in the lower band
BWmerged_color = BWmerged_color | BW_RY;

CC_color = bwconncomp(BWmerged_color);

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BW_oth,BWfilt,BWmerged_color),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
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
