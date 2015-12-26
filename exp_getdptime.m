function [ avgtime ] = exp_getdptime( imnum )
%exp_getdptime - gets the amount of time needed on average to run the
%dynamic programming algorithm of the voc-release5
%Used to compute percent of time saved


%gets model
load('2010/person_final.mat');
model.class = 'person grammar';
testset = 'val';
year = '2010';
suffix = '.txt';
cls = 'person';

%gets ids for image
conf = voc_config;
VOCopts = conf.pascal.VOCopts;
opts = VOCopts;
ids = textread(sprintf(VOCopts.imgsetpath, testset), '%s');
nums = [1:imnum];
ids = ids(nums,:);
num_ids = length(ids);

%gets time of dynamic programming algorithm
avgtime = 0;
for i = 1:num_ids
    fprintf('%s: testing: %s %s, %d/%d\n', cls, testset, year, ...
            i, num_ids);
    im = imread(sprintf(opts.imgpath, ids{i})); 
    im = color(im);
    pyra = featpyramid(im, model);
    [model, time] = exp_dptime(pyra, model, [35]);
    avgtime  = avgtime + time;
end

avgtime = avgtime/imnum;



end

