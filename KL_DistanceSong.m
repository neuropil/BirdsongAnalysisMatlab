function [] = KL_DistanceSong()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

featNames = {'Mamp','Mpitch','MFM','MAM','Mentropy','MpitchG','Mfreq','VFM',...
    'Ventropy','Vpitchg','Vfreq','VAM'};


%% Get Bird number and data location

birdNum = Get_Bird_Number;
sapCheck = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum);

cd(sapCheck)

%% Create list of file names excluding the Meta Pre dataset
fileNames = cellstr(ls);
songsDSNs = fileNames(3:end);

PreAllName = strcat(birdNum,'_PreALL.mat');
nameIndex = ~strcmp(PreAllName,songsDSNs);
songDSlist = songsDSNs(nameIndex);


%%

numDays = length(songDSlist);

% Create a cell array with each matrix of feature data (align with names)

alldayDataCA = cell(numDays,1);
allDATAmat = [];
for adi = 1:numDays
    tempdayDS = songDSlist{adi};
    load(tempdayDS)
    tempMatrix = double(songDataset(:,featNames));
    alldayDataCA{adi,1} = tempMatrix;
    allDATAmat = [allDATAmat ; tempMatrix];
end

% Set the discretization lines

lower_edge = min(allDATAmat) - eps;
upper_edge = max(allDATAmat) + eps;

numFeats = length(featNames);    % length of features
numBins = 16;                 % NumG - 1 is the number of bins in each coordinate
for binIter = 1:numFeats
    Edges{binIter} = linspace(lower_edge(binIter), upper_edge(binIter), numBins);
    Edges{binIter}(end) = Edges{binIter}(end) + 1e-10;      % inlcude the boundary points
end 

% calculate the probability in each bin %%%
for featIter = 1:numFeats - 1
    edges{1} = Edges{1};
    edges{2} = Edges{featIter+1};
    for dayIter = 1:numDays
        tempDay = hist3(alldayDataCA{dayIter}(:, [1 featIter + 1]),'Edges', edges);
        binprob(:,:,dayIter,featIter) = tempDay(1:end-1,1:end-1);    % remove the artifact in the command
        binprob(:,:,dayIter,featIter) = binprob(:,:,dayIter,featIter)/sum(sum(binprob(:,:,dayIter,featIter)));       % normalization
    end
end  

% avoid zero probability (because zero is sensitive in K-L calculations)
for featIter2 = 1:numFeats - 1
    for dayIter2 = 1:numDays
        binprob(:,:,dayIter2,featIter2) = (binprob(:,:,dayIter2,featIter2)+1e-6)/sum(sum(binprob(:,:,dayIter2,featIter2)+1e-6)); 
    end
end

% estimate the K-L distance from day 1 for each feature %%%
for featIter3 = 1:numFeats - 1
    E(1,featIter3) = sum(sum(binprob(:,:,1,featIter3).*log2(binprob(:,:,1,featIter3) + eps)));
    for dayIter3 = 2:numDays
        E(dayIter3,featIter3) = sum(sum(binprob(:,:,1,featIter3).*log2(binprob(:,:,dayIter3,featIter3) + eps)));
    end
end

KL = ones(numDays,1)*E(1,:)-E;

% 8/20/2013 NEED TO COMPLETE
% ORDER OF DAYS IS FUCKED

%%% plot the K-L distance %%%
figure(1)
for n = 1:numFeats
    subplot(2,6,n);
    plot(KL(:,n), 'o-'); % this dies on 12th iteration
    xlim([0.8 numDays + 0.2]);
    title(sprintf('Duration and %s', featNames{n}), 'fontsize', 11);
    ylabel(sprintf('KL-distance \n from day 1 (bits)'), 'fontsize', 10);
    
    xlabel('session (day)');
    
end


end

