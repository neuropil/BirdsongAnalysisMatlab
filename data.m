%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert xls file to matlab file %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
[ignore, data_info] = xlsfinfo('Data.xls'); 
data_info(end) = [];
for k = 1:length(data_info)
    temp = xlsread('Data.xls', data_info{k});
    
    % select Duration, Pitch, FM, Entropy, Pitch Goodness, and Bout Label
    x{k} = temp(:,[2 5 6 8 9 23]);  
end

save Data x data_info;
