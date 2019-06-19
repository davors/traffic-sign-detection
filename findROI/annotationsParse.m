% Loads and decodes JSON with annotations

jsonPath = '../data/annotations/default/test.json';

% Read file
jsonFid = fopen(jsonPath,'r');
jsonText = fread(jsonFid,'*char')';
fclose(jsonFid);

% Decode
ANNOT = jsondecode(jsonText);

% Save to MAT format for later use
save([jsonPath,'.mat'],'ANNOT','jsonPath');
