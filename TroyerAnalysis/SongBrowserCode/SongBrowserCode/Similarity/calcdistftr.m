function [mtch params] = calcdistftr(varargin)
% [matches params] = calcdistftr(varargin)
% script for calculating distance from clips in row directory (often already labeled)
% to clips in the col directory (often unlabeled) 
% use ftr values

cdftr.rowpath = [];
cdftr.rowfile = [];
cdftr.rowftrfile = [];
cdftr.rowclips = [];
cdftr.colpath = [];
cdftr.colfile = [];
cdftr.colftrfile = [];
cdftr.colclips = [];
cdftr.matchfile = [];
cdftr.ftrmetric = [];
cdftr.ftrlist = {'length','amp_mn','amp_std','Wentropy_mn','Wentropy_std','freqmean_mn','freqmean_std','freqstd_mn','freqstd_std','FFgood_mn','FFgood_std'};
cdftr.metric = @mnabsdev;
cdftr = parse_pv_pairs(cdftr,varargin);

%% get song directory for row clips load data
if ~(exist(fullfile(cdftr.rowpath,cdftr.rowfile))==2)
    [cdftr.rowfile cdftr.rowpath] = uigetfile({'*.dbk;*.bmk','Source file (*.dbk;*.bmk)';'*.*','All files (*.*)'},'Choose source of row (already labeled) data (*.dbk,*.sng)');
    if cdftr.rowfile==0 return; end
end
load(fullfile(cdftr.rowpath,cdftr.rowfile),'clips','-mat');
rowclips = clips;
rowclipnum = length(rowclips.a);
if isempty(cdftr.rowclips)
    cdftr.rowclips = 1:length(rowclips.a);
end
% get row features
if ~(exist(fullfile(cdftr.rowpath,cdftr.rowftrfile))==2)
    [cdftr.rowftrfile tmppath] = uigetfile({'*.ftr','Feature file (*.ftr)';'*.*','All files (*.*)'},...
                                                'Choose features for of row (already labeled) data');
    if cdftr.rowftrfile==0 return; end
    if ~strcmp(cdftr.rowpath,tmppath)
        disp('Path directory of ftr file does not match that of source file. Aborting.');return;
    end
end
load(fullfile(cdftr.rowpath,cdftr.rowftrfile),'-mat');
rowftrs = clipftrs;
rowftrlist = clipftrlist;
if isempty(cdftr.ftrlist)
    cdftr.ftrlist = rowftrlist;
end

%% get data for column clips
if ~(exist(fullfile(cdftr.colpath,cdftr.colfile))==2)
    [cdftr.colfile cdftr.colpath] = uigetfile({'*.bmk; .dbk','Source file (*.bmk; *.dbk)';'*.*','All files (*.*)'},...
                                                            'Choose source of ''col'' (unlabeled) data');
    if cdftr.colfile==0 return; end
end
load(fullfile(cdftr.colpath,cdftr.colfile),'clips','-mat')
colclips = clips;
colclipnum = length(colclips.a);
if isempty(cdftr.colclips)
    cdftr.colclips = 1:length(colclips.a);
end
% get col features
if ~(exist(fullfile(cdftr.colpath,cdftr.colftrfile))==2)
    [cdftr.colftrfile tmppath] = uigetfile({'*.ftr','Feature file (*.ftr)';'*.*','All files (*.*)'},...
                                            'Choose feature file for of col (unlabeled) data)');
    if cdftr.colftrfile==0 return; end
    if ~strcmp(cdftr.colpath,tmppath)
        disp('Path directory of ftr file does not match that of source file. Aborting.');return;
    end
end
load(fullfile(cdftr.colpath,cdftr.colftrfile),'-mat');
colftrs = clipftrs;
colftrlist = clipftrlist;
clear clipftrs clipftrlist


%% get ftr metric
if isempty(cdftr.ftrmetric) 
    [tmpfile tmppath] = uigetfile({'*.met','Metric file (*.met)';'*.*','All files (*.*)'},'Choose metric file');
    if tmpfile==0 return; end
    load(fullfile(tmppath,tmpfile),'-mat');
    cdftr.ftrmetric = metric;
end

% find matching categories, report others
comftrlist = intersect(intersect(rowftrlist,colftrlist),cdftr.ftrmetric.ftrlist);
if length(rowftrlist)~=length(comftrlist) | length(colftrlist)~=length(comftrlist) | length(cdftr.ftrmetric.ftrlist)~=length(comftrlist) 
    disp('Mismatch among ftrlists. Aborting.'); return;
end
    
rowftrinds = zeros(size(cdftr.ftrlist));
colftrinds = zeros(size(cdftr.ftrlist));
metftrinds = zeros(size(cdftr.ftrlist));
for i=1:length(cdftr.ftrlist)
    tmp = find(strcmp(cdftr.ftrlist{i},rowftrlist));
    if isempty(tmp)
        disp(['Can''t find feature ' cdftr.ftrlist{i} ' in row feauture list. Aborting.']); return;
    else
        rowftrinds(i)=tmp;
    end
    tmp = find(strcmp(cdftr.ftrlist{i},colftrlist));
    if isempty(tmp)
        disp(['Can''t find feature ' cdftr.ftrlist{i} ' in col feauture list. Aborting.']); return;
    else
        colftrinds(i)=tmp;
    end
    tmp = find(strcmp(cdftr.ftrlist{i},cdftr.ftrmetric.ftrlist));
    if isempty(tmp)
        disp(['Can''t find feature ' cdftr.ftrlist{i} ' in met feauture list. Aborting.']); return;
    else
        metftrinds(i)=tmp;
    end
end


%%% calculate matches 
mtch.m = -ones(rowclipnum,colclipnum);
wb = waitbar(0,['Matching clips, ' num2str(rowclipnum) 'x' num2str(colclipnum)]);
% calculate match
for i=1:length(cdftr.rowclips)
    for j=1:length(cdftr.colclips)
        mtch.m(cdftr.rowclips(i),cdftr.colclips(j)) = ...
                    feval(cdftr.metric,rowftrs(cdftr.rowclips(i),rowftrinds)./cdftr.ftrmetric.met(metftrinds),...
                                                colftrs(cdftr.colclips(j),colftrinds)./cdftr.ftrmetric.met(metftrinds));
    end
    waitbar(i/rowclipnum,wb);
end
close(wb)
mtch.rowclips = cdftr.rowclips;
mtch.colclips = cdftr.colclips;
mtch.colpath = cdftr.colpath;
mtch.colfile = cdftr.colfile;
mtch.rowpath = cdftr.rowpath;
mtch.rowfile = cdftr.rowfile;
mtch.ftrlist = comftrlist;
mtch.metric = cdftr.ftrmetric.met(metftrinds);

% save
pathname = cdftr.colpath;
if isempty(cdftr.matchfile)
    [cdftr.matchfile pathname] = uiputfile('*.mtch','Choose a match file (*.mtch)');
    if cdftr.matchfile==0 
        cdftr.matchfile = '';
    end
end

if ~isempty(cdftr.matchfile)
    save(fullfile(pathname,cdftr.matchfile),'mtch');
end

            
        
        
        
    