function alignftrs = dtwalignftrs(varargin)
% ftrs = dtwalignftrs(varargin)
% use DTW warps to make matrix of feature values aligned to template
% alignftrs is structure with fields sliceftrlist and a field containing
% a cell array where each entry is the matrix of feature values for one
% category

dtwalign.dtwpath = '';
dtwalign.ftrpath = '';
dtwalign.sliceftrlist = {'amp','Wentropy','freqmean','freqstd','FFgood'};
dtwalign.cats = []; % categories to do aligning
dtwalign.normalize = 0; % normalize by median values
dtwalign.save = 1; % save alignftrs structure
dtwalign = parse_pv_pairs(dtwalign,varargin);

%% get dtw path 
if ~isdir(dtwalign.dtwpath)
    dtwalign.dtwpath = uigetdirTT('.','Choose _dtw directory');
    if dtwalign.dtwpath==0 return; end
end
% load(fullfile(dtwalign.dtwpath,dtwalign.dtwfile),'warps','Dpaths','clipedges','clipinds',...
%     'excatinds','labels','temps','tempedges','tempcatinds','temps','-mat');
% locate ftr directory
[dtwalign.ftrpath] = uigetdirTT( 'Choose feature directory','Choose feature directory');
if dtwalign.ftrpath==0 return; end
[upperpath name ext] = fileparts(dtwalign.ftrpath);

% get list of category indices
if isempty(dtwalign.cats)
    disp('Need to specify list of category indices (''cats'' argument)'); return;
end
%     dtwalign.cats = 1:length(labels.labelkey);
% elseif ischar(dtwalign.cats) | iscell(dtwalign.cats)
%     dtwalign.cats = findlabelind(dtwalign.cats,labels);
% end
% get position of amplitude feature and dt
load(fullfile(dtwalign.ftrpath,[name(1:end-5) '_ftr_1.mat']));
dt = specparams.dt;
% initialize data
alignftrs.sliceftrlist = sliceftrlist;
ftrnum = length(sliceftrlist);
alignftrs.clips = [];
alignftrs.ftrs = [];
alignftrs.z = []; % zscore for each exemplar at each time bin
alignftrs.mn = []; % mean across exemplars at each time bin
alignftrs.std = []; % mean across exemplars at each time bin
alignftrs.mn_t = []; % mean across time for each exemplare 
alignftrs.std_t = []; % std across time for each exemplare 
alignftrs.corr = []; % correlation coefficient between exemplar and mean 
alignftrs.rmsz = []; % zscore for each exemplar averaged over time bins
alignftrs.rmszall = []; % zscore for each exemplar averaged over time bins and over features
alignftrs.Dpath = []; % DTW distance along path 
alignftrs.Dmn = []; % DTW distance along path, mean  for each time bin 
alignftrs.Dstd = []; % DTW distance along path, std  for each time bin 
alignftrs.Dmn_t = []; % DTW distance along path, mean for each exemplar 
alignftrs.Dstd_t = []; % DTW distance along path, std for each exemplar 
alignftrs.Dpz = []; % DTW distance along path, z score 
alignftrs.rmsDpz = []; % DTW distance along path, z score averaged over time (rms)
alignftrs.Dpnorm = []; % DTW distance along path, divided by std (but not mean subtracted)
alignftrs.rmsDpnorm = []; % DTW distance along path, divided by std averaged over time (rms)
alignftrs.Dpcorr = []; % correlation of Dp waveform with mean

