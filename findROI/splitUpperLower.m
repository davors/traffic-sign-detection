function [CC_up, CC_low]= splitUpperLower(CC,limit)

CCprops = regionprops(CC,'BoundingBox');
bboxes = reshape([CCprops.BoundingBox],4,CC.NumObjects)';
% Find components that touch upper band
bbox_top = bboxes(:,2);
mask_up = bbox_top <= limit;
mask_low = ~mask_up;

CC_up = struct();
CC_up.Connectivity = CC.Connectivity;
CC_up.ImageSize = CC.ImageSize;
CC_up.NumObjects = sum(mask_up);
CC_up.PixelIdxList = CC.PixelIdxList(mask_up);
CC_up.BBoxes = bboxes(mask_up,:);

CC_low = struct();
CC_low.Connectivity = CC.Connectivity;
CC_low.ImageSize = CC.ImageSize;
CC_low.NumObjects = sum(mask_low);
CC_low.PixelIdxList = CC.PixelIdxList(mask_low);
CC_low.BBoxes = bboxes(mask_low,:);
