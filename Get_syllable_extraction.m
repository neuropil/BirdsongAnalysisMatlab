function [Syll_Params] = Get_syllable_extraction()

birdNum = Get_Bird_Number;

DS_DATA_LOC = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum);

%% Get Feature to Use

featLoc = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\FeatureInformation';

cd(featLoc)

featFile = strcat(birdNum,'_FeatureMeta.mat');

if exist(featFile,'file')
    load(featFile)
else
    FeaUse = Feature2Use;
end

%% Get Song Dataset

% TO DO 9/1/2013 %%%%%%%%%%%%%%%$$$$$$$$$$$********************************
% Consider resaving with new x and ylim cut offs or save out cutoffs
% 

cd(DS_DATA_LOC);

dsSongN = strcat(birdNum,'_PreAll.mat');

load(dsSongN);

meanX = mean(PreMetaSet.syldur);
stdX3 = std(PreMetaSet.syldur)*2.5;

meanY = mean(PreMetaSet.(FeaUse));
stdY3 = std(PreMetaSet.(FeaUse))*2.5;

Xmax = meanX + stdX3;
Ymax = meanY + stdY3;

plot(PreMetaSet.syldur,PreMetaSet.(FeaUse),'.');
xlim([0 Xmax]);
ylim([0 Ymax]);

%% Obtain motif order

% Generate Motif directory location
motifDataLOC = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\Motif_Data\',birdNum);

% Check and see Motif directory exists; if not create it
if ~exist(motifDataLOC,'dir')
    mkdir(motifDataLOC)
end

% Check and see if Motif analysis has been run
cd(motifDataLOC)
motifCheck = strcat(birdNum,'_Motif1.mat');

% If not, run it 
if ~exist(motifCheck,'file')
    Get_Motif_Data; % Run Analysis
else 
% If analysis has been run then extract 4 example motif data into structure
    for moti = 1:4
        load(strcat(birdNum,'_Motif',num2str(moti),'.mat'))
        fName = strcat('Motif_',num2str(moti));
        motifData = eval(fName);
        Motifs.(strcat('motif',num2str(moti))) = motifData.feature;
    end
end

% Get field names for easier iteration through structure
iterNames = fieldnames(Motifs);

% Determine the maximum number of syllables
numSylls = zeros(4,1);
for modbs = 1:4
    [numSylls(modbs),~] = size(Motifs.(iterNames{modbs}));
end


%% Get number of syllables

% allMotifConcat = cat(1, Motifs.motif1 , Motifs.motif2 , Motifs.motif3 , Motifs.motif4);

hold on

colorsME = {[0 1 0], [1 0.6941 0.3922], [0 0.749 0.749], [1 0 0], [0 0 1],...
    [0 0.498 0], [0 0.8 0.4]};

for mmii = 1:4
    plot(Motifs.(strcat('motif',num2str(mmii))).syldur,...
        Motifs.(strcat('motif',num2str(mmii))).(FeaUse),...
        '.','Markersize',30,'Color',colorsME{mmii});
end


% bring up listdiag with number sylls question
options.Resize = 'on';
options.WindowStyle = 'normal';
prompt = {'Enter Number of Syllables with Intro:'};
dlg_title = 'Input';
num_lines = 1;
def = {'3'};
getNumSylls = inputdlg(prompt,dlg_title,num_lines,def,options);

maxNumSylls = str2double(getNumSylls);


% maxNumSylls = max(numSylls); % Includes intro notes

