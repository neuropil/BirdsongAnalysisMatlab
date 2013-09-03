function [labels ch2inds ampinds WEinds leninds] = noisescreen(varargin)
% [labels] = noisescreen(varargin)
% prescreen ftr file based on four criteria
% ch2 < ch2thresh -> Ch20 (default .7)
% amp < ampthresh -> nz9 (default 1)
% Wiener entropy > WEthresh -> nz8 (default -.35)
% length < lenthresh -> nz0 (default 30 msec)
% these are applied in this order, with later classifications overwriting
% earlier ones
% if pv pairs 'labels',labels is specified, function will
%  overwrite existing labels and report on what was overwritten

labels = [];
ch2inds = [];
ampinds = [];
WEinds = [];
leninds = [];


nzscr.ftrpath = '';
nzscr.ftrfile = '';
nzscr.ftrs = [];
nzscr.ftrlist = {};
nzscr.labels = []; % will overwrite existing labels for clips satisfying screen criteria
nzscr.lblfile = '';
nzscr.clips = ''; % only apply to specified clips
nzscr.loadlabels = 0; % prompt hand loading of labels
nzscr.lenthresh = 30;
nzscr.lencat = 'nz1';
nzscr.ampthresh = 1;
nzscr.ampcat = 'nz1';
nzscr.WEthresh = -.35;
nzscr.WEcat = 'nz1';
nzscr.ch2thresh = .7;
nzscr.ch2cat = 'ch21';
nzscr.report = 1;
nzscr.save = 1;
nzscr = parse_pv_pairs(nzscr,varargin);

% load ftr info
if isempty(nzscr.ftrs) & isempty(nzscr.ftrlist)
    if ~(exist(fullfile(nzscr.ftrpath,nzscr.ftrfile))==2)
        [nzscr.ftrfile nzscr.ftrpath] = uigetfile({'*.ftr','Feature files (*.ftr)'; ...
            '*.*',  'All Files (*.*)'},'Choose feature file');
        if nzscr.ftrfile==0 return; end
    end
    load(fullfile(nzscr.ftrpath,nzscr.ftrfile),'-mat');
    nzscr.ftrs = clipftrs;
    nzscr.ftrlist = clipftrlist;
    clear clipftrs clipftrlist
end

if isempty(nzscr.clips)
    nzscr.clips = 1:size(nzscr.ftrs,1);
end
% load labels or create blanks
if nzscr.loadlabels
    [lblfile lblpath] = uigetfile({'*.lbl','Label files (*.lbl)'; ...
        '*.*',  'All Files (*.*)'},'Choose label file');
    if lblfile ==0 return; end
    load(fullfile(lblpath,lblfile),'-mat');
    nzscr.labels = labels;
    clear labels
elseif isempty(nzscr.labels)
    nzscr.labels = blanklabels(length(nzscr.clips));
end
labelinds = [nzscr.labels.a.labelind];

%% screen for different channels
% look for category in labelkey or add new 
ch2ftrind = find(strcmp('ch2',nzscr.ftrlist));
if isempty(ch2ftrind)
    disp('Can''t find ch2 feature.'); return;
end
ch2lblind = findlabelind(nzscr.ch2cat,nzscr.labels,'warn',0);
if ch2lblind==0
    nzscr.labels = newcat(nzscr.ch2cat, 'labels',nzscr.labels,'warn',0,'save',0);
    ch2lblind = length(nzscr.labels.labelkey);
end
[tmplabel tmplabel2 tmplabel3] = parselabelstr(nzscr.ch2cat);
% find appropriate clips and recategorize - keep track of previous labels
ch2inds = nzscr.clips(nzscr.ftrs(nzscr.clips,ch2ftrind)<nzscr.ch2thresh);
for i=1:length(ch2inds)
    nzscr.labels.a(ch2inds(i)).labelind = ch2lblind;
    nzscr.labels.a(ch2inds(i)).label = tmplabel;
    nzscr.labels.a(ch2inds(i)).label2 = tmplabel2;
    nzscr.labels.a(ch2inds(i)).label3 = tmplabel3;
end
% report on overwritten labels
if nzscr.report
    ch2prevlbls = labelinds(ch2inds);
    ch2prevcats = unique(ch2prevlbls);
    ch2prevcats = setdiff(ch2prevcats,0); % eliminate unlabeled
    str = ['Ch2<' num2str(nzscr.ch2thresh) ': Tot-' num2str(length(ch2inds)) ';'];
    for i=1:length(ch2prevcats)
        catstr = makelabelstr(nzscr.labels.labelkey(ch2prevcats(i)),nzscr.labels.label2key(ch2prevcats(i)),...
                                                                            nzscr.labels.label3key{ch2prevcats(i)});
        str = [str ' ' catstr '-' num2str(sum(ch2prevlbls==ch2prevcats(i))) ';'];
    end  
    disp(str);
end

%% screen for low amplitude 
% look for category in labelkey or add new 
ampftrind = find(strcmp('amp_mn',nzscr.ftrlist));
if isempty(ampftrind)
    disp('Can''t find amp_mn feature.'); return;
end
amplblind = findlabelind(nzscr.ampcat,nzscr.labels,'warn',0);
if amplblind==0
    nzscr.labels = newcat(nzscr.ampcat,'labels',nzscr.labels,'warn',0,'save',0);
    amplblind = length(nzscr.labels.labelkey);
