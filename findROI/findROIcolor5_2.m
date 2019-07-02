function [BBtight, BBfull, BWmerged, CC] = findROIcolor5_2(imageFile,param,showResults)

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

% Fill all masks
if showResults > 1
    BWmasks_after_thresholdHSV = any(BWmasks,3);
end
BWmasks = filterMask(BWmasks,{'fill'});
if showResults > 1
    BWmasks_after_fill = any(BWmasks,3);
end

% Lower band processing
lowerBand = (704 + 50);

% Filter masks by color: clear blue sky, bottom particles, and small particles
% Filter sky: blue regions that touch the upper border
blueInd = strcmpi(colors,'blue');
blueBW = BWmasks(:,:,blueInd);
if showResults > 1
    blueBW_old = blueBW;
end
% erode a little
blueBW = filterMask(blueBW,{'erode_2'});
blueCC = bwconncomp(blueBW);
blueCCprops = regionprops(blueCC,'BoundingBox','Area');
blueBBoxes = reshape([blueCCprops.BoundingBox],4,blueCC.NumObjects)';
blueSkyInd = blueBBoxes(:,2) <= 1;
% Filter by blob size (max 208000)
blueAreaMask = [blueCCprops.Area]' >= 208000;
blueBW(vertcat(blueCC.PixelIdxList{blueSkyInd | blueAreaMask})) = 0;
blueBW = filterMask(blueBW,{'dilate_2'});
BWmasks(:,:,blueInd) = blueBW;


% GLOBAL
% Filter small/big particles on every color mask on whole image
% Filter regions that touches bottom border
thrCC = [];
thrCC.AreaMin = 300;
thrCC.AreaMax = 321100;
thrCC.WidthMin = 10;
thrCC.HeightMin = 10;
thrCC.ExtentMin = 0.10;
thrCC.AspectMin = 0.115; %0.125
thrCC.A2PSqMin = 0.005;
thrCC.ClearBandYMin = imHeight - 40;
thrCC.ClearBandYMax = Inf;
BWmasks = filterConnComp(BWmasks, thrCC);
if showResults > 1
    BW_smallParts = any(BWmasks,3);
end
filters = {'close_10','fillWithBorder'};
BWmasks = filterMask(BWmasks, filters);

% Special cases for blobs area in different colors
% GREEN + GREEN FLUOR
greenInd = ismember(colors,{'green','greenFluor'});
thrCC = [];
thrCC.AreaMin = 1000;
thrCC.AreaMax = 198000;
thrCC.AspectMin = 0.0;
thrCC.ClearBandYMin = lowerBand;
thrCC.ClearBandYMax = Inf;
BWmasks(:,:,greenInd) = filterConnComp(BWmasks(:,:,greenInd), thrCC);

% YELLOW-LIGHT
yellowLightInd = strcmpi(colors,{'yellowLight'});
thrCC = [];
thrCC.AreaMax = 155000; % file 2424.jpg
BWmasks(:,:,yellowLightInd) = filterConnComp(BWmasks(:,:,yellowLightInd), thrCC);

% RED
redInd = ismember(colors,{'red'});
thrCC = [];
thrCC.AreaMax = 120000;
BWmasks(:,:,redInd) = filterConnComp(BWmasks(:,:,redInd), thrCC);
redMask = BWmasks(:,:,redInd);

% BROWN
brownInd = ismember(colors,{'brown'});
thrCC = [];
thrCC.AreaMax = 50000;
thrCC.ExtentMin = 0.20;
thrCC.A2PSqMin = 0.012;
BWmasks(:,:,brownInd) = filterConnComp(BWmasks(:,:,brownInd), thrCC);

%-------------------------------------------------------

% OTHER: Filter all colors except red and yellows
colorOthInd = ~ismember(colors,{'red','yellowLight','yellowDark','brown'});
% OTHER: whole image
BW_oth = any(BWmasks(:,:,colorOthInd),3);

% Connected components filtering
thrCC=[];
thrCC.HeightMin=25;
thrCC.WidthMin=25;
thrCC.AreaMin = 500; % 625, 5000
thrCC.AreaMax = 210000;
thrCC.ExtentMin = 0.4;
thrCC.AspectMin = 0.16;
thrCC.A2PSqMin = 0.011;
BW_oth = filterConnComp(BW_oth, thrCC);

% OTHER: Lower band
BW_oth_lower = BW_oth(lowerBand:end,:);
thrCC = [];
thrCC.AreaMin = 800;
thrCC.AreaMax = 30000;
thrCC.WidthMin = 30;
thrCC.HeightMin = 30;
thrCC.ExtentMin = 0.3;
thrCC.A2PSqMin = 0.021;
BW_oth_lower = filterConnComp(BW_oth_lower, thrCC);
% Get whole image
BW_oth(lowerBand:end,:) = BW_oth_lower;


% RED, YELLOW, BROWN
% Process red and yellow separately
BWmasks_RY = any(BWmasks(:,:,~colorOthInd),3);
%BWmasks_RY = filterMask(BWmasks_RY,{'close_10','fillWithBorder'});
% Upper band
BWmasks_RY_up = BWmasks_RY(1:lowerBand-1,:);
thrCC = [];
thrCC.AreaMin = 0;
thrCC.AreaMax = Inf;
thrCC.WidthMin = 0;
thrCC.HeightMin = 0;
thrCC.ExtentMin = 0.2;
thrCC.AspectMin = 0.1;
thrCC.A2PSqMin = 0.017;
BWmasks_RY_up_filt = filterConnComp(BWmasks_RY_up, thrCC);

% Lower band
BWmasks_RY_low = BWmasks_RY(lowerBand:end,:);
thrCC = [];
thrCC.AreaMin = 625; % 400
thrCC.AreaMax = 20000;
thrCC.WidthMin = 25;
thrCC.HeightMin = 25;
thrCC.ExtentMin = 0.25; %0.28
thrCC.AspectMin = 0.1;
thrCC.A2PSqMin = 0.012; %0.017
BWmasks_RY_low_filt = filterConnComp(BWmasks_RY_low, thrCC);
% Get whole image (red and yellow)
BW_RY = [BWmasks_RY_up_filt; BWmasks_RY_low_filt];



% Add red and yellow blobs
redMask(lowerBand:end,:) = 0;
BWmerged = BW_oth | BW_RY | redMask;
BWmerged = filterMask(BWmerged,{'fillWithBorder'});
CC = bwconncomp(BWmerged);

if showResults > 1
    figure();
    montage({RGB, BWmasks_after_thresholdHSV, BWmasks_after_fill, blueBW_old, blueBW, BW_smallParts, BW_oth, BWmasks_RY, BW_RY, BWmerged},'BorderSize',10,'BackgroundColor','w');
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
