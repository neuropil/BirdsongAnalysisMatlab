function clips = dispcliparr(varargin)
% clips = dispcliparr(label,varargin)
% display array of clip spectrograms 
% clips to be displayed are held in 'clipinds' field
% clips are sorted by 'values' field

cliparr.clipinds = [];
cliparr.fileinfo = '';
% cliparr.rootdir = rootdirlist
cliparr.infopath = '';
cliparr.infofile = '';
cliparr.bmkfile = '';
cliparr.bmkext = ''; % .bmk or .dbk used to determine how to get specs/songs
cliparr.bmkpath = '';
cliparr.lblfile = '';
cliparr.ftrfile = '';
cliparr.specpath = '';
cliparr.wavpath = '';
cliparr.ftrpath = '';
cliparr.name = '';
cliparr.specparams = defaultspecparams;
cliparr.markedclips = [];
cliparr.sortby = 'length'; % either 'match' or 'length'
cliparr.mode = 'descend'; % either 'descend' or 'ascend'
cliparr.strings = {};
cliparr.selclips = [];
cliparr.values = [];
cliparr.figh = [];
cliparr.songviewer = 'sb3viewlbl';
cliparr.viewh = -1;
cliparr.songs = [];
cliparr.clips = [];
cliparr.specfloor = .05; 
cliparr.colN = 10;
cliparr.xgap = 20; % gap between clips in msec
cliparr.colcenters = []; % time for centers of clips
cliparr.freqrange = [0 8]; % display frequency range in kHz
cliparr.rowheight = 150; % heigth of each row in points
cliparr.dispheight = .75;
cliparr.labelheight = .1;
cliparr.disprowN = 7;
cliparr.histN = 50;
% DISPLAY VARIABLES
cliparr.figpos = [.05 .2 .6 .6];
cliparr.selectcolor = .75*[1 1 1];
cliparr.scrcolor = 0*[1 1 1];
cliparr.fontsize = 9;
cliparr.textfontsize = 9;
cliparr.titlefontsize = 12;
cliparr.cliph = [];
cliparr.texth = [];
cliparr.markh = [];
cliparr.filetexth = [];
cliparr.selh = [];
cliparr.selcol = 'g';
cliparr.selwidth = 3;
%  INTERNAL STATE VARIABLES AND FLAGS
cliparr.rowN = cliparr.disprowN;
cliparr.rowlength = 1000; % in msec
cliparr.maxwidth = 50;
cliparr.butpressed = 0;
cliparr.curtag = '';
cliparr.curpt = [];
cliparr.lastpt = [];
cliparr.hasmoved = [];
cliparr = parse_pv_pairs(cliparr,varargin);
% cliparr.rootdir = finddir(cliparr.rootdir);
cliparr = init(cliparr);

% if file exist load it
if exist(fullfile(cliparr.bmkpath,cliparr.bmkfile))
    loadfile(cliparr);
else
    loadfile_cb([],[],cliparr.figh);
end

% --------------------------------------------------------------------
function cliparr = init(cliparr)
% Create the view figure and initialize structure

name = 'Clip Browser';
% look for window, if found extract data; if not initialize
figh =findobj(0,'name', name);
if ~isempty(figh)
    close(figh);
end
% layout (in points)
xmarg = [40 40];
scrwidth = 20;
xgap = 20;
ymarg = [40 20];
ygap = 15;
butheight = cliparr.titlefontsize+2*3;
histheight = 50;
templwidth = 150;
histwidth = 200;
butheight = cliparr.titlefontsize+2*3;
butwidth = 50;
selbutwidth = 120;
% scroll bar color
rowheight = cliparr.rowheight;

cliparr.figh = figure('numbertitle','off', ...
    'color', get(0,'defaultUicontrolBackgroundColor'), ...
    'name',name, ...
    'units','normal','pos',cliparr.figpos);
set(cliparr.figh,...
    'WindowButtonDownFcn',@buttdownFcn,...
    'WindowButtonUpFcn',@buttupFcn,...
    'WindowButtonMotionFcn',@buttmotionFcn,...
    'KeyPressFcn',@keypressFcn);
