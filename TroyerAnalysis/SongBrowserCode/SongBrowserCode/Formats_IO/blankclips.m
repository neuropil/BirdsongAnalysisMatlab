function clips = blankclips(varargin);
% clips = blankclips;
% make empty clips structure with default fields
% clips = blankclips(N);
% makes empty structure where fields are length N
% 
% clips has two types of fields
% .a is structure array holding data for each clip
% other fields can be added as needed, 
%
%%% array fields 
%%% mandatory fields 
% a.fs = 0; % sample frequency in Hz
% a.date = 0; % date of recording in days from 0 A.D. (matlab format)
% a.time = 0; % time of recording during day in hours
% a.start = 0; % time from start of clip from start of song (in samples)
% a.length = 0; % length of song in samples
% a.songID = 0;
% a.sessionID = 0;
%
%%% addition fields can be added in groups by setting flags in
%%% parameter/value pairs, e.g. blankclips(3,'songptr',1);
% % if 'songptr' (default = 0) pointer to song in corresponding strcuture
%     a.song = 0;
% % if 'birdinfo' (default = 1) info about bird
%     a.birdID = 0; % at this point I assume this is an integer
%     a.age = 0; % in days
% % if 'stereo' (default = 0) info for stereo data
%     a.chan = 0; % 1=left, 2=right
%     a.pow = [0 0]; % rms power in chan 1, 2
% % if 'rawdatainfo' (default = 0) retain info from reading raw data 
%     a.timestamp = 0;
%     a.samplestamp = 0;
%     a.continue = 0;

% defaults
params.songptr = 1; % add field for pointer to song structure
params.birdinfo = 1; % add field bird and age
params.stereo = 1; % info for stereo data
params.sessioninfo = 1; % add field for sessions etc
params.rawdatainfo = 0; %fields related to reading raw data


N = 1;
if nargin > 0
    if isnumeric(varargin{1})
        N = varargin{1};
        varargin = varargin(2:end);
    end
    params = parse_pv_pairs(params,varargin);
end

% required of all song structures
a.fs = 0; % 
a.date = 0;
a.time = 0;
a.start = 0;
a.length = 0;
a.songID = 0;
a.sessionID = 0;
% pointer to song in corresponding strcuture
if params.songptr
    a.song = 0;
end
% % info needed for labeling
% if params.labels
%     a.label = 0;
%     a.label2= 0;
%     a.label3 = 0;
%     a.labeler = 0;
%     a.labeltime = 0;
% end
% info about bird
if params.birdinfo
    a.birdID = 0;
    a.age = 0;
end
% info for stereo data
if params.stereo
    a.chan = 0;
    a.pow = [0 0];
end
% include info from reading raw data 
if params.rawdatainfo
    a.timestamp = 0;
    a.samplestamp = 0;
    a.continue = 0;
end

if N>1
    a = repmat(a,N,1);
end
clips.a = a;
