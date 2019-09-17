% test resizing
path_orig = '../../data/original/';
file_image = '0000118.jpg';

scale = 0.5;
method = 'nearest';
antialias = false;

numIters = 100;

RGB = imread([path_orig,file_image]);
t = 0;
for i=1:numIters
tic();
RGBout = imresize(RGB,'Scale',scale,'Method',method,'Antialiasing',antialias);
t = t + toc();
end

fprintf('Avg time: %f s\n',t/numIters);