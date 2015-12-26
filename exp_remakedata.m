function [ testdata, aparray, timedata ] = exp_remakedata( imnum, conf )
%remaketestdata - in the event of a system / MATLAB crash, I can recover my
%data and make it into a single cell array laid out exactly like the
%original array
%imnum is the amount of FILES IN IMAGES- NOT ALL NEGS GET AN ANNOTATION

load([conf.expdata.pascaldata '/' 'persondata.mat'], 'personarray');
load([conf.expdata.pascaldata '/' 'negnames.mat'],'negnames');
parray = unique(personarray(:,1));
parray(length(parray) + 1:(length(parray) + length(negnames)),1) = negnames;

testdata = cell(1000000,12);
aparray = zeros(1000000,2);
tcount = 1;

for k = 1:imnum
    disp(k);
    imname = parray{k,1};
    txtname = strcat(imname,'.txt');
    txtfile = [conf.expdata.bboxanno '/' txtname];
    if exist(txtfile, 'file')
        file = fopen(txtfile, 'r');

        %scans in numbers
        c = textscan(file,'%s %f %f %f %f %f %f %f %f %f %f %f');

        %creates cell array around numbers
        tcountend = tcount + length(c{:,2}) -1;
        testdata(tcount:tcountend,1) = cellstr(imname);
        testdata(tcount:tcountend,2) = cellstr(num2str(c{:,2}));
        testdata(tcount:tcountend,3) = cellstr(num2str(c{:,3}));
        testdata(tcount:tcountend,4) = cellstr(num2str(c{:,4}));
        testdata(tcount:tcountend,5) = cellstr(num2str(c{:,5}));
        testdata(tcount:tcountend,6) = cellstr(num2str(c{:,6}));
        testdata(tcount:tcountend,7) = cellstr(num2str(c{:,7}));
        testdata(tcount:tcountend,8) = cellstr(num2str(c{1,8}));
        testdata(tcount:tcountend,9) = cellstr(num2str(c{1,9}));
        testdata(tcount:tcountend,10) = cellstr(num2str(c{1,10}));
        testdata(tcount:tcountend,11) = cellstr(num2str(c{1,11}));
        testdata(tcount:tcountend,12) = cellstr(num2str(c{1,12}));
        aparray(tcount:tcountend,1) = c{1,12};
        aparray(tcount:tcountend,2) = c{1,11};
        tcount = tcountend + 1;
        fclose(file);
    end
    
    %rebuilds performance data as well
    timefile  = [conf.expdata.timeanno '/' txtname];
    if exist(timefile,'file')
        file = fopen(timefile,'r');
        t = textscan(file,'%f');
        timedata(k,1) = t{1,1};
        fclose(file);
    end
    
    
end
testdata = testdata(1:(tcount-1),:);
aparray = aparray(1:(tcount-1),:);

for q = 1:length(testdata(:,11))
    if strcmp(testdata(q,11),num2str(1)) == 1
        testdata(q,11) = cellstr('tp');
    end

    if strcmp(testdata(q,11),num2str(0)) == 1
        testdata(q,11) = cellstr('fp');
    end

    if strcmp(testdata(q,11),num2str(-1)) == 1
        testdata(q,11) = cellstr('missed');
    end
end

%gets rid of blank rows in testdata and aparray
len = [1:length(testdata(:,1))];
q = 1;
while q < length(len) + 1
    if mod(len(q),2) == 0
       len(q) = [];
    else
    q = q + 1;
    end
end

testdata = testdata(len,:);
aparray = aparray(len,:);



%resorts aparray
aparray = sortrows(aparray);

%save(strcat(matfileloc,'testdata.mat'), 'testdata', 'aparray', 'tcount', 'imsproc');


clear imnum

    
end

