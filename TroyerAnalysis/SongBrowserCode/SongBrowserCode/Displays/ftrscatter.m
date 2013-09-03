function figh = ftrscatter(varargin)
% figh = ftrscatter(varargin)
% display grid of 2D feature combinations show clip upon double click
% ftrs is matrix of ftr values. rows one per clip, columns each feature
%   can be found as clipftrs variable in .ftr file
% ftrnames is cell array of feature names (clipftrlist in .ftr)
% labels and clips are standard variables in .lbl and .bmk files

% main data
scatfig.ftrs = [];
scatfig.ftrnames = [];
scatfig.clips = [];
scatfig.songs = []; % only needed for disptype = song
scatfig.labels = [];
scatfig.correctlbl = []; % optional binary vector indicating which clips have 
    % have been correctly labeled. Incorrect labels have different symbol
scatfig.name = ''; % 
scatfig.choosebmk = 0;
scatfig.chooseftr = 0;
scatfig.specparams = defaultspecparams;
scatfig.bmktype = 'bmk'; % type of file where wav file come from, 'bmk' or 'dbk'
scatfig.wavpath = []; % path for wav files
% paramaters
scatfig.binnum = 100; % number of bins in histogram along diagonal
scatfig.ftrstd = 1; % standard deviations to plot around each cluster center if 0 don't plot
% display variables
scatfig.ftrlist = {'length','amp_mn','freqmean_mn','freqstd_mn','Wentropy_mn','FFgood_mn','ampdiff'}; % features that will be shown
scatfig.chans = 1; % number of channels recorded
scatfig.showcats = []; % categories that will be plotted (binary vector)
scatfig.disptype = 'song'; % 'spec' or 'song'
scatfig.newdispfig = 0; % =1 creates new clip display figure on each click
scatfig.markersize = 3;
scatfig.title = '';
scatfig.titlefontsize = 14;
scatfig.labelfontsize = 12;
scatfig.fontsize = 11;
scatfig.correctmarker = 'o';
scatfig.incorrectmarker = 'x';
scatfig.colors = [];
% handles
scatfig.figh = -1;
scatfig.selfigh = -1; % fig handle of fig that contains buttons
scatfig.dispfigh = []; % list of figure handles to figures for displaying clip information
scatfig.axh = -1; % stores axis handles
scatfig.axposh = -1; % stores horizontal position of axis origin
scatfig.axposv = -1; % stores vertical position of axis origin
scatfig.daxposh = 0; % stores horizontal gap between axes
scatfig.daxposv = 0; % stores vertical gap between axes
scatfig.blowupax = [2 1]; % coordinate axis that is copied to blowup ax
scatfig.blowuph = -1; % handle of axis for blowup 
scatfig.bgaxh = -1; % handle of background axis used to write labels etc.
scatfig.bgsqh = -1; % handle of red square around bg axis
scatfig.curtxth = -1; % handle of txt near current selected pt
scatfig.curpth = -1; % handle of marker surrounding current selected pt

scatfig = parse_pv_pairs(scatfig,varargin);

% load necessary data
if isempty(scatfig.labels)
    [labelfile,labelpath] = uigetfile({'*.lbl;*.mlbl','label files (*.lbl,*.mlbl)';'*.*','All files'},...
        'Pick label file','Choose label file');
    if labelpath==0 return; end
    load(fullfile(labelpath,labelfile),'-mat');
    scatfig.labels = labels;
    clear labels
end
if isempty(scatfig.showcats)
    scatfig.showcats = ones(size(scatfig.labels.labelkey)); % categories that will be plotted (binary vector)
end
if isempty(scatfig.colors)
    % scatfig.disphandles = -ones(length(scatfig.showcats),2); % handle for each set of points plotted
    % set default colormap - use hsv but skip colors so that nearby cats don't
    % have adjacent colors
    tmp = hsv(length(scatfig.labels.labelkey));
    scatfig.colors = zeros(size(tmp));
    tmpinds1 = 1:2:size(tmp,1);
    tmpinds2 = 2:2:size(tmp,1);
    scatfig.colors(tmpinds1,:) = tmp(1:length(tmpinds1),:);
    scatfig.colors(tmpinds2,:) = tmp(length(tmpinds1)+(1:length(tmpinds2)),:);
end
if isempty(scatfig.name)
    [path name ext] = fileparts(labelfile);
    scatfig.name = name;
end