% Create a database wherein n x m (rows represent motif number and columns
% represent syllable types [N motifs X A B C D syllables]
sylDB = cell(1,maxNumSylls);
for mosSyl = 1:4
    tempSyldb = Motifs.(iterNames{mosSyl});
    for syl = 1:numSylls(mosSyl)
        sylDB{1,syl}(mosSyl,:) = tempSyldb(syl,:);
    end
end

% Check for empty rows
for motiC = 1:maxNumSylls
    if isempty(sylDB{1,motiC}.name{1})
        sylDB{1,motiC}(1,:) = [];
    end
end

%% This is where I am at 6/3/2013

% Turn into while predicated on uicontrol button on figure
% Add colors to clusters as created
% Terminate when uicontrol button clicked
% plot from line 27 ABOVE

for mpi = 1:maxNumSylls
    hold on
    plot(sylDB{1,mpi}.syldur, sylDB{1,mpi}.(FeaUse), 'r.', 'MarkerSize', 40)
    text(sylDB{1,mpi}.syldur, sylDB{1,mpi}.(FeaUse),num2str(mpi),'Color','k')
end

pause(0.1);
nodes = cell(1,maxNumSylls);
xcords = cell(1,maxNumSylls);
ycords = cell(1,maxNumSylls);
colorS = 'rgkycm';
IN = cell(1,maxNumSylls);
for i = 1:maxNumSylls
    
    [xcords{i}, ycords{i}] = getline('closed');
    
    nodes{i} = xcords{i};
    nodes{1,i}(:,2) = ycords{i};
    
    IN{i} = inpolygon(PreMetaSet.syldur,PreMetaSet.(FeaUse),xcords{i},ycords{i});

    hold on
    
    plot(PreMetaSet.syldur(IN{i}),PreMetaSet.(FeaUse)(IN{i}),'.','Color',colorS(i))
end

% Get index for noise values

allxcords = [];
allycords = [];
for i = 1:maxNumSylls
    allxcords = [allxcords ; xcords{i}];
    allycords = [allycords ; ycords{i}];
end

noise = ~inpolygon(PreMetaSet.syldur,PreMetaSet.(FeaUse),allxcords,allycords);


%% 7/13/2013

% Create a loop that determines where the motif clusters fall with the
% drawn clusters Align motif cluster numbers with letters 

syllOrder = cell(1,maxNumSylls);
sylltest = cell(maxNumSylls,maxNumSylls);
for so = 1:maxNumSylls
    for clusTest = 1:maxNumSylls
        sylltest{so,clusTest} = sum(inpolygon(sylDB{1,clusTest}.syldur,...
            sylDB{1,clusTest}.(FeaUse),...
            xcords{so},...
            ycords{so}));
    end
end

% Turn cell array in matrix
syllOmat = cell2mat(sylltest);

possibleNotes = 'iABCDEFGHIJKL';

for sol = 1:maxNumSylls
    [~,indexS] = max(syllOmat(:,sol));
    
    syllOrder{sol} = possibleNotes(indexS);
    
end


%% Create Cell array with indices for each syllable

syllable_indices = cell(1,maxNumSylls);

for i = 1:maxNumSylls
    
    syllable_indices{1,i} = inpolygon(PreMetaSet.syldur,PreMetaSet.(FeaUse), nodes{1,i}(:,1),nodes{1,i}(:,2));
    
end

% VERY COOL way to PLOT NOTE ID on each pass

% syllID = cell(1,maxNumSylls);
% 
% for i2 = 1:maxNumSylls
% 
% plot(PreMetaSet.syldur(syllable_indices{i2}),PreMetaSet.(FeaUse)(syllable_indices{i2}),...
%     'r+',PreMetaSet.syldur(~syllable_indices{i2}),PreMetaSet.(FeaUse)(~syllable_indices{i2}),'bo');
% xlim([0 Xmax]);
% ylim([0 Ymax]);
% 
% syllID{i2} = input('Which syllable does this cluster represent?: ','s');
% 
% end


%% ADD Syllable ID List to PreMeta Song Dataset

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


%% Outputs

% Individual syllable parameter space
% Sequence of syllable IDs for order of clusters
% Parameter space for all syllables
Syll_Params = struct;
Syll_Params.SyllPolyIndices = syllable_indices;
Syll_Params.SyllPolygons.xCords = xcords;
Syll_Params.SyllPolygons.yCords = ycords;
Syll_Params.SyllIDS = syllOrder;
Syll_Params.FeatureUsed = FeaUse;
Syll_Params.TotalSylls = maxNumSylls;

param_file_name = strcat(birdNum,'_SyllParamSpace.mat');

Param_Data_Loc = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\ParamSpace');

if ~exist(Param_Data_Loc,'dir')
    mkdir(Param_Data_Loc)
end

close all

cd(Param_Data_Loc)

save(param_file_name, '-struct', 'Syll_Params')

%%
%-------------------------------------------------------------------------%
% Save Meta Pre File
%-------------------------------------------------------------------------%
fileName = strcat(birdNum,'_PreALL.mat');

cd(DS_DATA_LOC);        

save(fileName,'PreMetaSet');
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        











