function [collabels mtchlbls srtlblinds srt srtinds] = knclust(varargin)
% [collabels mtchlbls srtlblinds srt srtinds] = knclust(varargin)
% vectorized k nearest neighbor clustering (clusters for a vector of k
% values)
% assume that we have a clips directory with a matchfile and bookmark file.
collabels = [];
mtchlbls = [];
srtlblinds = [];
srt = [];
srtinds= [];

kclust.k = 5;
% kclust.rootdir = rootdirlist;
kclust.rowpath = '';
% kclust.rowfile = '';
kclust.rowlabels = []; % initial label structure
kclust.rowfile = '';
kclust.rowpath = [];
kclust.rowclips = ''; % specify clips to use for knn
kclust.rowcats = ''; % row categories to place col clips into
kclust.colpath = '';
kclust.collabels = []; % categories for clustered syllables are over written
kclust.loadcollabels = 1; % if 0 and empty collabels, then make new blank labels structure
kclust.colcats = 1; % apply clustering to clips in these categories
kclust.colclips = ''; % specify clips to use for knn
kclust.mlblfile = '';
kclust.colfile = '';
kclust.matchfile = '';
kclust.selfclust = 0; % flags whether this is self clustering
kclust.save = 1;
kclust.srt = [];
kclust.srtlblinds = [];
kclust = parse_pv_pairs(kclust,varargin);
% kclust.rootdir = findrootdir(kclust.rootdir);

% load match info
if ~(exist(fullfile(kclust.colpath,kclust.matchfile))==2)
    [kclust.matchfile tmppath] = uigetfile({'*.mtch','match files (*.mtch)'; ...
        '*.*',  'All Files (*.*)'},'Choose matchfile');
    if kclust.matchfile==0 return; end
    if ~isempty(kclust.colpath) & ~strcmp(kclust.colpath,tmppath)
        disp('Match file path does not match column path. Aborting.');return;
    end
    kclust.colpath=tmppath;
end
% disp('Loading matchfile...');
load(fullfile(kclust.colpath,kclust.matchfile),'-mat');
% disp('Done.');

% load labels
if isempty(kclust.rowlabels)
    if ~(exist(fullfile(kclust.rowpath,kclust.rowfile))==2)
        [kclust.rowfile kclust.rowpath] = uigetfile({'*.lbl','Label files (*.lbl)'; ...
            '*.*',  'All Files (*.*)'},'Choose (row) label file');
        if kclust.rowfile ==0 return; end
    end
    load(fullfile(kclust.rowpath,kclust.rowfile),'-mat');
    kclust.rowlabels = labels;
end
% kclust.rowlabels = labels;
rowlabelinds = [kclust.rowlabels.a.labelind];
clear labels

% get list of category indices
if isempty(kclust.rowcats)
    rowcatinds = 1:length(kclust.rowlabels.labelkey);
elseif iscell(kclust.rowcats)
    rowcatinds = findlabelind(kclust.rowcats,kclust.rowlabels);
else
    rowcatinds = kclust.rowcats;
end

