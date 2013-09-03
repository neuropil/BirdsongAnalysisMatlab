function [spec f t] = calcspec(clipa, varargin)
% [spec f t] = calcspec(clipa, varargin)
% calculate spectrogram for a single clip 
% clipa is clips.a structure for that clip
% by default will search for data on the server
% 'wavedir',DIRECTORYNAME can be used to specify a directory

spec = [];
f = [];
t = [];

calsp.wavdir = '';
calsp.filename = '';
calsp.datadir = datadirlist;
calsp.specparams = defaultspecparams;
calsp = parse_pv_pairs(calsp,varargin);
calsp.datadir = finddir(calsp.datadir);


if isempty(calsp.filename)
    calsp.filename = [sessiondate 'Ft_' num2str(clipa.songID) '.wav'];
end
% if bmk get wav data from data server
if isempty(calsp.wavdir)
    sessiondate = [num2str(clipa.sessionID) '-' datestr(clipa.date,'yyyymmdd')];
    calsp.wavdir =  [calsp.datadir filesep 'FtSongWav' filesep 'FtSong' num2str(clipa.sessionID) ...
        filesep sessiondate 'Ft' filesep sessiondate 'Ft_wav'];
end
fullfilename = fullfile(calsp.wavdir, calsp.filename);
if ~exist(fullfilename)
    disp(['Can''t find wav file ' fullfilename '. Aborting.']); OK = 0; return;
end
[songdata fs] =  wavread(fullfilename);
if ~isfield(clipa,'chan')
    clipa.chan = 1;
end
[spec f t] = ftr_specgram(songdata(clipa.start-1+(1:clipa.length),clipa.chan),calsp.specparams);

