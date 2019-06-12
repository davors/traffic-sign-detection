function [BWmask,BWmerged,ccOut,CCs] = filterConnComp(BWmask, thr)

numMasks = size(BWmask,3);

CCs = cell(1,numMasks);

for m=1:numMasks
    
    % Get connected components
    cc = bwconncomp(BWmask(:,:,m));
    
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

