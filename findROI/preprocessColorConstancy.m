% Preprocess color RGB image with Color Constancy algorithm (white patch retinex, gray world, ...)
function I = preprocessColorConstancy(I,method,colorMode)
% RGB - image [H x W x 3]
% method - 'white', 'gray', or 'none'

if strcmpi(method, 'none')
    return;
end

if strcmpi(colorMode,'HSV')
    I = hsv2rgb(I);
end

if strcmpi(method, 'white')
    % White patch retinex
    topPercentile = 5;
    RGB_lin = rgb2lin(I);
    illuminant = illumwhite(RGB_lin,topPercentile);
    RGB_lin_adapt = chromadapt(RGB_lin,illuminant,'ColorSpace','linear-rgb');
    I = lin2rgb(RGB_lin_adapt);
    
elseif strcmpi(method, 'gray')
    % Gray world
    percentiles = 10;
    RGB_lin = rgb2lin(I);
    illuminant = illumgray(RGB_lin,percentiles);
    RGB_lin_adapt = chromadapt(RGB_lin,illuminant,'ColorSpace','linear-rgb');
    I = lin2rgb(RGB_lin_adapt);
else
    error('Unknown method for color constancy.');
end

if strcmpi(colorMode,'HSV')
    I = rgb2hsv(I);
end