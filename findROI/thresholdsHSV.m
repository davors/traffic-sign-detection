function [BWlayers, colors, tS] = thresholdsHSV(I,tS,colorMode)

if ~exist('tS','var') || isempty(tS)
    % Thresholds for HSV color model in a struct    
    % Vitabile et al. (2002) defined three different areas in the HSV colour space as follows:
    % 1) The achromatic area, characterised by S <= 0.25 or V <= 0.2 or V => 0.9.
    % 2) The unstable chromatic area, characterised by 0.25 <= S <= 0.5 and 0.2 <= V <= 0.9.
    % 3) The chromatic area, characterised by S >= 0.5 and 0.2 <= V <= 0.9.
    
    tS.red.Hmin = 0.93;
    tS.red.Hmax = 0.03;
    tS.red.Smin = 0.50;
    tS.red.Smax = 1.00;
    tS.red.Vmin = 0.20;
    tS.red.Vmax = 1.00;
    
    tS.blue.Hmin = 0.52;
    tS.blue.Hmax = 0.70;
    tS.blue.Smin = 0.60;
    tS.blue.Smax = 1.00;
    tS.blue.Vmin = 0.25;
    tS.blue.Vmax = 1.00;
        
    tS.yellowDark.Hmin = 0.05;
    tS.yellowDark.Hmax = 0.13;
    tS.yellowDark.Smin = 0.64;
    tS.yellowDark.Smax = 1.00;
    tS.yellowDark.Vmin = 0.20;
    tS.yellowDark.Vmax = 1.00;
    
    tS.yellowLight.Hmin = 0.13;
    tS.yellowLight.Hmax = 0.18;
    tS.yellowLight.Smin = 0.64;
    tS.yellowLight.Smax = 1.00;
    tS.yellowLight.Vmin = 0.20;
    tS.yellowLight.Vmax = 1.00;
    
    tS.green.Hmin = 0.36;
    tS.green.Hmax = 0.47;
    tS.green.Smin = 0.50;
    tS.green.Smax = 1.00;
    tS.green.Vmin = 0.20;
    tS.green.Vmax = 1.00;
    
    tS.greenFluor.Hmin = 0.16;
    tS.greenFluor.Hmax = 0.22;
    tS.greenFluor.Smin = 0.70;
    tS.greenFluor.Smax = 1.00;
    tS.greenFluor.Vmin = 0.50;
    tS.greenFluor.Vmax = 1.00;
    
    tS.brown.Hmin = 0.00;
    tS.brown.Hmax = 0.08;
    tS.brown.Smin = 0.60;
    tS.brown.Smax = 1.00;
    tS.brown.Vmin = 0.20;
    tS.brown.Vmax = 1.00;
    
    tS.black.Hmin = 0.00;
    tS.black.Hmax = 1.00;
    tS.black.Smin = 0.00;
    tS.black.Smax = 1.00;
    tS.black.Vmin = 0.00;
    tS.black.Vmax = 0.20;
    
    tS.white.Hmin = 0.00;
    tS.white.Hmax = 1.00;
    tS.white.Smin = 0.00;
    tS.white.Smax = 0.25;
    tS.white.Vmin = 0.80;
    tS.white.Vmax = 1.00;
else
    assert(isstruct(tS),'tS has to be a struct.');
end

[h,w,c] = size(I);
colors = fieldnames(tS);
numColors = numel(colors);

BWlayers = false(h,w,numColors);

if strcmpi(colorMode,'RGB')
    I = rgb2hsv(I);
end

for ci = 1:numColors
    color = colors{ci};    
    thres = tS.(color);
    
    % Hue around-the-circle thresholds check
    if thres.Hmin > thres.Hmax
        BWlayers(:,:,ci) =  ...
        ( (I(:,:,1) >= thres.Hmin ) | (I(:,:,1) <= thres.Hmax) ) & ...
        ( (I(:,:,2) >= thres.Smin ) & (I(:,:,2) <= thres.Smax) ) & ...
        ( (I(:,:,3) >= thres.Vmin ) & (I(:,:,3) <= thres.Vmax) );
    else
        BWlayers(:,:,ci) =  ...
        ((I(:,:,1) >= thres.Hmin ) & (I(:,:,1) <= thres.Hmax)) & ...
        ((I(:,:,2) >= thres.Smin ) & (I(:,:,2) <= thres.Smax)) & ...
        ((I(:,:,3) >= thres.Vmin ) & (I(:,:,3) <= thres.Vmax));
    end        
end
