function [ output_args ] = InsertSyllableID()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here






%% Get Bird ID
birdNum = Get_Bird_Number;

%% Syllable Parameter Location

cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\ParamSpace')

%% Check for Parameter m file

pfName = strcat(birdNum,'_SyllParamSpace.mat');

if ~exist(pfName,'file')
    Get_syllable_extraction
else
    load(pfName)
end

%% Get all file names and locations

dataLoc = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\SAP_Data\',birdNum);
sapCheck = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum);

cd(dataLoc)

cdirList = cellstr(ls);
conditions = cdirList(3:end);

%% Check for and generate song data sets

for ci = 1:length(conditions)
    tempLoc = strcat(dataLoc,'\',conditions{ci});
    cd(tempLoc)
    
    dList = cellstr(ls);
    xlList = dList(3:end);
    
    for xi = 1:numel(xlList)
        cd(tempLoc)
        
        xName = xlList{xi};
        
        removeFF = strtok(xName,'.');
        
        [birdN, dOut] = strtok(removeFF,'_');
        
        dateN = dOut(2:end);
        
        SapName = strcat(birdN,'_',conditions{ci},'_',dateN,'.mat');
        cd(sapCheck);
        getmFiles = dir('*.mat');
        mFiles = {getmFiles.name};
        if ismember(SapName,mFiles)
            continue
        else
            Instant_SAP_Dataset(birdN, conditions{ci} ,dateN);
        end
    end
end

%% Insert Syllable ID (8/1/2013)

fileNames = cellstr(ls);
songsDSNs = fileNames(3:end);

PreAllName = strcat(birdNum,'_PreALL.mat');
nameIndex = ~strcmp(PreAllName,songsDSNs);
songDSlist = songsDSNs(nameIndex);


% typicalTrans = nchoosek(cell2mat(SyllIDS),2);

% Use PreMat to get TypicalTrans 8/5/2013
load(PreAllName)
allPreSylls = PreMetaSet.syll_id;

% Get Syllable all Pre syllable transitions
syllPair = {};
spCount = 1;
fSl = 1;
sSl = 2;
for gsi = 1:length(allPreSylls) 
    if sSl > length(allPreSylls)
        break
    elseif allPreSylls{fSl} == 'n' || allPreSylls{sSl} == 'n';
        fSl = fSl + 1;
        sSl = sSl + 1;
    else
        syllPair{spCount,1} = strcat(allPreSylls{fSl},allPreSylls{sSl});
        fSl = fSl + 1;
        sSl = sSl + 1;
        spCount = spCount + 1;
    end
end
    
% Find unique syllable transitions and probabilities
allSyllTrans = unique(syllPair);
totalTrans = length(syllPair);

% Get probabilites
for stp = 1:length(allSyllTrans)
    tranOccur = sum(strcmp(allSyllTrans{stp},syllPair));
    allSyllTrans{stp,2} = tranOccur/totalTrans;
end

% Sort syll Trans Probabilites
syllProbs = cell2mat(allSyllTrans(:,2));
[~, sIndex] = sort(syllProbs, 'descend');
allSyllTrans = allSyllTrans(sIndex,:);

% Some Description

seqFilename = strcat(birdNum,'_SongSequenceData.mat');

songSeqDirName = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\SongSeqData\',...
    birdNum);

if exist(songSeqDirName,'dir')
    cd(songSeqDirName)
    if exist(seqFilename,'file')
        disp('Sequence data has been analyzed!!!!');
        return
    end
end

cd(sapCheck);

TotalSylls = length(SyllIDS);

AllSongData = cell(length(songDSlist),2);
for sdi = 1:length(songDSlist)
    tempSongDS = songDSlist{sdi};
    load(tempSongDS)

    if sum(isnan(songDataset.MAM)) ~= 0
        songDataset(isnan(songDataset.MAM),:) = [];
    end
    
    syllable_indices = cell(1,TotalSylls);
    
    for i = 1:TotalSylls
        syllable_indices{1,i} = inpolygon(songDataset.syldur,songDataset.(FeatureUsed),...
            SyllPolygons.xCords{1,i},SyllPolygons.yCords{1,i});
    end

    syll_id = cell(length(songDataset),1);
    for sii = 1:length(songDataset)
        songRow = false(1,TotalSylls);
        for sir = 1:TotalSylls
            songRow(sir) = syllable_indices{1,sir}(sii);
        end
        
        if sum(songRow) == 0
            syll_id{sii} = 'n';
        else 
            syll_id{sii} = SyllIDS{songRow};
        end
    end
    
    syllIDds = dataset(syll_id,'VarNames','SyllableID');
    wavNums = StripWav(songDataset.filename);
    songDataset = [songDataset , wavNums, syllIDds];
    save(tempSongDS,'songDataset');
    
    convert_wavs = zeros(length(songDataset),1);
    for cwi = 1:length(songDataset)
        convert_wavs(cwi) = str2double(strtok(songDataset.filename(cwi),'.'));
    end
    
    getWavindices = unique(convert_wavs);
    
    SongSeqStats = struct;
    
    for syl = 1:length(getWavindices)
        tempIndex = convert_wavs == getWavindices(syl);
        
        songSylls = sum(cellfun(@(x) ~strcmp(x,'n'), unique(syll_id(tempIndex))));
        
        sylIndex = syll_id(tempIndex);
        
        syl1 = 1;
        syl2 = 2;
        trans_count = 1;
        sylTrans = {};
        while syl2 < sum(tempIndex)
            sylTrans{trans_count} = strcat(sylIndex{syl1},sylIndex{syl2});
            
            syl1 = syl1 + 1;
            syl2 = syl2 + 1;
            trans_count = trans_count + 1;
        
        end
        
        songTrans = numel(unique(sylTrans)); 
        
        % Sequence Linearity = # different syllables/song / # transition types
        
        SongSeqStats.SeqLinearity(syl,1) = songSylls/songTrans;
        
        % Sequence Consistency = Sum typical syllables/song / Sum total transitions / song
        
        SongSeqStats.SeqConsistency(syl,1) = sum(ismember(sylTrans,allSyllTrans(:,1)))/numel(sylTrans);
        
        % Stereotypy Score = Sequence Linearity + Sequence Consistency / 2
        
        SongSeqStats.SongStereotypy(syl,1) = (SongSeqStats.SeqLinearity(syl,1) + SongSeqStats.SeqConsistency(syl,1)) / 2;
        
    end
    
    

    
    
    SeqSongStats = dataset(SongSeqStats.SeqLinearity,SongSeqStats.SeqConsistency,SongSeqStats.SongStereotypy,'VarNames',{'SLinearity','SConsistent','SongStereo'});
    
    AllSongData{sdi,1} = tempSongDS;
    AllSongData{sdi,2} = SeqSongStats;
    
    fprintf('Sequence analysis for file %s complete! \n', tempSongDS);
    
end

if ~exist(songSeqDirName,'dir')
    mkdir(songSeqDirName)
    cd(songSeqDirName)
else
    cd(songSeqDirName)
end


save(seqFilename,'AllSongData');


end

