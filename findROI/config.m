function param = config()

% Set parameters
param = [];

% =========== GENERAL =====================================================
% Select algorithm for traffic sign detection
% 'oracle' - known annotations, 100% true
% 'dummy' - default rectangles positions (defined in param.roi.default.pos) 
% 'smarty' - detects colors and white patches 
% 'smarty2' - detects colors and white patches (weighted) - alternative solution
% 'smartyColor' - detects colors (heavy implementation - each color is processed separately)
% 'smartyColor2' -  detects colors (light implementation - all color masks are merged)
% 'smartyColor3' -  detects colors (compromise - color masks are separately processed for small blobs, blue sky and bottom lying objects)
% ...
% 'smartyColor5_4' - the latest, the basis for a GPU implementation
param.general.findROIalgorithm = 'smartyColor6_1';
param.general.parallelNumWorkers = 4; % How many jobs to run in parallel (MATLAB parfor)
param.general.resizeInputByFactor = 0.5; % Only v6: Rescaling input image? Put 1 to skip it.
%param.general.folderSource = '../data/original'; % Sample dataset for the pipeline testing only
param.general.folderSource = '../../../datasets/DFGTSD/DFGTSD_vicos/1920_1080';
param.general.folderResults = '../data/results';
param.general.annotations = '../data/annotations/default/joined_train_test.mat';
param.general.precomputedPoly = '../data/annotations/default/joined_train_test.poly.mat'; % []
param.general.evaluateBBoxTypes = {'full'}; % {'full', 'tight'}
param.general.imageSize = [1080, 1920]; % leave empty to not filter by size. Works together with keepOnlyAnnotated
param.general.keepOnlyAnnotated = 1; % consider only images that have valid annotations
param.general.filterIgnore = 1; % filter out annotations with ignore flag
param.general.colorMode = 'HSV';
param.general.imageFormat = 'jpg';

% =========== MORPH FILTERS ===============================================
param.morphfilters.se_shape = 'square';
param.morphfilters.se_size_reconstruct = 8; % 4 for disc
param.morphfilters.se_size_close = 20; % 10 for disc


% =========== ROI =========================================================
param.roi.size = [704, 704];
param.roi.num = 3;
param.roi.alignOrigin = 'bottom'; % how to align tight and full bboxes? 'bottom' or 'center'
param.roi.disableHorizontalMove = 1; % move rectangles only vertically, horizontal position is as in default
param.roi.allowMiddleFloat = 1; % middle default ROI can move left and right
param.roi.allowLeftRightFloat = 1;
param.roi.processingOrder = [3 2 1]; % order of ROIs positioning
param.roi.floatSize = [50, 96, 50]; %[50, 96, 50];
param.roi.fixTightOffset = 5; % enlarge tight bbox by this num. of px in every direction
% top-left positions of default ROIs;
param.roi.default.imageSize = {[1080 1920], [576 720], [1236 1628]};
offsets = [50 0 50]; %[53, 12, 29];
offsetLeftRight = 0; % offset from left/right border
param.roi.default.pos = { ...
    [offsetLeftRight, offsets(1); ...
    1920/2-param.roi.size(1)/2, offsets(2); ...
    1920-param.roi.size(1)-offsetLeftRight, offsets(3)], ...
    [720/2-param.roi.size(1)/2, 0], ...
    [0, offsets(1); ...
    1628/2-param.roi.size(1)/2, offsets(2); ...
    1628-param.roi.size(1), offsets(3)], ...
    }; % empty position means that no default positions are used

% =========== WHITE v2 for findROIv2 ======================================
param.white2.weight = 50; % weight of white objects
param.white2.initPipeline = {'heq'}; % any combination of 'cc', 'adj', 'heq'
param.white2.initMethods.cc = 'none'; % 'white', ['gray'], 'none'
param.white2.initMethods.heq.type = 'local'; % 'global', ['local'], 'none'
param.white2.initMethods.heq.numTiles = [9, 16]; % number of tiles [m x n]
param.white2.initMethods.heq.clipLimit = 0.01;
param.white2.initMethods.heq.nBins = 64; % quite sensitive
param.white2.initMethods.heq.range = 'full'; % original, full
param.white2.initMethods.heq.distribution = 'uniform'; % uniform, rayleigh, exponential
param.white2.initMethods.adj = [0.3 0.7]; % percantage of input contrast clipping

