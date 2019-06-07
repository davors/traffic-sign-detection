% Preprocess color RGB image with Color Constancy algorithm (white patch retinex, gray world, ...)
function RGBout = preprocessColorConstancy(RGB,method)
% RGB - image [H x W x 3]
% method - 'white', 'gray', or 'none'

if strcmpi(method, 'white')
    % White patch retinex
    topPercentile = 5;
    RGB_lin = rgb2lin(RGB);
    illuminant = illumwhite(RGB_lin,topPercentile);
    RGB_lin_adapt = chromadapt(RGB_lin,illuminant,'ColorSpace','linear-rgb');
    RGBout = lin2rgb(RGB_lin_adapt);
    
elseif strcmpi(method, 'gray')
    % Gray world
    percentiles = 10;
    RGB_lin = rgb2lin(RGB);
    illuminant = illumgray(RGB_lin,percentiles);
    RGB_lin_adapt = chromadapt(RGB_lin,illuminant,'ColorSpace','linear-rgb');
    RGBout = lin2rgb(RGB_lin_adapt);

elseif strcmpi(method, 'none')
    % none
    RGBout = RGB;
else
    error('Unknown method for color constancy.');
end