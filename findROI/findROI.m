function [C,BB] = findROI(imageFile,heq,cc,K)

if ~exist('heq','var') || isempty(heq)
    heq = 'local'; % 'global', 'local', 'none'
end
if ~exist('cc','var') || isempty(cc)
    cc = 'gray'; % 'white', 'gray', 'none'
end
if ~exist('K','var') || isempty(K)
    K = 3; % number of final groups (ROIs)
end


% Read file
RGB = imread(imageFile);

% Preprocess
% Order of preprocessing is the same as in Fleyeh2005: hist. eq. -> color constancy
%RGB = imadjust(RGB, [],[]);
RGB = preprocessHistogramEq(RGB,heq);
RGB = preprocessColorConstancy(RGB,cc);


% HSV thresholding
[BWmasks, colors]= thresholdsHSV(RGB);
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
BWmasks_old_1 = BWmasks;
%figure();
%imshow(imtile(cat(3,BWmasks,BW),'BorderSize',10,'BackgroundColor','w'));


% Filter masks
% Available filters/operations: 
% 'median': median filtering
% 'gauss': gaussian filtering/blurring
% 'close': morphological closing
% 'fill': holes filling
[BWmasks] = filterMask(BWmasks, {'close_2','fill','gauss_3','close_7','fill'});
BWfilt1 = any(BWmasks,3);


% f2=figure('units','normalized','OuterPosition',[0,0.5,0.2,0.3]);
% imshow(RGB,'InitialMagnification','fit');
% 
% f1=figure('units','normalized','OuterPosition',[0,0,1,1]);
% imshow(imtile(cat(3,BWmasks,BWfilt1,BWmasks_old_1,BW),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
% text(0.4,1,strjoin(colors',', '),'Units','normalized','Color','g','Fontsize',14,'verticalalign','top');





% Connected components on masks + filtering
% TODO: Should we make an exception for 'stable' colors like blue and yellow?
% skipLayers = ismember(colors,{'blue'});
thr = [];
skipLayers = [];
[BWmasks, BWmerged, CC, CCs] = filterConnComp(BWmasks,thr,skipLayers);

% f3=figure('units','normalized','OuterPosition',[0,0,1,1]);
% imshow(imtile(cat(3,BWmasks,BWmerged,BWfilt1),'BorderSize',10,'BackgroundColor','w'),'InitialMagnification','fit');
% waitforbuttonpress;
% try
%     close([f1,f2,f3]);
% catch
%     ;
% end


% Place objects in K groups
[labels, C, BB] = findClusters(CC,K);

% Visualize
L = labelmatrix(CC);
figure();
imshow(label2rgb(L));
hold on;
% Bounding boxes and centroids
rects=placeBoxes(label2rgb(L), C, [704,704], 3)
for k = 1: K
    plot(C(k,1),C(k,2),'m+');
    rectangle('Position',BB(k,:),'EdgeColor','g','LineWidth',2);
    rectangle('Position',rects(k,:),'EdgeColor','b','LineWidth',2);
end

%Place boxes



