function [confuse perf] = dispconfuse(varargin)
% [confuse] = dispconfuse(varargin)
% display confusion matrix and report performance values
% report on classification performance vs. k

% if nargin>0
%     if isnumeric(varargin{1})
%         dconf.plotk = varargin{1};
%         varargin = varargin(2:end);
%     end
% end
confuse = [];

dconf.rowlblpath = '';
dconf.rowlblfile = '';
dconf.rowlabels = '';
dconf.collblpath = '';
dconf.collblfile = '';
dconf.collabels = '';
dconf.display = 1;
dconf.perf = 1; % print performance measures workspace
dconf.syls = {}; % can be used to define syllables for performance
dconf.sylvers = [1]; % versions of syllable labels that are in 'syls' category
dconf = parse_pv_pairs(dconf,varargin);

% load row labels 
if isempty(dconf.rowlabels)
    if ~exist(fullfile(dconf.rowlblpath,dconf.rowlblfile))
        [dconf.rowlblfile dconf.rowlblpath] = uigetfile({'*.lbl;*.mlbl','label file (*.lbl;*.mlbl)'; ...
            '*.*',  'All Files (*.*)'},'Choose (row) label file');
        if dconf.rowlblfile==0 return; end
    end
    load(fullfile(dconf.rowlblpath,dconf.rowlblfile),'labels','temps','-mat');
    dconf.rowlabels = labels;
end
rowlabelnum = length(dconf.rowlabels.labelkey);
% load col labels 
if isempty(dconf.collabels)
    if ~exist(fullfile(dconf.collblpath,dconf.collblfile))
        [dconf.collblfile dconf.collblpath] = uigetfile({'*.lbl;*.mlbl','label file (*.lbl;*.mlbl)'; ...
            '*.*',  'All Files (*.*)'},'Choose (col) label file');
        if dconf.collblfile==0 return; end
    end
    load(fullfile(dconf.collblpath,dconf.collblfile),'labels','-mat');
    dconf.collabels = labels;
end
if length(dconf.rowlabels.a)~=length(dconf.collabels.a)
    disp('Row and column labels must have same number of elements. Aborting.'); return
end
collabelnum = length(dconf.collabels.labelkey);


% initialize confusion structure
confuse.m = zeros(rowlabelnum,collabelnum);
confuse.clipinds = cell(rowlabelnum,collabelnum); % each cell holds list of clip indices in that entry in confusion matrix
confuse.rowlabelinds = zeros(length(dconf.rowlabels.a),1);
confuse.rowlabelkey = dconf.rowlabels.labelkey;
confuse.rowlabel2key = dconf.rowlabels.label2key;
confuse.rowlabel3key = dconf.rowlabels.label3key;
confuse.collabelinds = zeros(length(dconf.collabels.a),1);
confuse.collabelkey = dconf.collabels.labelkey;
confuse.collabel2key = dconf.collabels.label2key;
confuse.collabel3key = dconf.collabels.label3key;

% calculate confusion matrix
% unlab = labels.labelinds(:,i)==0;
% labels.labelinds(unlab,i) = numel(labels.label1)+1;
for i = 1:length(dconf.rowlabels.a)
    confuse.m(dconf.rowlabels.a(i).labelind,dconf.collabels.a(i).labelind) = ...
                1+confuse.m(dconf.rowlabels.a(i).labelind,dconf.collabels.a(i).labelind);
    confuse.clipinds{dconf.rowlabels.a(i).labelind,dconf.collabels.a(i).labelind}(end+1) = i;
end

% calculate performance

%display
if dconf.display
%     figure();
    clf;
    colormap(gray);
    % show confusion matrix
    axes('position',[.2 .1 .75 .8])
    imagesc(confuse.m.^.25);
