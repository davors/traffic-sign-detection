function displayStatisticsFolder(resPath,showByCategory,bboxType)
% folder is a folder with results. Results are in separate folders with
% results.mat and score.mat files

scoreFilename = 'scores.mat';

param = config();

if ~exist('resPath','var') || isempty(resPath)
    resPath = uigetdir(param.general.folderResults);
end
if ~exist('showByCategory','var') || isempty(showByCategory)
    showByCategory = 0;
end
if ~exist('bboxType','var') || isempty(bboxType)
    bboxType = 'full';
end

resFolders = dir(resPath);
mask = [resFolders.isdir] & ~ismember({resFolders.name},{'.','..'});
folderNames = {resFolders(mask).name};
numFolders = numel(folderNames);

fprintf(1,'%s\n',repmat('=',1,100));
for f = 1:numFolders
    folderName = folderNames{f};
    S = load([resPath,filesep,folderName, filesep, scoreFilename]);
    fprintf(1,'***   %s   ***\n\n', folderName);
    
    isNewFormat = isfield(S,'statistics');
    
    if strcmpi(bboxType,'full') || strcmpi(bboxType,'all')
        fprintf(1,'FULL bbox\n');
        if isNewFormat
            if isfield(S.statistics,'full') && ~isempty(S.statistics.full)
                displayStatistics(S.statistics.full,showByCategory);
            end
        else
            displayStatistics(S.statisticsFull,showByCategory);
        end
    end
    
    if strcmpi(bboxType,'tight') || strcmpi(bboxType,'all')
        fprintf(1,'%s\nTIGHT bbox\n',repmat('- ',1,50));
        if isNewFormat
            if isfield(S.statistics,'tight') && ~isempty(S.statistics.tight)
                displayStatistics(S.statistics.tight,showByCategory);
            end
        else
            displayStatistics(S.statisticsTight,showByCategory);
        end
    end
    
    fprintf(1,'%s\n',repmat('=',1,100));
end
