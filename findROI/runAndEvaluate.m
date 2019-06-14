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
[BBoxes, images, ~, folderSave] = runDetector(images, show, saveImage, saveResults);

%--------------------------------------------------------------------------
% Evaluate
fprintf(1,'Evaluating ...\n');
ticID = tic();
% Load annotations once
annot = load(param.general.annotations);
annot = annot.ANNOT;
% Compute scores for full bboxes
BBoxType = 'full';
[statisticsFull] = score(images, BBoxes, BBoxType ,annot);

% Compute scores for tight bboxes
BBoxType = 'tight';
[statisticsTight] = score(images, BBoxes, BBoxType ,annot);
t = toc(ticID);
fprintf(1,'Done. Evaluation time: %f s.\n\n',t);

%--------------------------------------------------------------------------
% Report
fprintf("Scores - FULL bboxes\n");
displayStatistics(statisticsFull);
fprintf("\n");
fprintf("Scores - TIGHT bboxes\n");
displayStatistics(statisticsTight);
fprintf("\n");

%--------------------------------------------------------------------------
% Save
if saveResults
    save([folderSave,filesep,'scores.mat'],'statisticsFull','statisticsTight');
end
