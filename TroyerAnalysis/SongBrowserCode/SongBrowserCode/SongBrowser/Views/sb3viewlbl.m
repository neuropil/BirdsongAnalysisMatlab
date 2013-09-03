function [sbview figh] = sb3viewlbl(varargin)
%   sbview figure #1 for SongBrowser version 3
%   has the following elements
%    line of zoom control buttons
%    oscillogram for navigation
%    scroll bar for navigation
%    label axis
%    spectrogram
%    spectrogram slice
%    oscillogram blow up window
%

% if first argument is 'feval', evaluate method
% second argument is assumed to be figure handle
if nargin>0
    if ischar(varargin{1})
        if strcmp(varargin{1},'feval')
            figh = varargin{2};
            if ~ishandle(figh)
                disp('Argument after ''feval'' must be figure handle.');
                figh = -1;
                return;
            end
            sbview = get(figh,'userdata');
            figh = sbview.figh;
            % make command string
            feval(eval(['sbview.' varargin{3}]),figh,varargin{4:end});
            return
        end
    end
end
% % if struct, assume first variable is song struct
% if isstruct(varargin{1}) 
%     song = varargin{1};
%     argbeginind = 2;
% else
    song = [];
    argbeginind = 1;
% end

reinit = 1;
% look for window; if found, extract (and overwrite) data; if not reinitialize
figh =findobj(0,'name', 'SongBrowser Label View');
if ~isempty(figh)
    sbview = get(figh,'userdata');
    reinit = 0;
    % overwrite arguments explicitly set in varargin, including possible reinit
    sbview = parse_pv_pairs(sbview,varargin(argbeginind:end));
end

if reinit
    % LINKS TO OTHER SONGBROWSER OBJECTS
%     sbview.template = 'sb3temp';
%     sbview.templateh = -1;
    sbview.sourceh = -1;
    sbview.bmksrc = 'sb3src_bmklbl'; % name of bmksrc function to call when bookmarking songs 
    sbview.bmksrch = []; % figure handle of src_bmk to recieve bookmarked songs  
    %Alex edit
    sbview.parentnexthandle=[]; % function handle of src_sng or src_bmklbl to call done function on
    % OPTIONS AND PARAMETERS
    sbview.playsong = 1; % flags whether to play song on load
    sbview.inittimelim = [0 1500]; % initial time limits upon loading song, if empty use song length
    sbview.timebuffer = [-50 50]; % buffers surrounding song (msec)
    sbview.mvsize = 20; % how far to move window on clicking move buttons
    sbview.zoomfac = sqrt(2); % factor to zoom in/out
    sbview.initzoom = 0; % if >0, initial zoom set to this scale (msec)
    sbview.curtimewidth = 10; % width of current time window (msec)
    sbview.focus = []; % can be used to retain focus in another figure (e.g. a source)
    sbview.labeler = 1; % person labeling song
    sbview.labelval = ' '; % value in label
    sbview.label2val = 1; % value in label2
    sbview.corruptedlabel = 0; % whether a labeled clip is corrupted
    sbview.lblposfrac = .25; % fix current clip as this fraction of time window, if empty do not fix
    sbview.lblautofwd = 1;
    sbview.matchcase = 0;
    sbview.splitmerge = 0;
    % DISPLAY VARIABLES
    sbview.figpos = [0.3 0.35 0.7 0.45];
    sbview.fontsize = 11;
    sbview.ctrlfontsize = 11;
    sbview.labelfontsize = 11;
    sbview.colormap = 'hot';
    sbview.selectcol = .8*[1 1 1];
    sbview.clipselectcol = .85*[0 1 0];
    sbview.gapcol = .75*[0 1 0];
    sbview.corruptedcolor = 'r';
    sbview.labelers = {'unknown','Todd','Meagan'};
    %  INTERNAL STATE VARIABLES AND FLAGS
    sbview.song = [];
    sbview.index = [];
    sbview.fs = [];
    sbview.features = [];
    sbview.mousemode = 1; % 2 = segment clips
    sbview.selectclips = 1; % current clip selecion
    sbview.selectlim = [0 100]; % current time selection
    sbview.curtime = 10; % current time marker
    sbview.timerange = [0 1000]+sbview.timebuffer;
    sbview.timelim = [0 1000]+sbview.timebuffer;
    sbview.curtime = 10;
    sbview.zoomhist = zeros(50,2); % 50 move zoom buffer
    sbview.zmhistn = 1; % current location in move history
    sbview.maxn = 1; % max index in move history
    % stuff for button callbacks
    sbview.curaxind = [];
    sbview.butpressed = 0; % 1 = left button press
    sbview.hasmoved = 0;
    sbview.curpt = [];
    sbview.lastpt = [];
    sbview.keystr = '';    
    sbview.stdlabel = true; % whether keystr should be interpreted according to standard labeling scheme
    % HANDLES AND AXES
    sbview.figh = [];
    sbview.ax = [];
    sbview.labelh = -1;
    sbview.selecth = -1*ones(5,1);
    sbview.clipselecth = -1;
    sbview.uictrlh = [];
    sbview.uictrl = [];
    sbview.curtimeh = [];
    sbview.curtimeedgeh = [];
    % METHODS
    sbview.dispFcn = @dispFcn; 
    sbview.loadsong = @loadsong; 
    sbview.updatesong = @updatesong; 
    sbview.assignlabeler = @assignlabeler;
    sbview.sourceupdate = []; 
    % sbview.refresh = @refresh;
    sbview.zoom = @zoom;
    set(sbview.figh,'ResizeFcn',@winresizeFcn);

    sbview = parse_pv_pairs(sbview,varargin(argbeginind:end));
    sbview=init(sbview);
end

if ~isempty(song)
    sbview.song = song;
end
set(sbview.figh,'userdata',sbview);
if ~isempty(sbview.song)
    feval(sbview.loadsong,sbview.figh,sbview.song);
end
figh = sbview.figh;

% --------------------------------------------------------------------
function sbview = init(sbview)
%% Create the sbview figure and initialize structure

sbview.figh = figure('numbertitle','off', ...
    'color', get(0,'defaultUicontrolBackgroundColor'), ...
    'name','SongBrowser Label View', ...
    'doublebuffer','on', 'backingstore','off', ...
    'integerhandle','off', 'vis','on', ...
    'units','normal','pos',sbview.figpos,...
    'PaperPositionMode','auto');
%     'menubar','none', 'toolbar','none', ...
set(sbview.figh,...
    'WindowButtonDownFcn',@buttdownFcn,...
    'WindowButtonUpFcn',@buttupFcn,...
    'WindowButtonMotionFcn',@buttmotionFcn,...
    'KeyPressFcn',@keypressFcn,...
    'ResizeFcn',@winresizeFcn);
sbview.menu_export = menu_export(sbview.figh);
sbview.menu_play = menu_play(sbview.figh);


%% add and position controls
sbview = adduicontrols(sbview);  % see below
uictrlrow(sbview.uictrlh,sbview.figh,sbview.uictrl.gap,.5,.95,...
    'verticalalignment','middle','horizontalalignment','center');

xleft = .05;
width = .85;
n = 0;

