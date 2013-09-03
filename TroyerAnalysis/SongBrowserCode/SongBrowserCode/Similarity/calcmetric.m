function [metric ftrlist] = calcmetric(varargin)
% [metric ftrlist] = calcmetric(varargin)
% use data from .ftr file to create metric based on standard deviations
% metric is a vector of 'standard' deviation values
% devtype can be used to set type of deviation:
%  one of 'std' (standard deviation),'MADmd' (mean abs dev from median - default)
%  'MADmn' (mean absolute deviation from mn

cmet.ftrs = [];
cmet.labels = [];
cmet.ftrpath = '';
cmet.ftrfile = '';
cmet.lblpath = '';
cmet.lblfile = '';
cmet.allclips = 0; % flags calculation from all clips - Mahlonobnis
cmet.clipinds = ''; % metric over all these clipinds
cmet.cats = ''; % categories to develop metric
cmet.devtype = 'MADmd';
cmet.save = 1; % flag saving of metric
cmet = parse_pv_pairs(cmet,varargin);

met = [];
ftrlist = {};

% load .ftr file
if isempty(cmet.ftrs) 
    if ~exist(fullfile(cmet.ftrpath,cmet.ftrfile))
        [cmet.ftrfile,cmet.ftrpath] = uigetfile({'*.ftr;feature files','*;*;All files'},...
            'Pick feature file','Choose feature file');
        if cmet.ftrpath==0 return; end
    end
    load(fullfile(cmet.ftrpath,cmet.ftrfile),'-mat');
    cmet.ftrs = clipftrs;
    ftrlist = clipftrlist;
    clear ftrs
end
% load .lbl file
if isempty(cmet.labels) & ~cmet.allclips & isempty(cmet.clipinds) 
    if ~exist(fullfile(cmet.lblpath,cmet.lblfile))
        [cmet.lblfile,cmet.lblpath] = uigetfile({'*.lbl;label files','*;*;All files'},...
            'Pick label file','Choose label file');
        if cmet.lblpath==0 return; end
    end
    load(fullfile(cmet.lblpath,cmet.lblfile),'-mat');
    cmet.labels = labels;
    clear labels
end

% if allclips or specified clipinds find  deviations across data
if cmet.allclips | ~isempty(cmet.clipinds)
    if cmet.allclips
        cmet.clipinds = 1:size(cmet.ftrs,1);
    end
    tmpftrs = cmet.ftrs(cmet.clipinds,:);
    switch cmet.devtype
        case 'MADmd'
            met = mean(tmpftrs-ones(length(cmet.clipinds),1)*median(tmpftrs));
        case 'MADmn'
            met = mean(tmpftrs-ones(length(cmet.clipinds),1)*mean(tmpftrs));
        case 'std'
            met = std(tmpftrs);
    end
else   % metric is average deviation over categories
    % get list of category indices
    if isempty(cmet.cats)
        catinds = 1:length(cmet.labels.labelkey);
    elseif iscell(cmet.cats)
        catinds = findlabelind(cmet.cats,cmet.labels);
    else
        catinds = cmet.cats;
    end
    tmpmet = zeros(length(catinds),size(cmet.ftrs,2));
    for i=1:length(catinds)
        clipinds = find([cmet.labels.a.labelind]==catinds(i));
        tmpftrs = cmet.ftrs(clipinds,:);
        switch cmet.devtype
            case 'MADmd'
                tmpmet(i,:) = mean(abs(tmpftrs-ones(length(clipinds),1)*median(tmpftrs)));
            case 'MADmn'
                tmpmet(i,:) = mean(abs(tmpftrs-ones(length(clipinds),1)*mean(tmpftrs)));
            case 'std'
                tmpmet(i,:) = std(tmpftrs);
        end
    end
    met = mean(tmpmet);
end
metric.met = met;
metric.devtype = cmet.devtype;
metric.ftrlist = ftrlist;
if cmet.save
    [filename pathname] = uiputfile({'*.met';'*.mat';'*.*'},'Save as');
    save(fullfile(pathname,filename),'metric','-mat');
end