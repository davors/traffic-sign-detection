function [statistics]=scoreFast(file_images, BBox, BBoxType, A, P)

% A: - cell with loaded annotations or
%    - path to annotations file
% P: - cell of precomputed polyshapes

lastwarn('');
if ~exist('BBoxType','var') || isempty(BBoxType)
    BBoxType = 'full';
end

param = config();
if ~exist('A','var') || isempty(A)
    % Load default annotations defined in config
    annotPath = param.general.annotations;
    A = load(annotPath);
    A = A.ANNOT;
elseif ischar(A)
    % user provided the path to annotations file. Load it.
    A = load(A);
    A = A.ANNOT; 
end

if ~iscell(A)
    A = annotationsGetByFilename(A,file_images, param.general.filterIgnore);
end

if ~exist('P','var') || isempty(P)
    % Load precomputed polyshapes, path defined in config
    pPath = param.general.precomputedPoly;
    P = load(pPath);
    P = P.P;
end

warning('off','MATLAB:polyshape:repairedBySimplify');

%statistics for every sign category and total
statistics.covered_signs=zeros(1,201);
statistics.partially_covered_signs=zeros(1,201);
statistics.total_signs=zeros(1,201);
statistics.covered_area=zeros(1,201);
statistics.total_area=zeros(1,201);
statistics.num_images=0;
statistics.per_image={};
%heatmap=zeros(1080,1920);
%figure;
%hold on;
for image_i=1:numel(A)
    % If there are no annotations for image_i, skip it.
    if isempty(A{image_i}) || isempty(A{image_i}.a)
        continue;
    end
    image_file_name=file_images{image_i};
    %height = A{image_i}.size(2);
    
    statistics.num_images=statistics.num_images+1;
    statistics.per_image{statistics.num_images}.file_name=image_file_name;
    statistics.per_image{statistics.num_images}.covered_area=0;
    statistics.per_image{statistics.num_images}.covered_signs=0;
    statistics.per_image{statistics.num_images}.partially_covered_signs=0;
    statistics.per_image{statistics.num_images}.not_covered_signs=0;
    statistics.per_image{statistics.num_images}.total_area=0;
    
        
    for sign_i=1:numel(A{image_i}.a)        
        sign_inside=0;
        area_covered=0;
        
        %extract sign data
        sign_category=A{image_i}.a(sign_i).category_id+1;
        xs=A{image_i}.a(sign_i).segmentation(1:2:end-2);
        ys=A{image_i}.a(sign_i).segmentation(2:2:end-2);
        
        %convert to polygon and calculate area
        signID = A{image_i}.a(sign_i).id;
        Pind = P.id == signID;
        poly = P.polygon{Pind};
        
        %poly = polyshape(xs,ys);
        poly_area = area(poly);
        %plot(poly)
        
        %update statistics
        statistics.total_signs(end)=statistics.total_signs(end)+1;
        statistics.total_area(end)=statistics.total_area(end)+poly_area;
        statistics.total_signs(sign_category)=statistics.total_signs(sign_category)+1;
        statistics.total_area(sign_category)=statistics.total_area(sign_category)+poly_area;
        statistics.per_image{statistics.num_images}.total_area=statistics.per_image{statistics.num_images}.total_area+poly_area;
        %find the correct bounding boxes for the current image
        index = cellfun(@(x) strcmpi(x.file_name,image_file_name), BBox, 'UniformOutput', 1);
        if strcmpi(BBoxType,'full')
            BBox_i = BBox{index}.BBox;
        elseif strcmpi(BBoxType,'tight')
            BBox_i = BBox{index}.BBoxTight;
        else
            error('Wrong BBoxType.');
        end
        
        %loop through all bounding boxes
        for box_i=0:size(BBox_i,2)/8-1
            xb=BBox_i(box_i*8+1:2:box_i*8+8);
            yb=BBox_i(box_i*8+2:2:box_i*8+8);
            
            %check if the sign is inside of the bounding box
            [in, on]=inpolygon(xs,ys,xb,yb);
            inside=or(in, on);
            
            %plot(polyB,'FaceColor','white','FaceAlpha',0)
            %check if sign inside the boundingbox and update status
            if sum(inside)==length(inside)
                sign_inside=1;
                area_covered=poly_area;
                break;
            else
                polyB = polyshape(xb,yb);
                polyout=intersect(poly,polyB);
                area_covered=max(area(polyout),area_covered);
            end
        end
        %update statistics
        statistics.covered_signs(end)=statistics.covered_signs(end)+sign_inside;
        statistics.covered_signs(sign_category)=statistics.covered_signs(sign_category)+sign_inside;
        
        statistics.covered_area(end)=statistics.covered_area(end)+area_covered;
        statistics.covered_area(sign_category)=statistics.covered_area(sign_category)+area_covered;
        
        
        statistics.per_image{statistics.num_images}.covered_area=statistics.per_image{statistics.num_images}.covered_area+area_covered;
        statistics.per_image{statistics.num_images}.covered_signs=statistics.per_image{statistics.num_images}.covered_signs+sign_inside;
        if (sign_inside==0) && (area_covered>0)
            statistics.partially_covered_signs(end)=statistics.partially_covered_signs(end)+1;
            statistics.per_image{statistics.num_images}.partially_covered_signs=statistics.per_image{statistics.num_images}.partially_covered_signs+1;
            statistics.partially_covered_signs(sign_category)=statistics.partially_covered_signs(sign_category)+1;
        end
        if (sign_inside==0) && (area_covered==0)
           statistics.per_image{statistics.num_images}.not_covered_signs=statistics.per_image{statistics.num_images}.not_covered_signs+1; 
        end
        
    end
end
    %statistics.heatmap=heatmap;
    warning('on','MATLAB:polyshape:repairedBySimplify');
end