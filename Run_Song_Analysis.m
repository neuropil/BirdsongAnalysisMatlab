function [] = Run_Song_Analysis()
%Run_Song_Analysis
%   Run this function with no input arguments to initiate Song analysis
%   folders and files.

addpath(genpath('C:\Users\Dr. JT\Documents\GitHub\BirdsongAnalysisMatlab'));

cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong');

%% 1st
FistSongAnalysisFile;

%% 2nd
Get_syllable_extraction;

%% 3rd
InsertSyllableID;

%% 4th
KL_DistanceSong;

%% 5th
TransitionEntropy;



end

