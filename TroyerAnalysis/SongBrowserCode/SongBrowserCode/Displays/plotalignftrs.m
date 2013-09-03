function plotalignftrs(varargin)
% plotalignftrs(varargin)
% plot ftr values from ftr directory per category
% using offsets in templates variable
% plots one figure per category
% param/value pair 'catinds', X can be used to restrict to vector of 
% category indices X
% ftrlist, {}, can be used to specify a list of features

%% set defaults
ftralign.tempfile = '';
ftralign.temppath = '';
ftralign.ftrpath = '';
ftralign.ftrlist = ''; % cell array of feature names
ftralign.cats = []; % index of categories to display
ftralign.ampthresh = .25;
ftralign.alpha = .1;
ftralign.normalize = 0;
ftralign.specplots = 2; % number of subplots for display of template spectrogram
% ftralign.thresh = .25; % amplitude threshold 
% ftralign.freqrange = [.7 7];
ftralign = parse_pv_pairs(ftralign,varargin);

%% get template from label file 
if ~exist(fullfile(ftralign.temppath,ftralign.tempfile))
    [ftralign.tempfile ftralign.temppath] = uigetfile({'*.lbl;label files','*;*;All files'},...
        'Pick lable file with templates','Choose template label file');
    if ftralign.temppath==0 return; end
end
load(fullfile(ftralign.temppath,ftralign.tempfile),'labels','temps','-mat');
% locate ftr directory
[ftralign.ftrpath] = uigetdir( 'Choose feature directory','Choose feature directory');
if ftralign.ftrpath==0 return; end
[upperpath name ext] = fileparts(ftralign.ftrpath);

% get list of category indices
if isempty(ftralign.cats)
    catinds = 1:length(labels.labelkey);
elseif ischar(ftralign.cats) | iscell(ftralign.cats)
    catinds = findlabelind(ftralign.cats,labels);
else
    catinds = ftralign.cats;
end
% get position of amplitude feature and dt
load(fullfile(ftralign.ftrpath,[name(1:end-5) '_ftr_1.mat']));
if isempty(ftralign.ftrlist)
    ftralign.ftrlist = sliceftrlist;
end
ftrnum = length(ftralign.ftrlist);

for i=catinds
    clipinds = temps.clipinds{i};
    offsets = temps.tmploffsets{i};
    t= specparams.dt*((1:size(temps.tmpl{i},2))-ceil(size(temps.tmpl{i},2)/2));
    tlim = [min(t)-specparams.dt max(t)+specparams.dt];
    figure(10+i); 
    if ftralign.specplots>0
        subplot(ftrnum+ftralign.specplots,1,1:ftralign.specplots);
        cla;
        imagesc(t,specparams.f,log(max(abs(temps.tmpl{i}),specparams.specfloor)));
        set(gca,'ydir','normal');
        set(gca,'xlim',tlim);
        title(makelabelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i}));
    end
    for f=1:ftrnum
        subplot(ftrnum+ftralign.specplots,1,f+ftralign.specplots);
        cla; hold on
        for j=1:length(clipinds)
            load(fullfile(ftralign.ftrpath,[name(1:end-5) '_ftr_' num2str(clipinds(j)) '.mat']));
            if j==1
                f_ind = find(strcmpi(ftralign.ftrlist{f},sliceftrlist));
            end
            if ftralign.normalize
                abovethreshinds = find(sliceftrs(:,ampind)>ftralign.thresh);
                if length(abovethreshinds)>1
                    edges = [min(abovethreshinds) max(abovethreshinds)];
                else
                    edges = [1 size(sliceftrs,1)];
                end
                cliplens(j) = diff(edges)+1;
                plottr(specparams.dt*((1:size(sliceftrs,1))-ceil(size(sliceftrs,1)/2)-offsets(j)),...
                                                sliceftrs(:,f_ind)/median(sliceftrs(edges(1):edges(2),f_ind)),ftralign.alpha,'b');
%                 plot(specparams.dt*((1:size(sliceftrs,1))-ceil(size(sliceftrs,1)/2)-offsets(j)),...
%                                                 sliceftrs(:,f_ind)/median(sliceftrs(edges(1):edges(2),f_ind)),'b');
        %                                         sliceftrs(ampind,:),'b');
            else
                plottr(specparams.dt*((1:size(sliceftrs,1))-ceil(size(sliceftrs,1)/2)-offsets(j)),sliceftrs(:,f_ind),ftralign.alpha,'b');
%                 plot(specparams.dt*((1:size(sliceftrs,1))-ceil(size(sliceftrs,1)/2)-offsets(j)),sliceftrs(:,f_ind),'b');
        %                                         sliceftrs(ampind,:),'b');
            end
            if strcmpi(ftralign.ftrlist{f},'amp') & ftralign.ampthresh>0
                plot(tlim,ftralign.ampthresh*[1 1],'r');
            end
            ylabel(ftralign.ftrlist{f})
            set(gca,'xlim',tlim);
        end
%         temptimes = specparams.dt*((1:length(tempamp))-ceil(length(tempamp)/2));
%         pp = plot(temptimes,tempamp/median(tempamp(tempedges(1):tempedges(2))),'r');
%             set(pp,'linewidth',2);
    end
end
        
        
        