% Join train and test annotations

pathBase = '../data/annotations/default';
pathTrain = [pathBase,'/train.json.mat'];
pathTest = [pathBase,'/test.json.mat'];

% Output file
jsonPath = [pathBase,'/joined_train_test.mat'];

% Load
ANNOT = load(pathTrain);
ANNOT_test = load(pathTest);

ANNOT = ANNOT.ANNOT;
ANNOT_test = ANNOT_test.ANNOT;

fields = fieldnames(ANNOT);
assert(isequal(fields,fieldnames(ANNOT_test)),'Field names do not match!');

numFields = numel(fields);

% Join
for fi = 1:numFields
   field = fields{fi};
   if strcmpi(field,'info')
       ANNOT.info.description = 'joined_train_test';
   elseif strcmpi(field,'categories')
       assert(isequal(ANNOT.(field),ANNOT_test.(field)), 'Categories do not match!');
   elseif strcmpi(field,'images')
       a = [ANNOT.(field); ANNOT_test.(field)];
       [~,index] = sortrows([a.id].');
       a = a(index);
       ANNOT.(field) = a;
   elseif strcmpi(field,'annotations')
       maxTrainID = max([ANNOT.(field).id]);
       numTest = length(ANNOT_test.(field));
       for i = 1:numTest
           ANNOT_test.(field)(i).id = ANNOT_test.(field)(i).id + maxTrainID +1;
       end
       ANNOT.(field) = [ANNOT.(field); ANNOT_test.(field)];
   else
       error('Field not covered.');
   end
end


save(jsonPath,'ANNOT','jsonPath');