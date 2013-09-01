function [allEntropies] = TransitionEntropy()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

birdNum = Get_Bird_Number;
sapCheck = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum);

cd(sapCheck)

fileNames = cellstr(ls);
songsDSNs = fileNames(3:end); % songDSNs has PreAll

PreAllName = strcat(birdNum,'_PreALL.mat');
nameIndex = ~strcmp(PreAllName,songsDSNs);
songDSlist = songsDSNs(nameIndex);

[songListReO , ~] = songDateReorder(songDSlist);

% Calculate transition probability

dayTransitionProbs = cell(length(songListReO),1);
for dayI = 1:length(songListReO)
    
    tempSongDS = songListReO{dayI};
    load(tempSongDS)
    
    waveIndex = songDataset.WavNumber;
    daySylls = songDataset.SyllableID;
    getWavindices = unique(songDataset.WavNumber);
    
    dayTrans = [];
    for syl = 1:length(getWavindices)
        tempIndex = waveIndex == getWavindices(syl);
        
        WavesylIndex = daySylls(tempIndex);
        
        syl1 = 1;
        syl2 = 2;
        trans_count = 1;
        sylTrans = {};
        while syl2 < sum(tempIndex)
            sylTrans{trans_count,1} = strcat(WavesylIndex{syl1},WavesylIndex{syl2});
            
            syl1 = syl1 + 1;
            syl2 = syl2 + 1;
            trans_count = trans_count + 1;

        end
        dayTrans = [dayTrans ; sylTrans];
    end
    
    uniqueTrans = unique(dayTrans);
    numTrans = numel(dayTrans);
    
    probTrans = zeros(1,length(uniqueTrans));
    for unI = 1:length(uniqueTrans)
        probTrans(unI) = sum(strcmp(uniqueTrans{unI},dayTrans))/numTrans;
    end
    
    dayTransitionProbs{dayI} = probTrans;
    
end

allEntropies = findEntropy(dayTransitionProbs);
    
end

