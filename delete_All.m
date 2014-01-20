function [] = delete_All(directory,files)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[row,~] = size(files);

for fi = 1:row
    fileLoc = strcat(directory,files(fi,:));
    delete(fileLoc)
end

