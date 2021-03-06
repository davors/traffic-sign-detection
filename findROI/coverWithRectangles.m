function [rectsTight,rectsFull,areaLeft] = coverWithRectangles(CC,param)
% Reference: https://stackoverflow.com/questions/32429311/finding-rectangle-position-that-makes-it-cover-maximum-points-in-2d-space
%
% defaultPos - top-left corners (K x 2) of default positions of K rectangles of
% size sizeRect. When the algorithm covers all blobs with less than K
% rectangles, use defaultPos to position remaining rectangles, so that
% there are K rectangles.

% Horizontal step: take left-most point and find right one such that
% rectangle width cover the span
% Vertical step: find optimal top position that results in coverage with
% maximum area

K = param.num;
sizeRect = param.size;
defaultPos = param.default.pos;
alignOrigin = param.alignOrigin; % how to align tight and full bboxes: bottom or center


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
imWidth = CC.ImageSize(2);

weightedMode = isfield(CC,'Weights');
if weightedMode
    weights = CC.Weights;
else
    weights = ones(1,numBlobs);
end

% Get bounding boxes and areas of blobs
CCprops = regionprops(CC, {'BoundingBox','Area'});
% Get bounding boxes of blobs in CC. They are in form [x y w h]
BB = reshape([CCprops.BoundingBox],4,numBlobs)';
% Add weighted area to matrix of bounding boxes, so: [x y width height area]
BB(:,5) = [CCprops.Area].*weights;
% Add an ID 
BB(:,6) = 1:CC.NumObjects;



% Prepare space for a solution
rectsTight = zeros(K,4);
rectsFull = zeros(K,4);

% Sort points (BB) by x
BB = sortrows(BB,1,'ascend');


