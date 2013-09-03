function figh = sb3src_bmk(varargin)
% sb3src_bmk(varargin)
%  spreadsheet for selecting files from bookmark
%
% version 2 uses new directory structure with wav subdirectory and .lbl
% file

% TODO:
% handle for labeling: deletemarked, newfile, closefile
% initlabels?
% 

%% initialize
% LINKS TO OTHER SONGBROWSER OBJECTS
bmk.view = 'sb3viewlbl';
bmk.viewh = -1;
% FILE AND PATHNAMES
bmk.pathname = './';
bmk.filename = '';
bmk.labelfile = '';
% bmk.rootdir = {'/Volumes/Groups','Y:','Z:','/Users/toddtroyer/Documents/Lab'};
bmk.rootdir = rootdirlist;
bmk.datadir = datadirlist;
% OPTIONS AND PARAMETERS
bmk.fields = {'birdID','age','date','time','length'};
bmk.dispfields = {'Bird','Age','Date','Time','Length'}; % must be matched to bmk.fields
bmk.argtype = '';
bmk.iswritable = 0;
bmk.showmarked = 1;
bmk.haslabels = 1;
% DISPLAY VARIABLES
bmk.figpos = [.05 .4 .25 .5];
bmk.selectcolor = .75*[1 1 1];
bmk.scrcolor = 0*[1 1 1];
bmk.fontsize = 10;
bmk.titlefontsize = 12;
bmk.ptsperchar = 10;
bmk.gridlinewidth = 1;
bmk.markwidth = 20;
% bmk.alignment = 'left';
bmk.charbuff = 1; % characters on either side of display string
%  INTERNAL STATE VARIABLES AND FLAGS
bmk.songs = blanksongs(0);
bmk.labels = blanklabels(0);
bmk.clips = blankclips(0);
bmk.marked = []; % binary vector determining whether song has been marked
bmk.ischanged = 0; % flags whether there have been changes to bmk.songs or bmk.marked
bmk.args = [];
bmk.specialfields = {'date','time','length','samples','datasamples'}; % fields that need special formatting
bmk.widths = [];
bmk.cursong = 1;
bmk.showrowN = 0; % reset according to font and fig height
bmk.rowN = 100; % reset according to data
bmk.curtag = '';
bmk.butpressed = 0;
bmk.curpt = [];
bmk.lastpt = [];
bmk.hasmoved = [];
bmk.labelers = {'Todd','Meagan','David'};
% HANDLES AND MENUS
bmk.figh = [];
bmk.cellhs = [];
bmk.ax = [];
bmk.scrrecth = [];
bmk.selecth = []; % handle of row selection rectangle
bmk.gridh = [];
bmk.texth = [];
bmk.tittexth = [];
bmk.markh = [];
bmk.menus = [];
% METHODS
bmk.viewsong = @viewsong;  % 
bmk.loadfile = @loadfile; % load info from existing bookmark(bmk) or data bookmark (dbk) file
bmk.closefile = @closefile; % close current file.  Save if bmk.ischanged and bmk.iswritable
bmk.updatesong = @updatesong; % Update song info from viewer. Can be called by viewer
bmk.newfile = @newfile; % create a (new empty) bookmark file
bmk.addsong = @addsong; % add song to end of bookmark file, requires bmk.iswritable=1
bmk.displayFcn = @displayFcn;
bmk.init = @init;
bmk.initlabels = @initlabels;
% bmk.delete = @delete; % not implemented

bmk = parse_pv_pairs(bmk,varargin);
bmk.rootdir = finddir(bmk.rootdir);
if isempty(bmk.rootdir)
    error('Can''t find root directory');
end
%bmk.datadir = finddir(bmk.datadir);
if isempty(bmk.datadir)
    disp('Can''t find data directory. Check connection to server.');
end
if ~iscell(bmk.dispfields)
    bmk.dispfields = bmk.fields;
end
bmk=init(bmk);

filefound =0;
if ~isempty(bmk.filename)
    if exist(bmk.filename,'file')
        [bmk.pathname,name,ext] = fileparts(bmk.filename);
        bmk.filename = [name ext];
        filefound = 1;
        bmk = feval(bmk.loadfile,bmk);
    end
end
set(bmk.figh,'userdata',bmk);
% viewsong(bmk,bmk.cursong);
figh = bmk.figh;

% --------------------------------------------------------------------
function bmk = init(bmk)
% Create the view figure and initialize structure

% look for window, if found extract data; if not initialize
figh =findobj(0,'name', ['SongBrowser Bmk Source']);
if ~isempty(figh)
    close(figh);
end
% layout (in points)
xmarg = [40 20];
scrwidth = 10;
xgap = 10;
ymarg = [20 20];
ygap = 5;
butheight = bmk.titlefontsize+2*3;
butwidth = 50;
% scroll bar color
rowheight = bmk.fontsize+2*3;

bmk.figh = figure('numbertitle','off', ...
    'color', get(0,'defaultUicontrolBackgroundColor'), ...
    'name','SongBrowser Bmk Source', ...
    'menubar','none', 'toolbar','none', ...
    'units','normal','pos',bmk.figpos);
