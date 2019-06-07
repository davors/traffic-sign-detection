function [BWmask,BWmerged,ccOut,CCs] = filterConnComp(BWmask, thr, skipLayers)

numMasks = size(BWmask,3);

if ~exist('skipLayers','var') || isempty(skipLayers)
    skipLayers = false(1,numMasks);
end

% Thresholds - defaults
if ~exist('thr','var') || isempty(thr)
    % Size of an area we want to filter out (in pixels)
    thr.AreaMin = 300;
    thr.AreaMax = 100000;

    % Extent filter (extent = area/(height*width))
    thr.ExtentMin = 0.5;
    thr.ExtentMax = 1;

    % Aspect ratio (shorter/longer)
    thr.AspectMin = 0.16;
    thr.AspectMax = 1;
end




CCs = cell(1,numMasks);

for m=1:numMasks
    
    % Get connected components
    cc = bwconncomp(BWmask(:,:,m));
    
    if ~skipLayers(m)
        % Compute the area of each component:
        stat = regionprops(cc, 'Area', 'Extent', 'BoundingBox');

        maskArea = ([stat.Area] >= thr.AreaMin) & ([stat.Area] <= thr.AreaMax);
        maskExtent = ([stat.Extent] >= thr.ExtentMin) & ([stat.Extent] <= thr.ExtentMax);
        %centroids = reshape([stat.Centroid],2,cc.NumObjects)';
        bboxes = reshape([stat.BoundingBox],4,cc.NumObjects)';
        bb_width = bboxes(:,3)';
        bb_height = bboxes(:,4)';    
        bb_aspect = bb_width ./ bb_height;
        flipOver = bb_aspect > 1;
        bb_aspect(flipOver) = 1./bb_aspect(flipOver);
        maskAspect = (bb_aspect >= thr.AspectMin) & (bb_aspect <= thr.AspectMax);

        mask = maskArea & maskExtent & maskAspect;
    else
        mask = true(1,cc.NumObjects);
    end
    filtCC = struct();
    filtCC.Connectivity = cc.Connectivity;
    filtCC.ImageSize = cc.ImageSize;
    filtCC.NumObjects = sum(mask);
    filtCC.PixelIdxList = cc.PixelIdxList(mask);
    
    pixelList = vertcat(filtCC.PixelIdxList{:});
    
    CCs{m} = filtCC;
    BW = false(filtCC.ImageSize);
    BW(pixelList) = true;
    BWmask(:,:,m) = BW;
    
end

% Join CCs into one structure
% Use merged masks and compute conn. comp. once more
BWmerged = any(BWmask,3);
ccOut = bwconncomp(BWmerged);