for k = 1:K
    optimalIDs = [];
    maxScore = 0;
    
    numPoints = size(BB,1);
    if numPoints > 1
        right = 1;
        for left=1:numPoints
            right = max(right,left);
            % Enlarge rectangle towards right - make sure that whole bb falls
            % into covering rectangle
            while (right <= numPoints) && ((BB(right,1)+BB(right,3)) <= (BB(left,1)+width))
                right = right + 1; % add bb
            end
            right = max(1,right - 1);

            % Sort selected blobs by y
            column = sortrows(BB(left:right,:),2,'ascend');
            numColumn = size(column,1);
            bottom = 1;
            for top=1:numColumn            
                while (bottom <= numColumn) && ((column(bottom,2)+column(bottom,4)) <= (column(top,2) + height)) 
                    bottom = bottom + 1;
                end
                bottom = max(1,bottom - 1);

                % Evaluate selected blobs - sum of covered area
                score = sum(column(top:bottom,5));
                if (score > maxScore)
                    maxScore = score;
                    optimalIDs = column(top:bottom,6); % store IDs
                end
                if (bottom == numColumn) 
                    break;
                end
            end
            if right == numPoints 
                break;
            end

        end
    
        % Find min and max x in optimalSet
        optimalInds = find(ismember(BB(:,6),optimalIDs));
        
        xMin = min(BB(optimalInds,1));
        xMax = min(max(BB(optimalInds,1)+BB(optimalInds,3)),xMin+width); % x+width
        w = xMax - xMin; % width of a covering rectangle
        % Extract top and bottom (y axis)
        yMin = min(BB(optimalInds,2));
        yMax = min(max(BB(optimalInds,2)+BB(optimalInds,4)),yMin+height);
        h = yMax - yMin;
    elseif numPoints == 1
        % Only 1 point (bb) left.
        optimalInds = 1;
        xMin = BB(1,1);
        w = BB(1,3);
        yMin = BB(1,2);
        h = BB(1,4);
    else
        % No blobs
        k = 0;
        break;
    end
    
    % Store rectangle (tight bounding box)
    % Enlarge tight bbox by fixOffset pixels to avoid bad scores due to
    % polygons overlap
    fixOffset = param.fixTightOffset; 
    xMax = xMin + w;
    yMax = yMin + h;    
    xMinFix = max(0,xMin-fixOffset);
    xMaxFix = min(imWidth, xMax+fixOffset);    
    yMinFix = max(0,yMin-fixOffset);
    yMaxFix = min(imHeight, yMax+fixOffset);
    wFix = min(width, xMaxFix - xMinFix);
    hFix = min(height, yMaxFix - yMinFix);    
    rectsTight(k,:) = [xMinFix, yMinFix, wFix, hFix];
    
    % Find full sized rectangle (exactly width x height)
    % h and w can be less than height and width of specified rectangle
    centerX = xMin + w/2;
    centerY = yMin + h/2;
    % Align center-center
    if strcmpi(alignOrigin,'center')        
        xMinFull = centerX - width/2;
        yMinFull = centerY - height/2;
    
    elseif strcmpi(alignOrigin,'bottomSpecial')
        % ONLY FOR MIDDLE DEFAULT RECTANGLE - not for general use
        % Align to left or right side or center of tight box
        if xMin < defaultPos(k,1)
            xMinFull = xMin;
        elseif (xMin+w) > (defaultPos(k,1)+width)
            xMinFull = xMin+w-width;
        else
            % Leave as default
            xMinFull = defaultPos(k,1);
        end        
        yMinFull = yMin - (height - h);
        
    % Align bottom-(left,center,right) HARDCODED K=3 FHD version
    elseif strcmpi(alignOrigin,'bottom')
        % determine the vertical band of tight bbox (left, center, right)
        if centerX <= defaultPos(1,1) + width
            % left
            xMinFull = xMin - (width - w);
            yMinFull = yMin - (height - h);                        
            
        elseif centerX > defaultPos(1,1) && centerX <= defaultPos(3,1)
            % center
            xMinFull = xMin - (width - w)/2;
            yMinFull = yMin - (height - h);
            
        else
            % right
            xMinFull = xMin;
            yMinFull = yMin - (height - h);
            
        end
        
    end
    
    if xMinFull < 0
        xMinFull = 0;
    elseif (xMinFull+width) > imWidth
        xMinFull = imWidth - width;
    end    
    if yMinFull < 0
        yMinFull = 0;
    elseif (yMinFull+height) > imHeight
        yMinFull = imHeight-height;
    end
    
    
    % Store rectangle (full bounding box)
    rectsFull(k,:) = [xMinFull, yMinFull, width, height];
    
    
    % Remove already covered points from BB
    BB(optimalInds,:) = [];
    % End loop if there is no more points
    if isempty(BB)
        break;
    end
end

if k==0 && ~isempty(defaultPos)
    rectsFull = [defaultPos, repmat([width, height],K,1)];
    rectsTight = rectsFull;

elseif k < K && ~isempty(defaultPos)
    % Use rectangles on defaultPos to fill in K-k rectangles
    % Get centres of k rectangles and also default ones
    centresAlgX = rectsFull(1:k,1) + rectsFull(1:k,3)/2; 
    centresAlgY = rectsFull(1:k,2) + rectsFull(1:k,4)/2;
    
    centresDefX = defaultPos(:,1) + width/2;
    centresDefY = defaultPos(:,2) + height/2;
    
    centresAlg = [centresAlgX, centresAlgY];
    centresDef = [centresDefX, centresDefY];
    
    D = pdist2(centresAlg, centresDef, 'euclidean');
    defaultAvailable = true(1,K);
    for alg_i = 1:k
        [~,minInd] = min(D(alg_i,:));
        D(:,minInd) = Inf;
        defaultAvailable(minInd) = false;        
    end
    
    rectsFull(k+1:K,:) = [defaultPos(defaultAvailable,:), repmat([width, height],K-k,1)];
    rectsTight(k+1:K,:) = rectsFull(k+1:K,:);
else
    % Keep only k rectangles (in case of premature exit)
    rectsTight = rectsTight(1:k,:);
    rectsFull = rectsFull(1:k,:);
end

% Compute area of remaining objects
if isempty(BB)
    areaLeft = 0;
else
    areaLeft = sum(BB(:,5));
end