% bmk.figh = figure('numbertitle','off', ...
%     'color', get(0,'defaultUicontrolBackgroundColor'), ...
%     'name','SongBrowser Bmk Source', ...
%     'units','normal','pos',bmk.figpos);
% %    'integerhandle','off', 'vis','on', ...
set(bmk.figh,...
    'WindowButtonDownFcn',@buttdownFcn,...
    'WindowButtonUpFcn',@buttupFcn,...
    'WindowButtonMotionFcn',@buttmotionFcn,...
    'KeyPressFcn',@keypressFcn);

% set menus
menu.file = uimenu('parent',bmk.figh,'label','File');
menu.new = uimenu('parent',menu.file,'label','New','callback',{@newfile_cb,bmk.figh});
menu.open = uimenu('parent',menu.file,'label','Open','callback',{@loadfile_cb,bmk.figh});
menu.saveas = uimenu('parent',menu.file,'label','Save As','callback',{@savefile_cb,bmk.figh});
menu.close = uimenu('parent',menu.file,'label','Close','callback',{@closefile_cb,bmk.figh});
menu.deletemarked = uimenu('parent',menu.file,'label','Delete Marked',...
                                        'callback',{@deletemarked_cb,bmk.figh});
bmk.menu = menu;

% layout in points, then switch to normalized to ease resizing
pos = getpos(bmk.figh,'pt pt pt pt');
height = pos(4)-sum(ymarg)-1.5*ygap-2*butheight;
width = pos(3)-sum(xmarg)-xgap-scrwidth;
bmk.showrowN = height/rowheight;

ax.curax = 0;
n = 0;

% make main axis
n = n+1;
ax.names{n} = 'main';
ax.h(n) = axes('tag','main','units','points','position',[xmarg(1) ymarg(1) width height]);
set(ax.h(n),'ylim',.5+[0 bmk.showrowN],'ydir','reverse'); % vertical units in row from top
set(ax.h(n),'xtick',[],'xlim',[0 width]); 
set(ax.h(n),'fontsize',bmk.fontsize);
bmk.selecth = patch([0 0 width width],[.5 1.5 1.5 .5],-1*ones(4,1),bmk.selectcolor);
    set(bmk.selecth,'edgecolor','none');
set(ax.h(n),'units','normalized'); % this allows normal resizing

% scroll axis
n = n+1;
ax.names{n} = 'scroll';
ax.h(n) = axes('tag','scroll','units','points','position',[pos(3)-xmarg(2)-scrwidth ymarg(1) scrwidth height]);
set(ax.h(n),'xlim',[0 1],'xtick',[]);
set(ax.h(n),'ydir','reverse','yaxislocation','right');
% selcted row rectangle
bmk.scrh =  patch([0 1 1 0],[.5 .5 bmk.showrowN bmk.showrowN],zeros(4,1),bmk.scrcolor);

set(ax.h(n),'ylim',.5+[0 bmk.rowN]); % vertical units in row
set(ax.h(n),'units','normalized'); % this allows normal resizing

% make title row as axis
n = n+1;
ax.names{n} = 'titles';
ax.h(n) = axes('tag','titles','units','points','position',[xmarg(1) ymarg(1)+height+.5*ygap width butheight]);
% set(bmk.titaxh,'ylim',[0 1]); % vertical units in row
set(ax.h(n),'xlim',[0 width],'xtick',[]); % horizontal units in points, .9 because we're going add scroll
set(ax.h(n),'ytick',[],'ydir','reverse');
set(ax.h(n),'units','normalized'); % this allows normal resizing

bmk.ax = ax;

