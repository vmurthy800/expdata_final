function [testdata] = exp_testpos(conf,imnum,train)
%testpersongrammar - generates cell array of data
% testdata is cell array of results for all pictures containing people in
% them
%overall function is based off of demo by R Girshick



if nargin ~= 3
td = 'test_data.mat';
else
td = 'train_data.mat';
end
load([conf.expdata.pascaldata '/' td],'gt');

if exist('persondata.mat')
    load([conf.expdata.pascaldata '/' 'persondata.mat'],'personarray');
else
    %get data from pascal array about PEOPLE in pictures. So we have a two
    %part strcmp to get that data.
    whilecheck = length(gt(:,1));
    n = 0;
    while n < whilecheck
        a = strcmp('person',gt{(n+1),2});
        if a == 0
          gt((n+1),:) = [];
        end
        if a == 1
            n = n + 1;
        end
        whilecheck = length(gt(:,1));
      
     end

personarray = gt;


save([conf.expdata.pascaldata '/' 'persondata.mat'],'personarray');  
end

%loads in existing test data (assuming you have it)
%if exist('testdata.mat')
%    load([conf.expdata.pascaldata '/' 'testdata.mat'], ...
%        'testdata','tcount','imsproc');
%    tcountprior = tcount;
%    tdjunk = cell(10000000,12);
%    tdjunk(1:length(testdata(:,1)),:) = testdata;
%    testdata = tdjunk;
%    clear tdjunk;
%else
    testdata = cell(10000000,12);
    tcount = 1;
    tcountprior = 1;
    imsproc = 1;
%end

gt = personarray;
parray = unique(personarray(:,1));
totalfp = 0;
totaltp = 0;

%now starts code based on R. Girshick's demo.m


for k = imsproc:imnum
    imagename = parray(k);
    disp(imagename{1,1});
    
    %clear is needed to wipe out any undeleted ground truth detections from
    %previous round of pictures
    gtpic = 1;
    clear('gtpic');
    
    %makes it so only person detections from the picture are kept in an
    %array
    gtcount = 0;     
    
    for q = 1:length(gt(:,1))
        f = strcmp(imagename,gt(q,1));
        if f == 1
            gtcount = gtcount + 1;
            gtpic(gtcount,1:6) = gt(q,1:6);
        end
    end
    
  
    %for each ground truth bounding box
    gtcoor = 1;
    clear('gtcoor');
    for n = 1:length(gtpic(:,1))
        gtcoor(n,:) = [ str2double(gtpic(n,3)) str2double(gtpic(n,4)) ...
            str2double(gtpic(n,5)) str2double(gtpic(n,6)) ];
    end
    

    filename = [conf.pascal.dev_kit 'VOC2010/JPEGImages/' imagename{1,1}];

    
    %loads in train-only model
    load('2010/person_final');
    model.class = 'person grammar';
    %model.vis = @() visualize_person_grammar_model(model, 6);
    
    
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
    else
        bs = [ds(:,1:4) bs];
        b = reduceboxes(model,bs(top,:));
    end
    
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
                detbbox(z,1) = 1;
            end
            if detbbox(z,2) < 0
                detbbox(z,2) = 1;
            end
            if detbbox(z,3) > length(im(1,:))
                detbbox(z,3) = length(im(1,:));
            end
            if detbbox(z,4) > length(im(:,1));
                detbbox(z,4) = length(im(:,1));
            end
                
    end
        
    imagesave = [conf.expdata.bboxpic '/' imagename{1,1}];    
    showdetgt(detbbox,gtcoor,imagesave,im);
    
    
    %if there are multiple people in a picture, we select for "best"
    %detection. Find intersection over detection values for each person and
    %each detection combination. Put them out into an array with rows as
    %ground truth boxes, colums as detections. Go through, eliminate so on.
    
    ioverdcomp = 1;
    clear('ioverdcomp');
    ioverdcomp = zeros(length(gtpic(:,1)),length(detbbox(:,1)));
    for n = 1:length(gtcoor(:,1))
        
        for q = 1:length(detbbox(:,1))
            combination = [ max(gtcoor(n,1),detbbox(q,1)) max(gtcoor(n,2),detbbox(q,2)) ...
                min(gtcoor(n,3),detbbox(q,3)) min(gtcoor(n,4),detbbox(q,4)) ];
            iw=combination(3)-combination(1)+1;
            ih=combination(4)-combination(2)+1;
            
            if iw > 0 & ih > 0
            %the +1 is based off of VOCCODE
                intersection = iw * ih;
                union = (detbbox(q,3)-detbbox(q,1)+1) * (detbbox(q,4)-detbbox(q,2)+1) + ...
                    (gtcoor(n,3)-gtcoor(n,1)+1) * (gtcoor(n,4)-gtcoor(n,2)+1) - intersection;
                ioverd = intersection / union;
            else              
                ioverd = 0;
            end

            %saves it to array
            ioverdcomp(n,q) = ioverd;
        end
        
    end
    
    
    %checks for repeat detections
    for r = 1:length(ioverdcomp(1,:))
        sumof(r) = sum(ioverdcomp(:,r));
    end
    if unique(sumof) < length(sumof)
        r = 1;
        while r < length(ioverdcomp(1,:))
            g = find(sumof == sumof(r));
            if length(g) > 1 & sumof(r) ~= 0
                g(1) = [];
                ioverdcomp(:,g) = [];
                detbbox(g,:) = [];
                sumof(g) = [];
            end
            r = r + 1;
        end
    end 
    
                
    
    
    %Use values in ioverdcomp to determine true positives and false
    %positives and hard negatives.
    
    %determines number of false postives / missed persons in image
    
    numgt = length(ioverdcomp(:,1));
    numdet = length(ioverdcomp(1,:));
    detdummy = detbbox;
    detdummy2 =detdummy;
    gtdummy = gtcoor;
    gtdummy2 = gtdummy;
   
    %flags false positives and missed detections
    if numdet > numgt
        counter = numgt;
    elseif numdet < numgt
        counter = numdet;
    else
        counter = numdet;
    end
    
    
    for q = 1:counter
        maxid = 0;
        for z = 1:length(ioverdcomp(1,:))
            m = max(ioverdcomp(:,z));
            if m >= maxid
                col = z;
                maxid = m;
            end  
        end

      [gtloc , bboxloc ] = find(ioverdcomp == max(ioverdcomp(:,col)));
      
      %in the event of multiple detections having the same ioverd with
      %different gtbboxes, this selects one for the next round of recording
      %and deletion
      gtloc = gtloc(1);
      bboxloc = bboxloc(1);
      
