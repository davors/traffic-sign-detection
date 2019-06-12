% Preprocess color RGB image with local histogram equalization (global or local=CLAHE)
% Process each channel separately.

function RGBout = preprocessHistogramEq(RGB,method)
% RGB - image [H x W x 3]
% method - 'global', 'local', or 'none'

if ~exist('method','var') || isempty(method)
    method.type = 'none';
end

if strcmpi(method.type, 'global')
    % Global
    R = histeq(RGB(:,:,1));
    G = histeq(RGB(:,:,2));
    B = histeq(RGB(:,:,3));
    RGBout = cat(3,R,G,B);
    
elseif strcmpi(method.type, 'local')
    % Local (CLAHE)    
    R = adapthisteq(RGB(:,:,1),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
    G = adapthisteq(RGB(:,:,2),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
    B = adapthisteq(RGB(:,:,3),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
    RGBout = cat(3,R,G,B);

elseif strcmpi(method.type, 'none')
    % none
    RGBout = RGB;
else 
    error('Unknown method for histogram equalization.');
end