%     xlabel(['k = ' num2str(labels.k(ind)) '; ' ...
%         num2str(correct(ind)*numel(labels.targetlabelinds)) '/' num2str(numel(labels.targetlabelinds)) ...
%         ' (' num2str(round(correct(ind)*1000)/10) '\%)']);
    % labels
    for i=1:length(dconf.rowlabels.labelkey)
        tt = text(0,i,makelabelstr(dconf.rowlabels.labelkey(i),dconf.rowlabels.label2key(i),dconf.rowlabels.label3key{i}));
            set(tt,'verticalalignment','middle','horizontalalignment','right','rotation',90);
        for j=1:length(dconf.collabels.labelkey)
            if confuse.m(i,j)>0
                tt = text(j,i,num2str(confuse.m(i,j)));
                set(tt,'color','r','verticalalignment','middle','horizontalalignment','center');
            end
        end
    end
    for i=1:length(dconf.collabels.labelkey)
        tt = text(i,0,makelabelstr(dconf.collabels.labelkey(i),dconf.collabels.label2key(i),dconf.collabels.label3key{i}));
            set(tt,'verticalalignment','top','horizontalalignment','center');
    end
    set(gca,'ytick',[],'ydir','normal')
    set(gca,'xtick',[])
    % show temps
    if isstruct(temps)
        ax = axes('position',[.05 .1 .075 .8]);
        set(ax,'color','k');
        fmax = max(temps.specparams.f); 
        cla; hold on
        maxtbins = 0;
        for i=1:length(temps.tmpl)
            tbins = size(temps.tmpl{i},2);
            maxtbins = max(tbins,maxtbins);
            imagesc(temps.specparams.dt*(-tbins:1)',-1.5+i+temps.specparams.f/fmax,log(max(temps.specparams.specfloor,abs(temps.tmpl{i}))));
        end
        set(gca,'xlim',temps.specparams.dt*[-maxtbins 0]);
        set(gca,'ylim',-.5+[0 length(dconf.rowlabels.labelkey)]);
        set(gca,'ytick',[])
        set(gca,'xtick',[])
    end
end

% categorize column labels into types
coltypes = cell(length(dconf.collabels.labelkey),1);
for i=1:length(dconf.collabels.labelkey)
    % decide on type and accumulate performance
    if ismember(lower(dconf.collabels.labelkey(i)),'abcdefghjklmnopqrs') 
        if ismember(dconf.collabels.label2key(i),dconf.sylvers)
            coltypes{i} = 'syl';
        else
            coltypes{i} = 'syl_oth';
        end
    elseif lower(dconf.collabels.labelkey(i))=='i'
        coltypes{i} = 'int';
    elseif ismember(lower(dconf.collabels.labelkey(i)),'uv')
        coltypes{i} = 'call';
    else
        coltypes{i} = 'other';
    end
end
% categorize row labels into types and evaluate performance
rowtypes = cell(length(dconf.rowlabels.labelkey),1);
perf.all = zeros(length(dconf.rowlabels.labelkey),2); % correct, total
perf.syl = [0 0]; 
perf.syl_oth = [0 0];
perf.int = [0 0];
perf.call = [0 0];
perf.other = [0 0];
for i=1:length(dconf.rowlabels.labelkey)
    % decide on type and accumulate performance
    if ismember(lower(dconf.rowlabels.labelkey(i)),'abcdefghjklmnopqrs') 
        if ismember(dconf.rowlabels.label2key(i),dconf.sylvers)
            rowtypes{i} = 'syl';
        else
            rowtypes{i} = 'syl_oth';
        end
        correct = (dconf.collabels.labelkey==dconf.rowlabels.labelkey(i) & ...
                    dconf.collabels.label2key==dconf.rowlabels.label2key(i));
    elseif lower(dconf.rowlabels.labelkey(i))=='i'
        rowtypes{i} = 'int';
        correct = (dconf.collabels.labelkey==dconf.rowlabels.labelkey(i) & ...
                    dconf.collabels.label2key==dconf.rowlabels.label2key(i));
    elseif ismember(lower(dconf.rowlabels.labelkey(i)),'uv')
        rowtypes{i} = 'call';
        correct = strcmp(coltypes,rowtypes{i});
    else
        rowtypes{i} = 'other';
        correct = strcmp(coltypes,rowtypes{i});
    end
    perf.all(i,1) = sum(confuse.m(i,correct));
    perf.all(i,2) = sum(confuse.m(i,:));
    eval(['perf.' rowtypes{i} ' = perf.' rowtypes{i} '+perf.all(i,:);']);  
end
perf.tot = sum(perf.all);
perf.sylint = perf.syl+perf.int;
perf.sylintcall = perf.syl+perf.int+perf.call;
if dconf.perf
    % make string of performance for each category
    str = [];
    for i=1:length(dconf.rowlabels.labelkey)
        cat = makelabelstr(dconf.rowlabels.labelkey(i),dconf.rowlabels.label2key(i),dconf.rowlabels.label3key{i});
        str = [str ' ' cat ': ' num2str(perf.all(i,1)) '/' num2str(perf.all(i,2)) '=' sprintf('%2.1f',100*perf.all(i,1)/perf.all(i,2)) ';'];
    end
    str
    % total, syls, syls+int, syls+int+call, 
    str = ['tot: ' num2str(perf.tot(1)) '/' num2str(perf.tot(2)) '=' sprintf('%2.1f',100*perf.tot(1)/perf.tot(2)) ';'];
    str = [str 'syls:' num2str(perf.syl(1)) '/' num2str(perf.syl(2)) '=' sprintf('%2.1f',100*perf.syl(1)/perf.syl(2)) ';'];
    str = [str 'sylint:' num2str(perf.sylint(1)) '/' num2str(perf.sylint(2)) '=' sprintf('%2.1f',100*perf.sylint(1)/perf.sylint(2)) ';'];
    str = [str 'sylintcall:' num2str(perf.sylintcall(1)) '/' num2str(perf.sylintcall(2)) '=' sprintf('%2.1f',100*perf.sylintcall(1)/perf.sylintcall(2)) ';'];
    str
    % syls, int, calls, other syls other
    str = ['syls:' num2str(perf.syl(1)) '/' num2str(perf.syl(2)) '=' sprintf('%2.1f',100*perf.syl(1)/perf.syl(2)) ';'];
    str = [str 'int:' num2str(perf.int(1)) '/' num2str(perf.int(2)) '=' sprintf('%2.1f',100*perf.int(1)/perf.int(2)) ';'];
    str = [str 'calls:' num2str(perf.call(1)) '/' num2str(perf.call(2)) '=' sprintf('%2.1f',100*perf.call(1)/perf.call(2)) ';'];
    str = [str 'syl_oth:' num2str(perf.syl_oth(1)) '/' num2str(perf.syl_oth(2)) '=' sprintf('%2.1f',100*perf.syl_oth(1)/perf.syl_oth(2)) ';'];
    str = [str 'other:' num2str(perf.other(1)) '/' num2str(perf.other(2)) '=' sprintf('%2.1f',100*perf.other(1)/perf.other(2)) ';'];
    str
end
    

