function runAndEvaluate(images, show, saveOutput)
% Pipeline for traffic signs detection and ROI extraction plus evaluation
% images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder
% show:  0 - do not display anything
%        1 - display final results
%        2 - display intermediate results


if ~exist('images','var') || isempty(images)
    images = [];
end
if ~exist('show','var') || isempty(show)
    show = 0;
end
if ~exist('saveOutput','var') || isempty(saveOutput)
    saveOutput = 0;
end


%--------------------------------------------------------------------------
% Load parameters configuration
param = config();

% Run detector
[BBoxes, images] = runDetector(images, show, saveOutput);

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

% Report
fprintf("Scores - FULL bboxes\n");
displayStatistics(statisticsFull);
fprintf("\n");
fprintf("Scores - TIGHT bboxes\n");
displayStatistics(statisticsTight);
fprintf("\n");
% Save


