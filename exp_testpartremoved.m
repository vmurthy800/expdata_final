function [ time, map, data] = exp_testpartremoved( rank,imnum)
%exp_testpartremoved gets 2 values- time and mAP for a given
%set of removed parts- starts with 0 and goes to 33 (all parts removed)
% time is elapsed time between beginning of imgdetect and end of nms- it's
% computed by just running the times out of loop and getting the values
% that way [34 x 2] double
% map is computed by pascal_test [34 x 1] double
%if further testing is needed to understand / get part data you can run it
%with the other functions, this is pureley for testing

%generates a new folder for the test results for time / boundingbox
rank = rank(:,1);
map = zeros(34,2);
time = zeros(34,1);

%gets model
load('2010/person_final.mat');
model.class = 'person grammar';
testset = 'val';
year = '2010';
suffix = '.txt';

%gets ids for image
conf = voc_config;
VOCopts = conf.pascal.VOCopts;
ids = textread(sprintf(VOCopts.imgsetpath, testset), '%s');
nums = [1:imnum];
ids = ids(nums,:);
%ids = ids(1:20,:);

for k = 1:34
    disp(strcat(num2str(k-1),'filters_removed'));
    VOCopts  = conf.pascal.VOCopts;
    cachedir = conf.paths.model_dir;
    cls = model.class;

% run detector in each image
  opts = VOCopts;
  num_ids = length(ids);
  ds_out = cell(1, num_ids);
  bs_out = cell(1, num_ids);
  for i = 1:num_ids;
    fprintf('%s: testing: %s %s, %d/%d\n', cls, testset, year, ...
            i, num_ids);
    im = imread(sprintf(opts.imgpath, ids{i})); 
    [ds, bs, time] = exp_imgtest(im, model, -0.6, removed, time);
    if ~isempty(bs)
      unclipped_ds = ds(:,1:4);
      [ds, bs, rm] = clipboxes(im, ds, bs);
      unclipped_ds(rm,:) = [];

      % NMS
      I = nms(ds, 0.5);
      ds = ds(I,:);
      bs = bs(I,:);
      unclipped_ds = unclipped_ds(I,:);

      % Save detection windows in boxes
      ds_out{i} = ds(:,[1:4 end]);
      bs_out{i} = cat(2, unclipped_ds, bs);
    else
      ds_out{i} = [];
      bs_out{i} = [];
    end
  end
  ds = ds_out;
  bs = bs_out;
[fmap, tp, data] = exp_evalpart('person', ds, testset, year, suffix,ids, nums);
map(k,1) = fmap;

close(gcf);
end


time = exp_gettimesaved(time,rank);
time = time/(length(nums)*k);



end

function time = exp_gettimesaved(time,rank)
%used to calculate the minimum amount of time saved as a result of removing
%a specified set of filters
ftime = time;
time = zeros(34,1);

%resorts so worst-scoring is first
rank = flipud(rank);

    for k = 2:length(ftime)
        %x the filter being removed at a certain iteration- e.g. 1 filter
        %removed removes filter no 23 - 23 would be x
        x = rank(k);
        
        %we find the value of that filter being removed
        time(k) = ftime(x);
    end

    time = cumsum(time);

end




