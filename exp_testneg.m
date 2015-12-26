function [ negdata, negap ] = exp_testneg(conf, train)
%testnegim tests images in which there is no person AT ALL- removes all
%images with persons and creates testdata + ap with additional fps

%if ~exist([conf.expdata.pascaldata '/' 'negdata.mat']);
    ncount = 1;
    ncountprior = 1;
    imnum = 1;
    negap = zeros(100000,2);
    negdata = cell(100000,12);
%else
%    load([conf.expdata.pascaldata '/' 'negdata.mat'],'negdata','negap','ncount','imnum');
%    ncountprior = ncount;
%    njunk = negdata;
%    napjunk = negap;
%    negap = zeros(100000,2);
%    negdata = cell(100000,12);
%    negdata(1:length(njunk(:,1)),:) = njunk;
%    negap(1:length(napjunk(:,1)),:) = napjunk;
%end
    
    

if nargin < 2
x = 'test_data.mat';
else
x = 'train_data.mat';
end
load([conf.expdata.pascaldata '/' x], 'gt');

%gets the names of all negative images; puts them in vector and saves them
%so this step does not need to be repeated over and over again.

if ~exist([conf.expdata.pascaldata '/' 'negnames.mat'])
    display('Generating Negative image database');
    load([conf.expdata.pascaldata '/' 'persondata.mat'],'personarray');
    parray = unique(personarray(:,1));
    negnames = unique(gt(:,1));
    
    k = 1;
    while k < length(parray) + 1
        disp(k);
        z = 1;
        while z < length(negnames) + 1
            if strcmp(parray(k),negnames(z)) == 1
                negnames(z) = [];
            else
                z = z + 1;
            end
        end
        k = k + 1;
    end
    save([conf.expdata.pascaldata '/' 'negnames.mat'],'negnames');
else
    display('Loading negative image database');
    load([conf.expdata.pascaldata '/' 'negnames.mat'],'negnames');
end




display('Done.');

display('Testing negative images');

%testing of negatives starts here
startup;

for k = imnum:length(negnames(:,1))
    imagename = negnames(k);
    disp(imagename);
    disp(k);
    filename = [conf.pascal.dev_kit,'VOC2010/JPEGImages/',imagename{1,1}];
    imagesave = [conf.expdata.bboxpic '/' imagename{1,1}];
    if ~exist(imagesave)
    load('2010/person_final');
    model.class = 'person grammar';
    model.vis = @() visualize_person_grammar_model(model, 6);
    
    
    thresh = -0.6;
    im = imread(filename);
    
    
    
    
    % detect objects
    tic;
    [ds, bs] = imgdetect(im, model, thresh);
    et = toc;
    exp_timedet( et, conf, imagename{1,1});
    top = nms(ds, 0.5);
    
    %makes sure something was detected in the image - otherwise outputs
    %zero vector
    if isempty(ds) & isempty(bs)
        b = [ 0 0 0 0 0];
        showdetgt(b,[0 0 0 0],imagesave,im);
    else
        bs = [ds(:,1:4) bs];
        b = reduceboxes(model,bs(top,:));
    
    %formats detbbox to be [ xmin ymin xmax ymax confidence]
    detbbox = zeros(length(b(:,1)),5);
    detbbox(:,1:4) = b(:,1:4);
    for z = 1:length(b(:,1))
        confloc = length(b(1,:));
        detbbox(z,5) = b(z,confloc);
        %formats each min and max coordinate to be xmin not less than zero,
        %ymin not less than zero, so on. This helps correct for differences
        %between the pascal annotation and the truncation feature of the
        %dpm.
           if detbbox(z,1) < 0
                detbbox(z,1) = 0;
            end
            if detbbox(z,2) < 0
                detbbox(z,2) = 0;
            end
            if detbbox(z,3) > length(im(1,:))
                detbbox(z,3) = length(im(1,:));
            end
            if detbbox(z,4) > length(im(:,1));
                detbbox(z,4) = length(im(:,1));
            end
                
    end
    
    %generates image of potential bounding boxes generated
    showdetgt(detbbox,[0 0 0 0],imagesave,im);
    
    % sees whether something was detected. If so, writes to negdata. 
    if sum(detbbox) ~= 0
       [row col] = find(detbbox(:,1) ~= 0);
       for z = 1:length(row)
        negdata(ncount,1) = cellstr(imagename);
        negdata(ncount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
            cellstr(num2str(0)) cellstr(num2str(0))];
        negdata(ncount,6:9) = [ cellstr(num2str(detbbox(z,1))) cellstr(num2str(detbbox(z,2))) ...
            cellstr(num2str(detbbox(z,3))) cellstr(num2str(detbbox(z,4)))];
        negdata(ncount,10) = cellstr(num2str(0));
        negdata(ncount,11) = cellstr('fp');
        negdata(ncount,12) = cellstr(num2str(detbbox(z,5)));
        
        negap(ncount,1) = detbbox(z,5);
        negap(ncount,2) = 0;
        
        ncount = ncount + 1;
       end
    end
    exp_savetxt( ncountprior, ncount, conf, negdata );
    ncountprior = ncount;
    end
    end 
end

imnum = k + 1;

negap = negap(1:ncount-1,:);
negdata = negdata(1:ncount-1,:);
save([conf.expdata.pascaldata '/' 'negdata.mat'],'negap','negdata','ncount','imnum');
display('Done.');
        


end

