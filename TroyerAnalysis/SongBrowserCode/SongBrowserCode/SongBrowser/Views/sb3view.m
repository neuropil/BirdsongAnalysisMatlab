function [sbview figh] = sb3view(varargin)
%   sbview figure #1 for SongBrowser version 3
%   has the following elements
%    line of zoom control buttons
%    oscillogram for navigation
%    scroll bar for navigation
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
figh =findobj(0,'name', ['SongBrowser View']);
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
    sbview.bmksrc = 'sb3src_bmk'; % name of bmksrc function to call when bookmarking songs 
    sbview.bmksrch = []; % figure handle of src_bmk to recieve bookmarked songs  
    sbview.sourceh = -1;
    %Alex edit
    sbview.parentnexthandle=[]; % function handle of src_sng or src_bmklbl to call done function on
    % OPTIONS AND PARAMETERS
    sbview.playsong = 1; % flags whether to play song on load
    sbview.inittimelim = []; % initial time limits upon loading song, if empty use song length
    sbview.timebuffer = [-50 50]; % buffers surrounding song (msec)
    sbview.mvsize = 20; % how far to move window on clicking move buttons
    sbview.zoomfac = sqrt(2); % factor to zoom in/out
    sbview.initzoom = 0; % if >0, initial zoom set to this scale (msec)
    sbview.curtimewidth = 10; % width of current time window (msec)
    sbview.focus = []; % can be used to retain focus in another figure (e.g. a source)
    % DISPLAY VARIABLES
    sbview.figpos = [0.3 0.25 0.7 0.5];
    sbview.fontsize = 11;
    sbview.ctrlfontsize = 11;
    sbview.labelfontsize = 11;
    sbview.colormap = 'hot';
    sbview.selectcol = .8*[1 1 1];
    %  INTERNAL STATE VARIABLES AND FLAGS
    sbview.song = [];
    sbview.features = [];
    sbview.index = 0;
    sbview.sourceupdate = [];
%     sbview.clips = [];
    sbview.selectlim = [0 100]; % current selection
    sbview.curtime = 10; % current time marker
    sbview.timerange = [0 1000]+sbview.timebuffer;
    sbview.timelim = [0 1000]+sbview.timebuffer;
    sbview.curtime = 10;
    sbview.zoomhist = zeros(50,2); % 50 move zoom buffer
    sbview.zmhistn = 1; % current location in move history
    sbview.maxn = 1; % max index in move history
    % stuff for button callbacks
    sbview.axind = [];
    sbview.butpressed = 0; % 1 = left button press
    sbview.hasmoved = 0;
    sbview.curpt = [];
    sbview.lastpt = [];
    % HANDLES AND AXES
    sbview.figh = [];
    sbview.ax = [];
    sbview.selecth = -1*ones(5,1);
    sbview.uictrlh = [];
    sbview.uictrl = [];
    sbview.curtimeh = [];
    sbview.curtimeedgeh = [];
    % METHODS
    sbview.dispFcn = @dispFcn; 
    sbview.loadsong = @loadsong; 
    % sbview.refresh = @refresh;
    sbview.updatesong = [];
    sbview.zoom = @zoom;
    sbview = parse_pv_pairs(sbview,varargin(argbeginind:end));
    sbview.sourceupdate = sbview.updatesong;
    sbview.updatesong = @updatesong;
    sbview=init(sbview);
    set(sbview.figh,'userdata',sbview);
    set(sbview.figh,'ResizeFcn',@winresizeFcn);
end
if ~isempty(song)
    sbview.song = song;
end
set(sbview.figh,'userdata',sbview);
% if ~isempty(sbview.song)
%     feval(sbview.loadsong,sbview.figh,sbview.song);
% end
figh = sbview.figh;

% --------------------------------------------------------------------
function sbview = init(sbview)
%% Create the sbview figure and initialize structure

sbview.figh = figure('numbertitle','off', ...
    'color', get(0,'defaultUicontrolBackgroundColor'), ...
    'name','SongBrowser View', ...
    'doublebuffer','on', 'backingstore','off', ...
    'integerhandle','off', 'vis','on', ...
    'units','normal','pos',sbview.figpos,...
    'menubar','none', 'toolbar','none', ...
    'PaperPositionMode','auto');
