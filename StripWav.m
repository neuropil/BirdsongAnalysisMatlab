function [wavDS] = StripWav(wavList)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

wavNums = zeros(length(wavList),1);
for wi = 1:length(wavList)
    tempWav = wavList{wi};
    tempOut = strsplit(tempWav,'.');
    tempNum = tempOut{1};
    wavNums(wi) = str2double(tempNum);
end

wavDS = dataset(wavNums,'VarNames','WavNumber');