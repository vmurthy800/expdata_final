function [ parts ] = exp_getparts( bs, bsmin, bsmax, pthresh)
%exp_getparts gets locations of unique parts in image
%headbbox - bounding boxes of all UNIQUE parts above pthresh
%numheads - number of part detection in image

partbbox = bs(:,(bsmin:bsmax));
partbbox(partbbox < 0) = 1;
[row col] = find(partbbox == 0);
row = unique(row);
clear col
partbbox(row,:) = [];
if sum(partbbox) == 0
    parts = [ 0 0 0 0];
else
partbbox = sortrows(partbbox);


%does initial recursive selection; later steps will be shortened due to
%this procedure
r = 0;
rcount = 1;
%while r < 1
%    for k = 2: (length(partbbox(:,1)))
%        combination = [ max(partbbox(k,1),partbbox((k-1),1)) max(partbbox(k,2),partbbox((k-1),2)) ...
%        min(partbbox(k,3), partbbox(k-1,3)) min(partbbox(k,4), partbbox(k-1,4)) ];
%        iw=combination(3)-combination(1)+1;
%        ih=combination(4)-combination(2)+1;%
%
%        if iw > 0 & ih > 0
%        %the +1 is based off of VOCCODE
%            intersection = iw * ih;
%            union = (partbbox(k,3)-partbbox(k,1)+1) * (partbbox(k,4)-partbbox(k,2)+1) + ...
%                (partbbox((k-1),3)-partbbox((k-1),1)+1) * (partbbox((k-1),4)-partbbox((k-1),2)+1) - intersection;
%            ioverd = intersection / union;
%        else               
%            ioverd = 0;
%        end
%        
%        ioverdarray(k-1) = ioverd;
%       
%        if ioverd >= pthresh
%            partbbox((k-1),:) = [ 0 0 0 0];
%        end
%        
%    end
%    
%    [row col] = find(partbbox == 0);%
%
%    partbbox(row,:) = [];
%    clear col;
%   
%    %in case of 1 head remaining, allows the loop to end.
%    if length(partbbox(:,1)) == 1
%        break;
%    end
%    
%    jnk = ioverdarray(ioverdarray < 0.1);
%    
%    if length(jnk) == length(ioverdarray) & r > 1
%        r = 1;
%    end
%    clear jnk ioverdarray
%    r = r + 1;
%end

%does full array method just to check
for z = 1:length(partbbox(:,1))
    for q = 1:length(partbbox(:,1))
        combination = [ max(partbbox(z,1),partbbox(q,1)) max(partbbox(z,2),partbbox(q,2)) ...
        min(partbbox(q,3), partbbox(z,3)) min(partbbox(z,4), partbbox(q,4)) ];
        iw=combination(3)-combination(1)+1;
        ih=combination(4)-combination(2)+1;

        if iw > 0 & ih > 0
        %the +1 is based off of VOCCODE
            intersection = iw * ih;
            union = (partbbox(z,3)-partbbox(z,1)+1) * (partbbox(z,4)-partbbox(z,2)+1) + ...
                (partbbox(q,3)-partbbox(q,1)+1) * (partbbox(q,4)-partbbox(q,2)+1) - intersection;
            ioverd = intersection / union;
        else               
            ioverd = 0;
        end        
        
        if ioverd > pthresh & z ~= q
            partbbox(z,:) = [0 0 0 0];
        end
    end
end
[row col] = find(partbbox == 0);
partbbox(row,:) = [];
clear col;

parts = partbbox;

end
end

