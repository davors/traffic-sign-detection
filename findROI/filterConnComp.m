function [BWmask,BWmerged,ccOut,CCs] = filterConnComp(BWmask, thr)

numMasks = size(BWmask,3);

% defaults
if ~isfield(thr,'AreaMin')
    thr.AreaMin = 0;
end
if ~isfield(thr,'AreaMax')
    thr.AreaMax = Inf;
end
if ~isfield(thr,'ExtentMin')
    thr.ExtentMin = 0;
end
if ~isfield(thr,'ExtentMax')
    thr.ExtentMax = 1;
end
if ~isfield(thr,'AspectMin')
    thr.AspectMin = 0;
end
if ~isfield(thr,'AspectMax')
    thr.AspectMax = 1;
end
if ~isfield(thr,'HeightMin')
    thr.HeightMin = 0;
end
if ~isfield(thr,'HeightMax')
    thr.HeightMax = Inf;
end
if ~isfield(thr,'WidthMin')
    thr.WidthMin = 0;
end
if ~isfield(thr,'WidthMax')
    thr.WidthMax = Inf;
end
if ~isfield(thr,'A2PSqMin')
    thr.A2PSqMin = -Inf;
end
if ~isfield(thr,'A2PSqMax')
    thr.A2PSqMax = Inf;
end
if ~isfield(thr,'ClearBandYMin')
    thr.ClearBandYMin = -Inf;
end
if ~isfield(thr,'ClearBandYMax')
    thr.ClearBandYMax = -Inf;
end


if nargout > 3
    CCs = cell(1,numMasks);
end

for m=1:numMasks
    
    % Get connected components
    cc = bwconncomp(BWmask(:,:,m));
    
    % Compute the area of each component:
    stat = regionprops(cc, 'Area', 'Extent', 'BoundingBox','Perimeter');
    
    maskArea = ([stat.Area] >= thr.AreaMin) & ([stat.Area] <= thr.AreaMax);
    maskExtent = ([stat.Extent] >= thr.ExtentMin) & ([stat.Extent] <= thr.ExtentMax);
    bboxes = reshape([stat.BoundingBox],4,cc.NumObjects)';
    bb_width = bboxes(:,3)';
    bb_height = bboxes(:,4)';
    bb_aspect = bb_width ./ bb_height;
    flipOver = bb_aspect > 1;
    bb_aspect(flipOver) = 1./bb_aspect(flipOver);
    maskAspect = (bb_aspect >= thr.AspectMin) & (bb_aspect <= thr.AspectMax);
    maskDim = (bb_width >= thr.WidthMin) & (bb_height >= thr.HeightMin);
    
    
    A2PSq = [stat.Area]./([stat.Perimeter].^2);
    maskA2PSq = (A2PSq >= thr.A2PSqMin) & (A2PSq <= thr.A2PSqMax);
    
    % Delete blobs that touch clearBand    
    bbox_upper = bboxes(:,2);
    bbox_lower = (bboxes(:,2)+bboxes(:,4));
    clearBandInd = ...
        ((bbox_upper >= thr.ClearBandYMin) & (bbox_upper <= thr.ClearBandYMax)) | ...
        ((bbox_lower >= thr.ClearBandYMin) & (bbox_lower <= thr.ClearBandYMax));
    maskClearBandY = ~clearBandInd';
    
    mask = maskArea & maskExtent & maskAspect & maskA2PSq & maskDim & maskClearBandY;
    
    filtCC = struct();
    filtCC.Connectivity = cc.Connectivity;
    filtCC.ImageSize = cc.ImageSize;
    filtCC.NumObjects = sum(mask);
    filtCC.PixelIdxList = cc.PixelIdxList(mask);
    
    pixelList = vertcat(filtCC.PixelIdxList{:});
    
    if nargout > 3
        CCs{m} = filtCC;
    end
    BW = false(filtCC.ImageSize);
    BW(pixelList) = true;
    BWmask(:,:,m) = BW;
    
end

% Join CCs into one structure
% Use merged masks and compute conn. comp. once more
if nargout > 1
    BWmerged = any(BWmask,3);
end
if nargout > 2
    ccOut = bwconncomp(BWmerged);
end

