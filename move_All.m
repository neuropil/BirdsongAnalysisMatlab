function [] = move_All(directory,files)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

row = max(size(files));

for fi = 1:row
    movefile(char(files(fi)),directory)
end