% full oscillogram axis for navigation
n = n+1;
height = .075; bottom = .775;
ax.names{n} = 'fulloscgram';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'ytick',[],'xaxislocation','top');
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.selecth{n} = -1; % negative handle as placeholder
ax.showcur(n) = 1;
ax.curh(n) = -1; % negative handle as placeholder
ax.showcuredge(n) = 0;
ax.curedgeh(n,:) = [-1 -1]; % negative handle as placeholder
ax.curcol{n} = 'g';
ax.ylim(n,:) = [-1 1];

% scrollbar axis
n = n+1;
height = .025; bottom = .75;
ax.names{n} = 'scroll';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'ytick',[],'xtick',[]);
ax.ylim(n,:) = [0 1];
ax.scrh = rectangle('position',[sbview.timelim(1) 0 diff(sbview.timelim) 1],'facecolor',.5*ones(1,3));

% label axis
n = n+1;
height = .05; bottom = .65;
ax.names{n} = 'label';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'ytick',[],'xtick',[]);
ax.ylim(n,:) = [0 1];
ax.selecth{n} = -1; % negative handle as placeholder

% oscillogram axis
n = n+1;
height = .075; bottom = .525;
ax.names{n} = 'oscgram';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'ytick',[],'xaxislocation','top');
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.selecth{n} = -1; % negative handle as placeholder
ax.showcur(n) = 1;
ax.curh(n) = -1; % negative handle as placeholder
ax.showcuredge(n) = 0;
ax.curedgeh(n,:) = [-1 -1]; % negative handle as placeholder
ax.curcol{n} = 'g';
ax.ylim(n,:) = [-1 1];

% spectrogram axis
n = n+1;
height = .275; bottom = .25;
ax.names{n} = 'specgram';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.selecth{n} = -1; % negative handle as placeholder
ax.showcur(n) = 1;
ax.curh(n) = -1; % negative handle as placeholder
ax.showcuredge(n) = 1;
ax.curedgeh(n,:) = [-1 -1]; % negative handle as placeholder
ax.curcol{n} = 'm';
ax.ylim(n,:) = [0 10]; % up to 10 kZ
ylabel('kHz');

% slice of spectrogram
n = n+1;
thiswidth = .05;
ax.names{n} = 'specslice';
ax.h(n) = axes('position',[xleft+width bottom thiswidth height],'tag',ax.names{n});
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.showcur(n) = 0;
ax.ylim(n,:) = [0 10];
set(ax.h(n),'yaxislocation','right');
ylabel('kHz');

% blow up of oscillogram
n = n+1;
height = .125; bottom = .05;
ax.names{n} = 'oscblowup';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
% set(ax.h(n),'ytick',[]);
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.showcur(n) = 1;
ax.curh(n) = -1; % negative handle as placeholder
ax.showcuredge(n) = 0;
ax.curedgeh(n,:) = [-1 -1]; % negative handle as placeholder
ax.curcol{n} = 'g';
ax.ylim(n,:) = [-1 1];

colormap(sbview.colormap);

sbview.ax = ax;

%% initialize feature list
n= 0;

n=n+1;
sbview.ftr.names{n} = 'oscgram';
sbview.ftr.obj{n} = ftr_oscgramobj('starttime',sbview.timebuffer(1));

n=n+1;
sbview.ftr.names{n} = 'specgram';
sbview.ftr.obj{n} = ftr_specgramobj('starttime',sbview.timebuffer(1));    
    
    
%% save 
set(sbview.figh,'userdata',sbview);

%-----------------------------------------------------------------------
function updatesong(figh,varargin)
% close song in view, if sbview.sourceupdate is a function handle
% call that function
% by default this function deletes the song and returns to blank display
% can be shut off by setting varargin to be 'noreset'

sbview = get(figh,'userdata');
% close existing song in source
if ishandle(sbview.sourceh)
    if isa(sbview.sourceupdate,'function_handle')
        feval(sbview.sourceupdate,sbview.sourceh,sbview.song,sbview.index);
    else
        sbview.sourceupdate = []; 
    end
end
if nargin==2
    if strcmpi(varargin{1},'noreset')
        return;
    else
        disp(['Unexpected argument ' varargin{1} ' in updatesong']);
    end
end
% reset and display
sbview.song = [];
sbview.index = [];
sbview.fs = [];
sbview.sourceh = [];
sbview.sourceupdate = [];
set(sbview.figh,'userdata',sbview);
dispFcn(sbview);


%-----------------------------------------------------------------------
function sbview = loadsong(figh,song,varargin)
% load song and calculate features
% if the song needs to be closed back in the source, then varargin should
% have the following value parameter pairs (values are examples):
% 'sourceh',bmk.fig, 'index',67,'updatesong', @closefn

sbview = get(figh,'userdata');
% error checking  
if ~isfield(song,'d')
    error('sb3view:FormatErr','No data field ''d''.'); return
end
if ~isfield(song.a,'fs')
    error('sb3view:FormatErr','No sample frequency field ''fs''.'); return
end
if ~isfield(song.clips.a,'length')
    error('sb3view:FormatErr','No ''length'' field in clip variable passed to loadsong.'); return
end
% add channel field and set to one if not specified in clips or song structure
if ~isfield(song.a,'chan')
        song.a.chan = 1;
end
if ~isfield(song.clips.a,'chan')
    for i=1:length(song.clips.a)
        song.clips.a(i).chan = 1;
    end
end
% update existing song in source no need to reset current song since we'll
% be overwriting
updatesong(sbview.figh,'noreset');
% set source index and close function handle
params.sourceh = -1;
params.index = 0;
params.updatesong = [];
params.selectclips = 1;
params = parse_pv_pairs(params,varargin);
sbview.sourceh = params.sourceh;
sbview.index = params.index;
sbview.sourceupdate = params.updatesong;
sbview.selectclips = params.selectclips;
if ~isfield(song,'labels')
    song.labels = blanklabels(length(song.clips.a));
end
sbview.keystr = '';
sbview.stdlabel = true;

% set info strings using birdID and age if available
infostr = '';
if isfield(song.a,'birdID')
    if ~isempty(song.a.birdID)
        infostr = [infostr 'BirdID = ' num2str(song.a.birdID)];
    end
end
if isfield(song.a,'age')
    if ~isempty(song.a.age)
        infostr = [infostr '; age = ' num2str(song.a.age)];
    end
end
infostr = [infostr ' '];
infoctrlind = find(strcmpi(sbview.uictrl.tag,'infotext'));
set(sbview.uictrlh(infoctrlind),'string',infostr);

% set filename string
filenamectrlind = find(strcmpi(sbview.uictrl.tag,'filenametext'));
set(sbview.uictrlh(filenamectrlind),'string',song.a.filename);

% reset zoom history buffer and time ranges
sbview.zoomhist(1,:) = sbview.timelim;
sbview.timerange = [0 size(song.d,1)*1000/song.a.fs]+sbview.timebuffer;
if ~isempty(sbview.inittimelim)
    sbview.timelim = sbview.inittimelim+sbview.timebuffer;
else
    sbview.timelim = sbview.timerange;
end
% zero pad song with buffers for display
padsamples = round(sbview.timebuffer*song.a.fs/1000);
song.d = [zeros(-padsamples(1),size(song.d,2));...
                    song.d; ...
                  zeros(padsamples(2),size(song.d,2))];
sbview.song = song;
sbview.fs = song.a.fs/1000;
%% calculate features
for i=1:length(sbview.ftr.obj)
    sbview.ftr.obj{i} = feval(sbview.ftr.obj{i}.calcFcn,song,sbview.ftr.obj{i});
end

