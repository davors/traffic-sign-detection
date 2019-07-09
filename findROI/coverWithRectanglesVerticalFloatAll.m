function [rectsTight,rectsFull,areaLeft] = coverWithRectanglesVerticalFloatAll(CC,param)
% Reference: https://stackoverflow.com/questions/32429311/finding-rectangle-position-that-makes-it-cover-maximum-points-in-2d-space
%
% defaultPos - top-left corners (K x 2) of default positions of K rectangles of
% size sizeRect. When the algorithm covers all blobs with less than K
% rectangles, use defaultPos to position remaining rectangles, so that
% there are K rectangles.

% Horizontal step: use default positions
% Vertical step: find optimal top position that results in coverage with
% maximum area

K = param.num;
sizeRect = param.size;
defaultPos = param.default.pos;
assert(~isempty(defaultPos),'defaultPos cannot be empty.');
alignOrigin = param.alignOrigin; % how to align tight and full bboxes: bottom or center
assert(strcmpi(alignOrigin,'bottom'),'alignOrigin bottom is supported only.');

if numel(sizeRect) == 1
    width = sizeRect;
    height = sizeRect;
elseif numel(sizeRect) == 2
    width = sizeRect(1);
    height = sizeRect(2);
else
    error('sizeRect can contain 1 or 2 elements.');
end

numBlobs = CC.NumObjects;
imHeight = CC.ImageSize(1);

weightedMode = isfield(CC,'Weights');
if ~weightedMode
    CC.Weights = ones(1,numBlobs);
end

% Get bounding boxes and areas of blobs
CCprops = regionprops(CC, {'BoundingBox'});
% Get bounding boxes of blobs in CC. They are in form [x y w h]
BB = zeros(numBlobs,7);
BB(:,1:4) = reshape([CCprops.BoundingBox],4,numBlobs)';
% Add weights
BB(:,5) = CC.Weights;
% Add an ID
BB(:,6) = 1:numBlobs;
% Add a flag 'uncovered'
BB(:,7) = ones(numBlobs,1);
% BB has a structure [x y width height weight ID uncovered]


% Prepare space for a solution
rectsTight = zeros(K,4);
rectsFull = zeros(K,4);

% Move middle default rectangle on the start position -process it first
dflTmp = defaultPos(2,:);
defaultPos(2,:) =  defaultPos(1,:);
defaultPos(1,:) = dflTmp;

dflTmp = param.floatSize(2);
param.floatSize(2) = param.floatSize(1);
param.floatSize(1) = dflTmp;

% Sort points (BB) by x
BB = sortrows(BB,1,'ascend');

for k = 1:K
    
    % Retain only blobs that are in vertical band of default ROI
    defX = defaultPos(k,1);
    defY = defaultPos(k,2);
    
    % Select blobs that have Xstart or Xend within default kth ROI's position
    BBselInd = ...
        ((BB(:,1) >= defX) & (BB(:,1) <= (defX+width))) | ...
        (((BB(:,1)+BB(:,3)) >= defX) & ((BB(:,1)+BB(:,3)) <= (defX+width)));
    % Select only those that are uncovered
    BBsel = BB(BBselInd & BB(:,7),:);
    numBlobs_k = size(BBsel,1);
    optimalPosY = defaultPos(k,2);
    
    if (numBlobs_k > 0)
        
        % sort BBsel by Y
        BBsel = sortrows(BBsel,2,'ascend');
        
        % Evaluate default position
        pos = [defX,defY,width,height];
        % We do not evaluate blobs that are not fully inside roi considering Y
        % direction
        BBinsideInd = (BBsel(:,2) >= defY) & ((BBsel(:,2)+BBsel(:,4)) <= (defY+height));
        scoreMax = evaluatePosition(BBsel(BBinsideInd,:),pos,CC);
        
        rectFullMid = pos;
        pad = param.floatSize(k);
        pos = [defX-pad,0,width+2*pad,imHeight];
        scoreMaxLimit = evaluatePosition(BBsel,pos,CC);
        
        if (scoreMax < scoreMaxLimit)
            % Clear blobs from CC that are outside padded ROI
            CCmid.NumObjects = numBlobs_k;
            CCmid.ImageSize = CC.ImageSize;
            CCmid.Connectivity = CC.Connectivity;
            CCmid.Weights = CC.Weights(BBsel(:,6));
            CCmid.PixelIdxList = CC.PixelIdxList(BBsel(:,6));
            paramMid = [];
            paramMid.num = 1;
            paramMid.size = sizeRect;
            paramMid.default.pos = defaultPos(k,:);
            paramMid.alignOrigin = 'bottomSpecial';
            paramMid.fixTightOffset = param.fixTightOffset;
            [~,rectFullMid] = coverWithRectangles(CCmid,paramMid);
            % Limits
            rectFullMid(1) = max(defX-pad, rectFullMid(1));
            rectFullMid(1) = min(defX+pad, rectFullMid(1));
        end
        rectsFull(k,:) = rectFullMid;
        rectsTight(k,:) = rectsFull(k,:);
               
    else
        rectsFull(k,:) = [defaultPos(k,1),optimalPosY,width,height];
        rectsTight(k,:) = rectsFull(k,:);
    end
    
    % Update uncovered flag
    BB = updateUncoveredFlag(BB,BBsel,rectsFull(k,:));
    
    
end
% Unused variable for now (#nedamise)
areaLeft = nan;

end

function score = evaluatePosition(B,pos,CC)
numBlobs = size(B,1);

score=0;
for bi=1:numBlobs
    CCid=B(bi,6);
    [Y,X] = ind2sub(CC.ImageSize,CC.PixelIdxList{CCid});
    inside = (X >= pos(1)) & (X <= (pos(1)+pos(3))) & (Y >= pos(2)) & (Y <= (pos(2)+pos(4)));
    score = score + sum(inside)*B(bi,5); % weighted sum of pixels inside pos
end


end

function BB = updateUncoveredFlag(BB,BBsel,rectFull)
totallyInside = ...
    (BBsel(:,1) >= rectFull(1)) & ... % left
    ((BBsel(:,1)+BBsel(:,3)) <= (rectFull(1)+ rectFull(3))) & ... % right
    (BBsel(:,2) >= rectFull(2)) & ... % top
    ((BBsel(:,2)+BBsel(:,4)) <= (rectFull(2)+ rectFull(4))); % bottom
BBids = BBsel(totallyInside,6);
BB(BBids,7) = 0;
end

