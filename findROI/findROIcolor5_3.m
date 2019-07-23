function [BBtight, BBfull, BWmerged, CC] = findROIcolor5_3(imageFile,param,showResults)

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end

% =========== PARAMETERS ==================================================

% Crop bottom part of the image (px)
cropBottom = 40;

% Lower band of the image
lowerBand = (704 + 50);

% Blue sky - num. of pixels that touches upper border of image
blueSkyPixelsLimit = Inf;%50;

% Filters for morphological image processing
morphFilters = {'reconstruct_4','close_10','fillWithBorder'};%{'erode_2','close_10','fill'};


% Read file
RGB = imread(imageFile);
[imHeight, imWidth, ~] = size(RGB);

if strcmpi(param.general.colorMode,'HSV')
    I = rgb2hsv(RGB);
else
    I = RGB;
end

%--------------------------------------------------------------------------
% Initial preprocessing
%--------------------------------------------------------------------------
I_col = preprocess(I, param.colors.initPipeline, param.colors.initMethods, param.general.colorMode);


%--------------------------------------------------------------------------
% HSV thresholding
%--------------------------------------------------------------------------
[BWmasks, colors] = thresholdsHSV(I_col,param.colors.thrHSV, param.general.colorMode);


%--------------------------------------------------------------------------
% Join similar colors
%   red = (red+brown)
%   green = (green+greenFluor)
%   yellow = (yellowLight+yellowDark)
%   blue = blue
%
% Crop the bottom part of an image, where we do not expect anything useful.
%--------------------------------------------------------------------------
%redInd = ismember(colors,{'red'});
redInd = ismember(colors,{'red','brown'});
greenInd = ismember(colors,{'green','greenFluor'});
yellowInd = ismember(colors,{'yellowLight','yellowDark'});
blueInd = strcmpi(colors,'blue');

BW_r = any(BWmasks(1:end-cropBottom,:,redInd),3);
BW_g = any(BWmasks(1:end-cropBottom,:,greenInd),3);
BW_y = any(BWmasks(1:end-cropBottom,:,yellowInd),3);
BW_b = BWmasks(1:end-cropBottom,:,blueInd);

if showResults > 1
    BW_r_join = BW_r;
    BW_g_join = BW_g;
    BW_y_join = BW_y;
    BW_b_join = BW_b;
end


%--------------------------------------------------------------------------
% Morphological filters on each mask:
%   - ...
%   - Fill holes
%--------------------------------------------------------------------------
BW_r = filterMask(BW_r,morphFilters);
BW_g = filterMask(BW_g,morphFilters);
BW_y = filterMask(BW_y,morphFilters);
BW_b = filterMask(BW_b,morphFilters);


if showResults > 1
    BW_r_fill = BW_r;
    BW_g_fill = BW_g;
    BW_y_fill = BW_y;
    BW_b_fill = BW_b;
end



%--------------------------------------------------------------------------
% Connected components filtering of each mask
%--------------------------------------------------------------------------
% BLUE
% Get connected components
CC_b = bwconncomp(BW_b);
% Split on upper and lower blobs, add bboxes to CC struct
[CC_b_up, CC_b_low]= splitUpperLower(CC_b, lowerBand);

% CC statistics on upper part of the image

thrCC = [];
thrCC.AreaMin = 500;
thrCC.AreaMax = 208000;
thrCC.WidthMin = 25;
thrCC.HeightMin = 25;
thrCC.ExtentMin = 0.4;
thrCC.AspectMin = 0.16;
thrCC.A2PSqMin = 0.011;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_b_up = filterConnComp2(CC_b_up, thrCC);


% CC statistics on lower part of the image

thrCC = [];
thrCC.AreaMin = 800;
thrCC.AreaMax = 30000;
thrCC.WidthMin = 30;
thrCC.HeightMin = 30;
thrCC.ExtentMin = 0.4;
thrCC.AspectMin = 0.16;
thrCC.A2PSqMin = 0.021;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_b_low = filterConnComp2(CC_b_low, thrCC);


% Remove sky (ie. blue regions that touch the upper border with more than blueSkyPixelsLimit pixels)
blueSkyInd = find(CC_b_up.BBoxes(:,2) <= 1);
blueSkyRemove = false(1,CC_b_up.NumObjects);
if ~isempty(blueSkyInd)
    for bsi = blueSkyInd(:)'
        [Y,~] = ind2sub(CC_b_up.ImageSize,CC_b_up.PixelIdxList{bsi});
        if sum(Y <= 1) >= blueSkyPixelsLimit
            blueSkyRemove(bsi) = true;
        end
    end
end
CC_b_up.PixelIdxList(blueSkyRemove) = [];
CC_b_up.NumObjects = CC_b_up.NumObjects - sum(blueSkyRemove);


