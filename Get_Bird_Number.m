function [birdNum] = Get_Bird_Number()
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












