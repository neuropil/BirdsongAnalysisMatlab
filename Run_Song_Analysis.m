function [] = Run_Song_Analysis()
%Run_Song_Analysis
%   Run this function with no input arguments to initiate Song analysis
%   folders and files.

addpath(genpath('C:\Users\Dr. JT\Documents\GitHub\BirdsongAnalysisMatlab'));

cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong');

% Pre Processing each condition in single Bird folder

%% Check to rename files % STAGE 3
SongFileRenamer;

%% Threshold wav files with 1000 high pass filter % STAGE 4
SongWavFilter;

%% 1st % STAGE 6
FirstSongAnalysisFile;

%% 2nd % STAGE 7
Get_syllable_extraction;

%% 3rd % STAGE 8
InsertSyllableID;

%% 4th % STAGE 9
KL_DistanceSong;

%% 5th % STAGE 10
TransitionEntropy;

%% 6th % STAGE 11
SongSequenceAnalysis;

end

