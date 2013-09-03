function clips = plotdtwalign(varargin)
% clips = dispdtwalign(label,varargin)
% display array of clip spectrograms 
% clips to be displayed are held in 'clipinds' field
% clips are sorted by 'values' field

dtwalign.cats = []; % category to do aligning
dtwalign.sliceftrlist = {'amp','Wentropy','freqmean','freqstd','FFgood'};
dtwalign.ftrinds = [];
dtwalign.matchtype = 'z'; % type of match to order 'z' or 'corr'
dtwalign.matchdisp = 'percent'; % type of match display 'percent' or 'hist'
dtwalign.histbins = 100; % bin argument for histogram display
dtwalign.normalize = 0; % normalize by median values
dtwalign.save = 1; % save alignftrs structure
dtwalign.alpha = .05;
dtwalign.alignftrs = [];
dtwalign.temps = [];
dtwalign.clipinds = [];
dtwalign.selclips = [];
dtwalign.curclip = [];
dtwalign.curftr = 1;
dtwalign.fileinfo = '';
dtwalign.infopath = '';
dtwalign.infofile = '';
dtwalign.bmkfile = '';
dtwalign.bmkext = ''; % .bmk or .dbk used to determine how to get specs/songs
dtwalign.bmkpath = '';
dtwalign.lblfile = '';
dtwalign.specpath = '';
dtwalign.ftrdtwfile = '';
dtwalign.ftrdtwpath = '';
dtwalign.name = '';
dtwalign.figh = [];
dtwalign.songviewer = 'sb3viewlbl';
dtwalign.viewh = -1;
dtwalign.clips = [];
dtwalign.specfloor = .05; 
% DISPLAY VARIABLES
dtwalign.figpos = [.05 .2 .6 .6];
dtwalign.selcol = 'r';
dtwalign.titlefontsize = 14;
%  INTERNAL STATE VARIABLES AND FLAGS
dtwalign.butpressed = 0;
dtwalign.sumaxh = [];
dtwalign.axh = [];
dtwalign.blowupaxh = [];
dtwalign.ftrh = [];
dtwalign.srtftrh = [];
dtwalign.srtallh = [];
dtwalign.blowupftrh = [];
dtwalign.srtblowupftrh = [];
dtwalign.curpt = [];
dtwalign.lastpt = [];
dtwalign.hasmoved = [];
dtwalign = parse_pv_pairs(dtwalign,varargin);

% if file exist load it
%% get alignftrs variable
if isempty(dtwalign.alignftrs)
    if ~(exist(fullfile(dtwalign.ftrdtwpath,dtwalign.ftrdtwfile))==2)
        [dtwalign.ftrdtwfile dtwalign.ftrdtwpath] = uigetfile({'ftrs_dtw.mat;dtw feature files'},...
            'Pick DTW feature file','Choose DTW feature file');
        if dtwalign.ftrdtwfile==0 return; end
    end
    load(fullfile(dtwalign.ftrdtwpath,dtwalign.ftrdtwfile),'-mat');
    dtwalign.alignftrs = alignftrs;

    dtwalign.temps = temps;
    dtwalign.tempedges = tempedges;
    dtwalign.labels = labels;
    dtwalign.clipinds = clipinds;
    dtwalign.clipedges = clipedges;
    dtwalign.dt = temps.specparams.dt;
    clear temps tempedges alignftrs labels clipinds clipedges
end
%% match ftr list

dtwalign.ftrinds = zeros(size(dtwalign.sliceftrlist));
for i=1:length(dtwalign.sliceftrlist)
    tmp = find(strcmp(dtwalign.sliceftrlist{i},dtwalign.alignftrs.sliceftrlist));
    if isempty(tmp)
        disp(['Can''t find slice feature ' dtwalign.sliceftrlist{i} ' in alignftrs structure. Aborting.']);
        return
    else
        dtwalign.ftrinds(i) = tmp;
    end
end
    
% %% get template from label file 
% if ~exist(fullfile(dtwalign.temppath,dtwalign.tempfile))
%     [dtwalign.tempfile dtwalign.temppath] = uigetfile({'*.lbl;label files','*;*;All files'},...
%         'Pick lable file with templates','Choose template label file');
%     if dtwalign.temppath==0 return; end
% end
% load(fullfile(dtwalign.temppath,dtwalign.tempfile),'labels','temps','-mat');
% dtwalign.temps = temps;
% locate ftr directory
% [dtwalign.ftrpath] = uigetdir( 'Choose feature directory','Choose feature directory');
% if dtwalign.ftrpath==0 return; end
% [upperpath name ext] = fileparts(dtwalign.ftrpath);

