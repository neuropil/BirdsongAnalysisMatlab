function [OK] = pathcmp(path1,path2)
% [OK] = pathcmp(path1,path2)
% pathname comparison. First eliminate characters '/' or '\'
% from path1 and path2 and then perform strcmp