%--------------------------------------------------------------------------
% RED
% Get connected components
CC_r = bwconncomp(BW_r);
% Split on upper and lower blobs, add bboxes to CC struct
[CC_r_up, CC_r_low]= splitUpperLower(CC_r, lowerBand);

% CC statistics on upper part of the image
thrCC = [];
thrCC.AreaMin = 300;
thrCC.AreaMax = 120000;
thrCC.WidthMin = 10;
thrCC.HeightMin = 10;
thrCC.ExtentMin = 0.20;
thrCC.AspectMin = 0.115;
thrCC.A2PSqMin = 0.017;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_r_up = filterConnComp2(CC_r_up, thrCC);

% CC statistics on lower part of the image
thrCC = [];
thrCC.AreaMin = 625; %625
thrCC.AreaMax = 20000;
thrCC.WidthMin = 25;
thrCC.HeightMin = 25;
thrCC.ExtentMin = 0.25;
thrCC.AspectMin = 0.115;
thrCC.A2PSqMin = 0.021;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_r_low = filterConnComp2(CC_r_low, thrCC);


%--------------------------------------------------------------------------
% GREEN
% Get connected components
CC_g = bwconncomp(BW_g);
% Split on upper and lower blobs, add bboxes to CC struct
% In 5_2 version we removed everything green in lower band, so no spliting
% is necessary.
%[CC_g_up, CC_g_low]= splitUpperLower(CC_g, lowerBand);

% CC statistics on upper part of the image
thrCC = [];
thrCC.AreaMin = 1000;
thrCC.AreaMax = 198000;
thrCC.WidthMin = 25;
thrCC.HeightMin = 25;
thrCC.ExtentMin = 0.40;
thrCC.AspectMin = 0.16;
thrCC.A2PSqMin = 0.011;
thrCC.ClearBandYMin = lowerBand;
thrCC.ClearBandYMax = Inf;
CC_g_up = filterConnComp2(CC_g, thrCC);

% CC statistics on lower part of the image
% thrCC = [];
% thrCC.AreaMin = 1000;
% thrCC.AreaMax = 30000;
% thrCC.WidthMin = 30;
% thrCC.HeightMin = 30;
% thrCC.ExtentMin = 0.4;
% thrCC.AspectMin = 0.16;
% thrCC.A2PSqMin = 0.021;
% thrCC.ClearBandYMin = imHeight;
% thrCC.ClearBandYMax = Inf;
% CC_g_low = filterConnComp2(CC_g_low, thrCC);



%--------------------------------------------------------------------------
% YELLOW
% Get connected components
CC_y = bwconncomp(BW_y);
% Split on upper and lower blobs, add bboxes to CC struct
[CC_y_up, CC_y_low]= splitUpperLower(CC_y, lowerBand);

% CC statistics on upper part of the image
thrCC = [];
thrCC.AreaMin = 300;
thrCC.AreaMax = 321100;
thrCC.WidthMin = 10;
thrCC.HeightMin = 10;
thrCC.ExtentMin = 0.20;
thrCC.AspectMin = 0.115;
thrCC.A2PSqMin = 0.017;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_y_up = filterConnComp2(CC_y_up, thrCC);

% CC statistics on lower part of the image
thrCC = [];
thrCC.AreaMin = 625;
thrCC.AreaMax = 20000;
thrCC.WidthMin = 25;
thrCC.HeightMin = 25;
thrCC.ExtentMin = 0.25;
thrCC.AspectMin = 0.115;
thrCC.A2PSqMin = 0.012;
thrCC.ClearBandYMin = imHeight - cropBottom;
thrCC.ClearBandYMax = Inf;
CC_y_low = filterConnComp2(CC_y_low, thrCC);

% Save filtered masks
if showResults > 1
    BW_r_filt = CC2BW({CC_r_up, CC_r_low});
    BW_g_filt = CC2BW(CC_g_up);
    BW_y_filt = CC2BW({CC_y_up, CC_y_low});
    BW_b_filt = CC2BW({CC_b_up,CC_b_low});
end

%--------------------------------------------------------------------------
% Merge upper and lower parts
BWmerged = CC2BW({...
    CC_r_up, CC_r_low,...
    CC_g_up, ...
    CC_y_up, CC_y_low,...
    CC_b_up, CC_b_low});
% It is easier to call bwconncomp than manually merge components ;)
CC = bwconncomp(BWmerged);


if showResults > 1
    figure();
    montage({...
        BW_r_join, BW_r_fill, BW_r_filt, ...
        BW_g_join, BW_g_fill, BW_g_filt, ...
        BW_y_join, BW_y_fill, BW_y_filt, ...
        BW_b_join, BW_b_fill, BW_b_filt, ...
        BWmerged, RGB},'BorderSize',10,'BackgroundColor','w');
    waitforbuttonpress;
    close();
end



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
