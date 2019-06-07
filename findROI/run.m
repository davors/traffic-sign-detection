function run(file_images)
% Pipeline for traffic signs detection and ROI extraction
% file_images: - cell array of strings with filenames or
%              - numeric array of image IDs or
%              - empty/notexistant to process all images in folder

if ~exist('file_images','var') || isempty(file_images)
    file_images = [];
elseif isnumeric(file_images)
    numIDs = numel(file_images);
    tmp = cell(1,numIDs);
    for i=1:numIDs
        tmp{i} = sprintf('%07.0f.jpg',file_images(i));
    end
    file_images = tmp;
end


% Specify folders for input/output
format = 'jpg';
folder_in = '../data/original';
folder_out = '../data/results';

show = 0; % 0 - run silently



%--------------------------------------------------------------------------
% Parameters
histEqMethod = 'local'; % 'global', 'local', 'none'
colConstMethod = 'gray'; % 'white', 'gray', 'none'



%--------------------------------------------------------------------------

% Scan data folder for files
if isempty(file_images)
    file_images = dir([folder_in,'/*.',format]);
    file_images = {file_images.name};
end

% Create output folder if it does not exist already.
[~,~,~] = mkdir(folder_out);

numImages = numel(file_images);

totalTime = 0;
% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    imagePath = [folder_in, filesep, file_image];
    
    tic();
    % Run detector
    findROI(imagePath,histEqMethod,colConstMethod);
        
    % Save
    %savePath = [folder_out,filesep,file_image];
    %imwrite(RGBcc, savePath, 'Quality',100);
    
    t = toc();
    totalTime = totalTime + t;
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
    
    % Show results if in interactive mode
%     if show
%         montage({RGB, RGBheq, RGBcc},'BorderSize',11,'BackgroundColor','w');
%         fprintf(1, 'File %s | hist. eq. (%s) | Color Constancy (%s)', file_image, histEqMethod, colConstMethod);
%         if image_i < numImages
%             waitforbuttonpress();
%         end
%     end   
end
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);