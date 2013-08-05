function [PreMetaSet] = Get_PreALLSAP_Dataset()
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
[Predates, condition, birdNum] = Get_Bird_PreALL;
%-------------------------------------------------------------------------%
% Generate cell list of xls file names
%-------------------------------------------------------------------------%
song_xls_fn = cell(length(Predates),1);
for dN = 1:length(song_xls_fn)
    song_xls_fn{dN,1} = strcat(Predates{dN},'.xls');
end
%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
PRE_SAP_LOC = strcat(SAP_DATA_LOC,'\',birdNum,'\',condition,'\');
cd(PRE_SAP_LOC);
songdatdir = cellstr(ls);
sngNames = songdatdir(3:end);

%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
sFIndex = zeros(length(sngNames),1);
for sL = 1:length(sngNames)
    sFIndex(sL,1) = find(cellfun(@(x) strcmp(song_xls_fn{sL},x), sngNames));
end

songAllPre = {};
for sfds = 1:length(sFIndex)
    
    songF2load = sngNames{sFIndex(sfds)};
    
    cd(PRE_SAP_LOC);
    [~, ~, raw.(strcat('day',num2str(sfds)))] = xlsread(songF2load,'Sheet1');

    songDataset.(strcat('day',num2str(sfds))) = CreatePreALLDS(raw.(strcat('day',num2str(sfds))));
    songAllPre = vertcat(songAllPre,songDataset.(strcat('day',num2str(sfds))));
    
end

NewcolTitles = {'name','syldur','sylstart','Mamp','Mpitch',...
    'MFM','MAM','Mentropy','MpitchG', 'Mfreq',...
    'Vpitch','VFM','Ventropy','Vpitchg',...
    'Vfreq','VAM','filename'};

sapXlsTitles = vertcat(NewcolTitles, songAllPre);
PreMetaSet = cell2dataset(sapXlsTitles);
%-------------------------------------------------------------------------%
% Save Meta Pre File
%-------------------------------------------------------------------------%
fileName = strcat(birdNum,'_PreALL.mat');

BIRD_DATA_LOC = strcat(DS_DATA_LOC,'\',birdNum);

if ~exist(BIRD_DATA_LOC,'dir')
    mkdir(BIRD_DATA_LOC)
end

cd(BIRD_DATA_LOC)
save(fileName,'PreMetaSet');

