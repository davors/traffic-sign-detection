function [labels, C, BB]= findClusters(CC,K)

numComponents = CC.NumObjects;

% Take care of specified number of desired bounding boxes
if isempty(K)
    K = numComponents;
else
    % Limit it
    K = min(numComponents,K);
end

% Get centroids and bounding boxes of objects in CC
CCprops = regionprops(CC, {'BoundingBox','Centroid'});
centroids = reshape([CCprops.Centroid],2,numComponents)';
bboxes = reshape([CCprops.BoundingBox],4,numComponents)';

% If there are more CCs than desired bounding boxes we group CCs into clusters
if numComponents > K
    [labels,C] = kmeans(centroids,K);
    %[labels,C] = kmeans(bboxes(:,1),K);
    % Use only X coordinate of a centroid - prefer vertical splits
    %[labels,C] = kmeans(centroids(:,1),K);
    
else
    % Otherwise every CC is a cluster on its own
    labels = (1:numComponents)';
end

% Create bounding boxes around clusters - their height and widths have
% to be a multiplier of 32
BB = zeros(K,4);
imHeight = CC.ImageSize(1);
imWidth = CC.ImageSize(2);


for bbi = 1: K
    B = bboxes(labels == bbi,:);
    B(:,3) = B(:,1) + B(:,3);
    B(:,4) = B(:,2) + B(:,4);
    % find extreme points (bottom-left and top-right)
    p_bottom_left = [min(B(:,1)), min(B(:,2))];
    p_top_right = [max(B(:,3)), max(B(:,4))];
    
    x = floor(p_bottom_left(1));
    y = floor(p_bottom_left(2));
    w = p_top_right(1) - p_bottom_left(1);
    h = p_top_right(2) - p_bottom_left(2);
    
    %bbpos = [x, y, w, h];
    %rectangle('Position',bbpos,'EdgeColor','m','LineWidth',2);
    
    modW = mod(w,32);
    modH = mod(h,32);
    if modW ~= 0
        wadd = (32-modW);
        w = w + wadd;
        x = x - round(wadd/2);
        leftOff = x < 0;
        rightOff = (x + w) > imWidth;
        if leftOff && rightOff
            x = 0;
            w = imWidth;
        elseif leftOff
            x = 0;
        elseif rightOff
            x = imWidth - w;
        end
    end
    if modH ~= 0
        hadd = (32-modH);
        h = h + hadd;
        y = y - round(hadd/2);
        leftOff = y < 0;
        rightOff = (y + h) > imHeight;
        if leftOff && rightOff
            y = 0;
            h = imHeight;
        elseif leftOff
            y = 0;
        elseif rightOff
            y = imHeight - y;
        end
    end
    
    bbpos = [x, y, w, h];
    BB(bbi,:) = bbpos;
    %rectangle('Position',bbpos,'EdgeColor','g','LineWidth',2);
end