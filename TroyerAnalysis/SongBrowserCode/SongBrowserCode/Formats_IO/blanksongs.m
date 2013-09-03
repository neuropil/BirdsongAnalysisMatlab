function songs = blanksongs(varargin);
% songs = blanksongs;
% make empty song structure with default fields
% songs = blanksongs(N);
% makes empty structure where fields are length N
% 
% songs has three types of fields
% .a is structure array holding data for each song
%
%%% array fields 
%%% mandatory fields 
% songs.type = 'bmk'; % type of associated songs: 
%   'sng' - songfile (list of songs from stored data set)
%   'bmk' - bookmark (list of user-selected songs with pointers to stored data0
%   'dbk' - data bookmark (list of user-selected songs with data stored locally)
% songs.datapath = ''; % path of root of data tree 
%    should be able to find wav file from this and filename 
%    default set by findrootdir then Data/FtSongWav
% a.filename = ''; % filename of song wav file
% a.fs = 0; % sample frequency in Hz
% a.date = 0; % date of recording in days from 0 A.D. (matlab format)
% a.time = 0; % time of recording during day in hours
% a.length = 0; % length of song in msec
% a.songID = 0; % ID number of song in original song file
% a.sessionID = 0; % ID number of session
% a.clipnum = 0; % number of clips in song
%
%%% addition fields can be added in groups by setting flags in
%%% parameter/value pairs, e.g. blanksong(3,'segmented',1);
% % if 'clipptrs' (default = 1) pointer to correponding clips structure
%     a.startclip = 0;
%     a.endclip = 0;
% % if 'birdinfo' (default = 1) info about bird
%     a.birdID = 0; % at this point I assume this is an integer
%     a.age = 0; % in days
% % if 'stereo' (default = 1) info for stereo data
%     a.chan = 0; % channel 1=left, 2=right
%     a.powL = 0; % rms power in left
%     a.powR = 0; % rms power in right
% %if 'sessioninfo' (default = 1)  include info about sessions etc - lab specific
%     a.sessiongroupID = 0;  % ID number of sessiongroup
%     a.sessiontype = 0; % index of session type
%     songs.sessiontypes = {'Father-father-father','Father-father-tutor2',...}
%      (see blanksongs.m for full list) 
% %if 'data' (def = 0)  include field for acoustic data
%     songs.d = []; 
% 

% defaults
params.rootdir = {'/Volumes/troyerlab','Y:','/Volumes/Groups','/Users/toddtroyer/Documents/Lab'};
params.clipptrs = 1; % add field for pointer to start and end clips
params.birdinfo = 1; % add field bird and age
params.stereo = 1; % info for stereo data
params.sessioninfo = 1; % add field for sessions etc
params.data = 0; % add empty field to hold acoustic data
params.nclockreset = 0; % add field to hold number of clock resets in a given day
params.sessiontypes  = {'Father-father-father','Father-father-tutor2','Father-tutor2-father',...
    'Father-tutor2-tutor2','Father-tutor2-tutor3','Abandoned','Directed songs','Other',...
    'Subsong development','Rapid Switch','Strobe','LMAN Lesion','Semi-Isolate','Other tutoring','Sample songs',...
    '2 Juveniles - tutor','Sample songs - young adult','Test'};

% get arguments
N = 1;
if nargin > 0
    if isnumeric(varargin{1})
        N = varargin{1};
        varargin = varargin(2:end);
    end
    params = parse_pv_pairs(params,varargin);
end

% % set datapath
% params.rootdir = findrootdir(params.rootdir);
% if isempty(params.rootdir)
%     disp('Warning: Can''t find root directory in blanksongs');
%     songs.datapath = '';
% else
%     songs.datapath = ['Data' filesep 'FtSongWav'];
% end

% set sessiontypes
songs.sessiontypes = params.sessiontypes;

% required of all song structures
a.filename = '';
a.fs = 0;
a.date = 0;
a.time = 0;
a.length = 0;
a.songID = 0;
a.sessionID = 0;
a.clipnum = 0;
% include pointers to associated clip strucutre
if params.clipptrs
    a.startclip = 0;
    a.endclip = 0;
end
% info about bird
if params.birdinfo
    a.birdID = 0;
    a.age = 0;
end
% info for stereo data
if params.stereo
    a.chan = 0;
    a.pow = [0 0];
    a.chanfn = {[1 0]};
    songs.chanfndate = now;
    songs.chanfnhist = {};
end
% include info about sessions etc 
if params.sessioninfo
    a.sessiongroupID = 0;
    a.sessiontype = 0;
    songs.sessiontypes = params.sessiontypes;
end
if params.nclockreset
    songs.nclockreset = 0;
end
if params.data
    songs.d = [];
end

% % include info needed to extract from raw data file - old
% if params.datafileinfo
%     a.fp = 0;
% end
% 

if N>1
    a = repmat(a,N,1);
end
songs.a = a;

