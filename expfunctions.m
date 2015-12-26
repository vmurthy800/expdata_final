%--------------------------------------------------------------------%
            %EXPERIMENT SCRIPT%
%--------------------------------------------------------------------%

%-------------------------------------------------------------------%
           %setup
%-------------------------------------------------------------------%


%this will configure some of the directories used in later code
%please edit the path names according to your setup
conf = voc_config;

%if you want the function to run on the 'train' image number, use 4998
%for val, use 5105
imnum = 4998;

%this is used as a 2nd / 3rd input to tell a given function to operate on
%train as opposed to val
t = 1;

%--------------------------------------------------------------------%
    %generates MAT file of all PASCAL picture data from 2008 in a given
    %dataset in the format [ filename obj_type xmin xmax ymin ymax ] -
    %default is val, second input of 't' can be given to get train gt
    %data
    
    %run twice to get both datasets processed
%--------------------------------------------------------------------%

[ gt] = exp_getgt(conf, t);
[gt] = exp_getgt(conf);

%--------------------------------------------------------------------
    %runs all positive images through person grammar detector trained on VOC 2010
    %- non-detections are marked as missed, or fp accordingly
    
    %train override can be given to run on training detection set
    %this is used to generate the 'control' values as opposed to the
    %'validation' values of the val database once a method has been
    %finalized
%---------------------------------------------------------------------

[testdata] = exp_testpos(conf,imnum, t);

%------------------------------------------------------------------\
    %runs negative images through person grammar demo- all detections are
    %marked fp
%--------------------------------------------------------------------
[ negdata, negap ] = exp_testneg(conf, t);


%-----------------------------------------------------------------------
    %in the event of a system failure- this regenerates testdata based off
    %of the text annotations;
    
    %in addition, it also remakes both the pos and neg data into a single
    %array- it is necessary that this be run to generate the true, combined
    %data for later processing
%------------------------------------------------------------------------

[ testdata, aparray,timedata ] = exp_remakedata( imnum, conf );

%-------------------------------------------------------------

    %gets location of each UNIQUE part in image- correlates unique parts to
    %ground truth bounding boxes. This is used for exp_rankparts to
    %generate the accuracy statistics for the part types, and thus the
    %rankings as for the accuracy of each part
%---------------------------------------------------------------

[ partdata ] = exp_partdata( conf,4998,testdata );


%-----------------------------------------------------------------

%ranks the parts by accuracy

%-----------------------------------------------------------------
[ celldata, rank ] = exp_rankparts( conf, imnum, train );

%-----------------------------------------------------------------

%generates data for parts removed- processing takes about 1 day for 1000
%images- 5105 images (No. of images in 'val') takes about 5 days

%rank is determined by accuracy. For sequential part removal, uncomment one
%of the two lines for rank below

%-------------------------------------------------------------------

%for 34(first) to 1(last) part removal
%rank = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34];

%for 1(first) to 34(last) part removal
%rank = [34;33;32;31;30;29;28;27;26;25;24;23;22;21;20;19;18;17;16;15;14;13;12;11;10;9;8;7;6;5;4;3;2;1];

[ time, map, data] = exp_testpartremoved( rank,5105);


