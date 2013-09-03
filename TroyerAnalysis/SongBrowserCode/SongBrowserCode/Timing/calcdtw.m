function  [warps,ranges,Dcums] = calcdtw(varargin)
% [warp,range,Dcum] = calcdtw(varargin)
% calculate DTW maps for clips in a labeled bookmark file 
% varargin can be used to set the following parameter/value pairs
% mlim - specifies bounds on dtw in terms of deviation from uniform timing
%   if 0<=mlim<1, mlim specifies fraction of template length
%   otherwise, mlim specifies number of bins 
%   default is mlim = .25
% boundary - specifies extent and cost along edges that terminate path
%    default is boundary = zeros(mlim,1);
% interpolate - flags whether to interpolate exmplar values to match length
%   of template (cubic spline interpolation, default = 1)

%% set defaults
caldtw.tempfile = '';
caldtw.temppath = '';
caldtw.specpath = '';
caldtw.dtwpath = '';
caldtw.lblpath = '';
caldtw.lblfile = ''; 
caldtw.cats = []; % categories to do warping
caldtw.thresh = .75;
caldtw.metric = @mnsqrdev2;
caldtw.mlim = .25;
caldtw.boundary = [];
caldtw.interpolate = 1;
caldtw.savespecs = 0;
caldtw.freqrange = [.7 7]; % frequency range to use for DTW (in kHz)
% caldtw.defaultnaming = 1; % assume default naming scheme for STD specs and template
caldtw.displaywarp = 1; % display warping map for each exemplar as it's calculated
caldtw.pauseafterdisplay = 0; % pause after each display
caldtw = parse_pv_pairs(caldtw,varargin);

%% get templates from label file 
if ~exist(fullfile(caldtw.temppath,caldtw.tempfile))
    [caldtw.tempfile caldtw.temppath] = uigetfile({'*.lbl;*.mlbl','label files';'*.*','All files'},...
        'Pick lable file with templates','Choose template label file');
    if caldtw.temppath==0 return; end
end
load(fullfile(caldtw.temppath,caldtw.tempfile),'labels','temps','-mat');

% get category inds and strings for template
if isempty(caldtw.cats)
    tempcatinds = 1:length(temps.labelkey);
    tempcatstr = makelabelstr(temps.labelkey,temps.label2key,temps.label3key);
elseif iscell(caldtw.cats)
    tempcatinds = findlabelind(caldtw.cats,temps);
    tempcatstr = caldtw.cats;
else
    tempcatinds = caldtw.cats;
    tempcatstr = makelabelstr(temps.labelkey(tempcatinds),...
                    temps.label2key(tempcatinds),temps.label3key(tempcatinds));
end


%% get labels for exemplar specs
if ~(exist(fullfile(caldtw.lblpath,caldtw.lblfile))==2)
    [caldtw.lblfile caldtw.lblpath] = uigetfile({'*.lbl;*.mlbl','label files';'*.*','All files'},...
        'Pick lable file for exemplars','Choose exemplar label file');
    if caldtw.lblfile==0 return; end
end
load(fullfile(caldtw.lblpath,caldtw.lblfile),'labels','-mat');

%% locate spec directory for exemplars
if ~exist(caldtw.specpath,'dir')
    [caldtw.specpath] = uigetdir( 'Choose spectrogram directory','Choose spectrogram directory');
    if caldtw.specpath==0 return; end
end
[upperpath name ext] = fileparts(caldtw.specpath);
% find frequency indices
load(fullfile(caldtw.specpath,'specparams.mat'),'-mat');
freqinds = find(specparams.f>=caldtw.freqrange(1) & specparams.f<=caldtw.freqrange(2));


% get category inds and strings for exemplar
if isempty(caldtw.cats)
    excatinds = 1:length(labels.labelkey);
    excatstr = makelabelstr(labels.labelkey,labels.label2key,labels.label3key);
elseif iscell(caldtw.cats)
    excatinds = findlabelind(caldtw.cats,labels);
    excatstr = caldtw.cats;
else
    excatinds = caldtw.cats;
    excatstr = makelabelstr(labels.labelkey(excatinds),...
                    labels.label2key(excatinds),labels.label3key(excatinds));