% HSV thresholds
thrHSV = [];
thrHSV.white.Hmin = 0.00;
thrHSV.white.Hmax = 1.00;
thrHSV.white.Smin = 0.00;
thrHSV.white.Smax = 0.35;
thrHSV.white.Vmin = 0.00;
thrHSV.white.Vmax = 1.00;
param.white2.thrHSV = thrHSV;

% Binary masks filtering
param.white2.maskFilters = {'fill','erode_2'};

% Connected components (blobs) thresholds
% Size of an area we want to filter out (in pixels)
thrCC = [];
thrCC.HeightMin = 25;
thrCC.WidthMin = 25;
thrCC.AreaMin = 625;
thrCC.AreaMax = 30000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.1; %0.5
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.15;
thrCC.AspectMax = 1;
% Area to squared perimeter ratio
thrCC.A2PSqMin = 0.021;%0.02;
thrCC.A2PSqMax = Inf;
param.white2.thrCC = thrCC;


% =========== COLORS ======================================================
% pipeline = order of processing. Only included steps are then processed.
% 'cc' - color constancy
% 'heq' - histogram equalization
% 'adj' - histogram adjustment
param.colors.weight = 100; % weight of objects in color
param.colors.initPipeline = {'heq'}; % any combination of 'cc', 'adj', 'heq'
param.colors.initMethods.cc = 'gray'; % 'white', ['gray'], 'none'
param.colors.initMethods.heq.type = 'local'; % 'global', ['local'], 'none'
param.colors.initMethods.heq.numTiles = [9, 16]; % number of tiles [m x n]
param.colors.initMethods.heq.clipLimit = 0.01;
param.colors.initMethods.heq.nBins = 64; % quite sensitive
param.colors.initMethods.heq.range = 'full'; % original, full
param.colors.initMethods.heq.distribution = 'uniform'; % uniform, rayleigh, exponential
param.colors.initMethods.adj = [0.3 0.7]; % percentage of input contrast clipping

% HSV thresholds 
thrHSV = [];

% Default
thrHSV.red.Hmin = 0.915;
thrHSV.red.Hmax = 0.03;
thrHSV.red.Smin = 0.45;
thrHSV.red.Smax = 1.00;
thrHSV.red.Vmin = 0.10;
thrHSV.red.Vmax = 1.00;

% alt 
% thrHSV.red.Hmin = 0.915;
% thrHSV.red.Hmax = 0.045; %0.03
% thrHSV.red.Smin = 0.45;
% thrHSV.red.Smax = 1.00;
% thrHSV.red.Vmin = 0.10;
% thrHSV.red.Vmax = 1.00;

thrHSV.blue.Hmin = 0.52;
thrHSV.blue.Hmax = 0.70; %0.7
thrHSV.blue.Smin = 0.62; %0.6
thrHSV.blue.Smax = 1.00;
thrHSV.blue.Vmin = 0.25; %0.2, 0.25, 0.4
thrHSV.blue.Vmax = 1.0; %1.0

% default
% thrHSV.yellowDark.Hmin = 0.05;
% thrHSV.yellowDark.Hmax = 0.13;
% thrHSV.yellowDark.Smin = 0.50; % 0.64, 0.6
% thrHSV.yellowDark.Smax = 1.00;
% thrHSV.yellowDark.Vmin = 0.20;
% thrHSV.yellowDark.Vmax = 1.00;

thrHSV.yellowDark.Hmin = 0.05;
thrHSV.yellowDark.Hmax = 0.13;
thrHSV.yellowDark.Smin = 0.60;
thrHSV.yellowDark.Smax = 1.00;
thrHSV.yellowDark.Vmin = 0.30;
thrHSV.yellowDark.Vmax = 1.00;

