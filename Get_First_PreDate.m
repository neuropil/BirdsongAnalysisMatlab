function [birdNum, date] = Get_First_PreDate()
%UNTITLED2 Summary of this function goes here
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

% possibleConds = {'Pre'};
% 
expCondFold = strcat(rawSongsDir,'\',birdNum,'\');
cd(expCondFold);
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

experCond = 'Pre';
%-------------------------------------------------------------------------%
% User input selected date
%-------------------------------------------------------------------------%

dateFold = strcat(expCondFold,'\',experCond,'\');
cd(dateFold);

datedir = cellstr(ls);
dates = datedir(3:end);

% dateSel = listdlg('ListString', dates,...
%     'SelectionMode', 'single',...
%     'ListSize', [95 250],...
%     'PromptString', 'Select a date');

dateSelection = dates{1};

date = dateSelection(5:end);








