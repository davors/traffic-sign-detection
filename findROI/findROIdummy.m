function [BBtight, BBfull, BWmerged, CC] = findROIdummy(imageFile,param,showResults)

if ~exist('showResults','var') || isempty(showResults)
    showResults = 0; % show detected regions
end




% =========== RECTANGLE COVERING ==========================================
% Check for image size
%[imHeight, imWidth, ~] = size(RGB);
infoImage = imfinfo(imageFile);
imHeight = infoImage.Height;
imWidth = infoImage.Width;

sizeInd = cellfun(@(x) (all(x==[imHeight, imWidth])), param.roi.default.imageSize, 'UniformOutput', 1);
if any(sizeInd)
    param.roi.default.pos = param.roi.default.pos{sizeInd};
else
    error('No default position for image %s.\n',imageFile); %param.roi.default.pos = [];
end
BBoxes = param.roi.default.pos;
K = size(BBoxes,1);
BBfull = [BBoxes, repmat(param.roi.size,K,1)];
BBtight = BBfull;
BWmerged = false(imHeight,imWidth);
CC = [];

if showResults
    % Read file
    RGB = imread(imageFile);
    Kreal = size(BBtight,1);
    % Visualize
    figure('units','normalized','OuterPosition',[0 0 1 1]);
    imshow(RGB, 'InitialMagnification','fit');
    for k = 1: Kreal
        %rectangle('Position',BBtight(k,:),'EdgeColor','g','LineWidth',2);
        rectangle('Position',BBfull(k,:),'EdgeColor','m','LineWidth',2);
    end
    %title(sprintf('Objects covered with %d rectangle(s). Remained pixels: %d',Kreal,areaLeft));
    waitforbuttonpress;
    close;
end