% do alignmentca
for i=1:length(dtwalign.cats)
    ii = dtwalign.cats(i);
    % load dtw information if appropriate dtw directory exists
    if isdir([dtwalign.dtwpath filesep 'cat' num2str(ii)])

        load(fullfile([dtwalign.dtwpath filesep 'cat' num2str(ii)],[name(1:end-4) 'spec_dtw_' num2str(ii) '.mat']),...
            'warps','Dpaths','clipedges','clipinds',...
            'labels','fulltemp','tempedges','tempamp','-mat');
    else
        disp(['Can''t find directory ' dtwalign.dtwpath filesep 'cat' num2str(ii) '. Aborting.']); return;
    end
    alignftrs.clips = clipinds;
    alignftrs.clipedges = clipedges;
    alignftrs.temp = fulltemp(tempedges(1):tempedges(2));
    wb = waitbar(0,['Aligning features for category ' num2str(ii)]);
    if ~isempty(alignftrs.clips)
        % initialize ftr matrices
        alignftrs.ftrs = zeros(length(sliceftrlist),length(clipinds),diff(tempedges)+1);
        alignftrs.z = zeros(length(sliceftrlist),length(clipinds),diff(tempedges)+1);
        alignftrs.rmsz = zeros(length(sliceftrlist),length(clipinds));
        alignftrs.rmszall = zeros(1,length(clipinds));
        alignftrs.mn = zeros(length(sliceftrlist),diff(tempedges)+1);
        alignftrs.std = zeros(length(sliceftrlist),diff(tempedges)+1);
        alignftrs.mn_t = zeros(length(sliceftrlist),length(clipinds));
        alignftrs.std_t = zeros(length(sliceftrlist),length(clipinds));
        alignftrs.corr = zeros(length(sliceftrlist),length(clipinds));
        alignftrs.Dpath = zeros(length(clipinds),diff(tempedges)+1);
        alignftrs.Dpz = zeros(length(clipinds),diff(tempedges)+1);
        alignftrs.rmsDpz = zeros(length(clipinds),1);
        alignftrs.Dpnorm = zeros(length(clipinds),diff(tempedges)+1);
        alignftrs.rmsDpnorm = zeros(length(clipinds),1);
        alignftrs.Dpmn = zeros(1,diff(tempedges)+1);
        alignftrs.Dpstd = zeros(1,diff(tempedges)+1);
        alignftrs.Dpmn_t = zeros(length(clipinds),1);
        alignftrs.Dpstd_t = zeros(length(clipinds),1);
        alignftrs.Dpcorr = zeros(length(clipinds),1);
        % load and apply warping to appropriate section of ftr matrix
        for j=1:length(alignftrs.clips)
            load(fullfile(dtwalign.ftrpath,[name(1:end-5) '_ftr_' num2str(alignftrs.clips(j)) '.mat']));
            tmpvals = warpinterp(sliceftrs(clipedges(j,1):clipedges(j,2),:)',warps(j,:));
            alignftrs.ftrs(:,j,:) = tmpvals;
    %         for k=1:length(sliceftrlist)
    %             eval(['alignftrs.' sliceftrlist{k} '{i}(j,:) = tmpmat(k,:);']);
    %         end   
            waitbar(j/length(alignftrs.clips),wb);
        end
        close(wb);
        % compute Dpath variables
        alignftrs.Dpath = Dpaths;
        alignftrs.Dpmn = mean(Dpaths);
        alignftrs.Dpstd = std(Dpaths);
        alignftrs.Dpz = (Dpaths-ones(size(Dpaths,1),1)*mean(Dpaths))./(ones(size(Dpaths,1),1)*std(Dpaths));;
        alignftrs.rmsDpz = sqrt(sum(alignftrs.Dpz.^2,2));
        alignftrs.Dpmn_t = mean(Dpaths,2);
        alignftrs.Dpstd_t = std(Dpaths,0,2);
        alignftrs.Dpcorr = corr(alignftrs.Dpmn',Dpaths');
        alignftrs.Dpnorm = alignftrs.Dpath./...
            (alignftrs.Dpstd_t*ones(1,size(alignftrs.Dpath,2)));
        alignftrs.rmsDpnorm = sqrt(sum(alignftrs.Dpnorm.^2,2));
        % compute feature variables
        for k=1:length(sliceftrlist)
            tmp = squeeze(alignftrs.ftrs(k,:,:));
            alignftrs.mn(k,:) = mean(tmp);
            alignftrs.std(k,:) = std(tmp);
            alignftrs.z(k,:,:) = (tmp-ones(size(tmp,1),1)*mean(tmp))./(ones(size(tmp,1),1)*std(tmp));
            alignftrs.rmsz(k,:) = sqrt(sum(squeeze(alignftrs.z(k,:,:)).^2,2));
            alignftrs.mn_t(k,:) = mean(tmp,2);
            alignftrs.std_t(k,:) = std(tmp,0,2);
            alignftrs.corr(k,:) = corr(tmp',mean(tmp)');
        end 
        alignftrs.rmszall = sqrt(sum(alignftrs.rmsz.^2));
        save(fullfile([dtwalign.dtwpath filesep 'cat' num2str(ii)],'alignftrs.mat'),'alignftrs','-mat');
    end
end