% load clips and songs from bookmark file
if isempty(scatfig.clips)
    if ~exist(fullfile(labelpath,scatfig.labels.clipfile)) | scatfig.choosebmk
        [bmkfile,bmkpath] = uigetfile({'*.bmk,*.dbk;bookmark files','*;*;All files'},...
            'Pick bookmark file','Choose bookmark file');
        if bmkfile==0 return; end
    else
        load(fullfile(labelpath,scatfig.labels.clipfile),'-mat');
        bmkfile = scatfig.labels.clipfile;
        bmkpath = labelpath;
    end
    [path name ext] = fileparts(bmkfile);
    scatfig.bmktype = ext;
    scatfig.bmkfile = bmkfile;
    scatfig.wavpath = [bmkpath name '_wav'];
    load(fullfile(bmkpath,bmkfile),'-mat');
    scatfig.clips = clips;
    scatfig.songs = songs;
    clear clips songs
end

% load .ftr file
if isempty(scatfig.ftrs) | isempty(scatfig.ftrnames)
    if ~exist(fullfile(labelpath,[name '.ftr'])) | scatfig.chooseftr
        [ftrfile,ftrpath] = uigetfile({'*.ftr;feature file','*;*;All files'},...
            'Pick feature file','Choose feature file');
        if ftrfile==0 return; end
    else
        load(fullfile(labelpath,[name '.ftr']),'-mat');
        ftrfile = [name '.ftr'];
        ftrpath = labelpath;
    end
    load(fullfile(ftrpath,ftrfile),'-mat');
    scatfig.ftrs = clipftrs;
    scatfig.ftrnames = clipftrlist;
    scatfig.specparams = specparams;
    scatfig.ftrranges = [min(scatfig.ftrs); max(scatfig.ftrs)];
    scatfig.ftrranges = [1; 1]*mean(scatfig.ftrranges)+[-.55; .55]*diff(scatfig.ftrranges);
    clear clipftrs clipftrlist specparams
end
if isempty(scatfig.correctlbl)
    scatfig.correctlbl  = ones(size(scatfig.ftrs,1),1);
end
% set ftrlist to be binary string
if iscell(scatfig.ftrlist)
    ftrlist = zeros(size(scatfig.ftrnames));
    for i=1:length(scatfig.ftrlist)
        ind = find(strcmp(scatfig.ftrlist{i},scatfig.ftrnames));
        ftrlist(ind) = 1;
    end
    scatfig.ftrlist = ftrlist; % change from cell array of names to binary vector
end
% remove ampdiff if equal to amp_mn
amp_mnind = find(strcmp(scatfig.ftrnames,'amp_mn'));
ampdiffind = find(strcmp(scatfig.ftrnames,'ampdiff'));
if ~isempty(amp_mnind) & ~isempty(ampdiffind)
    if sum(scatfig.ftrs(:,amp_mnind)==scatfig.ftrs(:,ampdiffind))==size(scatfig.ftrs,1)
        scatfig.ftrlist(ampdiffind)=0;
    end
end

% reduce everything to ftrs on ftrlist
scatfig.ftrs = scatfig.ftrs(:,scatfig.ftrlist==1);
scatfig.ftrnames = scatfig.ftrnames(scatfig.ftrlist==1);
scatfig.ftrranges = scatfig.ftrranges(:,scatfig.ftrlist==1);
scatfig.ftrlist = scatfig.ftrlist(scatfig.ftrlist==1);


