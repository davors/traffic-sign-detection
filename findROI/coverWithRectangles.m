function [rectsTight,rectsFull,areaLeft] = coverWithRectangles(CC,param)
% Reference: https://stackoverflow.com/questions/32429311/finding-rectangle-position-that-makes-it-cover-maximum-points-in-2d-space
%
% defaultPos - top-left corners (K x 2) of default positions of K rectangles of
% size sizeRect. When the algorithm covers all blobs with less than K
% rectangles, use defaultPos to position remaining rectangles, so that
% there are K rectangles.

% TODO: naive optimistic initialization: 
% place first rectangle so that the position of its
% top-left corner is at top-left corner of top-left-most BB. Check if all
% blobs are covered. If not, place second rectangle in opposite fashion to
% the right. Again, check for coverage. Repeat until, K rectangles are
% used.

% Horizontal step: take left-most point and find right one such that
% rectangle width cover the span
% Vertical step: find optimal top position that results in coverage with
% maximum area

K = param.num;
sizeRect = param.size;
defaultPos = param.default;

if numel(sizeRect) == 1
    width = sizeRect;
    height = sizeRect;
elseif numel(sizeRect) == 2
    width = sizeRect(1);
    height = sizeRect(2);
else
    error('sizeRect can contain 1 or 2 elements.');
end

if ~exist('defaultPos','var')
    defaultPos = [];
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

            % Enlarge rectangle towards right - make sure that whole bb falls
            % into covering rectangle
            while (right <= numPoints) && ((BB(right,1)+BB(right,3)) <= (BB(left,1)+width))
                right = right + 1; % add bb
            end
            right = right - 1;

            % Sort selected blobs by y
            column = sortrows(BB(left:right,:),2,'ascend');
            numColumn = size(column,1);
            bottom = 1;
            for top=1:numColumn            
                while (bottom <= numColumn) && ((column(bottom,2)+column(bottom,4)) <= (column(top,2) + height)) 
                    bottom = bottom + 1;
                end
                bottom = bottom - 1;

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
        xMax = max(BB(optimalInds,1)+BB(optimalInds,3)); % x+width
        w = xMax - xMin; % width of a covering rectangle
        % Extract top and bottom (y axis)
        yMin = min(BB(optimalInds,2));
        yMax = max(BB(optimalInds,2)+BB(optimalInds,4));
        h = yMax - yMin;
    else
        % Only 1 point (bb) left.
        optimalInds = 1;
        xMin = BB(1,1);
        w = BB(1,3);
        yMin = BB(1,2);
        h = BB(1,4);
    end
    
    % Store rectangle (tight bounding box)
    rectsTight(k,:) = [xMin, yMin, w, h];
    
    % Find full sized rectangle (exactly width x height)
    % h and w can be less than height and width of specified rectangle
    centerX = xMin + w/2;
    centerY = yMin + h/2;
    xMinFull = centerX - width/2;
    yMinFull = centerY - height/2;
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

if k < K && ~isempty(defaultPos)
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


