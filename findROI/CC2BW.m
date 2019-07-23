function BW = CC2BW(CC)

if isstruct(CC)
    numCC = 1;
    CC = {CC};
elseif iscell(CC)
    numCC = numel(CC);
else
    error('!!!');
end


BW = false(CC{1}.ImageSize);

for i = 1:numCC
    assert(isequal(CC{1}.ImageSize, CC{i}.ImageSize),'Image size not equal.');
    assert(CC{1}.Connectivity == CC{i}.Connectivity,'Connectivity not equal.');
    pixelList = vertcat(CC{i}.PixelIdxList{:});
    BW(pixelList) = true;
end




