function  calcftrclips(varargin)
% calcftrslice(varargin)
% also calculate amplitude, mean and std freq, and entropy

calftrcl.bmkpath = [];
calftrcl.bmkfile = [];
calftrcl.clipftrlist = {'ch2'};
calftrcl.thresh = .25; % look for segmentation at this level if zero use whole clip
calftrcl = parse_pv_pairs(calftrcl,varargin);

% locate bookmark file as pointer to ftrs and spec directories
if isempty(fullfile(calftrcl.bmkpath,calftrcl.bmkfile))
    [calftrcl.bmkfile calftrcl.bmkpath] = uigetfile({'*.bmk;*.dbk','Bookmark files (*.bmk;*.dbk)';'*.*','All files (*.*)'},...
                                                        'Select bookmark file','Select file');
    if calftrcl.bmkfile==0; return; end
end
% load(fullfile(calftrcl.bmkpath,calftrcl.bmkfile),'clips','-mat');
% separate bmk file into parts
[bmkpath name bmkext] = fileparts(fullfile(calftrcl.bmkpath,calftrcl.bmkfile));

ftrpath = [bmkpath filesep name '_ftrs'];
if ~exist(ftrpath,'dir')
    ftrpath = uigetdir('Get ftrs directory','Get ftrs directory');
    if ftrpath==0 return; end
end
specpath = [bmkpath filesep name '_spec'];
if ~exist(specpath,'dir')
    specpath = uigetdir('Get ftrs directory','Get ftrs directory');
    if specpath==0 return; end
end

% load segmentation and length info from specs directory 
%matt chg 3/6/2012
%load(fullfile(specpath,'cliplens.mat'));
if calftrcl.thresh==0 % use full clip lengths for feature calculations
    load(fullfile(specpath,'speclens.mat'));
    cliplens = speclens;
    edges = ones(size(edges));
    edges(:,2) = cliplens;
else
    if ~exist(fullfile(specpath,['clipseg_' num2str(calftrcl.thresh*100) '.mat']),'file')
        disp(['Can''t find file clipseg_' num2str(calftrcl.thresh*100) '.mat. Abotring.']); return;
    else
        load(fullfile(specpath,['clipseg_' num2str(calftrcl.thresh*100) '.mat']));
    end
end
    
% load first feature variable to get sliceftrlist and initialize data
load(fullfile(ftrpath,[name '_ftr_1.mat']),'-mat');
clipftrs = zeros(length(cliplens),1+length(calftrcl.clipftrlist)+2*length(sliceftrlist));
clipftrlist = cell(1+length(calftrcl.clipftrlist)+2*length(sliceftrlist),1);

wb = waitbar(0,'Calculating features per clip');
% set directory if local
for i=1:length(cliplens)
    load(fullfile(ftrpath,[name '_ftr_' num2str(i) '.mat']),'-mat');
    % calculate length
    clipftrlist{1} = 'length';
    clipftrs(i,1) = (diff(clipedges(i,:))+1)*specparams.dt; %length of clip in msec
    % features for the whole clips
    for j=1:length(calftrcl.clipftrlist)
        switch lower(calftrcl.clipftrlist{j})
            case 'ch2' % fraction of slices with greater power on 'correct' channel
                dampind = find(strcmp(sliceftrlist,'ampdiff'));
                clipftrs(i,j+1) = sum(sliceftrs(clipedges(i,1):clipedges(i,2),dampind)>=0)/(diff(clipedges(i,:))+1);
                clipftrlist{j+1} = 'ch2';
        end
    end
    % mean and standard deviation of all features calculated per slice
    offset = 1+length(calftrcl.clipftrlist);
    for j=1:length(sliceftrlist)
        clipftrlist{offset+2*j-1} = [sliceftrlist{j} '_mn'];
        clipftrs(i,offset+2*j-1) = mean(sliceftrs(clipedges(i,1):clipedges(i,2),j));
        clipftrlist{offset+2*j} = [sliceftrlist{j} '_std'];
        clipftrs(i,offset+2*j) = std(sliceftrs(clipedges(i,1):clipedges(i,2),j));
    end
    waitbar(i/length(speclens),wb); 
end

save([calftrcl.bmkpath filesep name '.ftr'],'clipftrs','clipftrlist','specparams','freqrange','-mat');

if ishandle(wb) close(wb); end

        
    
    

    
    