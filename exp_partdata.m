function [ partdata ] = exp_partdata( conf,imnum,testdata )
%exp_partdata uses the detections and gt matches obtained in testdata.
%From there, the algorithm seeks to match a part detection, bbox detection
%and root detection using ioverd
%1.) Load in testdata
%2.) Get rows for a given picture. Make them zeros and not cell. 
%3.) Run the detector, get parts through exp_getpart
%4.) Correlate each part to detection using ioverd. Match each detection to
%its gtbbox if it has one 
%struct partdata is arranged by filter (1-34) and by picture within each filter
%within each substruct is an array in the format :
%[ gt bbox det bbox part bbox i/d_det,gt i/d_part,det confidence]
%5.) make picture with name fx_picname.jpg and save it

if nargin < 3
    load([conf.expdata.pascaldata '/' 'testdata.mat'],'testdata');
end


partdata = [];
tarray = unique(testdata(:,1));
%for each picture
for k = 1766:1965
    imname = tarray(k);
    
    %gets data from testdata for each picture
    tcount = 1;
    picdata = 1;
    clear picdata
    for z = 1:length(testdata(:,1)) 
        if strcmp(testdata(z,1),tarray(k)) == 1
            picdata(tcount,:) = testdata(z,:);
            tcount = tcount + 1;
        end
    end
    
    %converts all data to numbers, puts them in double array with format
    %[ gtcoor detcoor (space for part) ioverd_det/gt
    %  conf]
    pcount = 1;
    clear partarray
    refarray = zeros(100,14);

    for z = 1:length(picdata(:,1))
        refarray(pcount,1) = str2double(picdata{z,2});
        refarray(pcount,2) = str2double(picdata{z,3});
        refarray(pcount,3) = str2double(picdata{z,4});
        refarray(pcount,4) = str2double(picdata{z,5});
        refarray(pcount,5) = str2double(picdata{z,6});
        refarray(pcount,6) = str2double(picdata{z,7});
        refarray(pcount,7) = str2double(picdata{z,8});
        refarray(pcount,8) = str2double(picdata{z,9});
        refarray(pcount,13) = str2double(picdata{z,10});

        %gets whether the det / gt is tp / fp or not
        refarray(pcount,14) = str2double(picdata{z,11});
        pcount = pcount + 1;

    end   
    refarray = refarray(1:pcount-1,:);

    
    %tests image
    imagename = tarray(k);
    disp(imagename);
    file = conf.pascal.dev_kit;
    filename = strcat(file,'VOC2010/JPEGImages/',imagename);
    load('2010/person_final');
    model.class = 'person grammar';
    thresh = -0.6;
    im = imread(filename{1,1});
    % detect objects
    bs = 1;
    clear bs
    [ds, bs] = imgdetect(im, model, thresh);
    clear ds

    
    %for each part type
    for z = 1:34
        disp(z);
        partarray = zeros(100,14);
        partarray(1:length(refarray(:,1)),:) = refarray;
        zcount = pcount;
        
        %gets location of given part in bs
        bsmin = 4*(z-1) + 1;
        bsmax = bsmin + 3;
        
        %gets threshold values for a given part
        if z < 2
            pthresh = 0.4;
        else
            pthresh = 0.1;
        end
        
            
        if isempty(bs)
            id = imagename;
            id = {id{1}(1:11)};
            id = id{1,1};
            partdata.(strcat('filter',num2str(z))).(strcat('A_',id)) = refarray;
            part_txt(refarray,conf,id, z);
        elseif sum(bs(:,bsmin:bsmax)) == 0
            id = imagename;
            id = {id{1}(1:11)};
            id = id{1,1};
            partdata.(strcat('filter',num2str(z))).(strcat('A_',id)) = refarray;
            part_txt(refarray,conf,id, z);
        else    
            %get part data
            parts = 1;
            clear parts
            [ parts ] = exp_getparts( bs, bsmin, bsmax, 0.3);
            ioverddata = 1;
            clear ioverddata
            [ ioverddata ] = exp_partioverd(parts, refarray(:,1:4), pthresh, imagename);
            %formats ioverddata into a double array
                ptid = 1;
                clear ptid
                rcount = 1;
                ptid = zeros(100,8);
                for b = 1:length(ioverddata(:,1))
                    ptid(rcount,1) = str2double(ioverddata(b,2));
                    ptid(rcount,2) = str2double(ioverddata(b,3));
                    ptid(rcount,3) = str2double(ioverddata(b,4));
                    ptid(rcount,4) = str2double(ioverddata(b,5));
                    ptid(rcount,5) = str2double(ioverddata(b,6));
                    ptid(rcount,6) = str2double(ioverddata(b,7));
                    ptid(rcount,7) = str2double(ioverddata(b,8));
                    ptid(rcount,8) = str2double(ioverddata(b,9));
                    rcount = rcount + 1;
                end
                ptid = ptid(1:rcount-1,:);
                clear ioverddata
                
               %matches detections / part matches to gt 
               j = 1;
               %boolv is used to determine whether the row needs to be increased or
               %not, helps process all root detections
               boolv = 0;
               while j < length(ptid(:,1)) + 1
                   cmp1 = strcat( num2str(ptid(j,1)),num2str(ptid(j,2)), ...
                       num2str(ptid(j,3)),num2str(ptid(j,4)));
                   for r = 1:length(refarray(:,1))
                       if refarray(r,1) ~= 0
                       cmp2 = strcat( num2str(refarray(r,1)),num2str(refarray(r,2)), ...
                       num2str(refarray(r,3)),num2str(refarray(r,4)));
                      
                      if strcmp(cmp1,cmp2) == 1
                          if j < length(ptid(:,1))
                          partarray(r,9:12) = ptid(j,5:8);
                          ptid(j,:) = [];
                          boolv = 1;
                          end
                          
                      end
                      end
                                             
                   end

                   if boolv == 0
                        j = j + 1;
                   end
                   boolv = 0;
                   

                   
               end
               
               %saves any uncorrelated parts (parts which DO NOT match a
               %ground truth box) to the partarray on their own row
               for w = 1:length(ptid(:,1))
                   partarray(zcount,9:12) = ptid(w,5:8);
                   zcount = zcount + 1;
               end
               partarray = partarray(1:zcount -1,:);
               
               %create and save picture- red is parts, blue is ground truth
               id = imagename;
               id = {id{1}(1:11)};
               id = id{1,1};             
               %imagesave = [ conf.expdata.partpic '/' 'filter' num2str(z) '_' id '.jpg'];
               %showdetgt( partarray(:,9:12), refarray(:,1:4), imagesave, im)
               part_txt(partarray,conf,id, z);
                
              
               %save to struct
                partdata.(strcat('filter',num2str(z))).(strcat('A_',id)) = partarray;
                partarray = zeros(100,14);
            
        %end of isempty    
        end
        
        
        
    %end of for each part    
    end
    
%end of for each picture    
end





%end of function
end



function part_txt(partarray,conf,imagename, filter)
    saveloc = [conf.expdata.partanno '/' 'filter_' num2str(filter) '_' imagename '.txt'];
    file = fopen(saveloc,'w');
    
    for k = 1:length(partarray(:,1))
        vec = partarray(k,:);
        fname = strcat('filter',num2str(filter));
        
        fprintf(file,'%s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f \n', imagename, fname, vec);
    
    end
    
    fclose(file);
    
end