%% set initial selection to first clip
% sbview.selectclips = 1;
sbview.selectlim = [sbview.song.clips.a(sbview.selectclips(1)).start ...
    sbview.song.clips.a(sbview.selectclips(end)).start+sbview.song.clips.a(sbview.selectclips(end)).length]/sbview.fs;
% center selected clip
if sbview.lblposfrac >0
    clippos = sbview.lblposfrac*diff(sbview.timelim);
    sbview.timelim = sbview.timelim(1)-clippos+sbview.timelim+sbview.selectlim(1);
end

% save data and display/play
set(sbview.figh,'userdata',sbview);
sbview = dispFcn(sbview);
if sbview.playsong
%     player=audioplayer(song.d,song.a.fs);
%     play(player);    
    sound(song.d,song.a.fs);
end

%-----------------------------------------------------------------------
function sbview = dispFcn(sbview)
% display

% hard coded options
selectlinewidth = 1;
selectlinecol = 'w';
curtimelinewidth = 2;
showcurtimeedge = [0 1 0]; % flags for the three axes
curtimeedgewidth = 1;
curtimeedgestyle = '--';

% get index of features
oscftrind = find(strcmpi(sbview.ftr.names,'oscgram'));
specftrind = find(strcmpi(sbview.ftr.names,'specgram'));

% delete old select rectangles
delete(sbview.selecth(ishandle(sbview.selecth)));
delete(sbview.clipselecth(ishandle(sbview.clipselecth)));

