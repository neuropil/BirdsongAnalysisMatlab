function [S,F] = readtabtext(format,varargin)
% [S,F] = readtabtext(FORMAT,FILENAME) read data from filename
%  using format string FORMAT
% FORMAT must be string appropriate for use with textscan.m and is usually
%  has a % followed by s,d,n for string, integer and floating point number respectively
% FILENAME should be a tab delimited text file with the same number of columns as % 
%  in FORMAT and where the first line holds a list of strings that become field names
%  S is a struct where each field holds a column of the data 
%  F is a cell array holding the field names
% [F,C] = readtagtext(FORMAT) will prompt the user for filename
%
% Example [S,F] = readtabtext('%d%d%n%n%s%s','data.txt') would read from
% file data.txt, having the first two columns of integers, the next two
% floating point numbers, and the last two holding strings

% Todd, 8/22/08
S = [];

% aregument checking
switch nargin 
    case 0
        error('??? Error using ==> readtabtext. Must specify a format string.');
    case 1
        foundfile = 0;
    case 2
        filename = varargin{1};
        if ~exist(filename,'file')
            foundfile = 0;
        else
            foundfile = 1;
        end
    otherwise
        error('??? Error using ==> readtabtext. Too many input arguments.');
end

% look for file if not found
if ~foundfile
    [filename, pathname] = uigetfile('*.txt','Select a tab delimited text file to read');
    if filename==0 | pathname==0
        S = []; F = []; return;
    else
        filename = fullfile(pathname,filename);
    end
end

% make format string for file headers
colnum = sum(format=='%');
fieldfmt = [];
for i=1:colnum
    fieldfmt = [fieldfmt '%s'];
end

fid = fopen(filename);
F = textscan(fid,fieldfmt,1,'Delimiter','\t');
C = textscan(fid,format,'Delimiter','\t');
fclose(fid);

% replace any blanks in fieldnames with underscore
for i=1:length(F)
    blanks = find(F{i}{1}==' ');
    F{i}{1}(blanks) = '_';
end

% write data to structure
for i=1:length(C)
    eval(['S.' F{i}{1} '=C{i};']);
end

