function CCout = filterConnComp2(CC, thr)

if CC.NumObjects == 0
   CCout = CC;
   return;    
end

% CC can have field 'BBoxes' that has bounding boxes of components inside
bboxesInside = isfield(CC,'BBoxes');

% Extremes of thresholds
ext_AreaMin = 0;
ext_AreaMax = Inf;
ext_ExtentMin = 0;
ext_ExtentMax = 1;
ext_AspectMin = 0;
ext_AspectMax = 1;
ext_HeightMin = 0;
ext_HeightMax = Inf;
ext_WidthMin = 0;
ext_WidthMax = Inf;
ext_A2PSqMin = 0;
ext_A2PSqMax = Inf;
ext_ClearBandYMin = -Inf;
ext_ClearBandYMax = -Inf;

% defaults
if ~isfield(thr,'AreaMin')
    thr.AreaMin = ext_AreaMin;
end
if ~isfield(thr,'AreaMax')
    thr.AreaMax = ext_AreaMax;
end
if ~isfield(thr,'ExtentMin')
    thr.ExtentMin = ext_ExtentMin;
end
if ~isfield(thr,'ExtentMax')
    thr.ExtentMax = ext_ExtentMax;
end
if ~isfield(thr,'AspectMin')
    thr.AspectMin = ext_AspectMin;
end
if ~isfield(thr,'AspectMax')
    thr.AspectMax = ext_AspectMax;
end
if ~isfield(thr,'HeightMin')
    thr.HeightMin = ext_HeightMin;
end
if ~isfield(thr,'HeightMax')
    thr.HeightMax = ext_HeightMax;
end
if ~isfield(thr,'WidthMin')
    thr.WidthMin = ext_WidthMin;
end
if ~isfield(thr,'WidthMax')
    thr.WidthMax = ext_WidthMax;
end
if ~isfield(thr,'A2PSqMin')
    thr.A2PSqMin = ext_A2PSqMin;
end
if ~isfield(thr,'A2PSqMax')
    thr.A2PSqMax = ext_A2PSqMax;
end
if ~isfield(thr,'ClearBandYMin')
    thr.ClearBandYMin = ext_ClearBandYMin;
end
if ~isfield(thr,'ClearBandYMax')
    thr.ClearBandYMax = ext_ClearBandYMax;
end
if ~isfield(thr,'ClearBorderLeftRight')
    thr.ClearBorderLeftRight = 0;
end

% Determine what to compute
isArea =   ~((thr.AreaMin == ext_AreaMin) && (thr.AreaMax == ext_AreaMax));
isExtent = ~((thr.ExtentMin == ext_ExtentMin) && (thr.ExtentMax == ext_ExtentMax));
isAspect = ~((thr.AspectMin == ext_AspectMin) && (thr.AspectMax == ext_AspectMax));
isHeight = ~((thr.HeightMin == ext_HeightMin) && (thr.HeightMax == ext_HeightMax));
isWidth =  ~((thr.WidthMin == ext_WidthMin) && (thr.WidthMax == ext_WidthMax));
isA2PSq =  ~((thr.A2PSqMin == ext_A2PSqMin) && (thr.A2PSqMax == ext_A2PSqMax));
isClearBandY = ~((thr.ClearBandYMin == ext_ClearBandYMin) && (thr.ClearBandYMax == ext_ClearBandYMax));
isClearBorderLeftRight = thr.ClearBorderLeftRight;

computeArea = isArea || isA2PSq;
computeExtent = isExtent;
computeBBox = isAspect || isWidth || isHeight || isClearBandY || isClearBorderLeftRight;
computePerimeter = isA2PSq;

% If there is nothing to do, return.
if ~(isArea || isExtent || isAspect || isHeight || isWidth || isA2PSq || isClearBandY || isClearBorderLeftRight)
    CCout = CC;
    return;
end

if bboxesInside
    computeBBox = false;
    bboxes = CC.BBoxes;
    bb_width = bboxes(:,3)';
    bb_height = bboxes(:,4)';
end

statStr = {};
if computeArea
    statStr = [statStr, 'Area'];
end
if computeExtent
    statStr = [statStr, 'Extent'];
end
if computeBBox
    statStr = [statStr, 'BoundingBox'];
end
if computePerimeter
    statStr = [statStr, 'Perimeter'];
end

% Compute regions properties
if ~isempty(statStr)
    stat = regionprops(CC, statStr);
end

if isArea
    maskArea = ([stat.Area] >= thr.AreaMin) & ([stat.Area] <= thr.AreaMax);
else
    maskArea = true(1, CC.NumObjects);
end

if isExtent
    maskExtent = ([stat.Extent] >= thr.ExtentMin) & ([stat.Extent] <= thr.ExtentMax);
else
    maskExtent = true(1, CC.NumObjects);
end

if computeBBox
    bboxes = reshape([stat.BoundingBox],4,CC.NumObjects)';
    bb_width = bboxes(:,3)';
    bb_height = bboxes(:,4)';
end

if isAspect
    bb_aspect = bb_width ./ bb_height;
    flipOver = bb_aspect > 1;
    bb_aspect(flipOver) = 1./bb_aspect(flipOver);
    maskAspect = (bb_aspect >= thr.AspectMin) & (bb_aspect <= thr.AspectMax);
else
    maskAspect = true(1, CC.NumObjects);
end

if isWidth || isHeight
    maskDim = (bb_width >= thr.WidthMin) & (bb_height >= thr.HeightMin);
else
    maskDim = true(1, CC.NumObjects);
end

if isClearBandY
    % Delete blobs that touch clearBand
    bbox_upper = bboxes(:,2);
    bbox_lower = (bboxes(:,2)+bboxes(:,4));
    clearBandInd = ...
        ((bbox_upper >= thr.ClearBandYMin) & (bbox_upper <= thr.ClearBandYMax)) | ...
        ((bbox_lower >= thr.ClearBandYMin) & (bbox_lower <= thr.ClearBandYMax));
    maskClearBandY = ~clearBandInd';
else
    maskClearBandY = true(1, CC.NumObjects);
end

if isClearBorderLeftRight
    % Delete blobs that touch left or right border of an image
    offset = 1; % number of px for offset of strict border    
    imWidth = CC.ImageSize(2);
    bbox_left = bboxes(:,1);
    bbox_right = (bboxes(:,1)+bboxes(:,3));
    clearInd = (bbox_left <= offset) | (bbox_right >= (imWidth-offset));
    maskClearBorderLeftRight = ~clearInd';
else
    maskClearBorderLeftRight = true(1, CC.NumObjects);
end


if isA2PSq
    A2PSq = [stat.Area]./([stat.Perimeter].^2);
    maskA2PSq = (A2PSq >= thr.A2PSqMin) & (A2PSq <= thr.A2PSqMax);
else
    maskA2PSq = true(1, CC.NumObjects);
end

% Join filters
mask = maskArea & maskExtent & maskAspect & maskA2PSq & maskDim & maskClearBandY & maskClearBorderLeftRight;

CCout = struct();
CCout.Connectivity = CC.Connectivity;
CCout.ImageSize = CC.ImageSize;
CCout.NumObjects = sum(mask);
CCout.PixelIdxList = CC.PixelIdxList(mask);
if bboxesInside
    CCout.BBoxes = CC.BBoxes(mask,:);
end


