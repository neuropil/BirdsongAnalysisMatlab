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

