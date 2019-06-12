function [fullyCovered, coveredArea]=score(file_images, BBox)

warning('off','MATLAB:polyshape:repairedBySimplify');
load('../data/annotations/default/joined_train_test.mat');
A = annotationsGetByFilename(ANNOT,file_images, []);

fullyCovered=0; 
coveredArea=0;
totalArea=0;
numSigns=0;
%figure;
%hold on;
for image_i=1:numel(A)
    image_id=file_images(image_i);
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
        index = cellfun(@(x) x.id==image_id, BBox, 'UniformOutput', 1);
        for box_i=0:size(BBox{index}.BBox,2)/8-1 
            xb=BBox{index}.BBox(box_i*8+1:2:box_i*8+8);
            yb=1080-BBox{index}.BBox(box_i*8+2:2:box_i*8+8);
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