%% Very Cool cluster 

% Next extract order of syllables from clusters

% Create function to determine which feature to use to separate syllables

figure;
plot(cell2mat(songDataset.syldur), cell2mat(songDataset.MpitchG),'.')

colors = ('rkymg');
nextCluster = 1;   
i = 1;
clusterID = zeros(length(cell2mat(songDataset.syldur)),1);
xcords = {};
ycords = {};
while nextCluster
    
    [xcords{i}, ycords{i}] = getline('closed');
    
    nodes{i} = xcords{i};
    nodes{1,i}(:,2) = ycords{i};
    
    IN = inpolygon(cell2mat(songDataset.syldur),cell2mat(songDataset.MpitchG),xcords{i},ycords{i});
    hold on
    plot(cell2mat(songDataset.syldur(IN)),cell2mat(songDataset.MpitchG(IN)),'.','Color',colors(i))
    
    clusterID(IN) = i;

    i = i + 1;
    nextCluster = input('Select another cluster? ');
end

% Get Seqeuence Values

Syll_Num = max(clusterID);
syll_trans = (Syll_Num + 1) * (Syll_Num + 1);

SeqBins = [];
for i = 0:Syll_Num
    SeqBins = [SeqBins 10*i + (0:Syll_Num)];
end
SeqBins = SeqBins';

binarySeq = [clusterID(1:end-1)*10 + clusterID(2:end) ; clusterID(end)];
SeqProb = histc(binarySeq, SeqBins);
SeqProb = SeqProb/sum(SeqProb); 

% Get Bout Start Indices
boutNumber = zeros(length(songDataset.filename),1);
for i = 1:length(songDataset.filename)
    boutNumber(i) = str2double(songDataset.filename{i}(1:5));
end

occurrs = {'first','last'};
boutIndices = zeros(max(boutNumber),2);
for bbi = 1:length(occurrs)
    [boutVals, boutIndices(:,bbi), ~] = unique(boutNumber, 'rows', occurrs{bbi});
end

% By bout probability
Bout_PST = cell(max(boutNumber),1);
for bi = 1:length(boutVals)
    Bout_PST{bi,1} = histc(binarySeq(boutIndices(bi,1):boutIndices(bi,2)),SeqBins);
    Bout_PST{bi,1} = Bout_PST{bi,1}/sum(Bout_PST{bi,1});
end

% BIND PROBability of TRANSITION to ACTUAL TRANSITION IN BOUT VECTOR


% Plot separate lines X axis : Possible transitions   Y axis : transition probabilities

figure;
for plotI = 1:length(Bout_PST)
    hold on
    plot(Bout_PST{plotI,1}, 'o')
end





songDataset.clusterID = clusterID;





songDataset.boutNumber = boutNumber;








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



sampleBout = songDataset(songDataset.boutNumber == 1,:);

plot(cell2mat(sampleBout.syldur),cell2mat(sampleBout.Mpitch),'o',...
    'MarkerFaceColor',[1,0,0]);

figure

hold on

% bring up spectrogram of bout 1
% bring up overlay of each note and dot location graph 
% user input Note number