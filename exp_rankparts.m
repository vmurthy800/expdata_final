function [ celldata, rank ] = exp_rankparts( conf, imnum, train )
%exp_rankparts - creates a hierarchial list of importance for each part in
%order from highest ranked to lowest ranked
% rank is a 34 x 2 array of parts and their rank values according to the
% formula usage * accuracy where usage = abs(1 - partdetections / numgt)
% and accuracy = (num tp part detections + num missed part detections) /
% num part detections


%loads in names of each image
if nargin == 3
    load([conf.expdata.pascaldata '/' 'train_data.mat'],'gt');
else
    load([conf.expdata.pascaldata '/' 'test_data.mat'],'gt')
end
gt = unique(gt(:,1));

load([conf.expdata.pascaldata '/' 'negnames.mat'],'negnames')

lengt = length(gt(:,1));
lenneg = length(negnames(:,1));

names = cell(100000,1);
names(1:lengt,1) = gt(:,1);
names((lengt + 1):(lengt + lenneg),:) = negnames;

names = names(1:(length(gt(:,1)) + length(negnames(:,1))),:);

%removes the .jpg from each name- for use reading in files
for k = 1:length(names(:,1))
    id = names(k);
    id = {id{1}(1:11)};
    names(k) = id;
end

rank = zeros(34,2);

%for each part
for k = 1:34
    disp(k);
    
    %for each image
    tcount = 1;
    celldata = cell(10,10);
    clear celldata
    celldata = cell(10000,16);
    for z = 1:imnum
        txtname = [conf.expdata.partanno '/' 'filter_' num2str(k) '_' ...
            names{z,1} '.txt'];
        if exist(txtname,'file')
            file = fopen(txtname,'r');
            c = textscan(file,'%s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f');


            tcountend = tcount + length(c{:,2}) -1;
            celldata(tcount:tcountend,1) = cellstr(c{:,1});
            celldata(tcount:tcountend,2) = cellstr(c{:,2});
            celldata(tcount:tcountend,3) = cellstr(num2str(c{:,3}));
            celldata(tcount:tcountend,4) = cellstr(num2str(c{:,4}));
            celldata(tcount:tcountend,5) = cellstr(num2str(c{:,5}));
            celldata(tcount:tcountend,6) = cellstr(num2str(c{:,6}));
            celldata(tcount:tcountend,7) = cellstr(num2str(c{:,7}));
            celldata(tcount:tcountend,8) = cellstr(num2str(c{:,8}));
            celldata(tcount:tcountend,9) = cellstr(num2str(c{:,9}));
            celldata(tcount:tcountend,10) = cellstr(num2str(c{:,10}));
            celldata(tcount:tcountend,11) = cellstr(num2str(c{:,11}));
            celldata(tcount:tcountend,12) = cellstr(num2str(c{:,12}));
            celldata(tcount:tcountend,13) = cellstr(num2str(c{:,13}));
            celldata(tcount:tcountend,14) = cellstr(num2str(c{:,14}));
            celldata(tcount:tcountend,15) = cellstr(num2str(c{:,15}));
            celldata(tcount:tcountend,16) = cellstr(num2str(c{:,16}));
            fclose(file);
            tcount = tcountend + 1;
        end
    %end of for each image
    end
    celldata = celldata(1:tcountend,:);
        
        %turns it into double array with filter number and image name
        %removed
        partdata = 3;
        clear partdata
        partdata = zeros(length(celldata(:,1)),14);
        for q = 1:length(celldata(:,1))
            partdata(q,1) = str2double(celldata{q,3});
            partdata(q,2) = str2double(celldata{q,4});
            partdata(q,3) = str2double(celldata{q,5});
            partdata(q,4) = str2double(celldata{q,6});
            partdata(q,5) = str2double(celldata{q,7});
            partdata(q,6) = str2double(celldata{q,8});
            partdata(q,7) = str2double(celldata{q,9});
            partdata(q,8) = str2double(celldata{q,10});
            partdata(q,9) = str2double(celldata{q,11});
            partdata(q,10) = str2double(celldata{q,12});
            partdata(q,11) = str2double(celldata{q,13});
            partdata(q,12) = str2double(celldata{q,14});
            partdata(q,13) = str2double(celldata{q,15});
            partdata(q,14) = str2double(celldata{q,16});

        %end of for each row in celldata
        end
        
        
        %gets the four values needed to compute part importance
        %1.) num part detections
        pts = partdata(:,9);
        pts(pts(:,1) == 0) = [];
        numpts = length(pts(:,1));
        
        %2.) num of ground truth bounding boxes
        numgt = partdata(:,1);
        numgt(numgt(:,1) == 0) = [];
        numgt = length(numgt(:,1));
        
        %3.) num of tp / part matches
        numtp = 0;
        for q = 1:length(partdata(:,1))
            if partdata(q,9) ~= 0 & partdata(q,14) == 1
                numtp = numtp + 1;
            end
        end
        
        %4.) num of missed / part matches
        nummissed = 0;
        for q = 1:length(partdata(:,1))
            if partdata(q,9) ~= 0 & partdata(q,14) == -1
                nummissed = nummissed + 1;
            end
        end
        
      
        accuracy = (numtp + nummissed) / numpts;
        score = accuracy;

        
        
        
rank(k,1) = k;
rank(k,2) = score;

rank = sortrows(rank,2);
rank = flipud(rank);
    
    
%end of for each part
end




end

