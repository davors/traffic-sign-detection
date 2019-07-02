function colorThresholderView(file_image)

if isnumeric(file_image)
    file_image = sprintf('%07.0f.jpg',file_image);
end

param=config();

RGB = imread([param.general.folderSource, filesep, file_image]);
HSV = rgb2hsv(RGB);
HSV = preprocess(HSV, param.colors.initPipeline, param.colors.initMethods, 'HSV');
RGB = hsv2rgb(HSV);
colorThresholder(RGB);