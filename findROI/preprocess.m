function RGB = preprocess(RGB, pipeline, methods)

numSteps = numel(pipeline);

for s=1:numSteps
    step = pipeline{s};
    if strcmpi(step,'cc')
        RGB = preprocessColorConstancy(RGB,methods.cc);
    elseif strcmpi(step,'heq')
        RGB = preprocessHistogramEq(RGB,methods.heq);
    elseif strcmpi(step,'adj')
        RGB = imadjust(RGB, [repmat(methods.adj(1),1,3); repmat(methods.adj(2),1,3)],[]);
    else
        error('!!!');
    end  
end