end
[tmplabel tmplabel2 tmplabel3] = parselabelstr(nzscr.ampcat);
% find appropriate clips and recategorize - keep track of previous labels
ampinds = nzscr.clips(nzscr.ftrs(nzscr.clips,ampftrind)<nzscr.ampthresh);
for i=1:length(ampinds)
    nzscr.labels.a(ampinds(i)).labelind = amplblind;
    nzscr.labels.a(ampinds(i)).label = tmplabel;
    nzscr.labels.a(ampinds(i)).label2 = tmplabel2;
    nzscr.labels.a(ampinds(i)).label3 = tmplabel3;
end
% report on overwritten labels
if nzscr.report
    ampprevlbls = labelinds(ampinds);
    ampprevcats = unique(ampprevlbls);
    ampprevcats = setdiff(ampprevcats,0);
    str = ['amp_mn<' num2str(nzscr.ampthresh) ': Tot-' num2str(length(ampinds)) ';'];
    for i=1:length(ampprevcats)
        catstr = makelabelstr(nzscr.labels.labelkey(ampprevcats(i)),nzscr.labels.label2key(ampprevcats(i)),...
                                                                            nzscr.labels.label3key{ampprevcats(i)});
        str = [str ' ' catstr '-' num2str(sum(ampprevlbls==ampprevcats(i))) ';'];
    end  
    disp(str);
end

%% screen for high weiner entropy  
% look for category in labelkey or add new 
WEftrind = find(strcmp('Wentropy_mn',nzscr.ftrlist));
if isempty(WEftrind)
    disp('Can''t find Wentropy_mn feature.'); return;
end
WElblind = findlabelind(nzscr.WEcat,nzscr.labels,'warn',0);
if WElblind==0
    nzscr.labels = newcat(nzscr.WEcat,nzscr.labels,'warn',0,'save',0);
    WElblind = length(nzscr.labels.labelkey);
end
[tmplabel tmplabel2 tmplabel3] = parselabelstr(nzscr.WEcat);
% find appropriate clips and recategorize - keep track of previous labels
WEinds = nzscr.clips(nzscr.ftrs(nzscr.clips,WEftrind)>nzscr.WEthresh);
for i=1:length(WEinds)
    nzscr.labels.a(WEinds(i)).labelind = WElblind;
    nzscr.labels.a(WEinds(i)).label = tmplabel;
    nzscr.labels.a(WEinds(i)).label2 = tmplabel2;
    nzscr.labels.a(WEinds(i)).label3 = tmplabel3;
end
% report on overwritten labels
if nzscr.report
    WEprevlbls = labelinds(WEinds);
    WEprevcats = unique(WEprevlbls);
    WEprevcats = setdiff(WEprevcats,0);
    str = ['WE_mn>' num2str(nzscr.WEthresh) ': Tot-' num2str(length(WEinds)) ';'];
    for i=1:length(WEprevcats)
        catstr = makelabelstr(nzscr.labels.labelkey(WEprevcats(i)),nzscr.labels.label2key(WEprevcats(i)),...
                                                                            nzscr.labels.label3key{WEprevcats(i)});
        str = [str ' ' catstr '-' num2str(sum(WEprevlbls==WEprevcats(i))) ';'];
    end  
    disp(str);
end

%% screen for short length 
% look for category in labelkey or add new 
lenftrind = find(strcmp('length',nzscr.ftrlist));
if isempty(lenftrind)
    disp('Can''t find length feature.'); return;
end
lenlblind = findlabelind(nzscr.lencat,nzscr.labels,'warn',0);
if lenlblind==0
    nzscr.labels = newcat(nzscr.lencat,nzscr.labels,'warn',0,'save',0);
    lenlblind = length(nzscr.labels.labelkey);
end
[tmplabel tmplabel2 tmplabel3] = parselabelstr(nzscr.lencat);
% find appropriate clips and recategorize - keep track of previous labels
leninds = nzscr.clips(nzscr.ftrs(nzscr.clips,lenftrind)<nzscr.lenthresh);
for i=1:length(leninds)
    nzscr.labels.a(leninds(i)).labelind = lenlblind;
    nzscr.labels.a(leninds(i)).label = tmplabel;
    nzscr.labels.a(leninds(i)).label2 = tmplabel2;
    nzscr.labels.a(leninds(i)).label3 = tmplabel3;
end
% report on overwritten labels
if nzscr.report
    lenprevlbls = labelinds(leninds);
    lenprevcats = unique(lenprevlbls);
    lenprevcats = setdiff(lenprevcats,0);
    str = ['length<' num2str(nzscr.lenthresh) ': Tot-' num2str(length(leninds)) ';'];
    for i=1:length(lenprevcats)
        catstr = makelabelstr(nzscr.labels.labelkey(lenprevcats(i)),nzscr.labels.label2key(lenprevcats(i)),...
                                                                            nzscr.labels.label3key{lenprevcats(i)});
        str = [str ' ' catstr '-' num2str(sum(lenprevlbls==lenprevcats(i))) ';'];
    end  
    disp(str);
end


labels = nzscr.labels;

%% save
if nzscr.save
    [lblfile lblpath] = uiputfile('*.lbl;*.mlbl','Choose label file to save data (.lbl;.mlbl)');
    if lblfile==0 return; end
    save(fullfile(lblpath,lblfile),'labels','-mat');
end


