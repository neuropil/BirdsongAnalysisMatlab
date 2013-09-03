function  calcspecs(varargin)
% calcspecs(varargin)
% calculate spectrograms and amplitude for a selection of songs

% calsp.songdirname = [];
calsp.bmkfile = [];
calsp.bmkpath = [];
calsp.specparams = defaultspecparams;
calsp.freqrange = [.7 7];
calsp.thresh = .25;
calsp.datadir = datadirlist;

calsp = parse_pv_pairs(calsp,varargin);
calsp.datadir = finddir(calsp.datadir);
if isempty(calsp.datadir)
    disp('Can''t find data directory. Check connection to server.');
end

% get songs from bookmark file
if isempty(calsp.bmkfile)
    [calsp.bmkfile calsp.bmkpath] = uigetfile({'*.bmk;*.dbk','Bookmark files (*.bmk;*.dbk)';'*.*','All files (*.*)'},...
                                                        'Select bookmark file','Select file');
    if calsp.bmkfile==0; return; end
end
load(fullfile(calsp.bmkpath,calsp.bmkfile),'clips','songs','-mat');
% separate bmk file into parts
[bmkpath bmkname bmkext] = fileparts(fullfile(calsp.bmkpath,calsp.bmkfile));

% make directory to save spec data into
if ~exist([bmkpath filesep bmkname '_spec'],'dir')
    mkdir([bmkpath filesep bmkname '_spec']);
end
specparams  = calsp.specparams;
freqrange = calsp.freqrange;
thresh = calsp.thresh;
save(fullfile([bmkpath filesep bmkname '_spec'],'specparams.mat'),'specparams','freqrange');

% initialize length/edge data
speclens = zeros(length(clips.a),1);
cliplens = zeros(length(clips.a),1);
clipedges = zeros(length(clips.a),2);
wb = waitbar(0,'Calculating spectrograms and amplitudes');
% set directory if local
havedir = 0;
wavdir = [calsp.bmkpath bmkname '_wav'];
if exist(wavdir)==7
    havedir = 1;
end
% process one song at a time
for i=1:length(songs.a)
    clipinds = songs.a(i).startclip:songs.a(i).endclip;
    % get file
    filename = songs.a(i).filename;
    if isempty(filename)
        sessiondate = [num2str(songs.a(i).sessionID) '-' datestr(songs.a(i).date,'yyyymmdd')];
        filename = [sessiondate 'Ft_' num2str(songs.a(i).songID) '.wav'];
    end
    if ~havedir
        wavdir =  [calsp.datadir filesep 'FtSongWav' filesep 'FtSong' num2str(songs.a(i).sessionID) ...
            filesep sessiondate 'Ft' filesep sessiondate 'Ft_wav'];
    end
    fullfilename = fullfile(wavdir, filename);
    if ~exist(fullfilename)
        disp(['Can''t find wav file ' fullfilename '. Aborting.']); OK = 0; return;
    end
    [songdata fs] =  wavread(fullfilename);
    
    
    for c = clipinds
        % calculate specgram and amplitude for each channel
        if size(songdata,2)>1
            [spec f t] = ftr_specgram(songdata(clips.a(c).start-1+(1:clips.a(c).length),clips.a(c).chan),calsp.specparams);
            amp = ftr_amp(abs(spec),f,'freqrange',calsp.freqrange);
            % calculate specgram and amplitude for second channel
            [spec2 f t] = ftr_specgram(songdata(clips.a(c).start-1+(1:clips.a(c).length),3-clips.a(c).chan),calsp.specparams);
            amp2 = ftr_amp(abs(spec2),f,'freqrange',calsp.freqrange);
        else
            [spec f t] = ftr_specgram(songdata(clips.a(c).start-1+(1:clips.a(c).length),1),calsp.specparams);
            amp = ftr_amp(abs(spec),f,'freqrange',calsp.freqrange);
           amp2 = zeros(length(amp),1)';
        end
        % calculate segmentation edges based on amplitude envelope
        if calsp.thresh>0
            abovethreshinds = find(amp>thresh);
            if length(abovethreshinds)>1
                edges = [min(abovethreshinds)  max(abovethreshinds)];
            else
                edges = [1 size(amp,1)];
            end
        else
            edges = [1 size(amp,1)];
        end
        speclens(c) = size(amp,1);
        clipedges(c,:) = edges;
        cliplens(c) = diff(edges)+1;
        save(fullfile([bmkpath filesep bmkname '_spec'],...
                    [bmkname '_spec_' num2str(c) '.mat']),'spec','f','t','amp','amp2','thresh','edges','-mat');
    end
    waitbar(i/length(songs.a),wb); 
end

if ishandle(wb) close(wb); end

save([bmkpath filesep bmkname '_spec' filesep 'speclens.mat'],'speclens');
save([bmkpath filesep bmkname '_spec' filesep 'clipseg_' num2str(calsp.thresh*100) '.mat'],'speclens','cliplens','clipedges','thresh');
       
    
    

    
    