% set menus
menu.file = uimenu('parent',cliparr.figh,'label','File');
menu.open = uimenu('parent',menu.file,'label','Open bmk file (.dbk)','callback',{@loadfile_cb,cliparr.figh});
menu.loadfileinfo = uimenu('parent',menu.file,'label','Load info file (.inf)','callback',{@loadinfofile_cb,cliparr.figh,'new'});
menu.selfileinfo = uimenu('parent',menu.file,'label','Load data files','callback',{@loadinfofile_cb,cliparr.figh});
menu.select = uimenu('parent',cliparr.figh,'label','Select');
menu.markselect = uimenu('parent',menu.select,'label','Mark Selected','callback',{@markselect_cb,cliparr.figh});
menu.clearselect = uimenu('parent',menu.select,'label','Clear Selected','callback',{@clearselect_cb,cliparr.figh});
menu.clearmarked = uimenu('parent',menu.select,'label','Clear Marked','callback',{@clearmarked_cb,cliparr.figh});

% layout in points, then switch to normalized to ease resizing
pos = getpos(cliparr.figh,'pt pt pt pt');
% height = pos(4)-sum(ymarg)-1.5*ygap-2*butheight;
% width = pos(3)-sum(xmarg)-xgap-scrwidth;
height = pos(4)-sum(ymarg)-3*ygap-histheight-butheight;
width = pos(3)-sum(xmarg)-2*xgap-scrwidth;
% cliparr.disprowN = height/rowheight;

ax.curax = 0;
n = 0;

% make main axis
n = n+1;
ax.names{n} = 'array';
ax.h(n) = axes('tag','array','units','points','position',[xmarg(1) ymarg(1) width height]);
set(ax.h(n),'ylim',.5+[0 cliparr.disprowN],'ydir','reverse'); % vertical units in row from top
% set(ax.h(n),'xtick',[],'xlim',[0 cliparr.rowlength]); 
set(ax.h(n),'xlim',[0 cliparr.rowlength]); 
set(ax.h(n),'fontsize',cliparr.fontsize);
% cliparr.selecth = patch([0 0 width width],[.5 1.5 1.5 .5],-1*ones(4,1),cliparr.selectcolor);
%     set(cliparr.selecth,'edgecolor','none');
set(ax.h(n),'units','normalized'); % this allows normal resizing

% scroll axis
n = n+1;
ax.names{n} = 'scroll';
ax.h(n) = axes('tag','scroll','units','points','position',[pos(3)-xmarg(2)-scrwidth ymarg(1) scrwidth height]);
set(ax.h(n),'xlim',[0 1],'xtick',[]);
set(ax.h(n),'ydir','reverse','yaxislocation','right');
% selcted row rectangle
cliparr.scrh =  patch([0 1 1 0],[.5 .5 cliparr.disprowN cliparr.disprowN],zeros(4,1),cliparr.scrcolor);
set(ax.h(n),'ylim',[-.5 .5]+[1 cliparr.rowN]); % vertical units in row
set(ax.h(n),'units','normalized'); % this allows normal resizing

% % template axis
% n = n+1;
% ax.names{n} = 'template';
% ax.h(n) = axes('tag','template','units','points','position',...
%     [xmarg(1) ymarg(1)+height+2*ygap templwidth histheight]);
% set(ax.h(n),'units','normalized'); % this allows normal resizing

% histogram axis
n = n+1;
ax.names{n} = 'hist';
ax.h(n) = axes('tag','hist','units','points','position',...
    [xmarg(1)+templwidth+2*xgap ymarg(1)+height+2*ygap histwidth histheight]);
set(ax.h(n),'units','normalized'); % this allows normal resizing

cliparr.ax = ax;

