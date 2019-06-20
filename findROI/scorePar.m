function [statistics]=scorePar(file_images, BBox, BBoxType, A)

% annot: - struct with loaded annotations or
%        - path to annotations file
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

warning('off','MATLAB:polyshape:repairedBySimplify');

% Filter out images without annotations
isemptyA = cellfun(@isempty, A);
%isemptyAa = cellfun(@(x) isempty(x.a), A);

file_images(isemptyA) = [];
A(isemptyA) = [];

numImages = numel(A);

%statistics for every sign category and total
covered_signs=zeros(numImages,201);
partially_covered_signs=zeros(numImages,201);
total_signs=zeros(numImages,201);
covered_area=zeros(numImages,201);
total_area=zeros(numImages,201);
per_image=cell(1,numImages);

% Use parallel loop - create new pool if there is none or with different
% number of workers
parallelNumWorkers = param.general.parallelNumWorkers;
currentPool = gcp('nocreate');
if isempty(currentPool) || currentPool.NumWorkers ~= parallelNumWorkers
    delete(currentPool);
    parpool(parallelNumWorkers);
end

parfor image_i=1:numImages
    image_file_name=file_images{image_i};
    
    warning('off','MATLAB:polyshape:repairedBySimplify');
    
    covered_signs_tmp=zeros(1,201);
    partially_covered_signs_tmp=zeros(1,201);
    total_signs_tmp=zeros(1,201);
    covered_area_tmp=zeros(1,201);
    total_area_tmp=zeros(1,201);
    
    per_image{image_i}.file_name=image_file_name;
    per_image{image_i}.covered_area=0;
    per_image{image_i}.covered_signs=0;
    per_image{image_i}.partially_covered_signs=0;
    per_image{image_i}.not_covered_signs=0;
    per_image{image_i}.total_area=0;
    
    numSigns = numel(A{image_i}.a);
    total_signs_tmp(end) = numSigns;
    
    for sign_i=1:numSigns
        sign_inside=0;
        area_covered=0;
        
        %extract sign data
        sign_category=A{image_i}.a(sign_i).category_id+1;
        xs=A{image_i}.a(sign_i).segmentation(1:2:end-2);
        ys=A{image_i}.a(sign_i).segmentation(2:2:end-2);
        
        %convert to polygon and calculate area
        poly = polyshape(xs,ys);
        poly_area = area(poly);
        %plot(poly)
        
        % update statistics
        total_area_tmp(end)=total_area_tmp(end)+poly_area;
        total_signs_tmp(sign_category)=total_signs_tmp(sign_category)+1;
        total_area_tmp(sign_category)=total_area_tmp(sign_category)+poly_area;
        per_image{image_i}.total_area=per_image{image_i}.total_area+poly_area;
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
        covered_signs_tmp(end)=covered_signs_tmp(end)+sign_inside;
        covered_signs_tmp(sign_category)=covered_signs_tmp(sign_category)+sign_inside;
        
        covered_area_tmp(end)=covered_area_tmp(end)+area_covered;
        covered_area_tmp(sign_category)=covered_area_tmp(sign_category)+area_covered;
        
        
        per_image{image_i}.covered_area = per_image{image_i}.covered_area+area_covered;
        per_image{image_i}.covered_signs = per_image{image_i}.covered_signs+sign_inside;
        if (sign_inside==0) && (area_covered>0)
            partially_covered_signs_tmp(end)=partially_covered_signs_tmp(end)+1;
            per_image{image_i}.partially_covered_signs=per_image{image_i}.partially_covered_signs+1;
            partially_covered_signs_tmp(sign_category)=partially_covered_signs_tmp(sign_category)+1;
        end
        if (sign_inside==0) && (area_covered==0)
            per_image{image_i}.not_covered_signs=per_image{image_i}.not_covered_signs+1;
        end
        
    end
    
    covered_signs(image_i,:)=covered_signs_tmp;
    partially_covered_signs(image_i,:)=partially_covered_signs_tmp;
    total_signs(image_i,:) = total_signs_tmp;
    covered_area(image_i,:)=covered_area_tmp;
    total_area(image_i,:)=total_area_tmp;
    
end
statistics.num_images = numImages;
statistics.per_image = per_image;
statistics.covered_signs = sum(covered_signs,1);
statistics.partially_covered_signs = sum(partially_covered_signs,1);
statistics.total_signs = sum(total_signs,1);
statistics.covered_area = sum(covered_area,1);
statistics.total_area = sum(total_area,1);

warning('on','MATLAB:polyshape:repairedBySimplify');
