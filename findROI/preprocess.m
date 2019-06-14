function I = preprocess(I, pipeline, methods, colorMode)

numSteps = numel(pipeline);

assert(any(ismember(colorMode,{'RGB','HSV'})),'Wrong colorMode.');

for s=1:numSteps
    step = pipeline{s};
    if strcmpi(step,'cc')
        I = preprocessColorConstancy(I, methods.cc, colorMode);
    elseif strcmpi(step,'heq')
        I = preprocessHistogramEq(I, methods.heq, colorMode);
    elseif strcmpi(step,'adj')
        if strcmpi(colorMode,'RGB')
            I = imadjust(I, [repmat(methods.adj(1),1,3); repmat(methods.adj(2),1,3)],[]);
        elseif strcmpi(colorMode,'HSV')
            I(:,:,3) = imadjust(I(:,:,3), [methods.adj(1); methods.adj(2)],[]);
        end
    else
        error('!!!');
    end  
end