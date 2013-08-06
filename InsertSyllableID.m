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
nameIndex = ~strcmp(PreAllName,songDSNs);
songDSlist = songsDSNs(nameIndex);


% typicalTrans = nchoosek(cell2mat(SyllIDS),2);

% Use PreMat to get TypicalTrans 8/5/2013

for sdi = 1:length(songDSlist)
    tempSongDS = songDSlist{sdi};
    load(tempSongDS)
    
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
    
    convert_wavs = zeros(length(songDataset),1);
    for cwi = 1:length(songDataset)
        convert_wavs(cwi) = str2double(strtok(songDataset.filename(cwi),'.'));
    end
    
    getWavindices = unique(convert_wavs);
    
    SongSeqStats = struct;
    
    for syl = 1:length(getWavindices)
        tempIndex = convert_wavs == getWavindices(syl);
        
        % Sequence Linearity = # different syllables/song / # transition types
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
        
        SongSeqStats.SeqLinearity(syl,1) = songSylls/songTrans;
        
        
    end
        
    
    
    
end



plot(PreMetaSet.syldur,PreMetaSet.(FeatureUsed),'.')
hold on
plot(songDataset.syldur,songDataset.(FeatureUsed),'r.')





syll_id = cell(length(PreMetaSet),1);
for sii = 1:length(PreMetaSet)
    songRow = false(1,maxNumSylls);
    for sir = 1:maxNumSylls
        songRow(sir) = syllable_indices{sir}(sii);
    end
    
    if sum(songRow) == 0
        syll_id{sii} = 'n';
    else
        syll_id{sii} = syllOrder{songRow};
    end
end

syllidds = dataset(syll_id);










PreMetaSet = horzcat(PreMetaSet,syllidds);





























end