%%%%%% oscillogram axis
axind = find(strcmpi(sbview.ax.names,'fulloscgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display selected times 
sbview.ax.selecth{axind} = rectangle('position',[sbview.selectlim(1) sbview.ax.ylim(axind,1) ...
                                        max(diff(sbview.selectlim),.1) diff(sbview.ax.ylim(axind,:))],...
                            'erasemode','xor','facecolor',sbview.selectcol,'edgecolor','none');
% display oscillogram
sbview.ax.ftrh{axind}  = feval(sbview.ftr.obj{oscftrind}.dispFcn,sbview.ftr.obj{oscftrind});
% display current time
if sbview.ax.showcur(axind)
    if sbview.ax.showcuredge(axind)
        sbview.ax.curedgeh(axind,1) = line(sbview.curtime-sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
        sbview.ax.curedgeh(axind,2) = line(sbview.curtime+sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
    end
    sbview.ax.curh(axind) = line(sbview.curtime*[1 1],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','linewidth',curtimelinewidth,'color',sbview.ax.curcol{axind});
end
% set axis limits
set(sbview.ax.h(axind),'xlim',sbview.timerange);
set(sbview.ax.h(axind),'ylim',sbview.ax.ylim(axind,:));

%%%%% scroll axis
axind = find(strcmpi(sbview.ax.names,'scroll'));
axes(sbview.ax.h(axind));
set(sbview.ax.h(axind),'xlim',sbview.timerange);
set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);

%%%%% label axis
if ~isempty(sbview.song)
    if ~isempty(sbview.song.clips)
        axind = find(strcmpi(sbview.ax.names,'label'));
        axes(sbview.ax.h(axind));
        cla; hold on
        % plot gaps
        gapon = [sbview.timerange(1); [sbview.song.clips.a.start]'/sbview.fs+[sbview.song.clips.a.length]'/sbview.fs];
        gapoff = [[sbview.song.clips.a.start]'/sbview.fs; sbview.timerange(2)];
    %     [sbview.song.clips.start sbview.song.clips.length]
        if sum(gapoff<gapon)>0
            [gapon gapoff]
        end
        for i=1:length(gapon)
            sbview.gaph(i) = rectangle('position',[gapon(i) 0 max(gapoff(i)-gapon(i),.1) 1],'facecolor',sbview.gapcol,'edgecolor',sbview.gapcol);
        end
        % select rectangle
        sbview.ax.selecth{axind} = rectangle('position',[sbview.selectlim(1) sbview.ax.ylim(axind,1) ...
                                            max(diff(sbview.selectlim),.1) diff(sbview.ax.ylim(axind,:))],...
                                'erasemode','xor','facecolor',sbview.selectcol,'edgecolor','none');
        % plot labels
        for i=1:length(sbview.song.labels.a)
%             str = labelstr(sbview.song.labels.a(i).label,sbview.song.labels.a(i).label2,sbview.song.labels.a(i).label3);
            str = makelabelstr(sbview.song.labels.a(i).label,sbview.song.labels.a(i).label2,sbview.song.labels.a(i).label3);
            sbview.labelh(i) = text((sbview.song.clips.a(i).start+sbview.song.clips.a(i).length/2)/sbview.fs,.5,str);
            set(sbview.labelh(i),'fontsize',sbview.labelfontsize,...
                'horizontalalignment','center','verticalalignment','middle','clipping','on');
            if isfield(sbview.song.labels.a,'corrupted')
                if sbview.song.labels.a(i).corrupted ==1
                    set(sbview.labelh(i),'color',sbview.corruptedcolor);
                else
                    set(sbview.labelh(i),'color','k');
                end
            end
        end
    end
end
set(sbview.ax.h(axind),'xlim',sbview.timelim);

%%%%%% oscillogram axis
axind = find(strcmpi(sbview.ax.names,'oscgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display selected times 
sbview.ax.selecth{axind} = rectangle('position',[sbview.selectlim(1) sbview.ax.ylim(axind,1) ...
                                        max(diff(sbview.selectlim),.1) diff(sbview.ax.ylim(axind,:))],...
                            'erasemode','xor','facecolor',sbview.selectcol,'edgecolor','none');
% display oscillogram
sbview.ax.ftrh{axind}  = feval(sbview.ftr.obj{oscftrind}.dispFcn,...
                                                sbview.ftr.obj{oscftrind});
% display current time
if sbview.ax.showcur(axind)
    if sbview.ax.showcuredge(axind)
        sbview.ax.curedgeh(axind,1) = line(sbview.curtime-sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
        sbview.ax.curedgeh(axind,2) = line(sbview.curtime+sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
    end
    sbview.ax.curh(axind) = line(sbview.curtime*[1 1],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','linewidth',curtimelinewidth,'color',sbview.ax.curcol{axind});
end
% set axis limits
set(sbview.ax.h(axind),'xlim',sbview.timelim);

%%%%% specgram axis
axind = find(strcmpi(sbview.ax.names,'specgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display spectrogram
sbview.ax.ftrh{axind}  = feval(sbview.ftr.obj{specftrind}.dispFcn,...
                                                sbview.ftr.obj{specftrind});
% display selectlimits
sbview.ax.selecth{axind}(1) = line(sbview.selectlim(1)*[1 1],sbview.ax.ylim(axind,:), ...
                 'color',selectlinecol,'linewidth',selectlinewidth);
sbview.ax.selecth{axind}(2) = line(sbview.selectlim(2)*[1 1],sbview.ax.ylim(axind,:), ...
                 'color',selectlinecol,'linewidth',selectlinewidth);
% display current time
if sbview.ax.showcur(axind)
    if sbview.ax.showcuredge(axind)
        sbview.ax.curedgeh(axind,1) = line(sbview.curtime-sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
        sbview.ax.curedgeh(axind,2) = line(sbview.curtime+sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
    end
    sbview.ax.curh(axind) = line(sbview.curtime*[1 1],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','linewidth',curtimelinewidth,'color',sbview.ax.curcol{axind});
end
% set axis limits
set(sbview.ax.h(axind),'xlim',sbview.timelim);
set(sbview.ax.h(axind),'ylim',sbview.ax.ylim(axind,:));

%%%%% spectral slice  axis
axind = find(strcmpi(sbview.ax.names,'specslice'));
axes(sbview.ax.h(axind));
cla; hold on
% find current spectral slice
specftrind = find(strcmpi(sbview.ftr.names,'specgram'));
xvals = sbview.ftr.obj{specftrind}.xvals;
xvals = xvals(1):xvals(2):xvals(3);
[minval sliceind] = min(abs(xvals-sbview.curtime));
tmpyvals = sbview.ftr.obj{specftrind}.yvals;
yvals = tmpyvals(1):tmpyvals(2):tmpyvals(3);
sbview.ax.ftrh{axind} = plot(sbview.ftr.obj{specftrind}.d(:,sliceind),yvals);
set(sbview.ax.h(axind),'ylim',sbview.ax.ylim(axind,:));

%%%%% oscillogram blowup axis
axind = find(strcmpi(sbview.ax.names,'oscblowup'));
axes(sbview.ax.h(axind));
cla; hold on
% display oscillogram
sbview.ax.ftrh{axind}  = feval(sbview.ftr.obj{oscftrind}.dispFcn,...
                                                    sbview.ftr.obj{oscftrind});
% display current time
if sbview.ax.showcur(axind)
    if sbview.ax.showcuredge(axind)
        sbview.ax.curedgeh(axind,1) = line(sbview.curtime-sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
        sbview.ax.curedgeh(axind,2) = line(sbview.curtime+sbview.curtimewidth*[.5 .5],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','color',sbview.ax.curcol{axind},...
                 'linewidth',curtimeedgewidth,'linestyle',curtimeedgestyle);
    end
    sbview.ax.curh(axind) = line(sbview.curtime*[1 1],sbview.ax.ylim(axind,:), ...
                 'erasemode','xor','linewidth',curtimelinewidth,'color',sbview.ax.curcol{axind});
end
% set axis limits
set(sbview.ax.h(axind),'xlim',sbview.curtime+sbview.curtimewidth*[-.5 .5]);
% set(sbview.ax.h(axind),'ylim',sbview.ax.ylim(axind,:));
set(sbview.figh,'userdata',sbview);

%-------------------------------------------------------------------------
function  setcurtime(sbview)
% ajust display to reflect current time 

% get axis indices
fulloscind = find(strcmp(sbview.ax.names,'fulloscgram'));
oscind = find(strcmp(sbview.ax.names,'oscgram'));
specind = find(strcmp(sbview.ax.names,'specgram'));
specsliceind = find(strcmp(sbview.ax.names,'specslice'));
blowupind = find(strcmp(sbview.ax.names,'oscblowup'));

% adjust limit of blowup axis
xlim = sbview.curtime+sbview.curtimewidth*[-.5 .5];
set(sbview.ax.h(blowupind),'xlim',xlim);
% to set ylimits, need info from oscgram
oscftrind = find(strcmpi(sbview.ftr.names,'oscgram'));
xvals = sbview.ftr.obj{oscftrind}.xvals;
xvals = xvals(1):xvals(2):xvals(3);
xinds = find(xvals>=xlim(1) & xvals<=xlim(2));
ymax = max(abs(sbview.ftr.obj{oscftrind}.d(xinds,sbview.ftr.obj{oscftrind}.chan)));
if isempty(ymax)
    ymax = eps;
end
set(sbview.ax.h(blowupind),'ylim',ymax*[-1 1]);


% adjust markers of current time on all axes
% fulloscgram
if sbview.ax.showcur(fulloscind)
    set(sbview.ax.curh(fulloscind),'xdata',sbview.curtime*[1 1]);
end
if sbview.ax.showcuredge(fulloscind)
    set(sbview.ax.curedgeh(fulloscind,1),'xdata',(sbview.curtime-sbview.curtimewidth*.5)*[1 1]);
    set(sbview.ax.curedgeh(fulloscind,2),'xdata',(sbview.curtime+sbview.curtimewidth*.5)*[1 1]);
end
% oscgram
if sbview.ax.showcur(oscind)
    set(sbview.ax.curh(oscind),'xdata',sbview.curtime*[1 1]);
end
if sbview.ax.showcuredge(oscind)
    set(sbview.ax.curedgeh(oscind,1),'xdata',(sbview.curtime-sbview.curtimewidth*.5)*[1 1]);
    set(sbview.ax.curedgeh(oscind,2),'xdata',(sbview.curtime+sbview.curtimewidth*.5)*[1 1]);
end

% specgram
if sbview.ax.showcur(specind)
    set(sbview.ax.curh(specind),'xdata',sbview.curtime*[1 1]);
end
if sbview.ax.showcuredge(specind)
    set(sbview.ax.curedgeh(specind,1),'xdata',(sbview.curtime-sbview.curtimewidth*.5)*[1 1]);
    set(sbview.ax.curedgeh(specind,2),'xdata',(sbview.curtime+sbview.curtimewidth*.5)*[1 1]);
end

% find and display current spectral slice
% get index of features
specftrind = find(strcmpi(sbview.ftr.names,'specgram'));
xvals = sbview.ftr.obj{specftrind}.xvals;
xvals = xvals(1):xvals(2):xvals(3);
[minval sliceind] = min(abs(xvals-sbview.curtime));
tmpyvals = sbview.ftr.obj{specftrind}.yvals;
yvals = tmpyvals(1):tmpyvals(2):tmpyvals(3);
set(sbview.ax.ftrh{specsliceind}, 'xdata',sbview.ftr.obj{specftrind}.d(:,sliceind));

% oscgramblowup
if sbview.ax.showcur(blowupind)
    set(sbview.ax.curh(blowupind),'xdata',sbview.curtime*[1 1]);
end
if sbview.ax.showcuredge(blowupind)
    set(sbview.ax.curedgeh(blowupind,1),'xdata',(sbview.curtime-sbview.curtimewidth*.5)*[1 1]);
    set(sbview.ax.curedgeh(blowupind,2),'xdata',(sbview.curtime+sbview.curtimewidth*.5)*[1 1]);
end
xlim = sbview.curtime+sbview.curtimewidth*[-.5 .5];
oscftrind = find(strcmpi(sbview.ftr.names,'oscgram'));
xvals = sbview.ftr.obj{oscftrind}.xvals;
xvals = xvals(1):xvals(2):xvals(3);
tmpinds = (xvals>=xlim(1) & xvals<=xlim(2));
ymag = max(max(abs(sbview.ftr.obj{oscftrind}.d(tmpinds,:))));
set(sbview.ax.h(blowupind),'xlim',xlim,'ylim',max(ymag,.001)*[-1 1]);

%-------------------------------------------------------------------------
function  settimelim(sbview)
% ajust display to reflect current time limits
axnames = {'oscgram','label','specgram'};
for i=1:length(axnames)
	ind = strcmpi(sbview.ax.names,axnames{i});
    set(sbview.ax.h(ind),'xlim',sbview.timelim);
end
set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);

%-------------------------------------------------------------------------
function  setselect(sbview)
% ajust display to reflect selected time limits

axind = strcmpi(sbview.ax.names,'fulloscgram');
pos = get(sbview.ax.selecth{axind},'position');
set(sbview.ax.selecth{axind},'position',[sbview.selectlim(1) pos(2) max(diff(sbview.selectlim),.01) pos(4)]);

axind = strcmpi(sbview.ax.names,'label');
pos = get(sbview.ax.selecth{axind},'position');
set(sbview.ax.selecth{axind},'position',[sbview.selectlim(1) pos(2) max(diff(sbview.selectlim),.01) pos(4)]);

axind = strcmpi(sbview.ax.names,'oscgram');
pos = get(sbview.ax.selecth{axind},'position');
set(sbview.ax.selecth{axind},'position',[sbview.selectlim(1) pos(2) max(diff(sbview.selectlim),.01) pos(4)]);

axind = strcmpi(sbview.ax.names,'specgram');
set(sbview.ax.selecth{axind}(1),'xdata',sbview.selectlim(1)*[1 1]);
set(sbview.ax.selecth{axind}(2),'xdata',sbview.selectlim(2)*[1 1]);

%-------------------------------------------------------------------------
function  sbview = assignlabeler(figh)
% ajust display to reflect selected time limits
sbview = get(figh,'userdata');

list = sbview.labelers;
list{end+1} = 'New';
[lblerind OK] = listdlg('PromptString','Choose a labeler','ListString',list);
if OK==1
    if lblerind<length(list)
        sbview.labeler = lblerind;
    else
        newname = inputdlg('Enter your name','New Labeler');
        if ischar(newname)
            sbview.labelers{end+1} = newname;
            sbview.labeler = length(sbview.labelers);
        end
    end
end

% --------------------------------------------------------------------
function buttdownFcn(hco,eventStruct)
% button press in a particular axis or control button

sbview = get(hco,'userdata');

curptfig = get(gcf,'currentpoint')';
sbview.curaxind  = getaxis(sbview.ax.h,curptfig);

if ~isempty(sbview.curaxind)
    sbview.butpressed = 1;
    sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
    sbview.lastpt = sbview.curpt;
%     name = sbview.ax.names{sbview.curaxind};
%     switch name
%         case 'specgram'
%             ylim = get(sbview.ax.h(2),'ylim');
%             tmplim = sbview.curpt(1,1)+[0 1];
% %             set(sbview.selecth(5),'xdata',[tmplim(1)*ones(1,2) tmplim(2)*ones(1,2)],...
% %                                                         'facealpha',.33);
%         case 'label'
%     end
else
    sbview.butpressed = 0;
end
set(hco,'userdata',sbview);

% --------------------------------------------------------------------
function buttmotionFcn(hco,eventStruct)
% button motion function, general to fig
sbview = get(hco,'userdata');
% sbview.butpressed
switch sbview.butpressed
    case 1 % left button press     
            sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
            switch sbview.ax.names{sbview.curaxind}
                case {'fulloscgram','oscgram','specgram'}
                    sbview.selectlim = [min([sbview.curpt(1,1) sbview.lastpt(1,1)]) ...
                                           max([sbview.curpt(1,1) sbview.lastpt(1,1)])];
                    setselect(sbview);
%                         pos = get(sbview.selecth(1),'position');
%                         set(sbview.selecth(1),'position',[tmplim(1) pos(2) diff(tmplim) pos(4)]);
                case 'scroll'
                    diffpt = sbview.curpt(1,1)-sbview.lastpt(1,1); 
                    sbview.timelim = sbview.timelim+diffpt;
                    settimelim(sbview);
%                     labelind = find(strcmpi(sbview.ax.names,'label'));
%                     set(sbview.ax.h(labelind),'xlim',sbview.timelim);
%                     oscind = find(strcmpi(sbview.ax.names,'oscgram'));
%                     set(sbview.ax.h(oscind),'xlim',sbview.timelim);
%                     specind = find(strcmpi(sbview.ax.names,'specgram'));
%                     set(sbview.ax.h(specind),'xlim',sbview.timelim);
%                     set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
                    sbview.lastpt=sbview.curpt;
                case 'label'
                    range = [min(sbview.lastpt(1,1),sbview.curpt(1,1)) max(sbview.lastpt(1,1),sbview.curpt(1,1))];
                    selrange = [min(find(range(1)<([sbview.song.clips.a.start]+[sbview.song.clips.a.length])/sbview.fs)) ...
                                                    max(find(range(2)>[sbview.song.clips.a.start]/sbview.fs))];
                    if diff(selrange)>=0
                        sbview.selectclips = selrange(1):selrange(2);
                        sbview.selectlim = [sbview.song.clips.a(sbview.selectclips(1)).start ...
                            sbview.song.clips.a(sbview.selectclips(end)).start+sbview.song.clips.a(sbview.selectclips(end)).length]/sbview.fs;
                        setselect(sbview);
%                         if ishandle(sbview.clipselecth)
%                             set(sbview.clipselecth,'position',[clipselrange(1) 0 diff(clipselrange) 1]);
%                         else
%                             sbview.clipselecth = rectangle('position',[clipselrange(1) 0 diff(clipselrange) 1],...
%                                 'erasemode','xor','facecolor',sbview.song.clipselectcol,'edgecolor','none');
%                         end
%                         if ishandle(sbview.selecth(5))
%                             set(sbview.selecth(5),'xdata',[clipselrange(1)*ones(1,2) clipselrange(2)*ones(1,2)]);
%                         end
                    else
                        sbview.selectclips = 0;
%                         delete(sbview.clipselecth);
%                         if ishandle(sbview.selecth(5))
%                             set(sbview.selecth(5),'xdata',[sbview.curtime*ones(1,2) (sbview.curtime+.01)*ones(1,2)]);
%                         end
                    end
            end
            sbview.hasmoved = 1;
            set(hco,'userdata',sbview);
end

% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

sbview = get(hco,'userdata');
if sbview.butpressed
    if ~isempty(sbview.curaxind)
%         sbview.ax.names{sbview.curaxind}
        switch sbview.ax.names{sbview.curaxind}
            case {'fulloscgram','oscgram','specgram'}
                sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                if sbview.hasmoved
                    sbview.selectlim = [min(sbview.curpt(1,1),sbview.lastpt(1,1)) ...
                                           max(sbview.curpt(1,1),sbview.lastpt(1,1))];
                    set(hco,'userdata',sbview);
                    setselect(sbview);
                        sbview.selectlim = [sbview.song.clips.a(sbview.selectclips(1)).start ...
                            sbview.song.clips.a(sbview.selectclips(end)).start+sbview.song.clips.a(sbview.selectclips(end)).length]/sbview.fs;
%                     pos = get(sbview.selecth(1),'position');
%                     set(sbview.selecth(1),'position',[tmplim(1) pos(2) max(diff(tmplim),.01) pos(4)]);
%                     sbview.selectlim = tmplim;
%                     sbview = feval(sbview.dispFcn,sbview);
                else
                    sbview.curtime = sbview.curpt(1,1);
                    set(hco,'userdata',sbview);
                    setcurtime(sbview);
                end               
            case 'label'
                    range = [min(sbview.lastpt(1,1),sbview.curpt(1,1)) max(sbview.lastpt(1,1),sbview.curpt(1,1))];
                    selrange = [min(find(range(1)<([sbview.song.clips.a.start]+[sbview.song.clips.a.length])/sbview.fs)) ...
                                                    max(find(range(2)>[sbview.song.clips.a.start]/sbview.fs))];
                    if diff(selrange)>=0
                        sbview.selectclips = selrange(1):selrange(2);
                        sbview.selectlim = [sbview.song.clips.a(sbview.selectclips(1)).start ...
                            sbview.song.clips.a(sbview.selectclips(end)).start+sbview.song.clips.a(sbview.selectclips(end)).length]/sbview.fs;
                        setselect(sbview);
%                     if ishandle(sbview.clipselecth)
%                         set(sbview.clipselecth,'position',[sbview.selectlim(1) 0 diff(sbview.selectlim) 1]);
%                     else
%                         sbview.clipselecth = rectangle('position',[sbview.selectlim(1) 0 diff(sbview.selectlim) 1],...
%                             'erasemode','xor','facecolor',sbview.song.clipselectcol,'edgecolor','none');
%                     end
%                     if ishandle(sbview.selecth(5))
%                         set(sbview.selecth(5),'xdata',[sbview.selectlim(1)*ones(1,2) sbview.selectlim(2)*ones(1,2)]);
%                     end
                    else
                    sbview.clipselect = [];
%                     sbview.selectlim = [];
%                     delete(sbview.curselecth);
%                     if ishandle(sbview.selecth(5))
%                         set(sbview.selecth(5),'xdata',[sbview.curtime*ones(1,2) (sbview.curtime+.01)*ones(1,2)]);
%                     end
                end
%             case 'specgram'
%                 if sbview.hasmoved
%                     tmplim = [min(sbview.curpt(1,1),sbview.lastpt(1,1)) ...
%                                            max(sbview.curpt(1,1),sbview.lastpt(1,1))];
%                     pos = get(sbview.selecth(1),'position');
%                     set(sbview.selecth(1),'position',[tmplim(1) pos(2) max(diff(tmplim),.01) pos(4)]);
%                     sbview.selectlim = tmplim;
%                     sbview = feval(sbview.dispFcn,sbview);
%                     set(hco,'userdata',sbview);
%                 else
%                     sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
%                     sbview.curtime = sbview.curpt(1,1);
%                     set(hco,'userdata',sbview);
%                     setcurtime(sbview);
%                 end
                case 'oscblowup'
                    sbview.curtime = sbview.curpt(1,1);
                    set(hco,'userdata',sbview);
                    setcurtime(sbview);
        end
    end 
%     if ishandle(sbview.selecth(5))
%         set(sbview.selecth(5),'facealpha',0); % make completely transparent
%     end
    sbview.hasmoved = 0;
    sbview.butpressed = 0;
    sbview.curaxind = [];
    set(hco,'userdata',sbview);
end

% --------------------------------------------------------------------
function winresizeFcn(hco,eventStruct)
% reposition control buttons when resizing main window
sbview = get(gcbo,'userdata');
if ~isempty(sbview)
    uictrlrow(sbview.uictrlh,sbview.figh,sbview.uictrl.gap,.5,.95,...
        'verticalalignment','middle','horizontalalignment','center');
end

% --------------------------------------------------------------------
function keypressFcn(hco,eventStruct)
% key press
sbview = get(hco,'userdata');
redoselect = 0;
if strcmp(eventStruct.Modifier,'control') & ~strcmp(eventStruct.Key,'control')
    sbview.corruptedlabel = 1;
end
if length(eventStruct.Key)==1
    % Change case of input
    if strcmp(get(sbview.figh,'selectiontype'),'extend')
        eventStruct.Key = lower(eventStruct.Key);
    else
        eventStruct.Key = upper(eventStruct.Key);
    end
    if sbview.stdlabel 
        if (eventStruct.Key>='0') && (eventStruct.Key<='9' ) 
            sbview.label2val = str2num(eventStruct.Key);
        elseif ((eventStruct.Key>='a') && (eventStruct.Key<='z' )) || ((eventStruct.Key>='A') && (eventStruct.Key<='Z' ))
            sbview.labelval = eventStruct.Key;
            str = maplabelchar(eventStruct.Key);
            if sbview.label2val ~=1
                str = [str num2str(sbview.label2val)];
            end
            set(sbview.labelh(min(sbview.selectclips)),'string',str);
            if sbview.corruptedlabel ==1
                set(sbview.labelh(min(sbview.selectclips)),'color',sbview.corruptedcolor);
            else
                set(sbview.labelh(min(sbview.selectclips)),'color','k');
            end
            sbview = writelabel(sbview,min(sbview.selectclips));
            sbview.selectclips = min(sbview.song.a.clipnum,min(sbview.selectclips)+1);
            redoselect = 1;                    
            sbview.labelval = ' ';
            sbview.lable2val = 1;
            sbview.keystr = '';
            if ishandle(sbview.sourceh)
                feval(sbview.updatesong,sbview.sourceh,sbview.song,sbview.index);
            else
                feval(sbview.updatesong,sbview.figh,sbview.song,sbview.index);
            end
        end
    else
        sbview.keystr(end+1) = eventStruct.Key;
        set(sbview.labelh(min(sbview.selectclips)),'string',sbview.keystr);
        if sbview.corruptedlabel ==1
            set(sbview.labelh(min(sbview.selectclips)),'color',sbview.corruptedcolor);
        else
            set(sbview.labelh(min(sbview.selectclips)),'color','k');
        end
    end
else
    switch eventStruct.Key
        case {'uparrow','downarrow'}
            if ~isempty(sbview.keystr)
                sbview = writelabel(sbview,min(sbview.selectclips));
            end
            disp(eventStruct.Key)
        case {'leftarrow'}
            if ~isempty(sbview.keystr)
                sbview = writelabel(sbview,min(sbview.selectclips));
            end
            sbview.selectclips = max(1,min(sbview.selectclips)-1);
            redoselect = 1;
        case {'rightarrow','space'}
            if ~isempty(sbview.keystr)
                sbview = writelabel(sbview,min(sbview.selectclips));
            end
            sbview.selectclips = min(sbview.song.a.clipnum,min(sbview.selectclips)+1);
            redoselect = 1;
       case {'return'}
            if ~isempty(sbview.keystr)
                sbview = writelabel(sbview,min(sbview.selectclips));
                sbview.selectclips = min(sbview.song.a.clipnum,min(sbview.selectclips)+1);
                redoselect = 1;
            elseif strcmp(class(sbview.parentnexthandle),'function_handle')
                sbview.parentnexthandle(sbview.sourceh)
            end
        case {'delete'}
            clipind = min(sbview.selectclips);
            if sbview.stdlabel || length(sbview.keystr)<=1
                sbview.keystr = '';
                sbview = writelabel(sbview,clipind);
            else
                sbview.keystr = sbview.keystr(1:end-1);
            end
    %         sbview.song.clips.labelinds(clipind) = 0;               
    %         set(sbview.labelh(clipind),'string','');
            sbview.selectclips = clipind;
            redoselect = 1;
        case {'backspace'}
            clipind = min(sbview.selectclips);
            if sbview.stdlabel
                sbview.keystr = '';
                sbview = writelabel(sbview,clipind);
                sbview.selectclips = max(1,clipind-1);
                redoselect = 1;
            else 
                if isempty(sbview.keystr)
                    sbview = writelabel(sbview,clipind);
                    sbview.selectclips = max(1,clipind-1);
                    redoselect = 1;
                else
                    sbview.keystr = sbview.keystr(1:end-1);
                    set(sbview.labelh(min(sbview.selectclips)),'string',sbview.keystr);
                end
            end
    %        clipind = min(sbview.selectclips);
    %         sbview.song.clips.labelinds(clipind) = 0;               
    %         set(sbview.labelh(clipind),'string','');
    %         sbview.selectclips = max(1,clipind-1);
    %         redoselect = 1;
    %     case {'space'}
    %         sbview.selectclips
    %         for i=1:length(sbview.selectclips)
    %             sbview.song.clips.labelinds(sbview.selectclips(i)) = 0;               
    %             set(sbview.labelh(sbview.selectclips(i)),'string','');
    %         end
        case {'equal'}
            sbview.stdlabel = 0;
            sbview.selectclips = min(sbview.selectclips);
            redoselect = 1;
    end
end
set(sbview.figh,'userdata',sbview);

if redoselect
    clipselrange = [sbview.song.clips.a(min(sbview.selectclips)).start ...
        sbview.song.clips.a(max(sbview.selectclips)).start+sbview.song.clips.a(max(sbview.selectclips)).length]/sbview.fs; 
    sbview.selectlim = clipselrange;
    setselect(sbview);
    if sbview.lblposfrac >0
        width = diff(sbview.timelim);
        sbview.timelim = clipselrange(1)+width*[-sbview.lblposfrac (1-sbview.lblposfrac)];
        settimelim(sbview);
    end       
end
set(sbview.figh,'userdata',sbview);

%-----------------------------------------------------------
function sbview = writelabel(sbview,clipind)
% write current label to clips structure

% assign labeler
if isempty(sbview.labeler)
    sbview = feval(sbview.assignlabeler,sbview.figh);
end
if sbview.labeler == 0
    sbview = feval(sbview.assignlabeler,sbview.figh);
end
sbview.song.labels.a(clipind).labeler = sbview.labeler;               
sbview.song.labels.a(clipind).labeltime = now;               
% if keystr is empty, then delete
if isempty(sbview.keystr) && sbview.labelval == ' ' % delete label
    sbview.song.labels.a(clipind).label = ' ';
    sbview.song.labels.a(clipind).label2 = 1;
    sbview.song.labels.a(clipind).label3 = '';
    if isfield(sbview.song.labels.a,'corrupted')
        sbview.song.labels.a(clipind).corrupted = 0;
    end
    sbview.stdlabel = 1;  
    set(sbview.labelh(clipind),'string','');
    return
end
% assign labels
if sbview.stdlabel
    sbview.song.labels.a(clipind).label = sbview.labelval;
    sbview.song.labels.a(clipind).label2 = sbview.label2val;
else
    sbview.song.labels.a(clipind).label = '=';
    sbview.song.labels.a(clipind).label2 = 1;
    sbview.song.labels.a(clipind).label3 = sbview.keystr;
end
if isfield(sbview.song.labels.a,'corrupted')
    sbview.song.labels.a(clipind).corrupted = sbview.corruptedlabel;
end
sbview.keystr = '';
sbview.stdlabel = 1;  
sbview.corruptedlabel = 0;  
sbview.labelval = ' ';  
sbview.label2val = 1;  

%-----------------------------------------------------------
function zoom(hco,eventStruct)
% implement zoom callbacks

% get main structure
fig = get(hco,'parent');
sbview = get(fig,'userdata');

% get axis indices
specind = find(strcmp(sbview.ax.names,'specgram'));
oscind = find(strcmp(sbview.ax.names,'oscgram'));
labelind = find(strcmp(sbview.ax.names,'label'));
blowupind = find(strcmp(sbview.ax.names,'oscblowup'));

% implement zoom
newzoom = 0;
switch get(hco,'tag')
    case 'mvleft'
        sbview.timelim = sbview.timelim-...
            min(sbview.mvsize,sbview.timelim(1)-sbview.timerange(1));
        newzoom = 1;
    case 'mvright'
        sbview.timelim = sbview.timelim+...
            min(sbview.mvsize,sbview.timerange(2)-sbview.timelim(2));
        newzoom = 1;
    case 'zoomin'
        mn = mean(sbview.timelim);
        sbview.timelim = mn+(sbview.timelim-mn)/sbview.zoomfac;
        newzoom = 1;
    case 'zoomout'
        mn = mean(sbview.timelim);
        sbview.timelim = mn+sbview.zoomfac*(sbview.timelim-mn);
        newzoom = 1;
    case 'zoom2select'
        sbview.timelim = sbview.selectlim;
        newzoom = 1;
    case 'zoom2full'
        sbview.timelim = sbview.timerange;
        newzoom = 1;
    case 'back'
        if sbview.zmhistn>1;
            sbview.zmhistn = sbview.zmhistn-1;
            sbview.timelim = sbview.zoomhist(sbview.zmhistn,:);
            settimelim(sbview);
%             set(sbview.ax.h(specind),'xlim',sbview.timelim);
%             set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
        end
    case 'next'
        if sbview.zmhistn<sbview.maxn;
            sbview.zmhistn = sbview.zmhistn+1;
            sbview.timelim = sbview.zoomhist(sbview.zmhistn,:);
            settimelim(sbview);
%             set(sbview.ax.h(specind),'xlim',sbview.timelim);
%             set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
        end
    case 'curzoomin'
        sbview.curtimewidth = sbview.curtimewidth/sbview.zoomfac;
        set(fig,'userdata',sbview);
        setcurtime(sbview);
    case 'curzoomout'
        sbview.curtimewidth = sbview.curtimewidth*sbview.zoomfac;
        set(fig,'userdata',sbview);
        setcurtime(sbview);
end
if newzoom
    sbview.zmhistn = sbview.zmhistn+1;
    sbview.maxn = sbview.zmhistn;
    sbview.zoomhist(sbview.zmhistn,:) = sbview.timelim;
    settimelim(sbview);
%     set(sbview.ax.h(specind),'xlim',sbview.timelim);
%     set(sbview.ax.h(oscind),'xlim',sbview.timelim);
%     set(sbview.ax.h(labelind),'xlim',sbview.timelim);
%     set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
end
set(fig,'userdata',sbview);

%-----------------------------------------------------------
function split(hco,eventStruct)
% split clip at current time

% get main structure
fig = get(hco,'parent');
sbview = get(fig,'userdata');

% find clip containing current time
% cursamp = sbview.curtime*sbview.song.a.fs/1000;
cursamp = sbview.curtime*sbview.fs;
start = [sbview.song.clips.a.start];
cliplength = [sbview.song.clips.a.length];
curclip = find((cursamp>=start) & (cursamp<=start+cliplength));
if isempty(curclip)
    disp('Current time not aligned within existing clip.'); return;
end
% reproduce current clip
sbview.song.clips.a = sbview.song.clips.a([1:curclip curclip:length(sbview.song.clips.a)]');
% adjust times and lengths
firstpiecelen =  cursamp-sbview.song.clips.a(curclip).start+1;
sbview.song.clips.a(curclip+1).length = sbview.song.clips.a(curclip).length-firstpiecelen;
sbview.song.clips.a(curclip).length = firstpiecelen;
sbview.song.clips.a(curclip+1).start = sbview.song.clips.a(curclip).start+firstpiecelen;
sbview.song.clips.a(curclip+1).label = ' ';
sbview.song.clips.a(curclip+1).label2 = 0';
sbview.song.clips.a(curclip+1).label3 = '';
blank=blanklabels(1);
sbview.song.labels.a=sbview.song.labels.a([1:curclip curclip:length(sbview.song.labels.a)]');
sbview.song.labels.a(curclip+1)=blank.a(1);
sbview.song.a.clipnum = sbview.song.a.clipnum+1;
set(sbview.figh,'userdata',sbview);
% reset song in src
if ishandle(sbview.sourceh)
    feval(sbview.updatesong,sbview.sourceh,sbview.song,sbview.index);
else
    feval(sbview.updatesong,sbview.figh,sbview.song,sbview.index);
end
% reset select rectangle
sbview.selectclips = curclip;
sbview.selectlim = [sbview.song.clips.a(curclip).start-1 sbview.song.clips.a(curclip).start-1+sbview.song.clips.a(curclip).length]/sbview.fs;
set(sbview.figh,'userdata',sbview);
% redisplay
dispFcn(sbview);

%-----------------------------------------------------------
function merge(hco,eventStruct)
% merge selected clips.  label retained is for the first clip

% get main structure
fig = get(hco,'parent');
sbview = get(fig,'userdata');

if length(sbview.selectclips)>1
    selrange = [min(sbview.selectclips) max(sbview.selectclips)];
    endtime = sbview.song.clips.a(selrange(2)).start+sbview.song.clips.a(selrange(2)).length;
    sbview.song.clips.a(selrange(1)+1:selrange(2)) = [];
    sbview.song.clips.a(selrange(1)).length = endtime-sbview.song.clips.a(selrange(1)).start;
    sbview.song.labels.a(selrange(1)+1:selrange(2)) = [];
end
set(sbview.figh,'userdata',sbview);
% reset song in src
if ishandle(sbview.sourceh)
feval(sbview.updatesong,sbview.sourceh,sbview.song,sbview.index);
else
feval(sbview.updatesong,sbview.figh,sbview.song,sbview.index);
end
% redisplay
dispFcn(sbview);

%-----------------------------------------------------------
function bmksong(hco,eventStruct)
% add song to target bookmark src

% get main structure
fig = get(hco,'parent');
sbview = get(fig,'userdata');
% start new src if necessary
need2init = 0;
if isempty(sbview.bmksrch) | isempty(sbview.bmksrc)
    need2init = 1;
elseif ~ishandle(sbview.bmksrch)
    need2init = 1;
end
if need2init
    sbview.bmksrch = feval(sbview.bmksrc,'iswritable',1);
    bmk = get(sbview.bmksrch,'userdata');
    bmk = feval(bmk.newfile,bmk);
else
    bmk = get(sbview.bmksrch,'userdata');
end
% add song
set(sbview.figh,'userdata',sbview);
if ~isempty(bmk.filename)
    feval(bmk.addsong,bmk,sbview.song);
end
set(sbview.figh,'userdata',sbview);

%-------------------------------------------------------------------------
function  sbview =  adduicontrols(sbview)
% add uicontrols 

if ~isempty(sbview.uictrlh)
    delete(sbview.uictrlh);
    sbview.uictrlh = [];
end
%vector holding gaps between controls
gap = [];
% standard gap between controls
stdgap = 3; % in points
stdwidth = 25; % in points

% specify attributes of buttons
n= 0;
tmpctrl.horizontalalignment{1} = ''; % make sure optional field is defined
% Bird Info text
n= n+1;
tmpctrl.tag{n} = 'infotext';
tmpctrl.style{n} = 'text';
tmpctrl.string{n} = '';
tmpctrl.callback{n} = '';
tmpctrl.width(n) = 300;
tmpctrl.gap(n) = 3*stdgap;
tmpctrl.horizontalalignment{n} = 'right';

% Filename text
n= n+1;
tmpctrl.tag{n} = 'filenametext';
tmpctrl.style{n} = 'text';
tmpctrl.string{n} = '';
tmpctrl.callback{n} = '';
tmpctrl.width(n) = 300;
tmpctrl.gap(n) = 3*stdgap;
tmpctrl.horizontalalignment{n} = 'right';

% move left
n= n+1;
tmpctrl.tag{n} = 'mvleft';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = ' < ';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% move right
n= n+1;
tmpctrl.tag{n} = 'mvright';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = ' > ';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% zoom in
n= n+1;
tmpctrl.tag{n} = 'zoomin';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = ' + ';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% zoom out
n= n+1;
tmpctrl.tag{n} = 'zoomout';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = ' - ';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% zoom 2 select
n= n+1;
tmpctrl.tag{n} = 'zoom2select';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = 'Sel';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% zoom 2 full
n= n+1;
tmpctrl.tag{n} = 'zoom2full';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = 'Full';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = 2*stdgap;

% back
n= n+1;
tmpctrl.tag{n} = 'back';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = '<<';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% back
n= n+1;
tmpctrl.tag{n} = 'next';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = '>>';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = 2*stdgap;

% curzoomin
n= n+1;
tmpctrl.tag{n} = 'curzoomin';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = 'T+';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = stdgap;

% curzoomout
n= n+1;
tmpctrl.tag{n} = 'curzoomout';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = 'T-';
tmpctrl.callback{n} = @zoom;
tmpctrl.width(n) = stdwidth;
tmpctrl.gap(n) = 5*stdgap;

if sbview.splitmerge
    % split current clip at current time
    n= n+1;
    tmpctrl.tag{n} = 'split';
    tmpctrl.style{n} = 'pushbutton';
    tmpctrl.string{n} = 'Split';
    tmpctrl.callback{n} = @split;
    tmpctrl.width(n) = 50;
    tmpctrl.gap(n) = 3*stdgap;

    % merge currently selected clips to one
    n= n+1;
    tmpctrl.tag{n} = 'merge';
    tmpctrl.style{n} = 'pushbutton';
    tmpctrl.string{n} = 'Merge';
    tmpctrl.callback{n} = @merge;
    tmpctrl.width(n) = 50;
    tmpctrl.gap(n) = 3*stdgap;
end

% Bookmark current song
n= n+1;
tmpctrl.tag{n} = 'bmk';
tmpctrl.style{n} = 'pushbutton';
tmpctrl.string{n} = 'Bookmark';
tmpctrl.callback{n} = @bmksong;
tmpctrl.width(n) = 80;
tmpctrl.gap(n) = 3*stdgap;


if length(tmpctrl.horizontalalignment)<n
    tmpctrl.horizontalalignment{n}='';
end

uictrlh = zeros(size(tmpctrl));
gaps = zeros(size(tmpctrl));
for i=1:n
    uictrlh(i) = uicontrol('units','points','fontsize',sbview.ctrlfontsize,...
        'Tag',tmpctrl.tag{i},'Style',tmpctrl.style{i},...
        'String',tmpctrl.string{i},'Callback',tmpctrl.callback{i});
    if ~isempty(tmpctrl.horizontalalignment{i})
        set(uictrlh(i),'horizontalalignment',tmpctrl.horizontalalignment{i});
    end
    tmppos = get(uictrlh(i),'position');
    tmppos(3) = tmpctrl.width(i);
    tmppos(4) = sbview.ctrlfontsize+2*3;
    set(uictrlh(i),'position',tmppos);
    gaps(i) = tmpctrl.gap(i);
end
sbview.uictrlh = uictrlh;
sbview.uictrl = tmpctrl;


%-------------------------------------------------------------------------
function  sbview =  closesong(sbview)
% added function for back consistency
