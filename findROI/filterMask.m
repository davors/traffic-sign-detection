function BWmask = filterMask(BWmask, filters, param)
% Available filters/operations: 
% 'median': median filtering
% 'gauss': gaussian filtering/blurring
% 'erode'
% 'dilate'
% 'open'
% 'close': morphological closing
% 'fill': holes filling

if ischar(filters)
    filters = {filters};
end

if ~exist('param','var') || isempty(param)
   % Shape of a morphological structuring element
   se_shape = 'square';
else
   se_shape = param.morphfilters.se_shape;
end

[imHeight, imWidth, numMasks] = size(BWmask);
numFilters = numel(filters);

% Filters' parameters
medianFiltSize = [3 3]; % default [3 3]
gaussFiltSigma = 3; % default 0.5
% Size of a morphological structuring element for image dilation
seSize_dilate = 18;
% Size of a morphological structuring element for image closing
seSize_close = 18;
% Size of a morphological structuring element for image opening
seSize_open = 6;


for m=1:numMasks
    
    for f=1:numFilters
        filter = filters{f};
        S = strsplit(filter,'_');
        filterName = S{1};
        if numel(S) > 1
            filterParam = S{2};
        else
            filterParam = [];
        end
        
        if strcmpi(filterName,'median')
            if isempty(filterParam)
                p = medianFiltSize;
            else
                p = str2double(filterParam);
                p = [p, p];
            end
            BWmask(:,:,m) = medfilt2(BWmask(:,:,m),p);
            
        elseif strcmpi(filterName,'gauss')
            if isempty(filterParam)
                p = gaussFiltSigma;
            else
                p = str2double(filterParam);
            end
            BWmask(:,:,m) = imgaussfilt(uint8(BWmask(:,:,m)), gaussFiltSigma);
        
        elseif strcmpi(filterName,'dilate')
            if isempty(filterParam)
                p = seSize_dilate;
            else
                p = str2double(filterParam);
            end
            se = strel(se_shape,p);
            BWmask(:,:,m) = imdilate(BWmask(:,:,m),se);
            
        elseif strcmpi(filterName,'erode')
            if isempty(filterParam)
                p = seSize_dilate;
            else
                p = str2double(filterParam);
            end
            se = strel(se_shape,p);
            BWmask(:,:,m) = imerode(BWmask(:,:,m),se);
            
        elseif strcmpi(filterName,'close')
            if isempty(filterParam)
                p = seSize_close;
            else
                p = str2double(filterParam);
            end
            se = strel(se_shape,p);
            BWmask(:,:,m) = imclose(BWmask(:,:,m),se);
            
        elseif strcmpi(filterName,'open')
            if isempty(filterParam)
                p = seSize_open;
            else
                p = str2double(filterParam);
            end
            se = strel(se_shape,p);
            BWmask(:,:,m) = imopen(BWmask(:,:,m),se);
            
        elseif strcmpi(filterName,'fill')
            BWmask(:,:,m) = imfill(BWmask(:,:,m),'holes');
            
        elseif strcmpi(filterName,'reconstruct')
            if isempty(filterParam)
                p = seSize_dilate;
            else
                p = str2double(filterParam);
            end
            se = strel(se_shape,p);
            marker = imerode(BWmask(:,:,m),se);
            BWmask(:,:,m) = imreconstruct(marker,BWmask(:,:,m));
        
        elseif strcmpi(filterName,'fillWithBorder')
            % Pad with 1px white border
            BWpad = padarray(BWmask(:,:,m),[1 1],1);
            % Make a hole in the bottom (no harm in this)
            BWpad(imHeight+2,floor((imWidth+2)/2)) = 0;
            BWpad = imfill(BWpad,'holes');
            BWmask(:,:,m) = BWpad(2:end-1,2:end-1);
            
        else
            error('Wrong filter name');
        end
        
        
    end
    
end