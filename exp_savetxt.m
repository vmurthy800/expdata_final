function exp_savetxt( tcountprior, tcount, conf, testdata )
%cbsaveindtxt - Saves each image's data in a separate text file, each laid
%out near identically to a row in testdata.mat
% filename = imagename.txt 
%setup of row [ imagename gtxmin gtymin bboxxmax bboxymax ioverd (tp = 1,
%fp = 0 missed = -1) confidence ] 

imagename = testdata((tcount - 1),1);
imageloc = [conf.expdata.bboxanno '/' imagename{1,1} '.txt'];
file = fopen(imageloc, 'w');

for k = tcountprior : (tcount-1)
    
    rowvec = testdata(k,:);
    
    imname = imagename{1,1};
    gtxmin = str2double(rowvec{2});
    gtymin = str2double(rowvec{3});
    gtxmax = str2double(rowvec{4});   
    gtymax = str2double(rowvec{5});  
   
    bboxxmin = str2double(rowvec{6});
    bboxymin = str2double(rowvec{7});
    bboxxmax = str2double(rowvec{8});   
    bboxymax = str2double(rowvec{9});     
   
    ioverd = str2double(rowvec{10}); 
    
    if strcmp(rowvec{11}, 'missed') == 1
        class = -1;
    end
    
    if strcmp(rowvec{11}, 'fp') == 1
        class =  0;
    end
    
    if strcmp(rowvec{11}, 'tp') == 1
        class = 1;
    end
    
    conf = str2double(rowvec{12});
    [ rowvec ] = cbgetcd( rowvec);
    cd = str2double(rowvec{13});
    
    txtvec = [ gtxmin, gtymin, gtxmax, ...
    gtymax, bboxxmin, bboxymin, bboxxmax, bboxymax, ioverd, class, conf, cd];
    
   fprintf(file, '%s %3.0f %3.0f %3.0f %3.0f %3.0f %3.0f %3.0f %3.0f %7.4f %1.0f %5.4f %3.4f  \r\n', imname, txtvec);
end
fclose(file);


end

