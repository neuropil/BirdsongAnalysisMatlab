function [File_Predates, experCond, birdNum] = Get_Bird_PreALL()
%Get_Bird_PreALL Summary of this function goes here
%   Detailed explanation goes here


%-------------------------------------------------------------------------%
% Change directory to folder that contains folders of raw bird song data
%-------------------------------------------------------------------------%
rawSongsDir = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\RawSongs';
cd(rawSongsDir);
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

%-------------------------------------------------------------------------%
% User input selected experimental condition
%-------------------------------------------------------------------------%

% possibleConds = {'Infusion','Lesion','LMAN','Pre'};
% 
% expCondFold = strcat(rawSongsDir,'\',birdNum,'\');
% cd(expCondFold);
% 
% expCdir = cellstr(ls);
% exConds = expCdir(3:end);
% 
% condSel = listdlg('ListString', possibleConds,...
%     'SelectionMode', 'single',...
%     'ListSize', [100 75],...
%     'PromptString', 'Select a condition');
% 
% conselection = possibleConds{condSel};
% 
% condOut = cellfun(@(x) strcmp(conselection,x), exConds);
% 
% experCond = exConds{condOut};

%-------------------------------------------------------------------------%
% User input selected date
%-------------------------------------------------------------------------%

dateFold = strcat(rawSongsDir,'\',birdNum,'\Pre\');
cd(dateFold);

datedir = cellstr(ls);
File_Predates = datedir(3:end);










