% Preprocess color RGB image with local histogram equalization (global or local=CLAHE)
% Process each channel separately.

function I = preprocessHistogramEq(I,method,colorMode)
% RGB - image [H x W x 3]
% method - 'global', 'local', or 'none'

if ~exist('method','var') || isempty(method)
    method.type = 'none';
end

if strcmpi(method.type, 'global')
    % Global
    if strcmpi(colorMode,'RGB')
        I(:,:,1) = histeq(I(:,:,1));
        I(:,:,2) = histeq(I(:,:,2));
        I(:,:,3) = histeq(I(:,:,3));
        
    elseif strcmpi(colorMode,'HSV')
        I(:,:,3) = histeq(I(:,:,3));
    end
    
elseif strcmpi(method.type, 'local')
    % Local (CLAHE)  
    if strcmpi(colorMode,'RGB')
        I(:,:,1) = adapthisteq(I(:,:,1),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
        I(:,:,2) = adapthisteq(I(:,:,2),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
        I(:,:,3) = adapthisteq(I(:,:,3),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
        
    elseif strcmpi(colorMode,'HSV')
        I(:,:,3) = adapthisteq(I(:,:,3),'NumTiles',method.numTiles,'ClipLimit',method.clipLimit, 'NBins', method.nBins, 'Range', method.range, 'Distribution', method.distribution);
    end

elseif strcmpi(method.type, 'none')
    % none
else 
    error('Unknown method for histogram equalization.');
end