% make button and file label
% bmk.openh = uicontrol('style','pushbutton','string','Open','units','points',...
%     'position',[xmarg(1) ymarg(1)+height+ygap+butheight butwidth butheight],...
%     'fontsize',bmk.titlefontsize,'callback',@loadfile_cb);
%     set(bmk.openh,'units','normalized');
bmk.filetxth = uicontrol('style','text','string','','units','points',...
    'position',[xmarg(1) ymarg(1)+height+1.5*ygap+butheight width butheight],...
    'fontsize',bmk.titlefontsize);
    set(bmk.filetxth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...

set(bmk.figh,'userdata',bmk);

% -----------------------------------------------------------------
function loadfile_cb(hco,eventStruct,figh)
% filemenu = get(hco,'parent');
% figh = get(filemenu,'parent');
bmk = get(figh,'userdata');
[bmk.filename bmk.pathname] = uigetfile('*.bmk;*.dbk','Choose a bookmark file');
if isequal(bmk.filename,0) || isequal(bmk.pathname,0) return; end

set(figh,'userdata',bmk);
bmk = feval(bmk.loadfile,bmk);
if isempty(bmk.labelfile)
    return
end
set(figh,'userdata',bmk);

bmk = displayFcn(bmk);
set(figh,'userdata',bmk);
% bmk.cursong
if ~(isempty(bmk.songs.a)||(length(bmk.songs.a)==1&&bmk.songs.a(1).length==0))
    viewsong(bmk,bmk.cursong);
end

% -----------------------------------------------------------------
function bmk = loadfile(bmk,varargin)
% bmk = loadfile(bmk)
%  load a bookmark file

labels = [];
full = fullfile(bmk.pathname,bmk.filename);
if (~isempty(varargin))&&strcmp(varargin(1),'noFileRead')
    songs=bmk.songs;
    clips=bmk.clips;
else
    load(full,'songs','clips','-mat'); % read data from bmk file
end
bmk.songs = songs; % keep all bmk data in case you need it
bmk.clips = clips;
[pathstr bmk.name ext] = fileparts(full);

% look for fields
fieldnum = length(bmk.fields);
foundfield = false(fieldnum,1);
try
    bmk.rowN = length(songs.a);
catch e
    bmk.rowN=0;
end

for j=1:fieldnum
    if isfield(songs.a,bmk.fields{j})
        foundfield(j) = true;
    else
        disp(['sb3src_bmk cannot find field named ' bmk.fields{j}]);
    end
end
bmk.fields = bmk.fields(foundfield);
bmk.dispfields = bmk.dispfields(foundfield);
bmk.cursong =1;
bmk.ischanged = 0; 
bmk.marked = zeros(bmk.rowN,1)==1;
% look for .lbl file
lblfiles = dir([bmk.pathname filesep '*.lbl']);
filefound = 0;
for i=1:length(lblfiles)
    [tmp name ext] = fileparts(lblfiles(i).name);
    if strcmp(bmk.name,name)
        filefound = 1;
        bmk.labelfile = lblfiles(i).name;
        load(fullfile(bmk.pathname,lblfiles(1).name),'-mat');
        break
    end
end
if filefound~= 1
    [filename pathname] = uigetfile({'*.lbl','Label file (*.lbl)';'*.*','All files'},'Choose a label file');
    if filename == 0
        aa = questdlg('Create new label file?','New label file?','Yes','No','No');
        if strcmp(aa,'Yes')
            tmpname = [bmk.name '.lbl'];
            [filename, pathname] = uiputfile(tmpname, 'New label file');
            if filename==0
                bmk.labelfile = '';
                return; 
            end
            bmk.labelfile = filename;
            if ~strcmp(pathname,bmk.pathname)
                warndlg('Label must be in bookmark directory');
                bmk.labelfile = '';
                return;
            end
            labels = blanklabels(length(clips.a));
            labels.clipfile = filename;
                        
            save(fullfile(bmk.pathname,bmk.labelfile),'labels','-mat');
        else
            bmk.labelfile = '';
            return; 
        end
    else
        if ~strcmp(pathname,bmk.pathname)
            warndlg('Label must be in bookmark directory');
            bmk.labelfile = '';
            return;
        end
        bmk.labelfile = filename;
        load(fullfile(bmk.pathname,bmk.labelfile),'labels','-mat');
    end
end
if size(labels.a)~=size(bmk.clips.a)
    disp('Size of labels.a does not match size of bmk.clips.a. Aborting.'); 
    bmk.labelfile = '';
    return;
end
bmk.labels = labels;
    
set(bmk.figh,'userdata',bmk);

% -----------------------------------------------------------------
function closefile_cb(hco,eventStruct,figh)
% figh = get(hco,'parent');
bmk = get(figh,'userdata');
bmk = closefile(bmk);
set(figh,'userdata',bmk);

% -----------------------------------------------------------------
function bmk = closefile(bmk)
% bmk = closefile(bmk)
% close current bookmark file

if bmk.ischanged & bmk.iswritable
    ans = questdlg('Save song data to file?','Save data?','Yes','No','No');
    if strcmp(ans,'Yes')
        if exist(fullfile(bmk.pathname,bmk.filename),'file')
            ans = questdlg(['Overwrite ' fullfile(bmk.pathname,bmk.filename) '?'],...
                'Overwrite?','Yes','No','No');
            if ~strcmp(ans,'Yes') return; end
        else
            [bmk.filename,bmk.pathname] = uiputfile({'*.bmk;*.dbk','Bookmark files'},'Save as');
            if bmk.filename==0 return; end
        end
        songs = bmk.songs;
        clips = bmk.clips;
        save(fullfile(bmk.pathname,bmk.filename),'clips','songs','-append','-mat');
        if strcmp(bmk.filename(end-2:end),'dbk')
            ans = questdlg('Saving raw data','Save data','OK','Cancel','Cancel');
            if ~strcmp(ans,'OK') return; end
            BmkDataWrite('filename',fullfile(bmk.pathname,bmk.filename));
        end
    end
    % resave labels
    labels = bmk.labels;
    save(fullfile(bmk.pathname,bmk.labelfile),'labels','-append','-mat');
else
    bmk.songs = blanksongs(0);
    bmk.clips = blankclips(0);
    bmk.ischanged = 0;
end

% -----------------------------------------------------------------
function updatesong(bmkhandle,song,index,varargin)
% updatesong(bmkhandle,song,index)
% save information for current song to bookmark files
params.savedata = 1;
params = parse_pv_pairs(params,varargin);

bmk = get(bmkhandle,'userdata');

if length(song.clips.a) == bmk.songs.a(index).clipnum
    clipinds = bmk.songs.a(index).startclip:bmk.songs.a(index).endclip;
    % if same numbers of clips but different starts/lengths, reset information
    if sum([bmk.clips.a(clipinds).start]~=[song.clips.a.start] & ...
                [bmk.clips.a(clipinds).length]~=[song.clips.a.length])~=0
        bmk.clips.a(clipinds) = song.clips.a;
        clips = bmk.clips;
        if params.savedata
            save(fullfile(bmk.pathname,bmk.filename),'clips','-append','-mat');
        end
    end
    % resave labels
    bmk.labels.a(clipinds) = song.labels.a;
    labels = bmk.labels;
    if params.savedata
        save(fullfile(bmk.pathname,bmk.labelfile),'labels','-append','-mat');
    end
% if return different numbers of clips call reset clipslabels
else
    [bmk.clips bmk.labels bmk.songs] = resetclipslabels(bmk,index, song);
    songs = bmk.songs;
    clips = bmk.clips;
    labels = bmk.labels;
    if params.savedata
        save(fullfile(bmk.pathname,bmk.filename),'clips','songs','-append','-mat');
        save(fullfile(bmk.pathname,bmk.labelfile),'labels','-append','-mat');
    end
end

set(bmkhandle,'userdata',bmk);

% -----------------------------------------------------------------
function newfile_cb(hco,eventStruct,figh)
% figh = get(hco,'parent');
bmk = get(figh,'userdata');
bmk = closefile(bmk);
bmk = newfile(bmk);
bmk = loadfile(bmk,'noFileRead');
set(figh,'userdata',bmk);

% -----------------------------------------------------------------
function bmk = newfile(bmk,varargin)
% bmk = newfile(bmk)
% create a  new or open existing bookmark file
p.filename = '';
p.pathname = '';
p = parse_pv_pairs(p,varargin);
labelfile='';
savenewfile = 0;
if isempty(p.pathname) || isempty(p.filename)
    [p.filename,p.pathname] = uiputfile({'*.bmk;*.dbk','Bookmark files'},'Get new bookmark file');
    if p.filename==0 return; end
end
[path, filename, ext]=fileparts([p.pathname p.filename]);
if strcmp(ext,'.dbk') %if the extension is .dbk, name it as a .dbk (nothing happened)
    p.filename=[filename,'.dbk'];
else %otherwise (which covers the cases where it is a .bmk, or anything else)
    %name it a .bmk
    p.filename=[filename,'.bmk']; %by default, create a .bmk file
end
labelfile=[filename '.lbl']; %label always has same name as bookmark file, without the extension
if exist(fullfile(p.pathname,p.filename),'file')&& ~strcmp(questdlg(['Clear data in ' p.filename '?'],...
        'Clear data?','Yes','No','No'),'Yes')
    %If the file exists, AND the user does not want to overwrite its
    %contents, read them in
    %         load(fullfile(p.pathname,p.filename),'songs','clips','-mat');
    bmk.filename = p.filename;
    bmk.pathname = p.pathname;
    bmk.labelfile=labelfile;
    bmk = loadfile(bmk);
else
    %Otherwise (covers if the user picked a file that doesn't exist, or if
    %it exists and they want to overwrite it
    bmk.filename = p.filename;
    bmk.pathname = p.pathname;
    songs = blanksongs(0,'clipptr',1);
    clips = blankclips(0,'songptr',1);
    bmk.songs = songs;
    bmk.clips = clips;
    bmk.filename = p.filename;
    bmk.pathname = p.pathname;
    bmk.labelfile=labelfile;
    fullname = fullfile(p.pathname,p.filename);
    save(fullname,'-struct','bmk');
    % clear wav files
    if strcmp(p.filename(end-2:end),'dbk')
        delete([p.pathname filesep 'wav' filesep '*.wav']);
    end
end
bmk.ischanged = 0;
bmk=loadfile(bmk,'noFileRead');
set(bmk.figh,'userdata',bmk);

% -----------------------------------------------------------------
function savefile_cb(hco,event,figh)
% figh = get(hco,'parent');
bmk = get(figh,'userdata');

[filename,pathname] = uiputfile({'*.bmk;*.dbk','Bookmark files'},'Save as');
if filename==0 return; end
if exist(fullfile(pathname,filename),'file')
    ans = questdlg(['Overwrite ' filename '?'],'Overwrite?','Yes','No','No');
    if ~strcmp(ans,'Yes') return; end
end
bmkIsDbk=false;
filenameIsDbk=false;
try bmkIsDbd= strcmp(bmk.filename(end-2:end),'dbk'); catch e; end
try filenameIsDbk=strcmp(filename(end-2:end),'dbk'); catch e; end

isdbk = [bmkIsDbk filenameIsDbk];
try
    areSameType=strcmp(bmk.filename(end-2:end),filename(end-2:end));
catch e
    areSameType=false;
end
if  areSameType % files are same type so just copy
    copyfile(fullfile(bmk.pathname,bmk.filename),fullfile(pathname,filename),'f');
else
    songs = bmk.songs;
    clips = bmk.clips;
    save(fullfile(pathname,filename),'songs','clips','-mat');
    [tmp name ext] = fileparts(filename);
    labels = bmk.labels;
    save(fullfile(pathname,[name '.lbl']),'labels','-mat');
    if strcmp(filename(end-2:end),'dbk')
        ans = questdlg('Saving raw data','Save data','OK','Cancel','Cancel');
        if ~strcmp(ans,'OK') return; end
        bmkdatawrite('filename',fullfile(pathname,filename));
    end
end

% -----------------------------------------------------------------
function deletemarked_cb(hco,event,figh)
% figh = get(hco,'parent');
bmk = get(figh,'userdata');
if isempty(bmk.marked)
    return;
end
try
    extension = bmk.filename(end-2:end);
catch e
    extension='bmk';
end
resp = questdlg('Save to new file?','New file?','Yes','Overwrite','Yes');
confirm = '';
switch resp
    case 'Yes'
        newfile = 1;
        [filename,pathname] = uiputfile({[bmk.pathname filesep '*.' extension],['Bookmark files (.' extension ')']},'Save as');
        if filename==0 return; end
    case 'Overwrite'
        confirm = questdlg('Marked songs will be lost. Are you sure?','Overwrite','Cancel','Overwrite','Cancel');
        if ~strcmp(confirm,'Overwrite') return; end
        newfile = 0;
        filename = bmk.filename; 
        pathname = bmk.pathname;
    otherwise
        return;
end
% close current song in viewer 
feval(bmk.view,'feval',bmk.viewh,'updatesong');
% If data bookmark, remove or copy songs as appropriate
if strcmp(extension,'dbk')
    if newfile
        mkdir([pathname filesep filename(1:end-4)]);
        unmarked = find(~bmk.marked);
        for i=1:length(unmarked)
            wavnm = wavname(bmk.songs.a(unmarked(i)));
            copyfile(fullfile([bmk.pathname filesep bmk.filename(1:end-4)],wavnm),...
                                        fullfile([pathname filesep filename(1:end-4)],wavnm));
        end
    else
        marked = find(bmk.marked);
        for i=1:length(marked)
            wavnm = wavname(bmk.songs.a(marked(i)));
            delete(fullfile([bmk.pathname filesep bmk.filename(1:end-4)],wavnm));
        end
    end
end
bmk.filename = filename;
bmk.pathname = pathname;
[songs clips] = deletesongs(bmk.songs,bmk.clips,find(bmk.marked));

bmk.songs =songs;
bmk.clips = clips;
bmk.cursong = 1;
bmk.marked = false(length(bmk.songs),1);

% save data
save(fullfile(bmk.pathname,bmk.filename),'songs','clips','-mat');
set(bmk.figh,'userdata',bmk);
loadfile(bmk);

% -----------------------------------------------------------------
function viewsong(bmk,row)
% look for location of song
% if strcmp(bmk.filename(end-2:end),'dbk') 
havefile = 0;
if exist([bmk.pathname bmk.filename(1:end-4) '_wav'])==7
    if isfield(bmk.songs.a(row),'filename')
        wavfile = bmk.songs.a(row).filename;
        if exist(fullfile([bmk.pathname bmk.filename(1:end-4) '_wav'],wavfile))==2
            filename = fullfile([bmk.pathname bmk.filename(1:end-4) '_wav'],wavfile);
            if (exist(filename,'file')==2)
                havefile = 1;
            end
        end
    elseif isfield(bmk.songs.a(row),'sessionID') & isfield(bmk.songs.a(row),'date') & isfield(bmk.songs.a(row),'songID') 
        filename = fullfile([bmk.pathname bmk.filename(1:end-4) '_wav'],wavname(bmk.songs.a(row)));
        if (exist(filename,'file')==2)
            havefile = 1;
        end
    end
end
%path = findsongwavpath(bmk.songs.a(row).filename); % use naming convention to get directory holding orginal data
%filename = fullfile(path,bmk.songs.a(row).filename);
if (exist(filename,'file')==2)
    havefile = 1;
end

if ~havefile
    [tmpfile tmppath] = uigetfile({'*.wav','wav files (*.wav)'; '*.*',  'All Files (*.*)'},'Find wav file');
    if tmpfile==0 return; end
    filename = fullfile(tmppath,tmpfile);
end
song.d = wavread(filename);
song.a = bmk.songs.a(row);
% call song viewer
if ~ishandle(bmk.viewh)
    [view bmk.viewh] = feval(bmk.view,'updatesong',bmk.updatesong,'parentnexthandle',@goToNext);
end
set(bmk.figh,'userdata',bmk);
% select clips and labels 
song.clips = bmk.clips;
song.clips.a = bmk.clips.a(song.a.startclip:song.a.endclip);
song.labels = bmk.labels;
try
    song.labels.a = bmk.labels.a(song.a.startclip:song.a.endclip);
catch e
    song.labels=blanklabels(song.a.clipnum);
end
% view song
feval(bmk.view,'feval',bmk.viewh,'loadsong',song,'sourceh',bmk.figh,'index',row,'updatesong',bmk.updatesong);

% -----------------------------------------------------------------
function bmk = displayFcn(bmk)
% bmk = displayFcn(bmk)
%  set up display

fieldnum = length(bmk.fields);
strings = cell(bmk.rowN,fieldnum);

% load cell and width values
for j=1:fieldnum
    bmk.widths(j) = length(bmk.dispfields{j}); % find # of char for display
    tmp = getfield(bmk.songs.a,bmk.fields{j});
    if sum(strcmp(bmk.specialfields,bmk.fields{j}))>0
%         bmk.fields{j}
        switch bmk.fields{j}
            case 'date'
                for i= 1:bmk.rowN
                   strings{i,j} = datestr(bmk.songs.a(i).date,'mm/dd/yy');
                   bmk.widths(j) = max(bmk.widths(j),length(strings{i,j}));
                end
            case 'time'
               for i= 1:bmk.rowN
                   strings{i,j} = datestr(bmk.songs.a(i).time/24,'HH:MM:SS');
                   bmk.widths(j) = max(bmk.widths(j),length(strings{i,j}));
               end
            case 'length'
               for i= 1:bmk.rowN
                   strings{i,j} = num2str(round(1000*bmk.songs.a(i).length/bmk.songs.a(i).fs)/1000);
                   bmk.widths(j) = max(bmk.widths(j),length(strings{i,j}));
               end
        end
    elseif ~iscell(tmp)
        if bmk.rowN>length(bmk.songs.a)
            disp([bmk.rowN length(bmk.songs.a)]);
        end
        for i=1:bmk.rowN
            strings{i,j} = num2str(round(eval(['bmk.songs.a(i).' bmk.fields{j}])));
            bmk.widths(j) = max(bmk.widths(j),length(strings{i,j}));
        end
    else
        for i=1:bmk.rowN
            bmk.strings{i,j} = eval(['bmk.songs.a(i).' bmk.fields{j}]);
            bmk.widths(j) = max(bmk.widths(j),length(strings{i,j}));
        end
    end
end

% change filename string
set(bmk.filetxth,'string',bmk.filename);

% delete old handles
delete(bmk.gridh(ishandle(bmk.gridh)));
delete(bmk.texth(ishandle(bmk.texth)));
delete(bmk.markh(ishandle(bmk.markh)));
bmk.texth = zeros(1,size(strings,2));

% set up boundary positions
vert = [0 cumsum(bmk.widths+2)]*bmk.ptsperchar;
hor = (0:bmk.rowN)+.5;

% plot field names
axes(bmk.ax.h(strcmp(bmk.ax.names,'titles')))
for j=1:size(strings,2)
    bmk.tittexth(j) = text((vert(j)+vert(j+1))/2,.5,bmk.dispfields{j},...
        'fontsize',bmk.fontsize,'verticalalignment','middle','horizontalalignment','center');
end
if bmk.showmarked
    xlim = [vert(1)-bmk.markwidth vert(end)];
else
    xlim = [vert(1) vert(end)];
end
set(gca,'xlim',xlim);

% plot cell boundaries 
if ~isempty(bmk.gridh)
    if ishandle(bmk.gridh)
        delete(bmk.gridh);
    end
    bmk.gridh = [];
end
axes(bmk.ax.h(find(strcmp(bmk.ax.names,'main'))))
if bmk.gridlinewidth>0
    % vertical stripes, ends at bottom right
    for j=1:length(vert)
        bmk.gridh(end+1) = line(vert(j)*[1 1],[hor(1) hor(end)],[1 1],...
            'color','k','linewidth',bmk.gridlinewidth);
    end
    for i=1:length(hor)
        bmk.gridh(end+1) = line(xlim,hor(i)*[1 1],[1 1],...
            'color','k','linewidth',bmk.gridlinewidth);
    end
    % now box the whole thing
    bmk.gridh = line([xlim(1) xlim(2) xlim(2) xlim(1)],[0 0 hor(end) hor(end)],[1 1 1 1],...
            'color','k','linewidth',bmk.gridlinewidth);
end
% plot strings
for i=1:size(strings,1)
    for j=1:size(strings,2)
        bmk.texth(i,j) = text((vert(j)+vert(j+1))/2,i,1,strings{i,j},...
            'fontsize',bmk.fontsize,'clipping','on',...
            'verticalalignment','middle','horizontalalignment','center');
    end
end
if bmk.showmarked
    for i=1:bmk.rowN
        bmk.markh(i) = rectangle('position',[-bmk.markwidth*.75,i-.25,bmk.markwidth*.5,.5]);
    end
    set(bmk.markh(bmk.marked==1),'facecolor','k');
end

set(gca,'xlim',xlim);

% readjust select bar
set(bmk.selecth,'ydata',bmk.cursong+[-.5 .5 .5 -.5],'xdata',[vert(1) vert(1) vert(end) vert(end)]);
% readjust scroll bar
set(bmk.ax.h(find(strcmp(bmk.ax.names,'scroll'))),'ylim',[0 max(bmk.rowN,1)]+.5);
set(bmk.scrh,'ydata',[.5 .5 bmk.showrowN bmk.showrowN]);
set(bmk.figh,'userdata',bmk);
    
% -----------------------------------------------------------------
function bmk = addsong(bmk,song)
% add song to bookmark structure

% check whether file is writable
if ~bmk.iswritable
    ans = questdlg('Enable writing to this bookmark structure?','Bmk Write Enable?',...
        'Yes','No','Yes');
    if ~strcmp(ans,'Yes') return; end
end
% make sure that song has clip information
if ~isfield(song,'clips')
    disp('Song does not have clips field.  Not adding song to bookmark.'); return
elseif ~length(song.clips.a)>0
    disp('Empty clips structure. Not adding song to bookmark.'); return
end
if isempty(bmk.songs)
    bmk.songs = blanksongs(1,'clipptrs',1);
    bmk.clips = blankclips(1,'labels',1,'songptr',1);
end
if isempty(bmk.songs.a)||(length(bmk.songs.a)==1 && bmk.songs.a(1).length == 0)
    newsongnum = 1;
else
    newsongnum = length(bmk.songs.a)+1;
end
% % move song information  one field at a time
srcfields = fieldnames(bmk.songs.a);
foundfield = zeros(length(srcfields),1);
for j=1:length(srcfields)
    if isfield(song.a,srcfields{j})
        foundfield(j) = 1;
        eval(['bmk.songs.a(newsongnum).' srcfields{j} '=song.a.' srcfields{j} ';']);
    elseif ~strcmpi(srcfields{j},'startclip') & ~strcmpi(srcfields{j},'endclip') 
        resp = questdlg(['Can''t find song field named ' srcfields{j} '. Proceed anyway?'],...
            'No song field','Yes','No','No');
        if ~strcmp(resp,'Yes'); return; end
        if isnumeric(getfield(bmk.songs.a, srcfields{j}))
            eval(['bmk.songs.a(newsongnum).' srcfields{j} '=0;']);
        elseif ischar(getfield(bmk.songs.a, srcfields{j}))
            eval(['bmk.songs.a(newsongnum)' srcfields{j} '='''';']);
        else
            eval(['bmk.songs.a(newsongnum)' srcfields{j} '={};']);
        end
    end
end

% set start and end clip
if newsongnum>1
    bmk.songs.a(newsongnum).startclip = bmk.songs.a(newsongnum-1).endclip+1;
else
    bmk.songs.a(newsongnum).startclip = 1;
end
bmk.songs.a(newsongnum).endclip = bmk.songs.a(newsongnum).startclip-1+song.a.clipnum;
% move clip information  one field at a time
if isempty(bmk.clips)||bmk.clips.a(1).length==0
    bmk.clips = song.clips;
else
    newclipinds = length(bmk.clips.a)+(1:song.a.clipnum);
%     bmk.clips.a(newclipinds) = song.clips.a;
    srcfields = fieldnames(bmk.clips.a);
    foundfield = zeros(length(srcfields),1);
    for j=1:length(srcfields)
        if isfield(song.clips.a,srcfields{j})
            foundfield(j) = 1;
            for n=1:length(newclipinds)
                eval(['bmk.clips.a(newclipinds(n)).' srcfields{j} '=song.clips.a(n).' srcfields{j} ';']);
            end
        else
            ans = questdlg(['Can''t find clips field named ' srcfields{j} '. Proceed anyway?'],...
                'No clips field','Yes','No','No');
            if ~strcmp(ans,'Yes'); return; end
            if isnumeric(getfield(bmk.clips.a, srcfields{j}))
                for n=1:length(newclipinds)
                    eval(['bmk.clips.a(newclipinds(n)).' srcfields{j} '=0;']);
                end
            else
               for n=1:length(newclipinds)
                   eval(['bmk.clips.a(newclipinds(n)).' srcfields{j} '='''';']);
               end
            end
        end
        % overwrite with new song index
        for n=1:length(newclipinds)
            bmk.clips.a(newclipinds(n)).song = newsongnum;
        end
    end
end
% if data bookmark file save raw data
if strcmp(bmk.filename(end-2:end),'dbk')
    tmpname = fullfile(bmk.pathname,bmk.filename);
    if ~exist(tmpname(1:end-4),'dir')
        mkdir(tmpname(1:end-4));
    end
    wavwrite(song.d,song.a.fs,fullfile(tmpname(1:end-4),song.a.filename));
end
% save song and clips structures
songs = bmk.songs;
clips = bmk.clips;
save(fullfile(bmk.pathname,bmk.filename),'songs','clips','-append','-mat');

% clean up, save to userdata and display
bmk.ischanged = 1; % flag as changed
bmk.rowN = length(bmk.songs.a);
set(bmk.figh,'userdata',bmk);
displayFcn(bmk);
    
% --------------------------------------------------------------------
function buttdownFcn(hco,eventStruct)
% button press in a particular axis or control button

bmk = get(hco,'userdata');

bmk.butpressed = 1;
bmk.curtag = get(gca,'tag');
axind = find(strcmpi(bmk.ax.names,bmk.curtag));
if ~isempty(axind)
    bmk.curpt = get(bmk.ax.h(axind),'currentpoint');
    bmk.lastpt = bmk.curpt;
end
if bmk.curpt(1,1)<0
    bmk.curtag = 'mark';
end
set(hco,'userdata',bmk);

% --------------------------------------------------------------------
function buttmotionFcn(hco,eventStruct)
% button motion function, general to fig
bmk = get(hco,'userdata');
% bmk.butpressed
switch bmk.butpressed
    case 1 % left button press     
        axind = find(strcmpi(bmk.ax.names,bmk.curtag));
        if ~isempty(axind)
            switch bmk.curtag
                case 'scroll'
                bmk.curpt = get(bmk.ax.h(axind),'currentpoint');
                midpt = min(max(bmk.curpt(1,2), bmk.showrowN/2+.5), bmk.rowN-bmk.showrowN/2+.5);
                ylim = midpt+bmk.showrowN*[-.5 .5];
                set(bmk.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
                set(bmk.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
            end
            bmk.hasmoved = 1;
            set(hco,'userdata',bmk);
            return
        end 
end

% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

bmk = get(hco,'userdata');
if strcmp(bmk.curtag,'mark')
    axname = 'main';
else
    axname = bmk.curtag;
end
axind = find(strcmpi(bmk.ax.names,axname));
if ~isempty(axind)
    switch bmk.curtag
        case 'main'
            bmk.curpt = get(bmk.ax.h(axind),'currentpoint');
            row = round(bmk.curpt(1,2));
            if row>=1 & row<= bmk.rowN & row~=bmk.cursong
                bmk.cursong = row;
                set(bmk.selecth,'ydata',row+[-.5 .5 .5 -.5]);
                viewsong(bmk,row);
                bmk = get(bmk.figh,'userdata');
            end
        case 'mark'
            bmk.curpt = get(bmk.ax.h(axind),'currentpoint');
            row = round(bmk.curpt(1,2));
            tmp = bmk.markwidth;
            if abs(bmk.curpt(1,2)-row)<.25 & abs(bmk.curpt(1,1)-(-tmp/2))<(tmp/4) & ...
                    row>=1 & row<= bmk.rowN 
                if bmk.marked(row)==0
                    bmk.marked(row)=1;
                    set(bmk.markh(row),'facecolor','k');
                else
                    bmk.marked(row)=0;
                    set(bmk.markh(row),'facecolor','none');
                end
            end
        case 'scroll'
            bmk.curpt = get(bmk.ax.h(axind),'currentpoint');
            midpt = min(max(bmk.curpt(1,2), bmk.showrowN/2+.5), bmk.rowN-bmk.showrowN/2+.5);
            ylim = midpt+bmk.showrowN*[-.5 .5];
            set(bmk.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
            set(bmk.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
    end
end 
bmk.hasmoved = 0;
bmk.butpressed = 0;
set(hco,'userdata',bmk);

% --------------------------------------------------------------------
function keypressFcn(hco,eventStruct)
% key press navigate by arrows
bmk = get(hco,'userdata');
curchan = bmk.songs.a(bmk.cursong).chan;

switch eventStruct.Key
    case {'uparrow','downarrow'}
        tmppos = cumsum(bmk.songs.chan==curchan); % for songs in curchan gives pos in list
        tmpcurind = tmppos(bmk.cursong);
        % note that 'up' is earlier in time
        if strcmp(eventStruct.Key,'downarrow')
            tmpcurind = min(tmpcurind+1,tmppos(end));
        else
            tmpcurind = max(tmpcurind-1,1);
        end
        bmk.cursong = min(find(tmppos==tmpcurind));        
    case {'leftarrow','rightarrow'}
        newchan = strcmp(eventStruct.Key,'rightarrow')+1;
        tmpinds = find(bmk.songs.chan==newchan);
        [val ind] = min(abs(bmk.songs.time(bmk.cursong)-bmk.songs.time(tmpinds)));
        bmk.cursong = tmpinds(ind);
end
if bmk.songs.chan(bmk.cursong)==1
    set(bmk.selecth,'xdata',1.5-bmk.seloffset,...
            'ydata',bmk.songs.time(bmk.cursong),'color',bmk.Lcolor);
else
    set(bmk.selecth,'xdata',1.5+bmk.seloffset,...
            'ydata',bmk.songs.time(bmk.cursong),'color',bmk.Rcolor);
end
set(hco,'userdata',bmk);
viewsong(bmk,bmk.cursong);
figure(bmk.figh)

function goToNext(thisFigure)
bmk=get(thisFigure,'userdata');
bmk.cursong=bmk.cursong+1;
if bmk.cursong>length(bmk.songs.a)
    bmk.cursong=length(bmk.songs.a);
end
viewsong(bmk,bmk.cursong);

function [clips labels songs] = resetclipslabels(bmk,index, song)
clips=bmk.clips;
labels=bmk.labels;
songs=bmk.songs;
startindex=bmk.songs.a(index).startclip-1; %get the number of indexes to skip in the clip/song list
changeCount=bmk.songs.a(index).clipnum-length(song.clips.a);
if changeCount>0 %if there was a merge
    % starting at the start index, remove clips equal in number to
    % the difference between the number of bookmark clips and song clips
    clips.a(startindex+(1:changeCount))=[];
    % do the same thing with the labels
    labels.a(startindex+(1:changeCount))=[];
    % change song start and end clips

else %if there was a split (changeCount is always -1
    % insert n blank clips, where n is the difference between the lengths
    % of the song clips and bookmark clips
    clips.a=cat(1,clips.a(1:startindex+1),clips.a(startindex+1:end)); %duplicate the startindex+1 tag to add an extra
    % same with the labels
    labels.a=cat(1,labels.a(1:startindex+1),labels.a(startindex+1:end));
end
for n=1:length(song.clips.a) %now overwrite the bookmark clips with the song's clips,
    %and the labels with the song's labels
    fieldNames=fieldnames(clips.a);
    for m=1:length(fieldNames)
        clips.a(startindex+n).(fieldNames{m})=song.clips.a(n).(fieldNames{m});
    end
    labels.a(startindex+n)=song.labels.a(n);
end
songs.a(index).endclip=songs.a(index).endclip-changeCount;
songs.a(index).clipnum=songs.a(index).clipnum-changeCount;
for n=index+1:length(songs.a) % shift all the bmk.songs.a startclip and endclip by
    % the number of clips that were added or removed, but do not shift the
    % startclip of the song that is selected; only those after it
    songs.a(n).startclip=songs.a(n).startclip-changeCount;
    songs.a(n).endclip=songs.a(n).endclip-changeCount;
    songs.a(n).clipnum=songs.a(n).endclip-songs.a(n).startclip+1;
end
true;