% get row clips
if isempty(kclust.rowclips)
    for i=1:length(rowcatinds)
        kclust.rowclips = [kclust.rowclips; find([kclust.rowlabels.a.labelind]==rowcatinds(i))'];
    end
end
% match up included row clips
[tmprowclips Ikclust Imtch] = intersect(kclust.rowclips,mtch.rowclips);
if length(kclust.rowclips)>length(tmprowclips)
    disp([num2str(length(kclust.rowclips)-length(tmprowclips)) ' clips not found in match file rowclips.']);
end
kclust.rowclips = tmprowclips;
rowclipnum = length(kclust.rowclips);

% make collabels structure
if isempty(kclust.collabels)
    if kclust.loadcollabels
        if ~(exist(fullfile(kclust.colpath,kclust.colfile))==2)
            [kclust.colfile kclust.colpath] = uigetfile({'*.lbl','Label files (*.lbl)'; ...
                '*.*',  'All Files (*.*)'},'Choose (col) label file');
            if kclust.colfile ==0 return; end
        end
        load(fullfile(kclust.colpath,kclust.colfile),'labels','-mat');
        kclust.collabels = labels;
        clear labels
    else
        kclust.collabels = blanklabels(size(mtch.m,2));
    end
end

% get list of category indices
if isempty(kclust.colcats)
    colcatinds = 1:length(kclust.collabels.labelkey);
elseif iscell(kclust.rowcats)
    colcatinds = findlabelind(kclust.colcats,kclust.collabels);
else
    colcatinds = kclust.colcats;
end

% match up included col clips
if isempty(kclust.colclips)
    kclust.colclips = mtch.colclips;
end
[tmpcolclips Ikclust Imtch] = intersect(kclust.colclips,mtch.colclips);
if length(kclust.colclips)>length(tmpcolclips)
    disp([num2str(length(kclust.colclips)-length(tmpcolclips)) ' clips not found in match file colclips.']);
end
kclust.colclips = tmpcolclips;
tmpcolclips = [];
% screen according to colcats
for i=1:length(colcatinds)
    tmpcolclips = [tmpcolclips; find([kclust.collabels.a.labelind]==colcatinds(i))'];
end
kclust.colclips = intersect(kclust.colclips,tmpcolclips);

colclipnum = length(kclust.colclips);
[tmpcolclips Ikclust Imtch] = intersect(kclust.colclips,mtch.colclips);
mtchcolclips = Imtch; % index of which col in mtch.m corresponds to that clip

% sort data
if isempty(kclust.srt) | isempty(kclust.srtlblinds) | isempty(kclust.srtinds)
    srt = -ones(kclust.k,size(mtch.m,2)); % sorted match values
    srtinds = -ones(kclust.k,size(mtch.m,2)); % clip index of sorted value
    srtlblinds = -ones(kclust.k,size(mtch.m,2)); % labelind of sorted value
    [tmpsrt tmpsrtinds] = sort(mtch.m(kclust.rowclips,kclust.colclips));
    if ~kclust.selfclust
        disp('Sorting data')
        srt(:,kclust.colclips) = tmpsrt(1:kclust.k,:);
        srtinds(:,kclust.colclips) = kclust.rowclips(tmpsrtinds(1:kclust.k,:));
        srtlblinds(:,kclust.colclips) = rowlabelinds(srtinds(:,kclust.colclips));
    else
        for j=1:colclipnum
            self = 0;
            if ismember(kclust.colclips(j),kclust.rowclips)
                self = 1;
            end
            srt(1:kclust.k,kclust.colclips(j)) = tmpsrt(self+(1:kclust.k),j);
            srtinds(1:kclust.k,kclust.colclips(j)) = kclust.rowclips(tmpsrtinds(self+(1:kclust.k),j));
            srtlblinds(1:kclust.k,kclust.colclips(j)) = rowlabelinds(srtinds(:,kclust.colclips(j)));
        end
    end
else
    srt = kclust.srt;
    srtlbl = kclust.srtinds;
    srtlblinds = kclust.srtlblinds;
end

% find k nearest neighbors - use same indexing as labels structure
labels = kclust.collabels;
labelinds = zeros(length(labels.a),1);
labelnums = zeros(length(labels.a),1);
labeldist = zeros(length(labels.a),1);

for j=1:colclipnum
    mtchlblinds = srtlblinds(1:kclust.k,kclust.colclips(j));
    mtchcats = unique(mtchlblinds); % categories with at lease one match
    mtchnum = zeros(length(mtchcats),1);
    mtchinds = cell(length(mtchcats),1);
    for jj = 1:length(mtchcats)
        mtchinds{jj} = find(mtchcats(jj)==mtchlblinds);
        mtchnum(jj) = length(mtchinds{jj});
    end
    winners = find(mtchnum==max(mtchnum));
    labelnums(kclust.colclips(j)) = max(mtchnum);
    if length(winners)==1
        labelinds(kclust.colclips(j)) = mtchcats(winners);
        labeldist(kclust.colclips(j)) = mean(srt(mtchinds{winners},j));
    else % use average distance as a tie breaker
        tmpdist = zeros(size(winners));
        for jjj = 1:length(winners)
            tmpdist(jjj) = mean(srt(mtchinds{winners(jjj)},kclust.colclips(j)));
        end
        winner = find(tmpdist==max(tmpdist));
        try
            labelinds(kclust.colclips(j)) = mtchcats(winner);
        catch
            winner
        end
        labeldist(kclust.colclips(j)) = mean(srt(mtchinds{winner},j));
    end
end
mtchlbls.labelinds = labelinds;
mtchlbls.labeldist = labeldist;
mtchlbls.labelnum = labelnums;
mtchlbls.rowclips = kclust.rowclips;
mtchlbls.colclips = kclust.colclips;
mtchlbls.k = kclust.k;
                        
for i=1:colclipnum
%     labels.a(kclust.colclips(i)).labelind =
%     labelinds(kclust.colclips(i)); % redo labelkey below
    labels.a(kclust.colclips(i)).labeltime = now;
    labels.a(kclust.colclips(i)).labeler = -1; % auto label?
    labels.a(kclust.colclips(i)).label = kclust.rowlabels.labelkey(labelinds(kclust.colclips(i)));
    labels.a(kclust.colclips(i)).label2 = kclust.rowlabels.label2key(labelinds(kclust.colclips(i)));
    labels.a(kclust.colclips(i)).label3 = kclust.rowlabels.label3key{labelinds(kclust.colclips(i))};
end
labels = makelabelkey(labels);
% labels.labelers = mtchlbls.labelers;
labels.clippath = kclust.rowpath;
labels.clipfile = mtch.colfile;

% save
if kclust.save
    if isempty(kclust.mlblfile)
        [kclust.mlblfile kclust.colpath] = uiputfile('.mlbl','Choose matchlabel file to save data (.mlbl)');
        if kclust.mlblfile==0 return; end
    end
    save(fullfile(kclust.colpath,kclust.mlblfile),'mtchlbls','labels','-mat');
end

collabels = labels;