set(sbview.figh,...
    'WindowButtonDownFcn',@buttdownFcn,...
    'WindowButtonUpFcn',@buttupFcn,...
    'WindowButtonMotionFcn',@buttmotionFcn,...
    'KeyPressFcn',@keypressFcn);
%     'ResizeFcn',@winresizeFcn
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
height = .075; bottom = .77;
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
height = .02; bottom = .75;
ax.names{n} = 'scroll';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'ytick',[],'xtick',[]);
ax.ylim(n,:) = [0 1];
ax.scrh = rectangle('position',[sbview.timelim(1) 0 diff(sbview.timelim) 1],'facecolor',.5*ones(1,3));

% oscillogram axis
n = n+1;
height = .075; bottom = .6;
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
height = .3; bottom = .275;
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
height = .1; bottom = .1;
ax.names{n} = 'oscblowup';
ax.h(n) = axes('position',[xleft bottom width height],'tag',ax.names{n});
set(ax.h(n),'fontsize',sbview.fontsize);
ax.ftrh{n} = -1; % handles of features plotted
ax.selecth{n} = -1; % negative handle as placeholder
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
% close existing song in source
if ishandle(sbview.sourceh)
    if isa(sbview.updatesong,'function_handle')
        feval(sbview.updatesong,sbview.sourceh,sbview.song,sbview.index);
    else
        warning('sbview.sourceupdatesong must be a function handle'); 
    end
end
% set source index and close function handle
sbview.sourceh = -1;
sbview.index = 0;
% sbview.updatesong = [];
sbview = parse_pv_pairs(sbview,varargin);
% params.sourceh = -1;
% params.index = 0;
% params.updatesong = [];
% params = parse_pv_pairs(params,varargin);
% sbview.sourceh = params.sourceh;
% sbview.index = params.index;
% sbview.updatesong = params.updatesong;

%% set info strings using birdID and age if available
infostr = '';
if isfield(song.a,'birdID')
    if ~isempty(song.a.birdID)
        infostr = [infostr 'BirdID = ' num2str(song.a.birdID)];
    end
end
if isfield(song,'age')
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
if isempty(sbview.selectlim)
    sbview.selectlim= [0 100]; 
    sbview.curtime = 10; 
else
    sbview.curtime = mean(sbview.selectlim); 
end
% zero pad song with buffers for display
padsamples = round(sbview.timebuffer*song.a.fs/1000);
song.d = [zeros(-padsamples(1),size(song.d,2));...
                    song.d; ...
                  zeros(padsamples(2),size(song.d,2))];
sbview.song = song;

%% calculate features
for i=1:length(sbview.ftr.obj)
    sbview.ftr.obj{i} = feval(sbview.ftr.obj{i}.calcFcn,song,sbview.ftr.obj{i});
end

% save data and display/play
set(sbview.figh,'userdata',sbview);
sbview = dispFcn(sbview);
if sbview.playsong
%     player=audioplayer(song.d,song.a.fs,16,-1);
%     disp('play')
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