% default
thrHSV.yellowLight.Hmin = 0.13;
thrHSV.yellowLight.Hmax = 0.18;
thrHSV.yellowLight.Smin = 0.64;
thrHSV.yellowLight.Smax = 1.00;
thrHSV.yellowLight.Vmin = 0.20;
thrHSV.yellowLight.Vmax = 1.00;

thrHSV.green.Hmin = 0.37;
thrHSV.green.Hmax = 0.50;
thrHSV.green.Smin = 0.45;
thrHSV.green.Smax = 1.00;
thrHSV.green.Vmin = 0.25;
thrHSV.green.Vmax = 1.00;

thrHSV.greenFluor.Hmin = 0.17;
thrHSV.greenFluor.Hmax = 0.26;
thrHSV.greenFluor.Smin = 0.63;
thrHSV.greenFluor.Smax = 1.00;
thrHSV.greenFluor.Vmin = 0.50;
thrHSV.greenFluor.Vmax = 1.00;

% thrHSV.brown.Hmin = 0.00;
% thrHSV.brown.Hmax = 0.1; %0.08
% thrHSV.brown.Smin = 0.40; % 0.6
% thrHSV.brown.Smax = 1.00;
% thrHSV.brown.Vmin = 0.00; %0.2
% thrHSV.brown.Vmax = 1.00;

% default
% thrHSV.brown.Hmin = 0.00;
% thrHSV.brown.Hmax = 0.1;
% thrHSV.brown.Smin = 0.60;
% thrHSV.brown.Smax = 1.00;
% thrHSV.brown.Vmin = 0.20;
% thrHSV.brown.Vmax = 1.00;

thrHSV.brown.Hmin = 0.00;
thrHSV.brown.Hmax = 0.1;
thrHSV.brown.Smin = 0.65; %0.65
thrHSV.brown.Smax = 1.00;
thrHSV.brown.Vmin = 0.50; %0.5
thrHSV.brown.Vmax = 1.00;


param.colors.thrHSV = thrHSV;

% Binary masks filtering
%param.colors.maskFilters = {'close_2','fill','gauss_3','close_7','fill','dilate_10'};
param.colors.maskFilters = {'close_2','fill','gauss_3','close_7','fill'};

% For smartyColor2 and 3
param.colors2.maskFilters = {'close_2','fill','gauss_3','close_7','fillWithBorder'};

% Connected components (blobs) thresholds
% Size of an area we want to filter out (in pixels)
thrCC=[];

thrCC.HeightMin=25;
thrCC.WidthMin=25;

thrCC.AreaMin = 500; % 625, 5000
thrCC.AreaMax = 321100; %230000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.4; %0.45
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.16;
thrCC.AspectMax = 1;
% Area to squared perimeter ration
thrCC.A2PSqMin = 0.012; %0.02;
thrCC.A2PSqMax = Inf;

param.colors.thrCC = thrCC;



% =========== WHITE OLD ======================================================
param.white.weight = 1; % weight of white objects
param.white.initPipeline = {'heq','adj'}; % any combination of 'cc', 'adj', 'heq'
param.white.initMethods.cc = 'none'; % 'white', 'gray', 'none'
param.white.initMethods.heq.type = 'local'; % 'global', 'local', 'none'
param.white.initMethods.heq.numTiles = [9, 16]; % number of tiles [m x n]; [16, 32]
param.white.initMethods.heq.clipLimit = 0.01; % 0.01, 0.2
param.white.initMethods.heq.nBins = 64; % quite sensitive; 32, 64
param.white.initMethods.heq.range = 'full'; % original, [full]
param.white.initMethods.heq.distribution = 'uniform'; % [uniform], rayleigh, exponential
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

thrCC.HeightMin=25;
thrCC.WidthMin=25;

thrCC.AreaMin = 700;
thrCC.AreaMax = 20000;
% Extent filter (extent = area/(height*width))
thrCC.ExtentMin = 0.5; %0.5
thrCC.ExtentMax = 1;
% Aspect ratio (shorter/longer)
thrCC.AspectMin = 0.16;
thrCC.AspectMax = 1;
% Area to squared perimeter ratio
thrCC.A2PSqMin = -Inf;%0.02;
thrCC.A2PSqMax = Inf;
param.white.thrCC = thrCC;