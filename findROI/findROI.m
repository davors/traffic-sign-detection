function [BBtight, BBfull, BWmerged, CC] = findROI(imageFile,heq,cc,thrColor,thrCC,K,roiSize,defaultRoi,showResults)

if ~exist('heq','var') || isempty(heq)
    heq = 'local'; % 'global', 'local', 'none'
end
if ~exist('cc','var') || isempty(cc)
    cc = 'gray'; % 'white', 'gray', 'none'
end
if ~exist('K','var') || isempty(K)
    K = 3; % number of final groups (ROIs)
end
if ~exist('roiSize','var') || isempty(roiSize)
    roiSize = [704,704]; % width and height of ROI rectangles
end
if ~exist('defaultRoi','var')
    defaultRoi = []; % do not use default positions of ROIs
end



if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end


% Read file
RGB = imread(imageFile);

% Preprocess
% Order of preprocessing is the same as in Fleyeh2005: hist. eq. -> color constancy
%RGB = imadjust(RGB, [],[]);
RGB = preprocessHistogramEq(RGB,heq);
RGB = preprocessColorConstancy(RGB,cc);


% HSV thresholding
[BWmasks, colors]= thresholdsHSV(RGB,thrColor);
% Take white and black out and process them separately
whiteInd = strcmpi('white',colors);
blackInd = strcmpi('black',colors);
colorInds = 1:size(BWmasks,3);
colorInds(whiteInd) = [];
colorInds(blackInd) = [];
whiteMask = BWmasks(:,:,whiteInd);
blackMask = BWmasks(:,:,blackInd);
BWmasks = BWmasks(:,:,colorInds);

BW = any(BWmasks,3); % composite mask - for plotting only
BWmasks_old_1 = BWmasks; % layer masks - for plotting only

% Filter masks
% Available filters/operations: 
% 'median': median filtering
% 'gauss': gaussian filtering/blurring
% 'close': morphological closing
% 'fill': holes filling
[BWmasks] = filterMask(BWmasks, {'close_2','fill','gauss_3','close_7','fill'});
BWmasks_old_2 = BWmasks;
BWfilt1 = any(BWmasks,3);



% Connected components on masks + filtering
[BWmasks, BWmerged, CC, CCs] = filterConnComp(BWmasks,thrCC);

if showResults
    figure('units','normalized','OuterPosition',[0,0,1,1]);
    imshow(imtile(cat(3,BWmasks_old_1,BW,BWmasks_old_2,BWfilt1,BWmasks,BWmerged),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
    waitforbuttonpress;
    close();
end



[BBtight, BBfull, areaLeft] = coverWithRectangles(CC, K, roiSize, defaultRoi);
% see also: findClusters, placeBoxes

if showResults
    Kreal = size(BBtight,1);
    % Visualize
    L = labelmatrix(CC);
    I = label2rgb(L,repmat([1 1 1],CC.NumObjects,1),'black');
    Im_fused = imfuse(I,RGB,'blend');
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




