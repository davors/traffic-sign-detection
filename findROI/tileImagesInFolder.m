% Tile selected images from same folder for easier threshold adjusting.

numTiles = 6;

format = 'jpg';
folders_in = {'../data/original', '../data/preprocessed_heq', '../data/preprocessed_cc', '../data/preprocessed_heq_cc'};
folder_out = '../data/tileImagesInFolder';

% leave empty to process all in folder_in folder.
%file_images = {'0000118.jpg'}; 
file_images = {};

if isempty(file_images)
    file_images = dir([folders_in{1},'/*.',format]);
    file_images = {file_images.name};
end


numImages = numel(file_images);
numPacks = ceil(numImages / numTiles);
numFolders = numel(folders_in);

for folder_i = 1: numFolders
    folder_in = folders_in{folder_i};
    folder_out_append = split(folder_in,'/');
    folder_out_append = [folder_out,'/',folder_out_append{end}];    
    [~,~,~] = mkdir(folder_out_append);
    
    fprintf(1,'Processing folder %s\n', folder_out_append);
    % Loop over all files with images
    for pack_i = 1:numPacks
        
        from = (pack_i-1)*numTiles +1;
        to = pack_i*numTiles;
        
        file_image_list = file_images(from:to);
        
        files = strcat(folder_in,'/',file_image_list);
        
        img = imtile(files);
        
        savePath = [folder_out_append,'/pack_',num2str(pack_i,'%03.f'),'.',format];
        imwrite(img, savePath, 'Quality',100);
        fprintf(1,'Done pack %d out of %d.\n', pack_i,numPacks);
    end
end