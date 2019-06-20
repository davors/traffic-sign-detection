function runAndEvaluate(images, show, saveMode)
% Pipeline for traffic signs detection and ROI extraction plus evaluation
% images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder
% show:  0 - do not display anything
%        1 - display final results
%        2 - display intermediate results
% saveMode: 'none' - do not save anything
%           'results' - save bounding boxes and evaluation statistics
%           'image' - save image with bounding boxes
%           'all' - same as both 'results' and 'image'

if ~exist('images','var') || isempty(images)
    images = [];
end
if ~exist('show','var') || isempty(show)
    show = 0;
end
if ~exist('saveMode','var') || isempty(saveMode)
    saveMode = 'none';
end

%assert(ismember(saveMode,{'none','results','image','all'}),'Wrong saveMode.');
saveImage = 0;
saveResults = 0;
if any(strcmpi(saveMode,{'image','all'}))
    saveImage = 1;
end
if any(strcmpi(saveMode,{'results','all'}))
    saveResults = 1;
end



%--------------------------------------------------------------------------
% Load parameters configuration
param = config();

%--------------------------------------------------------------------------
% Run detector
assert(param.general.parallelNumWorkers > 0,'param.general.parallelNumWorkers has to be positive integer.');
if param.general.parallelNumWorkers > 1 && ~strcmpi(param.general.findROIalgorithm,'oracle')
    [BBoxes, images, ~, folderSave, A] = runDetectorPar(images, show, saveImage, saveResults);
else
    [BBoxes, images, ~, folderSave, A] = runDetector(images, show, saveImage, saveResults);
end
%--------------------------------------------------------------------------
% Evaluate
fprintf(1,'Evaluating ...\n');
ticID = tic();

if isempty(A)
    % Load annotations once
    annot = load(param.general.annotations);
    annot = annot.ANNOT;
    A = annotationsGetByFilename(annot, images, param.general.filterIgnore);
end


% Load precomputed polyshapes for traffic signs
P = [];
if ~isempty(param.general.precomputedPoly)
    P = load(param.general.precomputedPoly);
    P = P.P;
end

BBoxTypes = param.general.evaluateBBoxTypes;

statistics = struct;

for bbType_i = 1:numel(BBoxTypes)
    
    BBoxType = BBoxTypes{bbType_i};
    
    if strcmpi(param.general.findROIalgorithm, 'dummy') && strcmpi(BBoxType,'tight')
        fprintf(1,'Dummy + tight bboxes = dummy + full bboxes. Skipping.\n');
        statistics.BBoxType = [];
        continue;
    end
    
    if param.general.parallelNumWorkers > 1
        if isempty(P)
            statistics.(BBoxType) = scorePar(images, BBoxes, BBoxType, A);
        else
            statistics.(BBoxType) = scoreFastPar(images, BBoxes, BBoxType, A, P);
        end
    else
        if isempty(P)
            statistics.(BBoxType) = score(images, BBoxes, BBoxType, A);
        else
            statistics.(BBoxType) = scoreFast(images, BBoxes, BBoxType, A, P);
        end
    end
    
    timeEvaluation = toc(ticID);
    fprintf(1,'Done type %s. Elapsed evaluation time: %f s.\n\n', upper(BBoxType), timeEvaluation);
    
    fprintf("Scores - %s bboxes\n", upper(BBoxType));
    displayStatistics(statistics.(BBoxType));
    fprintf("\n");    
end

%--------------------------------------------------------------------------
% Save
if saveResults
    save([folderSave,filesep,'scores.mat'],'statistics','timeEvaluation');
end
