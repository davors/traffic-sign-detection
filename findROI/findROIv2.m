function [BBtight, BBfull, BWmerged, CC] = findROIv2(imageFile,param,showResults)

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end

% Read file
RGB = imread(imageFile);

if strcmpi(param.general.colorMode,'HSV')
    I = rgb2hsv(RGB);
else
    I = RGB;
end

% =========== WHITE ======================================================
% Initial preprocessing - CLAHE
I_white = preprocess(I, param.white2.initPipeline, param.white2.initMethods, param.general.colorMode);
V_CLAHE = I_white(:,:,3);
% Binarize CLAHE output using Otsu method
V_CLAHE = imbinarize(V_CLAHE);
% Remove saturated (chromatic) parts
Smin = param.white2.thrHSV.white.Smin;
Smax = param.white2.thrHSV.white.Smax;
Smask = (I_white(:,:,2) >= Smin ) & (I_white(:,:,2) <= Smax);
V_CLAHE = V_CLAHE & Smask;

% Find and enhance edges (gradients)
Gmag = imgradient(V_CLAHE);
% Threshold gradient map to get edge map
E = imbinarize(Gmag);

% Save binary mask with edges
V_CLAHE_edges = V_CLAHE;
% Remove edges from binary mask of an V channel
V_CLAHE(E) = 0;

% Filter with morphological operations 
V_CLAHE_filt = filterMask(V_CLAHE, param.white2.maskFilters);
V_CLAHE_edges_filt = filterMask(V_CLAHE_edges, param.white2.maskFilters);

% Filter connected components
[~, BW] = filterConnComp(V_CLAHE_filt, param.white2.thrCC);
[~, BW2] = filterConnComp(V_CLAHE_edges_filt, param.white2.thrCC);

% Merge masks with and without edges
BWmerged_white = BW | BW2;

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,V_CLAHE_edges, V_CLAHE, V_CLAHE_edges_filt, V_CLAHE_filt, BW, BW2, BWmerged_white),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
    waitforbuttonpress;
    close();
end


% =========== COLORS ======================================================
% Initial preprocessing; skip if the parameters are same
if isequal(param.white.initPipeline, param.colors.initPipeline) && isequal(param.white.initMethods, param.colors.initMethods)
    I_col = I_white;
else
    I_col = preprocess(I, param.colors.initPipeline, param.colors.initMethods, param.general.colorMode);
end

% HSV thresholding
BWmasks = thresholdsHSV(I_col,param.colors.thrHSV, param.general.colorMode);

BW = any(BWmasks,3); % composite mask - for plotting only
BWmasks_old_1 = BWmasks; % layer masks - for plotting only

% Filter masks
[BWmasks] = filterMask(BWmasks, param.colors.maskFilters);
BWmasks_old_2 = BWmasks;
BWfilt1 = any(BWmasks,3);

% Connected components on masks + filtering
[BWmasks, BWmerged_color, CC_color] = filterConnComp(BWmasks, param.colors.thrCC);

if showResults > 1
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BWmasks_old_1,BW,BWmasks_old_2,BWfilt1,BWmasks,BWmerged_color),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
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
BWmerged = BWmerged_white | BWmerged_color;
BW_white_only = BWmerged_white & ~BWmerged_color;
CC_white_only = bwconncomp(BW_white_only);


weightWhite = param.white.weight;
weightColor = param.colors.weight;

CC = struct();
CC.ImageSize = CC_white_only.ImageSize;
CC.Connectivity = CC_white_only.Connectivity;
CC.NumObjects = CC_white_only.NumObjects + CC_color.NumObjects;
CC.PixelIdxList = [CC_white_only.PixelIdxList, CC_color.PixelIdxList];
CC.Weights = [ones(1,CC_white_only.NumObjects)*weightWhite, ones(1,CC_color.NumObjects)*weightColor];




% =========== RECTANGLE COVERING ==========================================
% Check for image size
[imW, imH, ~] = size(RGB);
sizeInd = cellfun(@(x) (all(x==[imW, imH])), param.roi.default.imageSize, 'UniformOutput', 1);
if any(sizeInd)
    param.roi.default.pos = param.roi.default.pos{sizeInd};
else
    param.roi.default.pos = [];
end

[BBtight, BBfull, areaLeft] = coverWithRectangles(CC, param.roi);
% see also: findClusters, placeBoxes

if showResults
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
