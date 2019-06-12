% Preprocess color RGB image with local histogram equalization (global or local=CLAHE)
% Process each channel separately.

function RGBout = preprocessHistogramEq(RGB,method)
% RGB - image [H x W x 3]
% method - 'global', 'local', or 'none'

if strcmpi(method, 'global')
    % Global
    R = histeq(RGB(:,:,1));
    G = histeq(RGB(:,:,2));
    B = histeq(RGB(:,:,3));
    RGBout = cat(3,R,G,B);
    
elseif strcmpi(method, 'local')
    % Local (CLAHE)
    numTiles = [16, 32];
    clipLimit = 0.01; %0.01
    nBins = 32; % sensitive
    range = 'full';
    distribution = 'uniform'; % uniform, rayleigh
    
    R = adapthisteq(RGB(:,:,1),'NumTiles',numTiles,'ClipLimit',clipLimit, 'NBins', nBins, 'Range', range, 'Distribution', distribution );
    G = adapthisteq(RGB(:,:,2),'NumTiles',numTiles,'ClipLimit',clipLimit, 'NBins', nBins, 'Range', range, 'Distribution', distribution );
    B = adapthisteq(RGB(:,:,3),'NumTiles',numTiles,'ClipLimit',clipLimit, 'NBins', nBins, 'Range', range, 'Distribution', distribution );
    RGBout = cat(3,R,G,B);

elseif strcmpi(method, 'none')
    % none
    RGBout = RGB;
else 
    error('Unknown method for histogram equalization.');
end