% get list of category indices
if isempty(dtwalign.cats)
    dtwalign.cats = 1;
elseif ischar(dtwalign.cats) | iscell(dtwalign.cats)
    dtwalign.cats = findlabelind(dtwalign.cats,labels);
else
    dtwalign.cats = dtwalign.cats;
end
if length(dtwalign.cats)>1
    disp('Only display one category at a time'); dtwalign.cats = dtwalign.cats(1);
end
dtwalign = init(dtwalign);
dtwalign = displayFcn(dtwalign);
set(dtwalign.figh,'userdata',dtwalign);
% --------------------------------------------------------------------
function dtwalign = init(dtwalign)
% Create the view figure and initialize structure

name = 'Clip Browser';
% look for window, if found extract data; if not initialize
figh =findobj(0,'name', name);
if ~isempty(figh)
    close(figh);
end

dtwalign.figh = figure('numbertitle','off', ...
    'color', get(0,'defaultUicontrolBackgroundColor'), ...
    'name',name, ...
    'units','normal','pos',dtwalign.figpos);
set(dtwalign.figh,...
    'WindowButtonUpFcn',@buttupFcn);
%     'WindowButtonUpFcn',@buttupFcn,...
%     'WindowButtonDownFcn',@buttdownFcn,...
%     'WindowButtonMotionFcn',@buttmotionFcn,...
%     'KeyPressFcn',@keypressFcn);
% set menus
menu.file = uimenu('parent',dtwalign.figh,'label','File');
menu.open = uimenu('parent',menu.file,'label','Open bmk file (.dbk)','callback',{@loadfile_cb,dtwalign.figh});
menu.loadfileinfo = uimenu('parent',menu.file,'label','Load info file (.inf)','callback',{@loadinfofile_cb,dtwalign.figh,'new'});
menu.selfileinfo = uimenu('parent',menu.file,'label','Load data files','callback',{@loadinfofile_cb,dtwalign.figh});
menu.select = uimenu('parent',dtwalign.figh,'label','Select');
menu.markselect = uimenu('parent',menu.select,'label','Mark Selected','callback',{@markselect_cb,dtwalign.figh});
menu.clearselect = uimenu('parent',menu.select,'label','Clear Selected','callback',{@clearselect_cb,dtwalign.figh});
menu.clearmarked = uimenu('parent',menu.select,'label','Clear Marked','callback',{@clearmarked_cb,dtwalign.figh});

