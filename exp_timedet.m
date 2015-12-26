function exp_timedet( et, conf, imagename, folder )
%exp_timedet - writes out elapsed time to text file
%INPUTS- et- elapsed time conf- voc_config imagename -imagetostore

if nargin < 4
filename = [conf.expdata.timeanno '/' imagename '.txt'];
else
filename = [conf.expdata.path '/timeanno' '/' imagename '.txt'];
end

file = fopen(filename,'w');
fprintf(file,'%f',et);
fclose(file);

end