if max(maxid) < 0.5
           
           %the zero check needs to precede the other code here to check for the case of an all-zero array 
        if all(ioverdcomp == 0) 
             if ~all(detdummy2 == 0)
                for r = 1:length(detdummy2(:,1))
                    if detdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(detdummy2(r,1))) cellstr(num2str(detdummy2(r,2))) ...
                            cellstr(num2str(detdummy2(r,3))) cellstr(num2str(detdummy2(r,4))) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('fp');
                        testdata(tcount,12) = cellstr(num2str(detdummy2(r,5)));
                        
                        totalfp = totalfp + 1;
                        tcount = tcount + 1;
                    end
                end
             end
             if ~all(gtdummy2 == 0)
                for r = 1:length(gtdummy2(:,1))
                    if gtdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(gtdummy2(r,1))) cellstr(num2str(gtdummy2(r,2))) ...
                            cellstr(num2str(gtdummy2(r,3))) cellstr(num2str(gtdummy2(r,4))) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('missed');
                        testdata(tcount,12) = cellstr(num2str(thresh-0.1));
                        
                        tcount = tcount + 1;
                    end
                end                 
             end
           else 
                testdata(tcount,1) = imagename;
                testdata(tcount,2:5) = [ cellstr(num2str(gtdummy(gtloc,1))) cellstr(num2str(gtdummy(gtloc,2))) ...
                    cellstr(num2str(gtdummy(gtloc,3))) cellstr(num2str(gtdummy(gtloc,4))) ];
                testdata(tcount,6:9) = [ cellstr(num2str(detdummy(bboxloc,1))) cellstr(num2str(detdummy(bboxloc,2))) ...
                    cellstr(num2str(detdummy(bboxloc,3))) cellstr(num2str(detdummy(bboxloc,4))) ];
                testdata(tcount,10) = cellstr(num2str(maxid));
                testdata(tcount,11) = cellstr('fp');
                testdata(tcount,12) = cellstr(num2str(detdummy(bboxloc,5)));
                
                tcount = tcount + 1;
                totalfp = totalfp + 1;

                detdummy2(bboxloc,:) = zeros(1,length(detdummy2(1,:)));
                gtdummy2(gtloc,:) = zeros(1,length(gtdummy2(1,:)));
                ioverdcomp(gtloc,:) = zeros(1,length(ioverdcomp(1,:)));
                ioverdcomp(:,bboxloc) = zeros(length(ioverdcomp(:,1)),1);
        if all(ioverdcomp == 0) 
             if ~all(detdummy2 == 0)
                for r = 1:length(detdummy2(:,1))
                    if detdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(detdummy2(r,1))) cellstr(num2str(detdummy2(r,2))) ...
                            cellstr(num2str(detdummy2(r,3))) cellstr(num2str(detdummy2(r,4))) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('fp');
                        testdata(tcount,12) = cellstr(num2str(detdummy2(r,5)));
                        
                        totalfp = totalfp + 1;
                        tcount = tcount + 1;
                    end
                end
             end
             if ~all(gtdummy2 == 0)
                for r = 1:length(gtdummy2(:,1))
                    if gtdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(gtdummy2(r,1))) cellstr(num2str(gtdummy2(r,2))) ...
                            cellstr(num2str(gtdummy2(r,3))) cellstr(num2str(gtdummy2(r,4))) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('missed');
                        testdata(tcount,12) = cellstr(num2str(thresh-0.1));
                        
                        tcount = tcount + 1;
                    end
                end                 
             end
        end
        end
          