end
% find matching categories, report others
exnottemp = setdiff(excatstr,tempcatstr);
if ~isempty(exnottemp)
    disp('Categories for exmplars without matching template:'); disp(exnottemp');
end
tempnotex = setdiff(tempcatstr,excatstr);
if ~isempty(tempnotex)
    disp('Categories for templates without matching exemplar category:'); disp(tempnotex');
end
[tmp Iex Itemp] = intersect(excatstr,tempcatstr);
excatstr = excatstr(Iex);
excatinds = excatinds(Iex);
tempcatstr = tempcatstr(Itemp);
tempcatinds = tempcatinds(Itemp);


% %% initialize data
% warps = cell(length(labels.labelkey),1);
% clipinds = cell(length(labels.labelkey),1);
% onsets = cell(length(labels.labelkey),1);
% offsets = cell(length(labels.labelkey),1);
% ranges = cell(length(labels.labelkey),1);
% Dcums = cell(length(labels.labelkey),1);
% specs = cell(length(labels.labelkey),1);

% if it doesn't exist, make dtw directory
%% locate spec directory for exemplars
if ~exist(caldtw.dtwpath,'dir')
    caldtw.dtwpath = [caldtw.specpath(1:end-4) 'dtw'];
end
if ~exist(caldtw.dtwpath,'dir')
    mkdir(caldtw.dtwpath);
end

%% warp one category at a time
for i=1:length(excatinds)
    tempi = tempcatinds(i);
    exi = excatinds(i);
    % get template and segment
    fulltemp = abs(temps.tmpl{tempi});
    tempamp = ftr_amp(fulltemp,temps.specparams.f,'freqrange',caldtw.freqrange);
    abovethreshinds = find(tempamp>caldtw.thresh);
    tempedges = [min(abovethreshinds) max(abovethreshinds)];
    temp = fulltemp(:,tempedges(1):tempedges(2));
    %% set mlim in units of time bins and find frequency indices
    if caldtw.mlim>0 & caldtw.mlim<1
        caldtw.mlim = ceil(.25*size(temp,2));
    end
    if isempty(caldtw.boundary)
        caldtw.boundary = zeros(caldtw.mlim,1);
        caldtw.boundary = zeros(ceil(caldtw.mlim/10),1);
    end

    %% find warp maps and ranges
    clipinds = find(exi==[labels.a.labelind]);
    warps = zeros(length(clipinds),size(temp,2));
    clipedges = zeros(length(clipinds),2);
    ranges =  zeros(length(clipinds),4);
    Dpaths =  zeros(length(clipinds),size(temp,2));
    if caldtw.savespecs
        specs = zeros(length(clipinds),size(temp,1),size(temp,2));
    end
    wb = waitbar(0,['Calculating DTW maps for category ' num2str(exi) ', ' num2str(length(clipinds)) ' clips.']);
    for j=1:length(clipinds)
        load(fullfile(caldtw.specpath,[name '_' num2str(clipinds(j)) '.mat']));
        spec = abs(spec);
%         specamp = ftr_amp(spec,temps.specparams.f,'freqrange',caldtw.freqrange);
%         abovethreshinds = find(specamp>caldtw.thresh);
%         % set boundaries to entire spec for short/soft clips
%         % these should be screened eventually
%         if length(abovethreshinds)<=4 
%             disp(['WARNING: clip ' num2str(clipinds{ii}(j)) ' has less than 5 bins above theshold']);
%             edges{ii}(j,:) = [1 length(specamp)];
%         else
%             edges{ii}(j,:) = [min(abovethreshinds) max(abovethreshinds)];
%         end
        [warp, range,M,Dpath,Dcum] = dtw(temp,spec(:,edges(1):edges(2)),...
            'freqinds',freqinds,'metric',caldtw.metric,'mlim',caldtw.mlim,'boundary',caldtw.boundary);
        clipedges(j,:) = edges;
        warps(j,:) = warp(:)';
        ranges(j,:) = range(:)';
        Dpaths(j,:) = Dpath(:)';
        if caldtw.savespecs
            specs(j,:,:) = warpinterp(spec(:,edges(1):edges(2)),warp,...
                                                        'pad',zeros(size(spec,1),1));
        end
        if caldtw.displaywarp
            figure(10); clf;
            dtwdisplay(temp,spec(:,edges(1):edges(2)),M,warp,range,diff(t(1:2)),f);
            if caldtw.pauseafterdisplay==Inf
                pause;
            else
                pause(caldtw.pauseafterdisplay);
            end
        end
        waitbar(j/length(clipinds),wb);
    end
    close(wb)
    if ~exist([caldtw.dtwpath filesep 'cat' num2str(excatinds(i))],'dir')
        mkdir([caldtw.dtwpath filesep 'cat' num2str(excatinds(i))]);
    end
    save(fullfile([caldtw.dtwpath filesep 'cat' num2str(excatinds(i))],[name '_dtw_' num2str(excatinds(i)) '.mat']),...
        'fulltemp','tempamp','tempedges','clipinds','warps','ranges','Dpaths','clipedges','labels','-mat');
    if caldtw.savespecs
        save(fullfile([caldtw.dtwpath filesep 'cat' num2str(excatinds(i))],[name '_dtw_' num2str(excatinds(i)) '_spec.mat']),...
            'fulltemp','tempamp','tempedges','clipinds','clipedges','specs','-mat');
    end
end


 