%%%%%% full oscillogram axis
axind = find(strcmpi(sbview.ax.names,'fulloscgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display selected times 
sbview.ax.selecth{axind}  = rectangle('position',[sbview.selectlim(1) sbview.ax.ylim(axind,1) ...
                                        max(diff(sbview.selectlim),.1) diff(sbview.ax.ylim(axind,:))],...
                            'erasemode','xor','facecolor',sbview.selectcol,'edgecolor','none');
% display oscillogram
sbview.ax.ftrh{axind} = feval(sbview.ftr.obj{oscftrind}.dispFcn,...
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
set(sbview.ax.h(axind),'xlim',sbview.timerange);
set(sbview.ax.h(axind),'ylim',sbview.ax.ylim(axind,:));

%%%%% scroll axis
axind = find(strcmpi(sbview.ax.names,'scroll'));
axes(sbview.ax.h(axind));
set(sbview.ax.h(axind),'xlim',sbview.timelim);
set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);

%%%%%% oscillogram axis
axind = find(strcmpi(sbview.ax.names,'oscgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display selected times 
sbview.ax.selecth{axind}  = rectangle('position',[sbview.selectlim(1) sbview.ax.ylim(axind,1) ...
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
set(sbview.ax.h(axind),'xlim',sbview.timelim);

%%%%% specgram axis
axind = find(strcmpi(sbview.ax.names,'specgram'));
axes(sbview.ax.h(axind));
cla; hold on
% display spectrogram
sbview.ax.ftrh{axind}  = feval(sbview.ftr.obj{specftrind}.dispFcn,sbview.ftr.obj{specftrind});
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
tmplim = [0 1];
ylim = sbview.ax.ylim(axind,:);
% sbview.selecth(5) = patch([tmplim(1)*ones(1,2) tmplim(2)*ones(1,2)],...
%                                                     [ylim(1) ylim(2)*ones(1,2) ylim(1)],'w',...
%                                                     'facealpha',0);
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
axes(sbview.ax.h(axind));
xlim = sbview.curtime+sbview.curtimewidth*[-.5 .5];
set(sbview.ax.h(axind),'xlim',xlim);
oscftrind = find(strcmpi(sbview.ftr.names,'oscgram'));
xvals = sbview.ftr.obj{oscftrind}.xvals;
xvals = xvals(1):xvals(2):xvals(3);
tmpinds = (xvals>=xlim(1) & xvals<=xlim(2));
ymag = max(max(abs(sbview.ftr.obj{oscftrind}.d(tmpinds,:))));
set(sbview.ax.h(axind),'ylim',max(ymag,.001)*[-1 1]);

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
set(sbview.ax.h(blowupind),'ylim',max(ymax,.001)*[-1 1]);


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

axind = strcmpi(sbview.ax.names,'specgram');
set(sbview.ax.selecth{axind}(1),'xdata',sbview.selectlim(1)*[1 1]);
set(sbview.ax.selecth{axind}(2),'xdata',sbview.selectlim(2)*[1 1]);

axind = strcmpi(sbview.ax.names,'oscgram');
pos = get(sbview.ax.selecth{axind},'position');
set(sbview.ax.selecth{axind},'position',[sbview.selectlim(1) pos(2) max(diff(sbview.selectlim),.01) pos(4)]);

% pos = get(sbview.selecth(2),'position');
% set(sbview.selecth(2),'position',[sbview.selectlim(1) pos(2) max(diff(sbview.selectlim),.01) pos(4)]);
% set(sbview.selecth(3),'xdata',sbview.selectlim(1)*[1 1]); 
% set(sbview.selecth(4),'xdata',sbview.selectlim(2)*[1 1]); 

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
%     specaxind = find(strcmpi(sbview.ax.names,'specgram'));
%         switch sbview.ax.names{sbview.curaxind}
%                 case {'fulloscgram','specgram','oscgram'}
%                     sbview.selectlim = sbview.curpt(1,1)+[0 1];
% %                     setselect(sbview);
% %                     set(sbview.selecth(5),'xdata',[tmplim(1)*ones(1,2) tmplim(2)*ones(1,2)],...
% %                                                     'facealpha',.33);
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
        if ~isempty(sbview.curaxind)
            switch sbview.ax.names{sbview.curaxind}
                case 'fulloscgram'
                    sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                    sbview.selectlim = [min([sbview.curpt(1,1) sbview.lastpt(1,1)]) ...
                                           max([sbview.curpt(1,1) sbview.lastpt(1,1)])];
                    setselect(sbview);
%                         pos = get(sbview.selecth(1),'position');
%                         set(sbview.selecth(1),'position',[tmplim(1) pos(2) diff(tmplim) pos(4)]);
                case 'scroll'
                    sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                    diffpt = sbview.curpt(1,1)-sbview.lastpt(1,1); 
                    sbview.timelim = sbview.timelim+diffpt;
                    settimelim(sbview)
%                     specind = find(strcmpi(sbview.ax.names,'specgram'));
%                     set(sbview.ax.h(specind),'xlim',sbview.timelim);
%                     oscind = find(strcmpi(sbview.ax.names,'oscgram'));
%                     set(sbview.ax.h(oscind),'xlim',sbview.timelim);
%                     set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
                    sbview.lastpt=sbview.curpt;
                case {'specgram','oscgram'}
                    sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                    sbview.selectlim = [min([sbview.curpt(1,1) sbview.lastpt(1,1)]) ...
                                           max([sbview.curpt(1,1) sbview.lastpt(1,1)])];
                    setselect(sbview);
%                         set(sbview.selecth(5),'xdata',[tmplim(1)*ones(1,2) tmplim(2)*ones(1,2)]);
            end
            sbview.hasmoved = 1;
            set(hco,'userdata',sbview);
            return
        end 
end

% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

sbview = get(hco,'userdata');
if sbview.butpressed
    if ~isempty(sbview.curaxind)
        switch sbview.ax.names{sbview.curaxind}
            case {'fulloscgram','oscgram'}
                sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                if sbview.hasmoved
                    sbview.selectlim = [min(sbview.curpt(1,1),sbview.lastpt(1,1))...
                                           max(sbview.curpt(1,1),sbview.lastpt(1,1))];
                    setselect(sbview);
%                     pos = get(sbview.selecth(1),'position');
%                     set(sbview.selecth(1),'position',[tmplim(1) pos(2) max(diff(tmplim),.01) pos(4)]);
%                     sbview.selectlim = tmplim;
%                     sbview = feval(sbview.dispFcn,sbview);
%                     set(hco,'userdata',sbview);
                else
                    sbview.curtime = sbview.curpt(1,1);
                    set(hco,'userdata',sbview);
                    setcurtime(sbview);
                end               
            case 'specgram'
                if sbview.hasmoved
                    sbview.selectlim = [min(sbview.curpt(1,1),sbview.lastpt(1,1)) ...
                                           max(sbview.curpt(1,1),sbview.lastpt(1,1))];
                    setselect(sbview);
%                     pos = get(sbview.selecth(1),'position');
%                     set(sbview.selecth(1),'position',[tmplim(1) pos(2) max(diff(tmplim),.01) pos(4)]);
%                     sbview.selectlim = tmplim;
%                     sbview = feval(sbview.dispFcn,sbview);
%                     set(hco,'userdata',sbview);
                else
                    sbview.curpt = get(sbview.ax.h(sbview.curaxind),'currentpoint');
                    sbview.curtime = sbview.curpt(1,1);
                    set(hco,'userdata',sbview);
                    setcurtime(sbview);
                end
    %         case 'oscgramblowup'
        end
    end 
%     if ishandle(sbview.selecth(5))
%         set(sbview.selecth(5),'facealpha',0); % make completely transparent
%     end
     sbview.hasmoved = 0;
    sbview.butpressed = 0;
    set(sbview.figh,'userdata',sbview);
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
% disp('No keypress');
sbview = get(hco,'userdata');
switch eventStruct.Key
    case {'leftarrow'}
        sbview.selectclips = max(1,min(sbview.selectclips)-1);
        redoselect = 1;
    case {'rightarrow','space'}
        sbview.selectclips = min(sbview.song.a.clipnum,min(sbview.selectclips)+1);
        redoselect = 1;
   case {'return'}
        if strcmp(class(sbview.parentnexthandle),'function_handle')
            sbview.parentnexthandle(sbview.sourceh)
        end
end


%-----------------------------------------------------------
function zoom(hco,eventStruct)
% implement zoom callbacks

% get main structure
fig = get(hco,'parent');
sbview = get(fig,'userdata');

% get axis indices
specind = find(strcmp(sbview.ax.names,'specgram'));
oscind = find(strcmp(sbview.ax.names,'oscgram'));
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
            set(sbview.ax.h(specind),'xlim',sbview.timelim);
            set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
        end
    case 'next'
        if sbview.zmhistn<sbview.maxn;
            sbview.zmhistn = sbview.zmhistn+1;
            sbview.timelim = sbview.zoomhist(sbview.zmhistn,:);
            set(sbview.ax.h(specind),'xlim',sbview.timelim);
            set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
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
    set(sbview.ax.h(specind),'xlim',sbview.timelim);
    set(sbview.ax.h(oscind),'xlim',sbview.timelim);
    set(sbview.ax.scrh,'position',[sbview.timelim(1) 0 diff(sbview.timelim) 1]);
end
set(fig,'userdata',sbview);

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
feval(bmk.addsong,bmk,sbview.song);
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
% Info text
n= n+1;
tmpctrl.tag{n} = 'infotext';
tmpctrl.style{n} = 'text';
tmpctrl.string{n} = '';
tmpctrl.callback{n} = '';
tmpctrl.width(n) = 300;
tmpctrl.gap(n) = 5*stdgap;
tmpctrl.horizontalalignment{n} = 'right';

% Filename text
n= n+1;
tmpctrl.tag{n} = 'filenametext';
tmpctrl.style{n} = 'text';
tmpctrl.string{n} = '';
tmpctrl.callback{n} = '';
tmpctrl.width(n) = 200;
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

% Bookmark current sogn
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


