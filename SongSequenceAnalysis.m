function [ output_args ] = SongSequenceAnalysis( input_args )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here



%-------------------------------------------------------------------------%
%---------------------- Get Bird ID --------------------------------------%
%-------------------------------------------------------------------------%
birdNum = Get_Bird_Number;

%-------------------------------------------------------------------------%
%---------------------- Syllable Parameters ------------------------------%
%-------------------------------------------------------------------------%
cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\ParamSpace')

pfName = strcat(birdNum,'_SyllParamSpace.mat');

if ~exist(pfName,'file')
    Get_syllable_extraction
else
    load(pfName)
end

%-------------------------------------------------------------------------%
%---------------------- Syllable Parameters ------------------------------%
%-------------------------------------------------------------------------%
sapCheck = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum);

cd(sapCheck)

fileNames = cellstr(ls);
songsDSNs = fileNames(3:end); % songDSNs has PreAll

PreAllName = strcat(birdNum,'_PreALL.mat');
nameIndex = ~strcmp(PreAllName,songsDSNs);
songDSlist = songsDSNs(nameIndex);

[songListReO , ~] = songDateReorder(songDSlist);

load(PreAllName);

%-------------------------------------------------------------------------%
%---------------------- Defaults -----------------------------------------%
%-------------------------------------------------------------------------%
% featNames = {'Mamp','Mpitch','MFM','MAM','Mentropy','MpitchG','Mfreq','VFM',...
%     'Ventropy','Vpitchg','Vfreq','VAM'};

% numFeats = length(featNames);

numClusts = length(SyllIDS);

durationPreall = PreMetaSet.syldur;
feat2usePreall = PreMetaSet.(FeatureUsed);

% Actual syllables in order contained in SyllIDS variable
syllIndex = zeros(length(SyllPolyIndices{1}),1);
for syI = 1:numClusts
    syllIndex = syllIndex + (syI * SyllPolyIndices{syI}); 
end

%% plot the clutered scatterplot %%%%

xMax = mean(durationPreall) + (std(durationPreall)*2.25);
yMax = mean(feat2usePreall) + (std(feat2usePreall)*2.25);

figure(1);
Rcolor = linspace(0.9,0,numClusts);
subplot(3,1,[1 2]);
plot(durationPreall(syllIndex == 0),feat2usePreall(syllIndex == 0), 'k.'); hold on;
for clI = 1:numClusts
    [GEOM, ~, ~] = polygeom(SyllPolygons.xCords{clI},SyllPolygons.yCords{clI});
    xCentroid = GEOM(2);
    yCentroid = GEOM(3);
    plot(SyllPolygons.xCords{clI},SyllPolygons.yCords{clI}, 'Color', [1 Rcolor(clI) Rcolor(clI)],'LineStyle', '--')
    hold on
    plot(durationPreall(syllIndex == clI),feat2usePreall(syllIndex == clI), '.', 'Color', [1 Rcolor(clI) Rcolor(clI)]);
    text(xCentroid,yCentroid,SyllIDS{clI},'FontSize',18,'FontWeight','bold','BackgroundColor',[1 1 1]);
    xlabel('Duration (ms)', 'fontsize', 12);
    ylabel(sprintf('%s', FeatureUsed), 'fontsize', 12);   
    title('Labeled Clusters', 'fontsize', 14);
    axis tight;
    axis([0 xMax 0 yMax]);
end


%% calculate probability for each sequence %%%
% prepare labels for sequence analysis

syllsNoise = 0:numClusts;
allSylls = ['n' , SyllIDS];

syllIDnums = zeros(1,numel(allSylls)^2);
binstart = 1:length(allSylls);
incstart = 0;
for clI = 1:length(allSylls)
    binInc = incstart * 10;
    syllIDnums(binstart) = (0:numClusts) + binInc;
    binstart = binstart + length(allSylls);
    incstart = incstart + 1;
end 

sylListPermute = [allSylls, fliplr(allSylls)];
sylPermRun = nchoosek(cell2mat(sylListPermute),2);
allPossSylTrans = unique(cellstr(sylPermRun)); % original sbin2

%% Probability of each cluster
syllOccur = histc(syllIndex, syllsNoise);
syllProb = syllOccur/sum(syllOccur);    % probability of each cluster 

% Identify unique transitions by multiplying each syllable by 10 (except last)
% and then adding that value to the next syllable identity starting with
% the second syllable. index A [1 2 3 4] + index B [2 3 4 5]. This will
% correspond to bin2 identities.

syllIndexTrans = syllIndex(1:end-1)*10 + syllIndex(2:end);
% remove first elements of bouts
wavNumsPreAll = StripWav(PreMetaSet.filename);

syllIndexTrans(diff(wavNumsPreAll.WavNumber) ~= 0) = []; 

syllTransOccur = histc(syllIndexTrans, syllIDnums);
syllTransProb = syllTransOccur/sum(syllTransOccur);    % probability of each sequence 


%% label each note for day 2 to day 12 %%%
numDays = length(songListReO);      % number of sessions (before and after surgery)
for dayI = 1:numDays - 1
    tempDay = songListReO{dayI};
    load(tempDay)
    
    tempSylIndex = zeros(length(songDataset.syldur),1);
    for clI = 1:numClusts
        tempSylIndex = tempSylIndex + clI *...
            inpolygon(songDataset.syldur,...
            songDataset.(FeatureUsed),...
            SyllPolygons.xCords{clI},...
            SyllPolygons.yCords{clI});
    end   

    syllOccur(:,dayI + 1) = histc(tempSylIndex, syllsNoise);
    syllProb(:,dayI + 1) = syllOccur(:, dayI + 1) / sum(syllOccur(:, dayI + 1)); % probability of each cluster 
    
    tempSylTransIndex = tempSylIndex(1:end-1)*10 + tempSylIndex(2:end);
    tempSylTransIndex(diff(songDataset.WavNumber) ~= 0) = [];  % remove the boundry points
    
    syllTransOccur(:,dayI + 1) = histc(tempSylTransIndex, syllIDnums);
    syllTransProb(:,dayI + 1) = syllTransOccur(:,dayI + 1)/sum(syllTransOccur(:,dayI + 1)); % probability of each sequence 
end

%% plot the selected sequencing distribution %%%

t = [1 4 8 12];
day = {'day 1', 'day 4', 'day 6', 'day 8'};
ind = find(max(p2(:,t),[],2) > 0.05);     % add low probability sequences together
p_new = p2(ind, :); 
p_new = [p_new; 1 - sum(p_new, 1)];  
for k = 1:4
    figure(2)
    subplot(4,1,k);
    bar(1:length(ind)+1, p_new(:,t(k)));  
    ylim([0 max(p2(:))+0.1]);
    xlim([0.5 length(ind)+1.5]); 
    set(gca, 'xtick', 0:length(ind), 'xticklabel', ' ');
    if k == 4
        set(gca, 'xtick', 1:length(ind)+1, 'xticklabel', [sbin2(ind) 'others'], 'fontsize', 12);
    end
    set(gca, 'ytick', [0 0.4], 'fontsize', 12);  
    text(length(ind)-1, 0.35, day{k}, 'fontsize', 14);
end








end

