function P = precomputePolyshapes(annot)

param = config();

if ~exist('annot','var') || isempty(annot)
    % Load default annotations defined in config
    annot = load(param.general.annotations);
    annot = annot.ANNOT;
end

id = [annot.annotations.id];
seg = {annot.annotations.segmentation};
clear annot;

numSigns = numel(seg);
polygons = cell(1,numSigns);

warning('off','MATLAB:polyshape:repairedBySimplify');
ticID = tic();
for sign_i = 1:numSigns
    fprintf(1,'%d / %d\n',sign_i,numSigns);
    xs = seg{sign_i}(1:2:end-2);
    ys = seg{sign_i}(2:2:end-2);
        
    %convert to polygon and calculate area
    polygons{sign_i} = polyshape(xs,ys);
end
timeElapsed = toc(ticID);
fprintf(1,'DONE in %f s\n',timeElapsed);
warning('on','MATLAB:polyshape:repairedBySimplify');

P = struct;
P.id = id;
P.polygon = polygons;

% Save
[savePath,filename,ext] = fileparts(param.general.annotations);
save(fullfile(savePath,[filename,'.poly',ext]),'P');