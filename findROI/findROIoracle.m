function [BBtight, BBfull, BWmerged, CC] = findROIoracle(imageFile,param,showResults,annot)
% ORACLE - she knows everything.
% She does not use default ROI positions.

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end

imW = annot.size(1);
imH = annot.size(2);

BWmerged = false(imH,imW);

numSigns = numel(annot.a);
for sign_i=1:numSigns
    % extract sign data
    xs = annot.a(sign_i).segmentation(1:2:end-2);
    ys = annot.a(sign_i).segmentation(2:2:end-2);
    
    % convert to polygon mask
    M = poly2mask(xs,ys,imH,imW);
    BWmerged = BWmerged | M;
end

CC = bwconncomp(BWmerged);


% =========== RECTANGLE COVERING ==========================================
% Turn off default positions of ROIs
param.roi.default.pos = [];

[BBtight, BBfull, areaLeft] = coverWithRectangles(CC, param.roi);

if showResults
    RGB = imread(imageFile);
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
