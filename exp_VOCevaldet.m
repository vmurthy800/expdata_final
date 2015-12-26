function [tp,ap] = exp_VOCevaldet(VOCopts,id,cls,draw, data, nums)

% load test set

cp=sprintf(VOCopts.annocachepath,VOCopts.testset);
if exist(cp,'file')
    fprintf('%s: pr: loading ground truth\n',cls);
    load(cp,'gtids','recs');
else
    [gtids,t]=textread(sprintf(VOCopts.imgsetpath,VOCopts.testset),'%s %d');
    for i=1:length(gtids)
        % display progress
        if toc>1
            fprintf('%s: pr: load: %d/%d\n',cls,i,length(gtids));
            drawnow;
            tic;
        end

        % read annotation
        recs(i)=PASreadrecord(sprintf(VOCopts.annopath,gtids{i}));
    end
    save(cp,'gtids','recs');
end

%reformatts results
ids = cell(length(data(:,1)),1);
confidence = zeros(length(data(:,1)),1);
b1 = zeros(length(data(:,1)),1);
b2 = zeros(length(data(:,1)),1);
b3 = zeros(length(data(:,1)),1);
b4 = zeros(length(data(:,1)),1);
for k = 1:length(data(:,1))
    ids(k,1) = data(k,1);
    confidence(k,1) = str2double(data(k,2));
    b1(k,1) = str2double(data(k,3));
    b2(k,1) = str2double(data(k,4));
    b3(k,1) = str2double(data(k,5));
    b4(k,1) = str2double(data(k,6));
end

BB=[b1 b2 b3 b4]';

nposcount = recs;

%removes all images not being tested

loc = [1:length(recs(1,:))];
loc(nums) = [];
nposcount(:,loc) = [];
npos = 0;
np = [];
for k = 1:length(nposcount(1,:))
    clsinds2 = strmatch(cls,{nposcount(k).objects(:).class},'exact');
    np(k).diff =[nposcount(k).objects(clsinds2).difficult];
    npos = npos + sum(~np(k).diff);
end

fprintf('%s: pr: evaluating detections\n',cls);

% hash image ids
hash=VOChash_init(gtids);
        
% extract ground truth objects

gt(length(recs))=struct('BB',[],'diff',[],'det',[]);
for i=1:length(recs)
    % extract objects of class
    clsinds=strmatch(cls,{recs(i).objects(:).class},'exact');
    gt(i).BB=cat(1,recs(i).objects(clsinds).bbox)';
    gt(i).diff=[recs(i).objects(clsinds).difficult];
    gt(i).det=false(length(clsinds),1);
end


% sort detections by decreasing confidence
[sc,si]=sort(-confidence);
ids=ids(si);
BB=BB(:,si);

% assign detections to ground truth objects
nd=length(confidence);
tp=zeros(nd,1);
fp=zeros(nd,1);
for d=1:nd
    % display progress
    if toc>1
        fprintf('%s: pr: compute: %d/%d\n',cls,d,nd);
        drawnow;
    end
    
    % find ground truth image
    i=VOChash_lookup(hash,ids{d});
    if isempty(i)
        error('unrecognized image "%s"',ids{d});
    elseif length(i)>1
        error('multiple image "%s"',ids{d});
    end

    % assign detection to ground truth object if any
    bb=BB(:,d);
    ovmax=-inf;
    for j=1:size(gt(i).BB,2)
        bbgt=gt(i).BB(:,j);
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
        if iw>0 & ih>0                
            % compute overlap as area of intersection / area of union
            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
               (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
               iw*ih;
            ov=iw*ih/ua;
            if ov>ovmax
                ovmax=ov;
                jmax=j;
            end
        end
    end
    % assign detection as true positive/don't care/false positive
    if ovmax>=VOCopts.minoverlap
        if ~gt(i).diff(jmax)
            if ~gt(i).det(jmax)
                tp(d)=1;            % true positive
		gt(i).det(jmax)=true;
            else
                fp(d)=1;            % false positive (multiple detection)
            end
        end
    else
        fp(d)=1;                    % false positive
    end
end

% compute precision/recall
fp=cumsum(fp);
tp=cumsum(tp);
rec=tp/npos;
prec=tp./(fp+tp);

ap=VOCap(rec,prec);

if draw
    % plot precision/recall
    plot(rec,prec,'-');
    grid;
    xlabel 'recall'
    ylabel 'precision'
    title(sprintf('class: %s, subset: %s, AP = %.3f',cls,VOCopts.testset,ap));
end
