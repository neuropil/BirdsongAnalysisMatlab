function [songDataset, birdNum, cond, dateN] = Instant_SAP_Dataset(birdNum,cond,dateN)
% Get_SAP_Dataset:
% Requests from the user a bird number, condition, and date.
% Returns dataset variable of SAP spreadsheet data


%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
SAP_DATA_LOC = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\SAP_Data';
DS_DATA_LOC = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data';
%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%

song_xls_fn = strcat(birdNum,'_',dateN,'.xls');
%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
Bird_SAP_LOC = strcat(SAP_DATA_LOC,'\',birdNum,'\',cond);
cd(Bird_SAP_LOC);
songdatdir = cellstr(ls);
sngNames = songdatdir(3:end);

%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
sFIndex = cellfun(@(x) strcmp(song_xls_fn,x), sngNames);

songF2load = sngNames{sFIndex};


cd(Bird_SAP_LOC);
[~, ~, raw] = xlsread(songF2load,'Sheet1');


song_DS_fn = strcat(birdNum,'_',cond,'_',dateN,'.mat');
[songDataset] = CreateSongdataSet(raw,song_DS_fn,Bird_SAP_LOC);

%-------------------------------------------------------------------------%
% Save Meta Pre File
%-------------------------------------------------------------------------%
fileName = strcat(birdNum,'_',cond,'_',dateN);

BIRD_DS_LOC = strcat(DS_DATA_LOC,'\',birdNum);

if ~exist(BIRD_DS_LOC,'dir')
    mkdir(BIRD_DS_LOC)
end

cd(BIRD_DS_LOC)
save(fileName,'songDataset');