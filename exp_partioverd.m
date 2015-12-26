function [ ioverddata ] = exp_partioverd(detbbox, gtcoor, detthresh, imagename )
%cbgetioverd - GENERALIZED ioverd function for use with the test parts
%function. Cuts down on lines of code in testpart function and increases
%code readability
% [ imagename gtcoor detcoor ioverd (missed, tp, fp)]

if nargin < 4
    imagename =cellstr('blank');
end

tcount = 1;
ioverdcomp = zeros(length(gtcoor(:,1)),length(detbbox(:,1)));
ioverddata = cell(20,10);
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
            if length(g) > 1
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
   
    %determines "limiting" box type
    if numdet > numgt
        counter = numgt;
    else
        counter = numdet;
    end
    
    for q = 1:counter
        
        %finds maximum ioverd value LEFT IN ARRAY
        maxid = 0;
        for z = 1:length(ioverdcomp(1,:))
            m = max(ioverdcomp(:,z));
            if m >= maxid
                col = z;
                maxid = m;
            end  
        end

      [gtloc , bboxloc ] = find(ioverdcomp == max(ioverdcomp(:,col)));
      gtloc = gtloc(1);
      bboxloc = bboxloc(1);
      
        if max(maxid) < detthresh
           
           %the zero check needs to precede the other code here to check for the case of an all-zero array 
           if all(ioverdcomp == 0) 
             if ~all(detdummy2 == 0)
                for r = 1:length(detdummy2(:,1))
                    if detdummy2(r,1) ~= 0
                        ioverddata(tcount,1) = imagename;
                        ioverddata(tcount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        ioverddata(tcount,6:9) = [ cellstr(num2str(detdummy2(r,1))) cellstr(num2str(detdummy2(r,2))) ...
                            cellstr(num2str(detdummy2(r,3))) cellstr(num2str(detdummy2(r,4))) ];
                        ioverddata(tcount,10) = cellstr(num2str(0));
                        detdummy2(r,:) = zeros(1,length(detdummy2(1,:)));
                        tcount = tcount + 1;
                    end
                end
             end
             if ~all(gtdummy2 == 0)
                for r = 1:length(gtdummy2(:,1))
                    if gtdummy2(r,1) ~= 0
                        ioverddata(tcount,1) = imagename;
                        ioverddata(tcount,2:5) = [ cellstr(num2str(gtdummy2(r,1))) cellstr(num2str(gtdummy2(r,2))) ...
                            cellstr(num2str(gtdummy2(r,3))) cellstr(num2str(gtdummy2(r,4))) ];
                        ioverddata(tcount,6:9) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        ioverddata(tcount,10) = cellstr(num2str(0));
                        gtdummy2(r,:) = zeros(1,length(gtdummy2(1,:)));
                        tcount = tcount + 1;
                    end
                end                 
             end
           else 
                ioverddata(tcount,1) = imagename;
                ioverddata(tcount,2:5) = [ cellstr(num2str(gtdummy(gtloc,1))) cellstr(num2str(gtdummy(gtloc,2))) ...
                    cellstr(num2str(gtdummy(gtloc,3))) cellstr(num2str(gtdummy(gtloc,4))) ];
                ioverddata(tcount,6:9) = [ cellstr(num2str(detdummy(bboxloc,1))) cellstr(num2str(detdummy(bboxloc,2))) ...
                    cellstr(num2str(detdummy(bboxloc,3))) cellstr(num2str(detdummy(bboxloc,4))) ];
                ioverddata(tcount,10) = cellstr(num2str(maxid));

                tcount = tcount + 1;

                %kills off bounding box and detected box that were matched,
                %as well as their intersection over detection values in the
                %array.
                detdummy2(bboxloc,:) = zeros(1,length(detdummy2(1,:)));
                gtdummy2(gtloc,:) = zeros(1,length(gtdummy2(1,:)));
                ioverdcomp(gtloc,:) = zeros(1,length(ioverdcomp(1,:)));
                ioverdcomp(:,bboxloc) = zeros(length(ioverdcomp(:,1)),1);               
           end
           

        else
        ioverddata(tcount,1) = imagename;
        ioverddata(tcount,2:5) = [ cellstr(num2str(gtdummy(gtloc,1))) cellstr(num2str(gtdummy(gtloc,2))) ...
            cellstr(num2str(gtdummy(gtloc,3))) cellstr(num2str(gtdummy(gtloc,4))) ];
        ioverddata(tcount,6:9) = [ cellstr(num2str(detdummy(bboxloc,1))) cellstr(num2str(detdummy(bboxloc,2))) ...
            cellstr(num2str(detdummy(bboxloc,3))) cellstr(num2str(detdummy(bboxloc,4))) ];
        ioverddata(tcount,10) = cellstr(num2str(maxid));
        
        tcount = tcount + 1;


        detdummy2(bboxloc,:) = zeros(1,length(detdummy2(1,:)));
        gtdummy2(gtloc,:) = zeros(1,length(gtdummy2(1,:)));
        ioverdcomp(gtloc,:) = zeros(1,length(ioverdcomp(1,:)));
        ioverdcomp(:,bboxloc) = zeros(length(ioverdcomp(:,1)),1);

           
         if all(ioverdcomp == 0)
             if ~all(detdummy2 == 0)
                for r = 1:length(detdummy2(:,1))
                    if detdummy2(r,1) ~= 0
                        ioverddata(tcount,1) = imagename;
                        ioverddata(tcount,2:5) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        ioverddata(tcount,6:9) = [ cellstr(num2str(detdummy2(r,1))) cellstr(num2str(detdummy2(r,2))) ...
                            cellstr(num2str(detdummy2(r,3))) cellstr(num2str(detdummy2(r,4))) ];
                        ioverddata(tcount,10) = cellstr(num2str(0));
                        
                        tcount = tcount + 1;
                        detdummy2(r,:) = zeros(1,length(detdummy2(1,:)));
                    end
                end
             end
             if ~all(gtdummy2 == 0)
                for r = 1:length(gtdummy2(:,1))
                    if gtdummy2(r,1) ~= 0
                        ioverddata(tcount,1) = imagename;
                        ioverddata(tcount,2:5) = [ cellstr(num2str(gtdummy2(r,1))) cellstr(num2str(gtdummy2(r,2))) ...
                            cellstr(num2str(gtdummy2(r,3))) cellstr(num2str(gtdummy2(r,4))) ];
                        ioverddata(tcount,6:9) = [ cellstr(num2str(0)) cellstr(num2str(0)) ...
                            cellstr(num2str(0)) cellstr(num2str(0)) ];
                        ioverddata(tcount,10) = cellstr(num2str(0));
                        gtdummy2(r,:) = zeros(1,length(gtdummy2(1,:)));
                        tcount = tcount + 1; 
                    end
                end                 
            end
          end
        end
    end

ioverddata = ioverddata((1:tcount-1),:);   
    

end