% reorder data to align with displayed data
scatfig.catnum = length(scatfig.labels.labelkey);
scatfig.ftrscorr = cell(scatfig.catnum,2); % second column holds vector of clip numbers
scatfig.ftrsincorr = cell(scatfig.catnum,2); % second column holds vector of clip numbers
scatfig.ftrmns = zeros(scatfig.catnum,sum(scatfig.ftrlist)); % hold mean feature value for each category
scatfig.ftrstds = zeros(scatfig.catnum,sum(scatfig.ftrlist)); % holds std of feature values for each category
scatfig.covmat = cell(scatfig.catnum,1); % covariance matrix of points for each category
scatfig.invcovmat = cell(scatfig.catnum,1); % inverse of covariance matrix of points for each category
for c=1:scatfig.catnum
    scatfig.ftrscorr{c,2} = find([scatfig.labels.a.labelind]'==c & scatfig.correctlbl==1);
    scatfig.ftrscorr{c,1} = scatfig.ftrs(scatfig.ftrscorr{c,2},scatfig.ftrlist==1);
    scatfig.ftrsincorr{c,2} = find([scatfig.labels.a.labelind]'==c & scatfig.correctlbl==0);
    scatfig.ftrsincorr{c,1} = scatfig.ftrs(scatfig.ftrsincorr{c,2},scatfig.ftrlist==1);
    % find means, stds and covariance matrices
    alldata = [scatfig.ftrscorr{c,1};scatfig.ftrsincorr{c,1}];
    if size(alldata,1)<2
        scatfig.ftrmns(c,:) = alldata;
        scatfig.ftrstds(c,:) = zeros(size(alldata));
        scatfig.covmat{c} = zeros(length(alldata),length(alldata));
        scatfig.invcovmat{c} = zeros(length(alldata),length(alldata));
    else
        scatfig.ftrmns(c,:) = mean(alldata);
        scatfig.ftrstds(c,:) = std(alldata);
        alldata = alldata-ones(size(alldata,1),1)*scatfig.ftrmns(c,:);
        scatfig.covmat{c} = (alldata'*alldata)/size(alldata,1);
        if size(alldata,1)<length(scatfig.ftrnames)+1 % covmat illconditioned
            scatfig.invcovmat{c} = diag(1./(scatfig.ftrstds.^2));
        else
            scatfig.invcovmat{c} = inv(scatfig.covmat{c});
        end
    end
end

scatfig.ftrscorrh = -1*ones(scatfig.catnum,1); % handle of plotted points
scatfig.ftrsincorrh = -1*ones(scatfig.catnum,1); % handle of plotted points

%remove underscore from ftrnames to avoid tex-like subscripting
for i=1:length(scatfig.ftrnames)
    scatfig.ftrnames{i}(scatfig.ftrnames{i}=='_')=' ';  
end

%% initialize main figure
figh =findobj(0,'name', ['Feature scatterplot']);
if isempty(figh)
    figh = figure('numbertitle','off', ...
        'color', get(0,'defaultUicontrolBackgroundColor'), ...
        'name','Feature scatterplot', ...
        'doublebuffer','on', 'backingstore','off', ...
        'units','normal');
    %     'integerhandle','off', 'vis','on', ...
    scatfig.figh = figh;
    set(scatfig.figh,...
        'WindowButtonUpFcn',@buttonupfcn);
    %     'WindowButtonDownFcn',@buttdownFcn,...
    %     'WindowButtonUpFcn',@buttupFcn,...
    %     'WindowButtonMotionFcn',@buttmotionFcn,...
    %     'KeyPressFcn',@keypressFcn);
    %     'ResizeFcn',@winresizeFcn
    menu.disptype = uimenu('parent',scatfig.figh,'label','Disp Type');
    menu.spec = uimenu('parent',menu.disptype,'label','Spec','callback',{@seldisptype,scatfig.figh,'spec'});
    menu.song = uimenu('parent',menu.disptype,'label','Song','callback',{@seldisptype,scatfig.figh,'song'});
    if strcmp(lower(scatfig.disptype),'spec')
        set(menu.spec,'checked','on');
    else
        set(menu.song,'checked','on');
    end
    menu.display = uimenu('parent',scatfig.figh,'label','Display');
    menu.new = uimenu('parent',menu.display,'label','New','callback',{@adddisplay,scatfig.figh});
    menu.displays = [];
    scatfig.menu = menu;
else
    tmpscatfig = get(figh,'userdata');
    scatfig.menu = tmpscatfig.menu;
    scatfig.figh = figh;
    clf(scatfig.figh);
end
set(figh,'userdata',scatfig);
%% initialize buttons figure
figh =findobj(0,'name', ['Feature selector']);
if isempty(figh)
    figh = figure('numbertitle','off', ...
        'color', [1 1 1], ...
        'name','Feature selector', ...
        'doublebuffer','on', 'backingstore','off', ...
        'integerhandle','off', 'vis','on', ...
        'units','points');
    %     'color', get(0,'defaultUicontrolBackgroundColor'), ...
end
scatfig.selfigh = figh;
clf(scatfig.selfigh);
figure(scatfig.selfigh);
fontsize = 12;
ftrbutwidth = 108;
catbutwidth = 72;
axwidth = 24;
rownum = max(length(scatfig.ftrnames),scatfig.catnum)+1;
figheight = 2*fontsize+2*rownum*fontsize+(rownum-1)*fontsize/2;
figwidth = ftrbutwidth+catbutwidth+axwidth+4*fontsize;
set(scatfig.selfigh,'position',[72 72 figwidth figheight]);
% make structure to store with selection figure
selfig.scatfigh = scatfig.figh;
selfig.disph = uicontrol('style','pushbutton','string','Update','units','points',...
    'position',[fontsize figheight-fontsize-2*fontsize figwidth-2*fontsize 2*fontsize],...
    'callback',@displayscat_cb);
selfig.ftrbuth = -ones(length(scatfig.ftrnames),1);
for i=1:length(scatfig.ftrnames)
    selfig.ftrbuth(i) = uicontrol('style','checkbox','string',scatfig.ftrnames{i},'units','points',...
    'position',[fontsize figheight-fontsize-2*(i+1)*fontsize-(i/2)*fontsize ftrbutwidth 2*fontsize],...
    'value',scatfig.ftrlist(i));
end
selfig.catbuth = -ones(scatfig.catnum,1);
for i=1:scatfig.catnum
    clipnum = sum([scatfig.labels.a.labelind]==i);
    str = makelabelstr(scatfig.labels.labelkey(i),scatfig.labels.label2key(i), scatfig.labels.label3key{i});
    str = [str ' (' num2str(clipnum) ')'];
    selfig.catbuth(i) = uicontrol('style','checkbox','string',str,'units','points',...
    'position',[2*fontsize+ftrbutwidth figheight-fontsize-2*(i+1)*fontsize-(i/2)*fontsize catbutwidth 2*fontsize],...
    'value',scatfig.showcats(i),'foregroundcolor',scatfig.colors(i,:),'fontweight','bold');
end
set(figh,'userdata',selfig);


scatfig = displayscat(scatfig.figh);
% % data cursor mode
% scatfig.cm_obj = datacursormode(figh);
% set(scatfig.cm_obj,'DisplayStyle','datatip',...
%     'SnapToDataVertex','on','Enable','on',...
%     'updatefcn',@displayclip)

set(scatfig.figh,'userdata',scatfig);



%---------------------------------------
% display callback function
function displayscat_cb(hco,event_obj)
selfigh = get(hco,'parent');
selfig = get(selfigh,'userdata');
scatfig = get(selfig.scatfigh,'userdata');
for i=1:length(scatfig.ftrnames)
    scatfig.ftrlist(i) = get(selfig.ftrbuth(i),'value'); 
end
for i=1:scatfig.catnum
    scatfig.showcats(i) = get(selfig.catbuth(i),'value'); 
end
set(selfig.scatfigh,'userdata',scatfig);
scatfig = displayscat(selfig.scatfigh);
set(selfig.scatfigh,'userdata',scatfig);

%---------------------------------------
% display function
function scatfig = displayscat(figh)

figure(figh)
% clf(figh);
scatfig = get(figh,'userdata');

ftrinds = find(scatfig.ftrlist == 1);
ftrnum = length(ftrinds);
scatfig.axh = zeros(ftrnum,ftrnum);
scatfig.axposh = zeros(ftrnum,1);
scatfig.axposv = zeros(ftrnum,1);
% show histogram of points along diagonal
for i=1:length(ftrinds)
    [n x] = hist(scatfig.ftrs(:,ftrinds(i)),scatfig.binnum);
    scatfig.axh(i,i) = subplot(ftrnum,ftrnum,i+(i-1)*ftrnum,'align');
    tmppos = get(scatfig.axh(i,i),'position');
    scatfig.axposh(i) = tmppos(1);
    scatfig.axposv(i) = tmppos(2);
    cla; hold on
    bar(x,n,'k');
    set(gca,'xlim',scatfig.ftrranges(:,ftrinds(i)));
        if i==1
            ylabel(scatfig.ftrnames{ftrinds(i)});
        end
        if i==length(ftrinds)
            xlabel(scatfig.ftrnames{ftrinds(i)});
        end
end
scatfig.daxposh = diff(scatfig.axposh(1:2))-tmppos(3);
scatfig.daxposv = -diff(scatfig.axposv(1:2))-tmppos(4);
% define angles for cluster plots
angles = (0:360)*(2*pi)/360;
% show scatter plots
for c=length(scatfig.showcats):-1:1        
    for i=1:length(ftrinds)
        for j=i+1:length(ftrinds)
            scatfig.axh(j,i) = subplot(ftrnum,ftrnum,i+(j-1)*ftrnum,'align');
            hold on;
            p1 = plot(scatfig.ftrscorr{c,1}(:,ftrinds(i)),scatfig.ftrscorr{c,1}(:,ftrinds(j)),scatfig.correctmarker);
                set(p1,'markeredgecolor',scatfig.colors(c,:),'markersize',scatfig.markersize);
            p2 = plot(scatfig.ftrsincorr{c,1}(:,ftrinds(i)),scatfig.ftrsincorr{c,1}(:,ftrinds(j)),scatfig.incorrectmarker);
                set(p2,'markeredgecolor',scatfig.colors(c,:),'markersize',scatfig.markersize);
            if scatfig.ftrstd>0
                c1 = plot(scatfig.ftrmns(c,ftrinds(i)),scatfig.ftrmns(c,j),'x');
                    set(c1,'markeredgecolor',scatfig.colors(c,:),'markersize',2*scatfig.markersize);
                if max(scatfig.ftrstds(c,:))>0
                    c2 = plot(scatfig.ftrmns(c,ftrinds(i))+scatfig.ftrstd*scatfig.ftrstds(c,ftrinds(i))*sin(angles),...
                            scatfig.ftrmns(c,ftrinds(j))+scatfig.ftrstd*scatfig.ftrstds(c,ftrinds(j))*cos(angles));
                        set(c2,'color',scatfig.colors(c,:));
                end
            end
            if scatfig.showcats(c)==0
                set(p1,'visible','off');
                set(p2,'visible','off');
                set(c1,'visible','off');
                if max(scatfig.ftrstds(c,:))>0
                    set(c2,'visible','off');
                end
            end
            set(gca,'xlim',scatfig.ftrranges(:,ftrinds(i)));
            set(gca,'ylim',scatfig.ftrranges(:,ftrinds(j)));
            if i==1
                ylabel(scatfig.ftrnames{ftrinds(j)});
            end
            if j==length(ftrinds)
                xlabel(scatfig.ftrnames{ftrinds(i)});
            end
        end
    end
end
% plot data in blowup axis
scatfig.blowupaxh = subplot(ftrnum,ftrnum,[floor(ftrnum/2)+1,ftrnum*floor(ftrnum/2)-rem(ftrnum,2)]);
scatfig = plotblowup(scatfig);

% write titles
% if ishandle(scatfig.bgaxh)
%     delete(scatfig.bgaxh)
% end
% scatfig.bgaxh = axes('position',[0 0 1 1]);
% cla; hold on
% set(scatfig.bgaxh,'xlim',[0 1],'xtick',[],'ylim',[0 1],'ytick',[]);
% axes(scatfig.bgaxh);
%     for i=1:length(ftrinds)
%     %     tt = text(scatfig.axposh(1)-1.5*scatfig.daxposh,scatfig.axposv(i),scatfig.ftrnames{ftrinds(i)});
%     %         set(tt,'rotation',90)
%     %     tt = text(scatfig.axposh(i),...
%     %             scatfig.axposv(length(ftrinds))-1.5*scatfig.daxposv,scatfig.ftrnames{ftrinds(i)});
%         axes(scatfig.axh(i,1));
%         xlim = get(scatfig.axh(i,1),'xlim');
%         ylim = get(scatfig.axh(i,1),'ylim');
%         tt = text(xlim(1)-.1*length(ftrinds)*diff(xlim),ylim(1),scatfig.ftrnames{ftrinds(i)});
%             set(tt,'verticalalignme','middle','rotation',90)
%         axes(scatfig.axh(end,i));
%         xlim = get(scatfig.axh(end,i),'xlim');
%         ylim = get(scatfig.axh(end,i),'ylim');
%         tt = text(xlim(1),ylim(1)-.1*length(ftrinds)*diff(ylim),scatfig.ftrnames{ftrinds(i)});
%     end
% draw red line around blown up axis
tmph = scatfig.axposh(scatfig.blowupax(2));
tmph = [tmph tmph+diff(scatfig.axposh(1:2))]-(scatfig.daxposh/2)*[1 1];
tmpv = scatfig.axposv(scatfig.blowupax(1));
tmpv = [tmpv tmpv-diff(scatfig.axposv(1:2))]-(scatfig.daxposv/2)*[1 1];
scatfig.bgsqh = plot(tmph([1 2 2 1 1]),tmpv([1 1 2 2 1]),'r');
% set(scatfig.bgaxh,'visible','off');
   
set(scatfig.figh,'userdata',scatfig);
  
% --------------------------------------------------------------------
function scatfig = plotblowup(scatfig)
% plot data in blowup axis
axes(scatfig.blowupaxh)
cla reset; hold on
if scatfig.blowupax(1) == scatfig.blowupax(2)
    [n x] = hist(scatfig.ftrs(:,scatfig.blowupax(1)),scatfig.binnum);
    bar(x,n,'k');
    xlabel(scatfig.ftrnames{scatfig.blowupax(1)});
    ylabel('');
else
    % define angles for cluster plots
    angles = (0:360)*(2*pi)/360;
    for c=scatfig.catnum:-1:1
%         cordata = scatfig.ftrs([scatfig.labels.a.labelind]'==c & scatfig.correctlbl==1,scatfig.blowupax);
%         incordata = scatfig.ftrs([scatfig.labels.a.labelind]'==c & scatfig.correctlbl==0,scatfig.blowupax);
        for i=scatfig.blowupax(2)
            for j=scatfig.blowupax(1)
                if ~isempty(scatfig.ftrscorr{c,1}(:,i))
                    scatfig.ftrscorrh(c) = plot(scatfig.ftrscorr{c,1}(:,i),scatfig.ftrscorr{c,1}(:,j),scatfig.correctmarker);
                        set(scatfig.ftrscorrh(c),'markeredgecolor',scatfig.colors(c,:),'markersize',scatfig.markersize);
                    if scatfig.showcats(c)==0
                        set(scatfig.ftrscorrh(c),'visible','off');
                    end
                else
                    scatfig.ftrscorrh(c) = -1;
                end
                if ~isempty(scatfig.ftrsincorr{c,1}(:,i))
                    scatfig.ftrsincorrh(c) = plot(scatfig.ftrsincorr{c,1}(:,i),scatfig.ftrsincorr{c,1}(:,j),scatfig.incorrectmarker);
                        set(scatfig.ftrsincorrh(c),'markeredgecolor',scatfig.colors(c,:),'markersize',scatfig.markersize);
                    if scatfig.showcats(c)==0
                        set(scatfig.ftrsincorrh(c),'visible','off');
                    end
                else
                    scatfig.ftrsincorrh(c) = -1;
                end
                if scatfig.ftrstd>0
                    c1 = plot(scatfig.ftrmns(c,i),scatfig.ftrmns(c,j),'x');
                        set(c1,'markeredgecolor',scatfig.colors(c,:),'markersize',2*scatfig.markersize);
                    c2 = plot(scatfig.ftrmns(c,i)+scatfig.ftrstd*scatfig.ftrstds(c,i)*sin(angles),...
                            scatfig.ftrmns(c,j)+scatfig.ftrstd*scatfig.ftrstds(c,j)*cos(angles));
                        set(c2,'color',scatfig.colors(c,:));
                    if scatfig.showcats(c)==0
                        set(c1,'visible','off');
                        set(c2,'visible','off');
                    end
                end

            end
        end
    end
    xlabel(scatfig.ftrnames{scatfig.blowupax(2)});
    ylabel(scatfig.ftrnames{scatfig.blowupax(1)});
    set(scatfig.blowupaxh,'xlim',scatfig.ftrranges(:,scatfig.blowupax(2)));
    set(scatfig.blowupaxh,'ylim',scatfig.ftrranges(:,scatfig.blowupax(1)));
end
    

% --------------------------------------------------------------------
function scatfig = displayclip(scatfig,clipind)
% display clip in current display figure

% purge display list and make new fig if necessary
scatfig.dispfigh = scatfig.dispfigh(ishandle(scatfig.dispfigh));
figh =findobj(0,'name', ['Clip ' num2str(clipind)]);
if isempty(figh)% set display figure
    scatfig.dispfigh(end+1)  = figure('numbertitle','off', 'name',['Clip ' num2str(clipind)]);
    curdisp = length(scatfig.dispfigh);
else
    curdisp = find(scatfig.dispfigh==figh);
end

% load spectrogram
if ~exist([scatfig.name '_spec'])
    specdir = uigetdir('.','Select spec directory');
    if specdir==0
        return;
    end
    fileseps = find(specdir==filesep);
    if fileseps(end) == length(specdir)
        fileseps(end) = [];
    end
    scatfig.name = specdir(fileseps(end)+1:end-5);
end
load([scatfig.name '_spec' filesep scatfig.name '_spec_' num2str(clipind) '.mat']);
load([scatfig.name '_spec' filesep 'specparams.mat']);
scatfig.specparams = specparams;
% load features
load([scatfig.name '_ftrs' filesep scatfig.name '_ftr_' num2str(clipind) '.mat']);

set(scatfig.figh,'userdata',scatfig);
ftrnum = size(sliceftrs,2);
figure(scatfig.dispfigh(curdisp));
subplot(2*ftrnum,1,1:ftrnum)
cla; hold on;
imagesc(t,f,log(abs(spec)+scatfig.specparams.specfloor)-log(scatfig.specparams.specfloor));
set(gca,'ydir','normal','xdir','normal');
ylabel('kHz');
xlabel('Time (msec)');
title(['Clip ' num2str(clipind)]);
dt = diff(t(1:2));
xlim = [min(t)-dt max(t)+dt];
df = diff(f(1:2));
ylim = [0 max(f)+df];
set(gca,'xlim',xlim);
set(gca,'ylim',ylim);
for i=1:ftrnum
    subplot(2*ftrnum,1,ftrnum+i)
    cla; hold on;
    plot(t,sliceftrs(:,i));
    set(gca,'xlim',xlim);
    set(gca,'xtick',[]);
    ylabel(ftrlist{i});
end
    


% --------------------------------------------------------------------
function buttonupfcn(hco,event_obj)
% button up function, general to fig
txt = '';
scatfig = get(gcf,'userdata');
ftrinds = find(scatfig.ftrlist == 1);
ftrnum = length(ftrinds);
axh = gca;
if axh==scatfig.blowupaxh
%     index = get(event_obj,'dataindex');
%     curplot = find(get(event_obj,'target')==scatfig.ftrscorrh);
%     if ~isempty(curplot)
%         scatfig.curclip = scatfig.ftrscorr{curplot,2}(index);
%     else
%         curplot = find(hco==scatfig.ftrsincorrh);
%         if ~isempty(curplot)
%             scatfig.curclip = scatfig.ftrsincorr{curplot,2}(index);
%         else
%             disp('Cant find plot object.'); return
%         end
%     end
%     pos = get(event_obj,'Position');
    % find nearest data pt
    pos = get(gca,'currentpoint');
    pos = pos(1,1:2);
    xlim = get(gca,'xlim');
    ylim = get(gca,'ylim');
    mindist = 1e10;
    minpos = [0 0];
    cat = 0;
    scatfig.curclip = 0;
    for c=1:scatfig.catnum
        if scatfig.showcats(c)==1
            [tmpmin tmpind] = min(((pos(1)-scatfig.ftrscorr{c,1}(:,scatfig.blowupax(2)))/diff(xlim)).^2+...
                            (((pos(2)-scatfig.ftrscorr{c,1}(:,scatfig.blowupax(1)))/diff(ylim)).^2));
            if tmpmin<mindist
                minpos = [scatfig.ftrscorr{c,1}(tmpind,scatfig.blowupax(2)) ...
                                scatfig.ftrscorr{c,1}(tmpind,scatfig.blowupax(1))];
                mindist = tmpmin;
                cat = c;
                scatfig.curclip = scatfig.ftrscorr{c,2}(tmpind);
            end
            [tmpmin tmpind] = min(((pos(1)-scatfig.ftrsincorr{c,1}(:,scatfig.blowupax(2)))/diff(xlim)).^2+...
                            (((pos(2)-scatfig.ftrsincorr{c,1}(:,scatfig.blowupax(1)))/diff(ylim)).^2));
            if tmpmin<mindist
                minpos = [scatfig.ftrsincorr{c,1}(tmpind,scatfig.blowupax(2)) ...
                                scatfig.ftrsincorr{c,1}(tmpind,scatfig.blowupax(1))];
                mindist = tmpmin;
                cat = c;
                scatfig.curclip = scatfig.ftrsincorr{c,2}(tmpind);
            end
        end
    end
    for i=1:2
        txt{i} = [scatfig.ftrnames{i} ' : ' num2str(minpos(i))];
    end
    txt{3} = ['cat = ' makelabelstr(scatfig.labels.labelkey(cat),...
                    scatfig.labels.label2key(cat), scatfig.labels.label3key{cat})];
    txt{4} = ['clip = ' num2str(scatfig.curclip)];
    if ishandle(scatfig.curtxth)
        delete(scatfig.curtxth);
    end
    xlim = get(gca,'xlim');
    scatfig.curtxth = text(minpos(1)+diff(xlim)/50,minpos(2),txt);
    if ishandle(scatfig.curpth)
        delete(scatfig.curpth);
    end
    scatfig.curpth = plot(minpos(1),minpos(2),'o');
        set(scatfig.curpth,'markeredgecolor',scatfig.colors(cat,:),'markersize',2*scatfig.markersize);
    set(scatfig.figh,'userdata',scatfig);
    if strcmpi(get(hco,'selectiontype'),'open')
        switch lower(scatfig.disptype)
            case 'spec'
                displayclip(scatfig,scatfig.curclip);
            case 'song'
                if isempty(scatfig.songs)
                    disp('Song info not loaded. Will display specs instead.');
                    scatfig.disptype = 'spec';
                else
                    tmpsong = scatfig.songs;
                    tmpsong.a = scatfig.songs.a(scatfig.clips.a(scatfig.curclip).song);
                    tmpsong.a = scatfig.songs.a(scatfig.clips.a(scatfig.curclip).song);
                    clipinds = tmpsong.a.startclip:tmpsong.a.endclip;
                    clipind = scatfig.curclip-tmpsong.a.startclip+1;
                    tmpsong.a.startclip = 1;
                    tmpsong.a.endclip = tmpsong.a.clipnum;
                    tmpclips = scatfig.clips;
                    tmpclips.a = tmpclips.a(clipinds);
                    tmplabels = scatfig.labels;
                    tmplabels.a = tmplabels.a(clipinds);
                    if strcmp(scatfig.bmktype,'bmk')
                        viewh = dispclipsong(clipind,'view','sb3viewlbl',...
                            'clips',tmpclips,'labels',tmplabels,'song',tmpsong);
                    else
                        viewh = dispclipsong(clipind,'view','sb3viewlbl',...
                            'clips',tmpclips,'labels',tmplabels,'song',tmpsong,'wavpath',scatfig.wavpath);
                    end
                end
        end
    end
    % figure;
%     dispclipfig(scatfig.clips.a(index));
%     figure(scatfig.figh);
else
    axind = find(axh==scatfig.axh);
    if ~isempty(axind)
        ii = rem(axind-1,ftrnum)+1;
        jj = ceil(axind/ftrnum);
        scatfig.blowupax(1) = ftrinds(ii);
        scatfig.blowupax(2) = ftrinds(jj);
        tmph = scatfig.axposh(jj);
        tmph = [tmph tmph+diff(scatfig.axposh(1:2))]-(scatfig.daxposh/2)*[1 1];
        tmpv = scatfig.axposv(ii);
        tmpv = [tmpv tmpv-diff(scatfig.axposv(1:2))]-(scatfig.daxposv/2)*[1 1];
%         if ishandle(scatfig.bgsqh)
%             set(scatfig.bgsqh,'xdata',tmph([1 2 2 1 1]),'ydata',tmpv([1 1 2 2 1]));
%         else
%             tmph = scatfig.axposh(scatfig.blowupax(2));
%             tmph = [tmph tmph+diff(scatfig.axposh(1:2))]-(scatfig.daxposh/2)*[1 1];
%             tmpv = scatfig.axposv(scatfig.blowupax(1));
%             tmpv = [tmpv tmpv-diff(scatfig.axposv(1:2))]-(scatfig.daxposv/2)*[1 1];
%             scatfig.bgsqh = plot(scatfig.bgaxh,tmph([1 2 2 1 1]),tmpv([1 1 2 2 1]));
%                 set(scatfig.bgsqh,'color','r');
%         end
        scatfig = plotblowup(scatfig);
        set(scatfig.figh,'userdata',scatfig);
%         pos = get(event_obj,'Position');
%         txt{1} = [scatfig.ftrnames{ftrinds(scatfig.blowupax(1))} ' : ' num2str(pos(1))];
%         txt{2} = [scatfig.ftrnames{ftrinds(scatfig.blowupax(2))} ' : ' num2str(pos(2))];
    end
end

% --------------------------------------------------------------------
function seldisptype(hco,event_obj,figh,type)
% select the display type

scatfig = get(figh,'userdata');
if hco==scatfig.menu.spec
    scatfig.disptype = 'spec';
    set(scatfig.menu.spec,'checked','on');
    set(scatfig.menu.song,'checked','off');
else
    scatfig.disptype = 'song';
    set(scatfig.menu.spec,'checked','off');
    set(scatfig.menu.song,'checked','on');
end   
set(scatfig.figh,'userdata',scatfig);

% --------------------------------------------------------------------
function seldisplay(hco,event_obj,figh)
% select the display type

scatfig = get(figh,'userdata');
ind = find(scatfig.menu.displays==hco);
if isempty(ind)
    disp('Can''t find display menu handle');
    return
end

for i=1:length(scatfig.menu.displays)
    set(scatfig.menu.displays(i),'checked','off');
end
set(scatfig.menu.displays(ind),'checked','on'); 

% --------------------------------------------------------------------
function adddisplay(hco,event_obj,figh)
% select the display type

scatfig = get(figh,'userdata');
newfigh = figure;
set(newfigh,'numbertitle','off','name',['Display ' num2str(length(scatfig.menu.displays)+1)]);
scatfig.dispfigh = [scatfig.dispfigh newfigh];
for i=1:length(scatfig.menu.displays)
    set(scatfig.menu.displays(i),'checked','off');
end
tmpmenuh = uimenu('parent',scatfig.menu.display,'label',...
    ['Display ' num2str(length(scatfig.menu.displays)+1)],...
    'callback',{@seldisplay,scatfig.figh},'checked','on');
scatfig.menu.displays = [scatfig.menu.displays tmpmenuh];
set(scatfig.figh,'userdata',scatfig);