dtwalign.selbuth = uicontrol('style','pushbutton','string','Export selectinds','units','points',...
    'units','normalized','position',[.7 .925 .2 .05],...
    'fontsize',dtwalign.titlefontsize,'callback',@exportselinds);
    set(dtwalign.selbuth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...
dtwalign.selbuth = uicontrol('style','pushbutton','string','Import selectinds','units','points',...
    'units','normalized','position',[.7 .85 .2 .05],...
    'fontsize',dtwalign.titlefontsize,'callback',@importselinds);
    set(dtwalign.selbuth,'units','normalized');
%     'position',[xmarg(1)+butwidth+xgap ymarg(1)+height+1.5*ygap+butheight width-butwidth-xgap butheight],...


% % -----------------------------------------------------------------
% function loadfile_cb(hco,eventStruct,figh)
% % filemenu = get(hco,'parent');
% % figh = get(filemenu,'parent');
% dtwalign = get(figh,'userdata');    
% [dtwalign.bmkfile dtwalign.bmkpath] = uigetfile({'*.bmk;*.dbk','bookmark file (*.bmk;*.dbk)'; '*.*',  'All Files (*.*)'}, 'Select bookmark file. Specs must be defined.');
% if dtwalign.bmkpath ==0 return; end
% loadfile(dtwalign);

% -----------------------------------------------------------------
function loadinfofile_cb(hco,eventStruct,figh,varargin)

dtwalign = get(figh,'userdata'); 
dtwalign = loadfileinfo('strct',dtwalign);
if isempty(dtwalign) return; end
set(figh,'userdata',dtwalign); 


% -----------------------------------------------------------------
function dtwalign = displayFcn(dtwalign)
% dtwalign = displayFcn(dtwalign)
%  set up display
ii = dtwalign.cats;
ftrnum = length(dtwalign.sliceftrlist);
tempinds = dtwalign.tempedges{ii}(1):dtwalign.tempedges{ii}(2);
times = dtwalign.dt*(tempinds);
xlim = [times(1)-dtwalign.dt times(end)+dtwalign.dt];
dtwalign.sumaxh(1) = subplot(ftrnum+2,3,1);
cla; hold on
imagesc(times,dtwalign.temps.specparams.f,abs(dtwalign.temps.tmpl{ii}(:,tempinds)));
set(gca,'ydir','normal');
set(gca,'ylim',[0 max(dtwalign.temps.specparams.f)]);
set(gca,'xlim',xlim);
% plot rms of all z
dtwalign.sumaxh(2) = subplot(ftrnum+2,3,2);
cla; hold on
z2 = dtwalign.alignftrs.a(ii).rmszall;
if strcmp(dtwalign.matchdisp,'hist')
    hist(z2,dtwalign.histbins);
else
    dtwalign.srtallh = -ones(length(z2),1);
    [tmp srtinds] = sort(z2);
    for pp=1:length(tmp)
        dtwalign.srtallh(srtinds(pp)) = plot(tmp(pp),pp/length(tmp),'.');
    end
%     plot(sort(z2),(1:length(z2))/length(z2),'.');
end
dtwalign.axh = -ones(ftrnum+1,2);
dtwalign.blowupaxh = -ones(1,2);
dtwalign.ftrh = -ones(ftrnum+1,size(dtwalign.alignftrs.a(ii).ftrs,2));
dtwalign.srtftrh = -ones(ftrnum+1,size(dtwalign.alignftrs.a(ii).ftrs,2));
dtwalign.blowupftrh = -ones(1,size(dtwalign.alignftrs.a(ii).ftrs,2));
dtwalign.srtblowupftrh = -ones(1,size(dtwalign.alignftrs.a(ii).ftrs,2));
for k=1:ftrnum
    kk = dtwalign.ftrinds(k);
    dtwalign.axh(k,1) = subplot(ftrnum+2,3,3*k+1);
    cla; hold on
    tmp = squeeze(dtwalign.alignftrs.a(ii).ftrs(kk,:,:));
    if dtwalign.normalize
        for pp=1:size(tmp,1)
            dtwalign.ftrh(k,pp) = plottr(times,tmp(pp,:)./median(tmp(pp,:)),dtwalign.alpha);
        end
    else
        for pp=1:size(tmp,1)
            dtwalign.ftrh(k,pp) = plottr(times,tmp(pp,:),dtwalign.alpha);
        end
    end
    ylabel(dtwalign.sliceftrlist{k});
    set(gca,'xlim',xlim);
        
    dtwalign.axh(k,2) = subplot(ftrnum+2,3,3*k+2);
    cla; hold on
    if strcmp(dtwalign.matchtype,'z')
        tmp = dtwalign.alignftrs.a(ii).rmsz(kk,:);
    else
        tmp = dtwalign.alignftrs.a(ii).corr(kk,:);
    end
    if strcmp(dtwalign.matchdisp,'hist')
        hist(tmp,dtwalign.histbins);
    else
        [tmp2 srtinds] = sort(tmp);
        for pp=1:length(tmp)
            dtwalign.srtftrh(k,srtinds(pp)) = plot(tmp2(pp),pp/length(tmp),'.');
        end
    end
    if dtwalign.curftr==k
        dtwalign.blowupaxh(1) = subplot(ftrnum+2,3,6+[0,3*floor((ftrnum+1)/2)]);
        cla; hold on
        tmp = squeeze(dtwalign.alignftrs.a(ii).ftrs(kk,:,:));
        if dtwalign.normalize
            for pp=1:size(tmp,1)
                dtwalign.blowupftrh(pp) = plottr(times,tmp(pp,:)./median(tmp(pp,:)),dtwalign.alpha);
            end
        else
            for pp=1:size(tmp,1)
                dtwalign.blowupftrh(pp) = plottr(times,tmp(pp,:),dtwalign.alpha);
            end
        end
        ylabel(dtwalign.sliceftrlist{k});
        set(gca,'xlim',xlim);
        
        dtwalign.blowupaxh(2) = subplot(ftrnum+2,3,[6+3*(1+floor((ftrnum+1)/2)),3*(ftrnum+2)]);
        cla; hold on
        if strcmp(dtwalign.matchtype,'z')
            tmp = dtwalign.alignftrs.a(ii).rmsz(kk,:);
        else
            tmp = dtwalign.alignftrs.a(ii).corr(kk,:);
        end
        if strcmp(dtwalign.matchdisp,'hist')
            hist(tmp,dtwalign.histbins);
        else
            [tmp2 srtinds] = sort(tmp);
            for pp=1:length(tmp)
                dtwalign.srtblowupftrh(srtinds(pp)) = plot(tmp2(pp),pp/length(tmp),'.');
            end
        end
    end
end
% display match values along path
dtwalign.axh(ftrnum+1,1)= subplot(ftrnum+2,3,3*(ftrnum+1)+1);
cla; hold on
tmp = dtwalign.alignftrs.a(ii).Dpnorm;
if dtwalign.normalize
    for pp=1:size(tmp,1)
        dtwalign.ftrh(ftrnum+1,pp) = plottr(times,tmp(pp,:)./median(tmp(pp,:)),dtwalign.alpha);
    end
else
    for pp=1:size(tmp,1)
        dtwalign.ftrh(ftrnum+1,pp) = plottr(times,tmp(pp,:),dtwalign.alpha);
    end
end
ylabel('match');
set(gca,'xlim',xlim);
dtwalign.axh(ftrnum+1,2)= subplot(ftrnum+2,3,3*(ftrnum+1)+2);
cla; hold on
if strcmp(dtwalign.matchtype,'z')
    tmp = dtwalign.alignftrs.a(ii).rmsDpnorm;
else
    tmp = dtwalign.alignftrs.a(ii).Dpcorr;
end
cla; hold on
if strcmp(dtwalign.matchdisp,'hist')
    hist(tmp,dtwalign.histbins);
else
    [tmp2 srtinds] = sort(tmp);
    for pp=1:length(tmp)
        dtwalign.srtftrh(ftrnum+1,srtinds(pp)) = plot(tmp2(pp),pp/length(tmp),'.');
    end
end
if dtwalign.curftr==ftrnum+1
    dtwalign.blowupaxh(1) = subplot(ftrnum+2,3,6+[0,3*floor((ftrnum+1)/2)]);
    cla; hold on
    tmp = dtwalign.alignftrs.a(ii).Dpnorm;
    if dtwalign.normalize
        for pp=1:size(tmp,1)
            dtwalign.blowupftrh(pp) = plottr(times,tmp(pp,:)./median(tmp(pp,:)),dtwalign.alpha);
        end
    else
        for pp=1:size(tmp,1)
            dtwalign.blowupftrh(pp) = plottr(times,tmp(pp,:),dtwalign.alpha);
        end
    end
    ylabel('match');
    set(gca,'xlim',xlim);
    dtwalign.blowuph(2) = subplot(ftrnum+2,3,[6+3*(1+floor((ftrnum+1)/2)),3*(ftrnum+2)]);
    cla; hold on
    if strcmp(dtwalign.matchtype,'z')
        tmp = dtwalign.alignftrs.a(ii).rmsDpnorm;
    else
        tmp = dtwalign.alignftrs.a(ii).Dpcorr;
    end
    cla; hold on
    if strcmp(dtwalign.matchdisp,'hist')
        hist(tmp,dtwalign.histbins);
    else
        [tmp2 srtinds] = sort(tmp);
        for pp=1:length(tmp)
            dtwalign.srtblowupftrh(srtinds(pp)) = plot(tmp2(pp),pp/length(tmp),'.');
        end
    end
end
% % --------------------------------------------------------------------
% function buttdownFcn(hco,eventStruct)
% % button press in a particular axis or control button
% 
% dtwalign = get(hco,'userdata');
% 
% dtwalign.butpressed = 1;
% dtwalign.curpt = get(gca,'currentpoint');
% dtwalign.lastpt = dtwalign.curpt;
% % locate axis
% tmp = find(gca==dtwalign.axh);
% if ~isempty(tmp)
%     if(tmp<=length(stwalign.sliceftrlist)+1)
%         dtwalign.curftr = tmp;
%         
%     tmp = find(gca==dtwalign.blowupaxh);
%     dtwalign.
% 
%     
%     
% set(hco,'userdata',dtwalign);

% % --------------------------------------------------------------------
% function buttmotionFcn(hco,eventStruct)
% % button motion function, general to fig
% dtwalign = get(hco,'userdata');
% % dtwalign.butpressed
% switch dtwalign.butpressed
%     case 1 % left button press     
%         axind = find(strcmpi(dtwalign.ax.names,dtwalign.curtag));
%         if ~isempty(axind)
%             switch dtwalign.curtag
%                 case 'scroll'
%                 dtwalign.curpt = get(dtwalign.ax.h(axind),'currentpoint');
%                 midpt = min(max(dtwalign.curpt(1,2), dtwalign.disprowN/2+.5), dtwalign.rowN-dtwalign.disprowN/2+.5);
%                 ylim = midpt+dtwalign.disprowN*[-.5 .5];
%                 set(dtwalign.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
%                 set(dtwalign.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
%             end
%             dtwalign.hasmoved = 1;
%             set(hco,'userdata',dtwalign);
%             return
%         end 
% end
% 
% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

dtwalign = get(hco,'userdata');

dtwalign.butpressed = 1;
dtwalign.curpt = get(gca,'currentpoint');
dtwalign.lastpt = dtwalign.curpt;
% locate axis
tmp = find(gca==dtwalign.axh);
if ~isempty(tmp)
    if(tmp<=length(dtwalign.sliceftrlist)+1)
        dtwalign.curftr = tmp;
        dtwalign = displayFcn(dtwalign);
    end
end
%         
%     tmp = find(gca==dtwalign.blowupaxh);
%     dtwalign.

    
    
% 
% if ~isempty(axind)
%     switch dtwalign.curtag
%         case 'array'
%             % locate selected clip          
%             dtwalign.curpt = get(dtwalign.ax.h(axind),'currentpoint');
%             row = round(abs(dtwalign.curpt(1,2)));
%             lastrow = round(abs(dtwalign.lastpt(1,2)));
%             if row>=1 && row<= dtwalign.rowN 
%                 [val col] = min(abs(dtwalign.colcenters-dtwalign.curpt(1,1)));
%                 [val lastcol] = min(abs(dtwalign.colcenters-dtwalign.lastpt(1,1)));
%                 dtwalign.curclip = ((row-1)*dtwalign.colN+col);
%                 lastclip = ((lastrow-1)*dtwalign.colN+lastcol);
% %                 [lastclip dtwalign.curclip]
%                 switch get(hco,'selectiontype')
%                     case 'normal' % single click - select/deselect clip, clear other seleted clips
%                         tmpind = find(dtwalign.selclips==dtwalign.curclip);
%                         delete(dtwalign.selh(ishandle(dtwalign.selh)));
%                         dtwalign.selh = [];
%                         dtwalign.selclips = [];
%                         if isempty(tmpind)
%                             dtwalign.selclips = dtwalign.curclip;
%                             dy = .02;
%                             dtwalign.selh(1) = rectangle('position', [dtwalign.colcenters(col)-dtwalign.maxwidth/2 row-.5+dy dtwalign.maxwidth 1-2*dy]);
%                                 set(dtwalign.selh(end),'linewidth',dtwalign.selwidth,'edgecolor',dtwalign.selcol);
%                         end
%                     case 'alt' % single ctrl click - select/deselect clip, but don't clear
%                         tmpind = find(dtwalign.selclips==dtwalign.curclip);
%                         if isempty(tmpind)
%                             dtwalign.selclips(end+1) = dtwalign.curclip;
%                             dy = .02;
%                             dtwalign.selh(end+1) = rectangle('position', [dtwalign.colcenters(col)-dtwalign.maxwidth/2 row-.5+dy dtwalign.maxwidth 1-2*dy]);
%                                 set(dtwalign.selh(end),'linewidth',dtwalign.selwidth,'edgecolor',dtwalign.selcol);
%                         else
%                             delete(dtwalign.selh(tmpind));
%                             dtwalign.selh(tmpind) = [];
%                             dtwalign.selclips(tmpind) = [];
%                         end
%                     case 'extend' % single shift click - select clips between button down and button up positon, keep others
%                         selinds = min(dtwalign.curclip,lastclip):max(dtwalign.curclip,lastclip);
%                         newinds = setdiff(selinds, dtwalign.selclips);
%                         oldinds = intersect(dtwalign.selclips,selinds);
% %                         for i=1:length(oldinds)
% %                             tmpind = find(dtwalign.selclips==oldinds(i));
% %                             delete(dtwalign.selh(tmpind));
% %                             dtwalign.selh(tmpind) = [];
% %                             dtwalign.selclips(tmpind) = [];
% %                         end
%                         for i=1:length(newinds)
%                             dtwalign.selclips(end+1) = newinds(i);
%                             dy = .02;
%                             tmprow = ceil(newinds(i)/dtwalign.colN);
%                             tmpcol = newinds(i)-(tmprow-1)*dtwalign.colN;
%                             dtwalign.selh(end+1) = rectangle('position', [dtwalign.colcenters(tmpcol)-dtwalign.maxwidth/2 tmprow-.5+dy dtwalign.maxwidth 1-2*dy]);
%                                 set(dtwalign.selh(end),'linewidth',dtwalign.selwidth,'edgecolor',dtwalign.selcol);
%                         end
%                     case 'open' % double click - display clip
%                         seps = find(dtwalign.bmkpath==filesep);
%                         if seps(end) == length(dtwalign.bmkpath)
%                             name = dtwalign.bmkpath(seps(end-1):end-1);
%                         else
%                             name = dtwalign.bmkpath(seps(end)+1:end);
%                         end
%                         dtwalign.clipinds(dtwalign.curclip)
%                         dtwalign.viewh = dispclipsong(dtwalign.clipinds(dtwalign.curclip),...
%                                             'bmkfile',dtwalign.bmkfile,'bmkpath',dtwalign.bmkpath,...
%                                             'lblfile',dtwalign.lblfile,'lblpath',dtwalign.bmkpath);
% %                         dtwalign.viewh = dispclipsongfile(fullfile([dtwalign.rootdir filesep dtwalign.bmkpath],dtwalign.bmkfile),...
% %                                     dtwalign.clipinds(dtwalign.curclip),...
% %                                     'labelfile',fullfile([dtwalign.rootdir filesep dtwalign.bmkpath],dtwalign.bmkfile),...
% %                                     'viewh',dtwalign.viewh,'songviewer',dtwalign.songviewer);
%                 end 
%             end
%         case 'scroll'
%             dtwalign.curpt = get(dtwalign.ax.h(axind),'currentpoint');
%             midpt = min(max(dtwalign.curpt(1,2), dtwalign.disprowN/2+.5), dtwalign.rowN-dtwalign.disprowN/2+.5);
%             ylim = midpt+dtwalign.disprowN*[-.5 .5];
%             set(dtwalign.scrh,'ydata',[ylim(1) ylim(1) ylim(2) ylim(2)]);
%             set(dtwalign.ax.h(1),'ylim',ylim); % hard code main axis as axis 1
%     end
% end 
dtwalign.hasmoved = 0;
dtwalign.butpressed = 0;
set(hco,'userdata',dtwalign);


% % --------------------------------------------------------------------
% function exportselinds(hco,eventStruct)
% 
% figh = get(hco,'parent');
% dtwalign = get(figh,'userdata');
% disp(['Saved to base workspace: selectinds = [' sprintf('%d ',dtwalign.clipinds(dtwalign.selclips)) '];']);
% assignin('base','selectinds',dtwalign.clipinds(dtwalign.selclips));

% --------------------------------------------------------------------
function importselinds(hco,eventStruct)

tmp = evalin('base','who(''selectinds'')');
if isempty(tmp)
    disp('No variable in workspace named selectinds');
else
    figh = get(hco,'parent');
    dtwalign = get(figh,'userdata');
    selectinds = evalin('base','selectinds');
    [findselect inds1 inds2] = intersect(selectinds,dtwalign.alignftrs.a(dtwalign.cats).clips);
    if length(findselect)<length(selectinds)
        diffinds = setdiff(selectinds,findselect);
        disp(['Couldn''t find clips = [' sprintf('%d ',diffinds) '];']);
    end
    dtwalign.selclips = inds2;
    for k=1:length(dtwalign.sliceftrlist)+1
        set(dtwalign.ftrh(k,inds2),'edgecolor',dtwalign.selcol);
        tmpinds = inds2(ishandle(dtwalign.srtftrh(k,inds2)));
        if ~isempty(tmpinds)
            set(dtwalign.srtftrh(k,tmpinds),'color',dtwalign.selcol);
        end
    end
    set(dtwalign.blowupftrh(inds2),'edgecolor',dtwalign.selcol);
    tmpinds = inds2(ishandle(dtwalign.srtblowupftrh(inds2)));
    if ~isempty(tmpinds)
        set(dtwalign.srtblowupftrh(tmpinds),'color',dtwalign.selcol);
    end
    tmpinds = inds2(ishandle(dtwalign.srtallh(inds2)));
    if ~isempty(tmpinds)
        set(dtwalign.srtallh(tmpinds),'color',dtwalign.selcol);
    end
end