else
        testdata(tcount,1) = imagename;
        testdata(tcount,2:5) = [ cellstr(num2str(gtdummy(gtloc,1))) cellstr(num2str(gtdummy(gtloc,2))) ...
            cellstr(num2str(gtdummy(gtloc,3))) cellstr(num2str(gtdummy(gtloc,4))) ];
        testdata(tcount,6:9) = [ cellstr(num2str(detdummy(bboxloc,1))) cellstr(num2str(detdummy(bboxloc,2))) ...
            cellstr(num2str(detdummy(bboxloc,3))) cellstr(num2str(detdummy(bboxloc,4))) ];
        testdata(tcount,10) = cellstr(num2str(maxid));
        testdata(tcount,11) = cellstr('tp');
        testdata(tcount,12) = cellstr(num2str(detdummy(bboxloc,5)));
        
        tcount = tcount + 1;
        totaltp = totaltp + 1;

        detdummy2(bboxloc,:) = zeros(1,length(detdummy2(1,:)));
        gtdummy2(gtloc,:) = zeros(1,length(gtdummy2(1,:)));
        ioverdcomp(gtloc,:) = zeros(1,length(ioverdcomp(1,:)));
        ioverdcomp(:,bboxloc) = zeros(length(ioverdcomp(:,1)),1);

           
         if all(ioverdcomp == 0)
             if ~all(detdummy2 == 0)
                for r = 1:length(detdummy2(:,1))
                    if detdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(detdummy2(r,1))) cellstr(num2str(detdummy2(r,2))) ...
                            cellstr(num2str(detdummy2(r,3))) cellstr(num2str(detdummy2(r,4))) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('fp');
                        testdata(tcount,12) = cellstr(num2str(detdummy(bboxloc,5)));
                        
                        tcount = tcount + 1;
                        totalfp = totalfp + 1;
                    end
                end
             end
             if ~all(gtdummy2 == 0)
                for r = 1:length(gtdummy2(:,1))
                    if gtdummy2(r,1) ~= 0
                        testdata(tcount,1) = imagename;
                        testdata(tcount,2:5) = [ cellstr(num2str(gtdummy2(r,1))) cellstr(num2str(gtdummy2(r,2))) ...
                            cellstr(num2str(gtdummy2(r,3))) cellstr(num2str(gtdummy2(r,4))) ];
                        testdata(tcount,6:9) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        testdata(tcount,10) = cellstr(num2str(0));
                        testdata(tcount,11) = cellstr('missed');
                        testdata(tcount,12) = cellstr(num2str(thresh-0.1));
                        
                        tcount = tcount + 1; 
                    end
                end                 
            end
         end
end
    end

imsproc = imsproc + 1;
exp_savetxt( tcountprior, tcount, conf, testdata );
tcountprior = tcount;
end



%sorts aparray to be in confidence order upon processing of all images
testdata = testdata(1:(tcount-1),:);
save([conf.expdata.pascaldata '/' 'testdata.mat'], 'testdata' , 'tcount', 'imsproc');



end

