function [fullyCovered, coveredArea]=score(file_images, BBox, BBoxType, annot)

% annot: - struct with loaded annotations or
%        - path to annotations file

if ~exist('BBoxType','var') || isempty(BBoxType)
    BBoxType = 'full';
end

if ~exist('annot','var') || isempty(annot)
    % Load default annotations defined in config
    param = config();
    annotPath = param.general.annotations;
    annot = load(annotPath);
    annot = annot.ANNOT;
elseif ischar(annot)
    % user provided the path to annotations file. Load it.
    annot = load(annot);
    annot = annot.ANNOT;
else
    % user provided structure with annotations
    assert(isstruct(annot),'annot should be struct with annotations.');
end

warning('off','MATLAB:polyshape:repairedBySimplify');

A = annotationsGetByFilename(annot,file_images, []);

fullyCovered=0; 
coveredArea=0;
totalArea=0;
numSigns=0;
%figure;
%hold on;
for image_i=1:numel(A)
    % If there are no annotations for image_i, skip it.
    if isempty(A{image_i})
        continue;
    end
    image_file_name=file_images{image_i};
    signs_inside=zeros(1,numel(A{image_i}));
    area_covered=zeros(1,numel(A{image_i}));
    for sign_i=1:numel(A{image_i})
        xs=A{image_i}(sign_i).segmentation(1:2:end-2);
        ys=A{image_i}(sign_i).segmentation(2:2:end-2);
        poly = polyshape(xs,ys);
        %plot(poly)
        poly_area = area(poly);
        totalArea=totalArea+poly_area;
        numSigns=numSigns+1;
        index = cellfun(@(x) strcmpi(x.file_name,image_file_name), BBox, 'UniformOutput', 1);
        
        if strcmpi(BBoxType,'full')
            BBox_i = BBox{index}.BBox;
        elseif strcmpi(BBoxType,'tight')
            BBox_i = BBox{index}.BBoxTight;
        else
            error('Wrong BBoxType.');
        end
                
        for box_i=0:size(BBox_i,2)/8-1 
            xb=BBox_i(box_i*8+1:2:box_i*8+8);
            yb=1080-BBox_i(box_i*8+2:2:box_i*8+8);
            [in, on]=inpolygon(xs,ys,xb,yb);
            polyB = polyshape(xb,yb);
            %plot(polyB,'FaceColor','white','FaceAlpha',0)
            inside=or(in, on);
            if sum(inside)==length(xs)
               signs_inside(sign_i)=1;
               area_covered(sign_i)=poly_area;
            else
                polyout=intersect(poly,polyB);
                area_covered(sign_i)=max(area(polyout),area_covered(sign_i));
            end    
        end
    end
    coveredArea=coveredArea+sum(area_covered);
    fullyCovered=fullyCovered+sum(signs_inside);
end
    warning('on','MATLAB:polyshape:repairedBySimplify');
    coveredArea=coveredArea/totalArea;
    fullyCovered=fullyCovered/numSigns;
end