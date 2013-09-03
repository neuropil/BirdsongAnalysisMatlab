function [path] = findsongwavpath(wavfilename,varargin)
% [path] = findsongwavpath(wavfilename,varargin)
% Get path of song wav file from name of file
% findsongwavpath accepts the following opitional parameter/value pairs
%  rootdir - root directory - default set by findroot.m
%  datadir - (def=rootdir/Data/FtSongWav/)
% [[Optional arguments rely on parse_pv_pairs.m being on your MATLAB path]]
%   getsong2 looks in the

%
% (Todd, 3/9/2009)
 
% params.rootdir = {'/Volumes/Groups','Y:','/Users/toddtroyer/Documents/Lab'};
params.rootdir = rootdirlist;
% params.datadir = {'/Volumes/share/Data','Z:/Data','/Volumes/troyerlab/Data',};
params.datadir = datadirlist;

params = parse_pv_pairs(params,varargin);
if iscell(params.rootdir)
params.rootdir = finddir(params.rootdir);
end
if isempty(params.rootdir)
    error('Can''t find root directory');
end
if iscell(params.datadir)
params.datadir = finddir(params.datadir);
end
if isempty(params.datadir)
    disp('Can''t find data directory. Check connection to server.');
end
params.datadir = [params.datadir filesep 'FtSongWav']; 


%% look for file first in current directory, then according to data path
%% and filename
if exist(wavfilename,'file')
    [path,name,ext] = fileparts(wavfilename);
else
    underscoreinds = find(wavfilename=='_');
    if isempty(underscoreinds)
        path = [params.datadir filesep 'FtSong' wavfilename(1:4) ...
                                                    filesep wavfilename filesep wavfilename '_wav'];
    else
        path = [params.datadir filesep 'FtSong' wavfilename(1:4) ...
                    filesep wavfilename(1:underscoreinds(end)-1) filesep wavfilename(1:underscoreinds(end)-1) '_wav'];
    end        
    if ~exist([path filesep wavfilename])
        path = '';
        ans = questdlg({['Can''t find Song file ' wavfilename '.'],...
            'Do you want to search manually?'},'Can''t find songwavfile','Yes','No','Yes');
        if ~strcmpi(ans,'Yes')
            song = [];
            return
        else
            [songfilename,songpath] = uigetfile({'*.wav','*.wav files'}, ['Look for' wavfilename]);
            if exist(fullfile(songpath,songfilename),'file')~=2
                path = '';
            else
                path=songpath;
            end
        end
    end
end
