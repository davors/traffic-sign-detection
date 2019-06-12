% Script for batch image preprocessing

% order of processing
% 'cc' - color constancy
% 'heq' - histogram equalization
% 'adj' - histogram adjustment
pipeline = {'cc','heq','adj'};
methods = [];
methods.cc = 'gray'; % 'white', 'gray', 'none'
methods.heq = 'local'; % 'global', 'local', 'none'
methods.adj = [0.3 0.7]; % percantage of input contrast clipping

numSteps = numel(pipeline);

suffix = strjoin(pipeline,'_');
% Specify folder with input images
format_in = 'jpg';
format_out = 'jpg';
folder_in = '../data/original';
folder_out = ['../data/preprocessed_',suffix];


show = 0; % 0 - run silently



% leave empty to process all in folder_in folder.
%file_images = {'0000118.jpg'}; 
file_images = {};

%--------------------------------------------------------------------------

% Scan data folder for files
if isempty(file_images)
    file_images = dir([folder_in,'/*.',format_in]);
    file_images = {file_images.name};
end

% Create output folder if it does not exist already.
[~,~,~] = mkdir(folder_out);

numImages = numel(file_images);

totalTime = 0;
% Loop over all files with images
for image_i = 1:numImages
    file_image = file_images{image_i};
    [~,file_image_name] = fileparts(file_image);
    tic();
    % Read file
    RGB = imread([folder_in, filesep, file_image]);
    RGBorig = RGB;
    
    % Preprocess
    for s=1:numSteps
        step = pipeline{s};
        if strcmpi(step,'cc')
            RGB = preprocessColorConstancy(RGB,methods.cc);            
        elseif strcmpi(step,'heq')
            RGB = preprocessHistogramEq(RGB,methods.heq);
        elseif strcmpi(step,'adj')
            RGB = imadjust(RGB, [repmat(methods.adj(1),1,3); repmat(methods.adj(2),1,3)],[]); 
        else
            error('!!!');
        end
        
    end
    
    % Save
    savePath = [folder_out,filesep,file_image_name,'.',format_out];
    imwrite(RGB, savePath);
    
    t = toc();
    totalTime = totalTime + t;
    
    fprintf(1,'File %s done. Time: %f sec.\n', file_image,  t);
    
    % Show results if in interactive mode
    if show
        montage({RGBorig, RGB},'BorderSize',11,'BackgroundColor','w');
        fprintf(1, 'File %s | hist. eq. (%s) | Color Constancy (%s) | Adjust (%f)', file_image, methods.heq, methods.cc, methods.adj);
        if image_i < numImages
            waitforbuttonpress();
        end
    end   
end
save([folder_out,filesep,'info.mat'],'pipeline', 'methods');
fprintf(1,'Done %d images. Total time: %f sec.\n', numImages, totalTime);