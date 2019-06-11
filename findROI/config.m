function param = config()

% Set parameters
param = [];
param.roi.size = [704, 704];
param.roi.num = 3;
% top-left positions of default ROIs; WARNING: works only for FHD images
param.roi.default = [
    0, 200; 
    1920/2-param.roi.size(1)/2, 0; 
    1920-param.roi.size(1), 200];


% =========== COLORS ======================================================
% pipeline = order of processing. Only included steps are then processed.
% 'cc' - color constancy
% 'heq' - histogram equalization
% 'adj' - histogram adjustment
param.colors.initPipeline = {'heq'}; % any combination of 'cc', 'adj', 'heq'
param.colors.initMethods.cc = 'gray'; % 'white', 'gray', 'none'
param.colors.initMethods.heq = 'local'; % 'global', 'local', 'none'
param.colors.initMethods.adj = [0.3 0.7]; % percantage of input contrast clipping

% HSV thresholds 
thrHSV = [];
thrHSV.red.Hmin = 0.93;
thrHSV.red.Hmax = 0.03;
thrHSV.red.Smin = 0.50;
thrHSV.red.Smax = 1.00;
thrHSV.red.Vmin = 0.00;
thrHSV.red.Vmax = 1.00;

thrHSV.blue.Hmin = 0.52;
thrHSV.blue.Hmax = 0.70;
thrHSV.blue.Smin = 0.60;
thrHSV.blue.Smax = 1.00;
thrHSV.blue.Vmin = 0.20;
thrHSV.blue.Vmax = 1.00;

thrHSV.yellowDark.Hmin = 0.05;
thrHSV.yellowDark.Hmax = 0.13;
thrHSV.yellowDark.Smin = 0.64;
thrHSV.yellowDark.Smax = 1.00;
thrHSV.yellowDark.Vmin = 0.20;
thrHSV.yellowDark.Vmax = 1.00;

thrHSV.yellowLight.Hmin = 0.13;
thrHSV.yellowLight.Hmax = 0.18;
thrHSV.yellowLight.Smin = 0.64;
thrHSV.yellowLight.Smax = 1.00;
thrHSV.yellowLight.Vmin = 0.20;
thrHSV.yellowLight.Vmax = 1.00;

thrHSV.green.Hmin = 0.36;
thrHSV.green.Hmax = 0.50;
thrHSV.green.Smin = 0.50;
thrHSV.green.Smax = 1.00;
thrHSV.green.Vmin = 0.20;
thrHSV.green.Vmax = 1.00;

thrHSV.greenFluor.Hmin = 0.16;
thrHSV.greenFluor.Hmax = 0.22;
thrHSV.greenFluor.Smin = 0.70;
thrHSV.greenFluor.Smax = 1.00;
thrHSV.greenFluor.Vmin = 0.50;
thrHSV.greenFluor.Vmax = 1.00;

thrHSV.brown.Hmin = 0.00;
thrHSV.brown.Hmax = 0.08;
thrHSV.brown.Smin = 0.60;
thrHSV.brown.Smax = 1.00;
thrHSV.brown.Vmin = 0.20;
thrHSV.brown.Vmax = 1.00;

param.colors.thrHSV = thrHSV;

% Binary masks filtering
param.colors.maskFilters = {'close_2','fill','gauss_3','close_7','fill'};

% Connected components (blobs) thresholds
% Size of an area we want to filter out (in pixels)
thrCC=[];
thrCC.AreaMin = 300;
thrCC.AreaMax = 230000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.45;
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.16;
thrCC.AspectMax = 1;

param.colors.thrCC = thrCC;


% =========== WHITE ======================================================
param.white.initPipeline = {'cc','heq','adj'}; % any combination of 'cc', 'adj', 'heq'
param.white.initMethods.cc = 'gray'; % 'white', 'gray', 'none'
param.white.initMethods.heq = 'local'; % 'global', 'local', 'none'
param.white.initMethods.adj = [0.4 0.7]; % percentage of input contrast clipping

% HSV thresholds
thrHSV = [];
thrHSV.white.Hmin = 0.00;
thrHSV.white.Hmax = 1.00;
thrHSV.white.Smin = 0.00;
thrHSV.white.Smax = 0.25;
thrHSV.white.Vmin = 0.80;
thrHSV.white.Vmax = 1.00;
param.white.thrHSV = thrHSV;

% Binary masks filtering
param.white.maskFilters = {'close_1','fill','open_5'};

% Connected components (blobs) thresholds
% Size of an area we want to filter out (in pixels)
thrCC = [];
thrCC.AreaMin = 700;
thrCC.AreaMax = 30000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.5;
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.16;
thrCC.AspectMax = 1;
param.white.thrCC = thrCC;