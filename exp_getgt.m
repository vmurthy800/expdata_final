function [ gt ] = exp_getgt (conf,train)
%expgetgt - gets ground truth data for a given test set (e.g. VOC2010 val
%or train)
%INPUTS - voc_config struct, possible train override
%OUTPUTS - gt, the ground truth data for a given dataset 
%original function was cbgeneratemat, rewritten to be more modular and fit
%new naming conventions for function

%reads in picture names

if nargin == 2
t = 'train';
traintxt = ['VOC2010/ImageSets/Main/person_' conf.pascal.VOCopts.trainset '.txt'];
trainloc = strcat(conf.pascal.VOCopts.datadir,traintxt);
file = fopen(trainloc, 'r');
else
t = 'test';
testtxt = ['VOC2010/ImageSets/Main/person_' conf.pascal.VOCopts.testset '.txt'];
testloc = strcat(conf.pascal.VOCopts.datadir,testtxt);
file = fopen(testloc, 'r');
end

%opens, reads all the filenames and closes file
junkstruct = textscan(file, '%s %f');
trainnames = cellstr(junkstruct{1,1});
clear junkstruct
fclose(file);

%generates the names of all pictures in a given dataset
lengthofpas = length( length(trainnames));
lengthpas = cell(lengthofpas);
lengthpas(1:length(trainnames)) = trainnames;
names = sort(lengthpas);
names = unique(names);
%

%opens annotation and reads them into a struct

pascalstruct = [];
gt = cell(9,4000);
anno = 'VOC2010/Annotations/';
xml = '.xml';

%sets up labels for array
gt(1,1) = cellstr('filename');
gt(2,1) = cellstr('pose');
gt(3,1) = cellstr('truncated');
gt(4,1) = cellstr('occluded');
gt(5,1) = cellstr('difficult');
gt(6,1) = cellstr('bndbox_xmin');
gt(7,1) = cellstr('bndbox_ymin');
gt(8,1) = cellstr('bndbox_xmax');
gt(9,1) = cellstr('bndbox_ymax');

r = 2;
%for each picture
for k = 1:length(names)
    disp(names(k));
    namefile = strcat(conf.pascal.VOCopts.datadir,anno,names(k),xml);
    %pascalstruct is the raw data taken from the annotations through
    %VOCCODE
    picstruct = VOCreadxml(namefile{1,1});
    pascalstruct.(strcat('a',num2str(k))) = picstruct;
    % turns struct into cell array
    z = size(pascalstruct.(strcat('a',num2str(k))).annotation.object);
    objnum = z(2);
    %for each object in each picture
    for q = 1:objnum
            gt(r,1) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.filename);
            gt(r,2) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.object(q).name);
            gt(r,3) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.object(q).bndbox.xmin);
            gt(r,4) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.object(q).bndbox.ymin);
            gt(r,5) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.object(q).bndbox.xmax);
            gt(r,6) = cellstr(pascalstruct.(strcat('a',num2str(k))).annotation.object(q).bndbox.ymax);           
            r = r + 1;
    end
    %
end


%cleans up each array so that there are no empty cells
gt = gt(2:(r-1),1:6);
%

%saves out cell array so that this process needs to only be repeated once
%for a given dataset
save([conf.expdata.pascaldata '/' t '_data.mat'], 'gt');
end

