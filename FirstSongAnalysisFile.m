function [] = FirstSongAnalysisFile()


%% Select Bird and Get Pre date names

%-------------------------------------------------------------------------%
% Change directory to folder that contains folders of raw bird song data
%-------------------------------------------------------------------------%
rawSongsDir = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\SAP_Data';
cd(rawSongsDir);
dsDir = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\';
%-------------------------------------------------------------------------%
% User input selected bird number
%-------------------------------------------------------------------------%
birdsdir = cellstr(ls);
birdnums = birdsdir(3:end);

birdSel = listdlg('ListString', birdnums,...
    'SelectionMode', 'single',...
    'ListSize', [95 125],...
    'PromptString', 'Select a bird');

birdNum = birdnums{birdSel};

dateFold = strcat(rawSongsDir,'\',birdNum,'\Pre\');
cd(dateFold);

datedir = cellstr(ls);
File_Predates = datedir(3:end);

%-------------------------------------------------------------------------%
% User input selected experimental condition
%-------------------------------------------------------------------------%
birdDsDir = strcat(dsDir,birdNum);
for si = 1:length(File_Predates)
    cd(dateFold)
    [~, ~, songxlsfile] = xlsread(File_Predates{si},'Sheet1');
    [songDataset] = CreateSongdataSet(songxlsfile);
    cd(birdDsDir)
    songPieces = strsplit(File_Predates{si},'_');
    dateParts = strsplit(songPieces{2},'.');
    datePart = dateParts{1};
    save(strcat(birdNum,'_Pre_',datePart,'.mat'),'songDataset');
end
%-------------------------------------------------------------------------%
% Get PREALL
%-------------------------------------------------------------------------%
Get_PreALLSAP_Dataset;
