function viewh = dispclipsong(clipind,varargin)
% dispclipsong(CLIPIND,varargin)
% bring up SongBrowser view to display song containing clip
% 

dclip.song = [];
dclip.clips = [];
dclip.bmkfile = [];
dclip.bmkpath = [];
dclip.lblfile = [];
dclip.lblpath = [];
dclip.labels = [];
dclip.wavpath = [];
dclip.data = [];
dclip.rootdir = rootdirlist;
dclip.datadir = datadirlist;
dclip.wavpath = []; % directory of wav files for dbk files
dclip.view = 'sb3view'; % assume no labels unless they can be located
dclip.viewh = -1;
dclip = parse_pv_pairs(dclip,varargin);
dclip.rootdir = finddir(dclip.rootdir);
dclip.datadir = finddir(dclip.datadir);

% if don't have song info
ext = ''; % bookmark extension - indicates where to locate wav file
if isempty(dclip.song)
    if ~(exist(fullfile(dclip.bmkpath,dclip.bmkfile))==2)
        [dclip.bmkfile dclip.bmkpath] = uigetfile({'*.bmk;*.dbk','bookmark file (*.bmk;*.dbk)'; '*.*',  'All Files (*.*)'}, 'Select bookmark file.');
        if dclip.bmkfile==0 return; end
    end
    load(fullfile(dclip.bmkpath,dclip.bmkfile),'songs','clips','-mat');
    dclip.song = songs;
    dclip.song.a = songs.a(clips.a(clipind).song);
    dclip.clips = clips;
    dclip.clips.a = clips.a(dclip.song.a.startclip:dclip.song.a.endclip);
    clipind = clipind-dclip.song.a.startclip+1;
    % get bmkfile extension in case data is not specified
    [path name ext] = fileparts(fullfile(dclip.bmkpath,dclip.bmkfile));
end

% clips are empty, check song structure
if isempty(dclip.clips)
    if isfield(dclip.song,'clips')
        dclip.clips = dclip.song.clips;
    else
        disp('Could not locate clips. Aborting.'); return;
    end
end
% % go get song and clip data from sng file if not specified
% if isempty(dclip.song)  || isempty(dclip.clips) 
%     load([dclip.datadir filesep 'FtSongWav' filesep 'FtSong' sessstr filesep ...
%          name filesep name '.sng'],'-mat');
%     songs.a = songs.a(dclip.clips.a(clipind).songID);
%     clipinds = songs.a.startclip:songs.a.endclip;
%     clips.a = dclip.clips.a(clipinds);
% end

% get song data
if isempty(dclip.data)
    if isempty(dclip.wavpath)
        dirname = [dclip.bmkpath name '_wav'];
        if ~(exist(dirname)==7)
            sessstr = num2str(dclip.clips.a(1).sessionID);
            songname = [sessstr '-' datestr(dclip.clips.a(1).date,'yyyymmdd') 'Ft'];
            dirname = [dclip.datadir filesep 'FtSongWav' filesep 'FtSong' sessstr filesep songname filesep songname '_wav'];
        end
    else
        dirname = dclip.wavpath;
    end
    if isfield(dclip.song.a,'filename')
        wavfile = dclip.song.a.filename;
        if exist(fullfile(dirname,wavfile))==2
            filename = fullfile(dirname,wavfile);
            if (exist(filename,'file')==2)
                havefile = 1;
            end
        end
    elseif isfield(dclip.song.a,'sessionID') & isfield(dclip.song.a,'date') & isfield(dclip.song.a,'songID') 
        filename = fullfile(dirname,wavname(dclip.song.a));
        if (exist(filename,'file')==2)
            havefile = 1;
        end
    end
    if (exist(filename,'file')==2)
        havefile = 1;
    end

    if ~havefile
        [tmpfile tmppath] = uigetfile({'*.wav','wav files (*.wav)'; '*.*',  'All Files (*.*)'},'Find wav file');
        if tmpfile==0 return; end
        filename = fullfile(tmppath,tmpfile);
    end
    dclip.data = wavread(filename);

%     filename = [dirname filesep songname '_' num2str(dclip.clips.a(clipind).songID) '.wav'];
%     if exist(filename)
%         dclip.data = wavread(filename);
%     else
%         disp(['Cannot find ' filename ' in dispclipsong. Check connection to data server.']);
%         viewh = [];
%         return
%     end
end
dclip.song.d = dclip.data;
dclip.song.clips = dclip.clips;
% get labels
if isempty(dclip.labels) & exist(fullfile(dclip.lblpath,dclip.lblfile))==2
    load(fullfile(dclip.lblpath,dclip.lblfile),'-mat');
    dclip.labels = labels;
end
if ~isempty(dclip.labels)
    if length(dclip.labels.a)>length(dclip.song.a.clipnum)
        dclip.labels.a = dclip.labels.a(dclip.song.a.startclip:dclip.song.a.endclip);
    end
    dclip.song.labels = dclip.labels;
    if ~ishandle(dclip.viewh)
        [view dclip.viewh] = feval('sb3viewlbl');
    end
    viewh = feval('sb3viewlbl','feval',dclip.viewh,'loadsong',dclip.song,'selectclips',clipind);
else
    if ~ishandle(dclip.viewh)
        [view dclip.viewh] = feval('sb3view');
    end
    selectlim = (dclip.clips.a(clipind).start+[0 dclip.clips.a(clipind).length])*(1000/dclip.clips.a(clipind).fs);
    viewh = feval('sb3view','feval',dclip.viewh,'loadsong',dclip.song,'selectlim',selectlim);
end

% % pass the limits of the clip (in msec) to viewer
% % initialize viewer
% if ~ishandle(dclip.viewh)
%     [view dclip.viewh] = feval(dclip.view);
% end
% viewh = dclip.viewh;
% % set song structure and call viewer
% song = dclip.song;
% song.d = dclip.data;
% clipinds = song.a.startclip:song.a.endclip;
% song.clips = dclip.clips;
% song.clips.a = song.clips.a(clipinds);

    
    