% make file label
cliparr.filetexth = uicontrol('style','text','string','','units','points',...
    'position',[xmarg(1) ymarg(1)+height+3*ygap+histheight width butheight],...
    'fontsize',cliparr.titlefontsize);
    set(cliparr.filetexth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...
% import/export buttons
cliparr.selbuth = uicontrol('style','pushbutton','string','Export selectinds','units','points',...
    'position',[xmarg(1)+width-selbutwidth ymarg(1)+height+1.5*ygap+butheight selbutwidth butheight],...
    'fontsize',cliparr.titlefontsize,'callback',@exportselinds);
    set(cliparr.selbuth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...
cliparr.selbuth = uicontrol('style','pushbutton','string','Import selectinds','units','points',...
    'position',[xmarg(1)+width-selbutwidth ymarg(1)+height+2.5*ygap+2*butheight selbutwidth butheight],...
    'fontsize',cliparr.titlefontsize,'callback',@importselinds);
    set(cliparr.selbuth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...

% up and down buttons
scrbutheight = 15;
cliparr.upbuth = uicontrol('style','pushbutton','string','^','units','points','tag','upbut',...
    'position',[pos(3)-xmarg(2)-scrwidth ymarg(1)+height scrwidth scrbutheight],...
    'fontsize',cliparr.titlefontsize,'callback',@butscroll);
    set(cliparr.upbuth,'units','normalized');
cliparr.downbuth = uicontrol('style','pushbutton','string','v','units','points','tag','downbut',...
    'position',[pos(3)-xmarg(2)-scrwidth ymarg(1)-scrbutheight scrwidth scrbutheight],...
    'fontsize',cliparr.titlefontsize,'callback',@butscroll);
    set(cliparr.downbuth,'units','normalized');

    set(cliparr.figh,'userdata',cliparr);

% -----------------------------------------------------------------
function loadfile_cb(hco,eventStruct,figh)
% filemenu = get(hco,'parent');
% figh = get(filemenu,'parent');
cliparr = get(figh,'userdata');    
[cliparr.bmkfile cliparr.bmkpath] = uigetfile({'*.bmk;*.dbk','bookmark file (*.bmk;*.dbk)'; '*.*',  'All Files (*.*)'}, 'Select bookmark file. Specs must be defined.');
if cliparr.bmkpath ==0 return; end
loadfile(cliparr);

% -----------------------------------------------------------------
function cliparr = loadfile(cliparr)
% cliparr = loadfile(cliparr,varargin)
%  load a bookmark file
load(fullfile(cliparr.bmkpath,cliparr.bmkfile),'clips','songs','-mat');
[tmp cliparr.name ext] = fileparts(cliparr.bmkfile);
cliparr.bmkext = ext;
if exist([cliparr.bmkpath  cliparr.name '_spec'])==7 & isempty(cliparr.specpath)
    cliparr.specpath = [cliparr.bmkpath  cliparr.name '_spec'];
end
if exist([cliparr.bmkpath  cliparr.name '_wav'])==7 & isempty(cliparr.wavpath)
    cliparr.wavpath = [cliparr.bmkpath  cliparr.name '_wav'];
end

cliparr.clips = clips;
cliparr.songs = songs;
clear clips
clear songs
% set(cliparr.filetexth,'string',cliparr.name);
set(cliparr.filetexth,'string',cliparr.bmkfile);
if isempty(cliparr.values)
    % sort clips
    switch cliparr.sortby
        case 'length'
            lens = [cliparr.clips.a.length]*(1000/cliparr.clips.a(1).fs);
    %             cliparr.values = lens(cliparr.clipinds);
            cliparr.values = round(lens(cliparr.clipinds));
        otherwise
            cliparr.values = 1:length(cliparr.clipinds);
    end
end
[cliparr.values inds] = sort(cliparr.values(:),1,cliparr.mode);
cliparr.clipinds = cliparr.clipinds(inds);
if ~isempty(cliparr.strings)
    cliparr.strings = cliparr.strings(inds);
end

% display histogram of values overlay with histogram of mismatches in red
axind = find(strcmpi(cliparr.ax.names,'hist'));
axes(cliparr.ax.h(axind));
cla; hold on
[hvals bins] = hist(cliparr.values,cliparr.histN);
bar(bins,hvals);
if ~isempty(cliparr.clipinds)
    cliparr.maxwidth = max([cliparr.clips.a(cliparr.clipinds(:)).length])*1000/cliparr.clips.a(1).fs;
    cliparr.rowlength = (cliparr.maxwidth+cliparr.xgap)*cliparr.colN+cliparr.xgap;
    % cliparr.colN = floor(cliparr.rowlength /(cliparr.maxwidth+cliparr.xgap));
    % width = (cliparr.rowlength-(cliparr.colN+1)*cliparr.xgap)/cliparr.colN;
    cliparr.colcenters = cliparr.xgap+cliparr.maxwidth/2+(0:cliparr.colN-1)*(cliparr.maxwidth+cliparr.xgap);
    cliparr.rowN = ceil(length(cliparr.clipinds)/cliparr.colN);
    set(cliparr.figh,'userdata',cliparr);
    displayFcn(cliparr);
else
    set(cliparr.figh,'userdata',cliparr);
end

% -----------------------------------------------------------------
function loadinfofile_cb(hco,eventStruct,figh,varargin)

cliparr = get(figh,'userdata'); 
cliparr = loadfileinfo('strct',cliparr);
if isempty(cliparr) return; end
set(figh,'userdata',cliparr); 


% -----------------------------------------------------------------
function cliparr = displayFcn(cliparr)
% cliparr = displayFcn(cliparr)
%  set up display

% delete old handles
delete(cliparr.cliph(ishandle(cliparr.cliph)));
cliparr.cliph = -ones(1,length(cliparr.clipinds));
delete(cliparr.texth(ishandle(cliparr.texth)));
cliparr.texth = -ones(1,length(cliparr.clipinds));
delete(cliparr.markh(ishandle(cliparr.markh)&cliparr.markh~=0));
cliparr.markh = -ones(1,length(cliparr.markedclips));
axind = find(strcmp(cliparr.ax.names,'array'));
axes(cliparr.ax.h(axind));
cla; hold on
% readjust limits and scroll bar
set(cliparr.ax.h(axind),'xlim',[0 cliparr.rowlength],'ylim',.5+[0 cliparr.disprowN]);

% readjust scroll bar
set(cliparr.ax.h(find(strcmp(cliparr.ax.names,'scroll'))),'ylim',[0 max(cliparr.rowN,cliparr.disprowN)]+.5);
set(cliparr.scrh,'ydata',[0 0 cliparr.disprowN cliparr.disprowN]+.5);
set(cliparr.figh,'userdata',cliparr);


% load(fullfile([cliparr.bmkpath  cliparr.name '_spec'],[cliparr.name '_spec_' num2str(cliparr.clipinds(1)) '.mat']),'f','t','spec');
finds = find(cliparr.specparams.f>=cliparr.freqrange(1) & cliparr.specparams.f<=cliparr.freqrange(2));
% fvals = cliparr.labelheight+cliparr.dispheight*(.5:length(finds))/length(finds);
fvals = cliparr.dispheight*fliplr((.5:length(finds))/length(finds));
% spec = spec(finds,:);
% cliparr.cliph(1) = imagesc(cliparr.colcenters(1)+t-(t(1)+t(length(t)))/2, 0+.5+fvals, log(max(abs(spec),cliparr.specfloor)));
% if isempty(cliparr.strings)
%     str = num2str(cliparr.clipinds(1));
%     if ~isempty(cliparr.values)
%         str = [str ', ' num2str(cliparr.values(1))];
%     end
% else
%     str = cliparr.strings{1};
% end
% cliparr.texth(1) = text(cliparr.colcenters(1),1-.5+cliparr.dispheight,str);
%     set(cliparr.texth(1),'horizontalalignment','center','verticalalignment','top','fontsize',cliparr.textfontsize,'clipping','on',...
%                                     'parent',cliparr.ax.h(axind));
row = 1;
wb = waitbar(1/numel(cliparr.clipinds),['Displaying ' num2str(numel(cliparr.clipinds)) ' clips.']);
for i=1:numel(cliparr.clipinds)
    if cliparr.colN ==1
        row = i;
    else
        row = floor((i-1)/cliparr.colN)+1;
    end
    col = rem((i-1),cliparr.colN)+1;
    markind = find(cliparr.clipinds(i)==cliparr.markedclips);
    if ~isempty(markind)
        xpos = [cliparr.colcenters(col)-cliparr.maxwidth/2 cliparr.colcenters(col)+cliparr.maxwidth/2];
        ypos = [row-.5 row+.5];
        cliparr.markh(i) = patch(xpos([1 2 2 1]),ypos([1 1 2 2]),-ones(4,1),.8*ones(1,3));
            set(cliparr.markh(i),'edgecolor','none')
    end
    filename = cliparr.songs.a(cliparr.clips.a(cliparr.clipinds(i)).song).filename;
    if isdir(cliparr.specpath)
        load(fullfile(cliparr.specpath,[cliparr.name '_spec_' num2str(cliparr.clipinds(i)) '.mat']),'f','t','spec');
    elseif isdir(cliparr.wavpath)
        [spec f t] = calcspec(cliparr.clips.a(cliparr.clipinds(i)),'specparams',cliparr.specparams,'wavdir',cliparr.wavpath,'filename',filename);
        if isempty(spec)
            disp('Can''t find spec. Aborting.'); close(wb); return;
        end
    else
        [spec f t] = calcspec(cliparr.clips.a(cliparr.clipinds(i)),'specparams',cliparr.specparams,'filename',filename);
        if isempty(spec)
            disp('Can''t find spec. Aborting.'); close(wb); return;
        end
    end
    spec = spec(finds,:);
    cliparr.cliph(i) = imagesc(cliparr.colcenters(col)+t-(t(1)+t(length(t)))/2, row-1+.5+fvals, log(max(abs(spec),cliparr.specfloor)),...
                                    'parent',cliparr.ax.h(axind));
    if isempty(cliparr.strings)
        str = num2str(cliparr.clipinds(i));
        if ~isempty(cliparr.values)
            str = [str ', ' num2str(cliparr.values(i))];
        end
    else
        str = cliparr.strings{i};
    end
    cliparr.texth(i) = text(cliparr.colcenters(col),row-.5+cliparr.dispheight,str);
        set(cliparr.texth(i),'horizontalalignment','center','verticalalignment','top','fontsize',cliparr.textfontsize,'clipping','on',...
                                    'parent',cliparr.ax.h(axind));
    drawnow
    wb = waitbar(i/numel(cliparr.clipinds),wb);
end
close(wb);


% -----------------------------------------------------------------
function markselect_cb(hco,eventStruct,figh)
% move selected clips to new category

cliparr = get(figh,'userdata'); 
selinds = cliparr.clipinds(cliparr.selclips);
cliparr.markedclips = [setdiff(cliparr.markedclips,selinds) setdiff(selinds, cliparr.markedclips)];
set(cliparr.figh,'userdata',cliparr);
% display rectangles
delete(cliparr.markh(ishandle(cliparr.markh)&~cliparr.markh==0));
cliparr.markh = -ones(1,length(cliparr.markedclips));
for i=1:length(cliparr.markedclips)
    tmpind = find(cliparr.clipinds==cliparr.markedclips(i));
    tmprow = ceil(tmpind/cliparr.colN);
    tmpcol = tmpind-(tmprow-1)*cliparr.colN;
    xpos = [cliparr.colcenters(tmpcol)-cliparr.maxwidth/2 cliparr.colcenters(tmpcol)+cliparr.maxwidth/2];
    ypos = [tmprow-.5 tmprow+.5];
    cliparr.markh(i) = patch(xpos([1 2 2 1]),ypos([1 1 2 2]),-ones(4,1),.8*ones(1,3));
        set(cliparr.markh(i),'edgecolor','none')
end

% cliparr = initcategory(cliparr);
set(cliparr.figh,'userdata',cliparr);

% -----------------------------------------------------------------
function clearselect_cb(hco,eventStruct,figh)

cliparr = get(figh,'userdata'); 
cliparr.selclips = [];
% display rectangles
delete(cliparr.selh(ishandle(cliparr.selh)&~cliparr.selh==0));
set(cliparr.figh,'userdata',cliparr);

% -----------------------------------------------------------------
function clearmarked_cb(hco,eventStruct,figh)

cliparr = get(figh,'userdata'); 
cliparr.markedclips = [];
cliparr.templates.markedclips{cliparr.labelind} = [];

% save back to original label file
templates = cliparr.templates;
labels = cliparr.labels;
save(fullfile(cliparr.bmkpath,cliparr.bmkfile),'labels','templates','-mat');
set(cliparr.figh,'userdata',cliparr);
% display rectangles
delete(cliparr.markh(ishandle(cliparr.markh)&~cliparr.markh==0));
cliparr.markh = [];

% cliparr = initcategory(cliparr);
set(cliparr.figh,'userdata',cliparr);



% --------------------------------------------------------------------
function buttdownFcn(hco,eventStruct)
% button press in a particular axis or control button

cliparr = get(hco,'userdata');

cliparr.butpressed = 1;
cliparr.curtag = get(gca,'tag');
axind = find(strcmpi(cliparr.ax.names,cliparr.curtag));
if ~isempty(axind)
    cliparr.curpt = get(cliparr.ax.h(axind),'currentpoint');
    cliparr.lastpt = cliparr.curpt;
end
set(hco,'userdata',cliparr);

% --------------------------------------------------------------------
function buttmotionFcn(hco,eventStruct)
% button motion function, general to fig
cliparr = get(hco,'userdata');
% cliparr.butpressed
switch cliparr.butpressed
    case 1 % left button press     
        axind = find(strcmpi(cliparr.ax.names,cliparr.curtag));
        if ~isempty(axind)
            switch cliparr.curtag
                case 'scroll'
                cliparr.curpt = get(cliparr.ax.h(axind),'currentpoint');
                midpt = min(max(cliparr.curpt(1,2), cliparr.disprowN/2+.5), cliparr.rowN-cliparr.disprowN/2+.5);
                ylim = midpt+cliparr.disprowN*[-.5 .5];
                set(cliparr.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
                set(cliparr.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
            end
            cliparr.hasmoved = 1;
            set(hco,'userdata',cliparr);
            return
        end 
end

% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

cliparr = get(hco,'userdata');
if strcmp(cliparr.curtag,'mark')
    axname = 'main';
else
    axname = cliparr.curtag;
end
axind = find(strcmpi(cliparr.ax.names,axname));
if ~isempty(axind)
    switch cliparr.curtag
        case 'array'
            % locate selected clip          
            cliparr.curpt = get(cliparr.ax.h(axind),'currentpoint');
            row = round(abs(cliparr.curpt(1,2)));
            lastrow = round(abs(cliparr.lastpt(1,2)));
            if row>=1 && row<= cliparr.rowN 
                [val col] = min(abs(cliparr.colcenters-cliparr.curpt(1,1)));
                [val lastcol] = min(abs(cliparr.colcenters-cliparr.lastpt(1,1)));
                cliparr.curclip = ((row-1)*cliparr.colN+col);
                lastclip = ((lastrow-1)*cliparr.colN+lastcol);
%                 [lastclip cliparr.curclip]
                switch get(hco,'selectiontype')
                    case 'normal' % single click - select/deselect clip, clear other seleted clips
                        tmpind = find(cliparr.selclips==cliparr.curclip);
                        delete(cliparr.selh(ishandle(cliparr.selh)));
                        cliparr.selh = [];
                        cliparr.selclips = [];
                        if isempty(tmpind)
                            cliparr.selclips = cliparr.curclip;
                            dy = .02;
                            cliparr.selh(1) = rectangle('position', [cliparr.colcenters(col)-cliparr.maxwidth/2 row-.5+dy cliparr.maxwidth 1-2*dy]);
                                set(cliparr.selh(end),'linewidth',cliparr.selwidth,'edgecolor',cliparr.selcol);
                        end
                    case 'alt' % single ctrl click - select/deselect clip, but don't clear
                        tmpind = find(cliparr.selclips==cliparr.curclip);
                        if isempty(tmpind)
                            cliparr.selclips(end+1) = cliparr.curclip;
                            dy = .02;
                            cliparr.selh(end+1) = rectangle('position', [cliparr.colcenters(col)-cliparr.maxwidth/2 row-.5+dy cliparr.maxwidth 1-2*dy]);
                                set(cliparr.selh(end),'linewidth',cliparr.selwidth,'edgecolor',cliparr.selcol);
                        else
                            delete(cliparr.selh(tmpind));
                            cliparr.selh(tmpind) = [];
                            cliparr.selclips(tmpind) = [];
                        end
                    case 'extend' % single shift click - select clips between button down and button up positon, keep others
                        selinds = min(cliparr.curclip,lastclip):max(cliparr.curclip,lastclip);
                        newinds = setdiff(selinds, cliparr.selclips);
                        oldinds = intersect(cliparr.selclips,selinds);
%                         for i=1:length(oldinds)
%                             tmpind = find(cliparr.selclips==oldinds(i));
%                             delete(cliparr.selh(tmpind));
%                             cliparr.selh(tmpind) = [];
%                             cliparr.selclips(tmpind) = [];
%                         end
                        for i=1:length(newinds)
                            cliparr.selclips(end+1) = newinds(i);
                            dy = .02;
                            tmprow = ceil(newinds(i)/cliparr.colN);
                            tmpcol = newinds(i)-(tmprow-1)*cliparr.colN;
                            cliparr.selh(end+1) = rectangle('position', [cliparr.colcenters(tmpcol)-cliparr.maxwidth/2 tmprow-.5+dy cliparr.maxwidth 1-2*dy]);
                                set(cliparr.selh(end),'linewidth',cliparr.selwidth,'edgecolor',cliparr.selcol);
                        end
                    case 'open' % double click - display clip
                        seps = find(cliparr.bmkpath==filesep);
                        if seps(end) == length(cliparr.bmkpath)
                            name = cliparr.bmkpath(seps(end-1):end-1);
                        else
                            name = cliparr.bmkpath(seps(end)+1:end);
                        end
                        cliparr.clipinds(cliparr.curclip)
                        cliparr.viewh = dispclipsong(cliparr.clipinds(cliparr.curclip),...
                                            'bmkfile',cliparr.bmkfile,'bmkpath',cliparr.bmkpath,...
                                            'lblfile',cliparr.lblfile,'lblpath',cliparr.bmkpath);
%                         cliparr.viewh = dispclipsongfile(fullfile([cliparr.rootdir filesep cliparr.bmkpath],cliparr.bmkfile),...
%                                     cliparr.clipinds(cliparr.curclip),...
%                                     'labelfile',fullfile([cliparr.rootdir filesep cliparr.bmkpath],cliparr.bmkfile),...
%                                     'viewh',cliparr.viewh,'songviewer',cliparr.songviewer);
                end 
            end
        case 'scroll'
            cliparr.curpt = get(cliparr.ax.h(axind),'currentpoint');
            midpt = min(max(cliparr.curpt(1,2), cliparr.disprowN/2+.5), cliparr.rowN-cliparr.disprowN/2+.5);
            ylim = midpt+cliparr.disprowN*[-.5 .5];
            set(cliparr.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
            set(cliparr.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
    end
end 
cliparr.hasmoved = 0;
cliparr.butpressed = 0;
set(hco,'userdata',cliparr);

% --------------------------------------------------------------------
function butscroll(hco,eventStruct)

figh = get(hco,'parent');
cliparr = get(figh,'userdata');
if strcmp(get(hco,'tag'),'upbut')
    dir = -1;
else
    dir = 1;
end
midpt = mean(get(cliparr.scrh,'ydata'))+dir;
midpt = max(midpt,cliparr.disprowN/2+.5);
midpt = min(midpt,cliparr.rowN-cliparr.disprowN/2+.5);
ylim = midpt+cliparr.disprowN*[-.5 .5];
set(cliparr.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
set(cliparr.ax.h(1),'ylim',ylim); % hard code main axis as axis 1

% --------------------------------------------------------------------
function exportselinds(hco,eventStruct)

figh = get(hco,'parent');
cliparr = get(figh,'userdata');
disp(['Saved to base workspace: selectinds = [' sprintf('%d ',cliparr.clipinds(cliparr.selclips)) '];']);
assignin('base','selectinds',cliparr.clipinds(cliparr.selclips));

% --------------------------------------------------------------------
function importselinds(hco,eventStruct)

tmp = evalin('base','who(''selectinds'')');
if isempty(tmp)
    disp('No variable in workspace named selectinds');
else
    figh = get(hco,'parent');
    cliparr = get(figh,'userdata');
    selectinds = evalin('base','selectinds');
    [findselect inds1 inds2] = intersect(selectinds,cliparr.clipinds);
    if length(findselect)<length(selectinds)
        diffinds = setdiff(selectinds,findselect);
        disp(['Couldn''t find clips = [' sprintf('%d ',diffinds) '];']);
    end
    cliparr.selclips = inds2;
    delete(cliparr.selh(ishandle(cliparr.selh)));
    cliparr.selh = zeros(size(cliparr.selclips));
    dy = .02;
    for i=1:length(cliparr.selclips)
        row = ceil(cliparr.selclips(i)/cliparr.colN);
        col = cliparr.selclips(i)-(row-1)*cliparr.colN;
        cliparr.selh(i) = rectangle('position', [cliparr.colcenters(col)-cliparr.maxwidth/2 row-.5+dy cliparr.maxwidth 1-2*dy]);
        set(cliparr.selh(i),'linewidth',cliparr.selwidth,'edgecolor',cliparr.selcol);
    end                         
end

% --------------------------------------------------------------------
function keypressFcn(hco,eventStruct)
% key press navigate by arrows
cliparr = get(hco,'userdata');

