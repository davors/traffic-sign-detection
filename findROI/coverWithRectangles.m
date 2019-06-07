function [rects] = coverWithRectangles(CC,K,width,height)

% TODO: naive optimistic initialization: place first rectangle so that the position of its
% top-left corner is at top-left corner of top-left-most BB. Check if all
% blobs are covered. If not, place second rectangle in opposite fashion to
% the right. Again, check for coverage. Repeat until, K rectangles are
% used.

% Horizontal step: take left-most point and find right one such that
% rectangle width cover the span
% Vertical step: find optimal top position that results in coverage with
% maximum area

numBlobs = CC.NumObjects;
imHeight = CC.ImageSize(1);
imWidth = CC.ImageSize(2);

% Limit the number of desired rectangles

K = min(numBlobs,K);

% Get bounding boxes of blobs in CC. They are in form [x y w h]
BB = reshape([CCprops.BoundingBox],4,numBlobs)';
% Get areas of blobs
CCprops = regionprops(CC, {'BoundingBox'});
% Add area to matrix of bounding boxes, so: [x y width height area]
BB(:,5) = [CCprops.Area];



% Prepare space for a solution
rects = zeros(K,4);

for k = 1:K
    optimalSet = [];
    maxScore = 0;
    
    % Sort points (BB) horizontaly by x and then by y
    BB = sortrows(BB,[1 2],'ascend');
    
    numPoints = size(BB,1);
    
    for left=1:numPoints
        right = 1;
        % Enlarge rectangle towards right - make sure that whole bb falls
        % into covering rectangle
        while (right < numPoints) && (BB(right,1)+BB(right,3) <= (BB(left,1)+width)) 
            right = right + 1; % add bb
        end
        % Selected blobs, already sorted by y
        column = BB(left:right,:);
        
        numColumn = size(column,1);
        for top=1:numColumn
            bottom = 1;
            while (bottom < numColumn) && (column(bottom,2)+column(bottom,4) <= column(top,2) + height) 
                bottom = bottom + 1;
            end
            % Evaluate selected blobs - sum of covered area
            score = sum(column(top:bottom,5));
            if (score > maxScore)
                maxScore = score;
                optimalSet = column(top:bottom,:);
            end
            if (bottom == numColumn) 
                break;
            end
        end
        if right == numPoints 
            break;
        end
        
    end
end


% function placeRectangle(p, width, height) {
%     var optimal, max = 0;
%     var points = p.slice();
%     points.sort(horizontal);
% 
%     for (var left = 0, right = 0; left < points.length; left++) {
%         while (right < points.length && points[right].x <= points[left].x + width) ++right;
%         var column = points.slice(left, right);
%         column.sort(vertical);
% 
%         for (var top = 0, bottom = 0; top < column.length; top++) {
%             while (bottom < column.length && column[bottom].y <= column[top].y + height) ++bottom;
%             if (bottom - top > max) {
%                 max = bottom - top;
%                 optimal = column.slice(top, bottom);
%             }
%             if (bottom == column.length) break;
%         }
%         if (right == points.length) break;
%     }
% 
%     var left = undefined, right = undefined, top = optimal[0].y, bottom = optimal[optimal.length - 1].y;
%     for (var i = 0; i < optimal.length; i++) {
%         var x = optimal[i].x;
%         if (left == undefined || x < left) left = x;
%         if (right == undefined || x > right) right = x;
%     }
%     return {x: (left + right) / 2, y: (top + bottom) / 2};
% 
%     function horizontal(a, b) {
%         return a.x - b.x;
%     }
% 
%     function vertical(a, b) {
%         return a.y - b.y;
%     }
% }