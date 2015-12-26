function [ap, tp, data] = exp_evalpart(cls, ds, testset, year, suffix, ids, nums)
% Score detections using the PASCAL development kit.
%   [ap, prec, recall] = pascal_eval(cls, ds, testset, suffix)
%
% Return values
%   ap        Average precision score
%   prec      Precision at each detection sorted from high to low confidence
%   recall    Recall at each detection sorted from high to low confidence
%
% Arguments
%   cls       Object class to evaluate
%   ds        Detection windows returned by pascal_test.m
%   testset   Test set to evaluate against (e.g., 'val', 'test')
%   year      Test set year to use  (e.g., '2007', '2011')
%   suffix    Results are saved to a file named:
%             [cls '_pr_' testset '_' suffix]

conf = voc_config('pascal.year', year, ...
                  'eval.test_set', testset);
cachedir = conf.paths.model_dir;                  
VOCopts  = conf.pascal.VOCopts;
data = cell(100,6);

% write out detections in PASCAL format and score
fid = fopen(sprintf(VOCopts.detrespath, 'comp3', cls), 'w');
datacount = 1;
for i = 1:length(ids);
  bbox = ds{i};
  if ~isempty(bbox)
      for j = 1:size(bbox,1)
        fprintf(fid, '%s %f %d %d %d %d\n', ids{i}, bbox(j,end), bbox(j,1:4));
        data(datacount,1) = cellstr(ids{i});
        data(datacount,2) = cellstr(num2str(bbox(j,end)));
        data(datacount,3) = cellstr(num2str(bbox(j,1)));
        data(datacount,4) = cellstr(num2str(bbox(j,2)));
        data(datacount,5) = cellstr(num2str(bbox(j,3)));
        data(datacount,6) = cellstr(num2str(bbox(j,4)));
        datacount = 1 + datacount;
      end
  end
end
fclose(fid);
data = data(1:(datacount-1),:);

recall = [];
prec = [];
ap = 0;

do_eval = (str2num(year) <= 2007) | ~strcmp(testset, 'test');
if do_eval
    % Bug in VOCevaldet requires that tic has been called first
    [tp, ap] = exp_VOCevaldet(VOCopts, 'comp3', cls, true, data,nums);
  % force plot limits
  ylim([0 1]);
  xlim([0 1]);

end

% save results
%save([cachedir cls '_pr_' testset '_' suffix], 'recall', 'prec', 'ap');
