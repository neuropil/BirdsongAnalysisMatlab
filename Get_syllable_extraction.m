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

paramLoc = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\ParamSpace';

cd(paramLoc)

paramFile = strcat(birdNum,'_SyllParamSpace.mat');

if exist(paramFile,'file')
    skipFlag = 0;
    load(paramFile);
    maxNumSylls = TotalSylls;
else
    skipFlag = 1;
end

% TO DO 9/1/2013 %%%%%%%%%%%%%%%$$$$$$$$$$$********************************
% Consider resaving with new x and ylim cut offs or save out cutoffs
%

cd(DS_DATA_LOC);

dsSongN = strcat(birdNum,'_PreAll.mat');

load(dsSongN);

% meanX = mean(PreMetaSet.syldur);
% stdX3 = std(PreMetaSet.syldur)*2.5;
%
% meanY = mean(PreMetaSet.(FeaUse));
% stdY3 = std(PreMetaSet.(FeaUse))*2.5;

% Xmax = meanX + stdX3;
% Ymax = meanY + stdY3;

%%%%%% PARAMETERS SKIP

if skipFlag % FIRST SKIP FLAG
    
    Xmin = quantile(PreMetaSet.syldur,0.001);
    Ymin = quantile(PreMetaSet.(FeaUse),0.001);
    Xmax = quantile(PreMetaSet.syldur,0.999);
    Ymax = quantile(PreMetaSet.(FeaUse),0.999);
    
    plot(PreMetaSet.syldur,PreMetaSet.(FeaUse),'.');
    xlim([Xmin Xmax]);
    ylim([Ymin Ymax]);
    
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
        
        pause
        
        for moti = 1:4
            load(strcat(birdNum,'_Motif',num2str(moti),'.mat'))
            fName = strcat('Motif_',num2str(moti));
            motifData = eval(fName);
            Motifs.(strcat('motif',num2str(moti))) = motifData.feature;
        end
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
        [0 0.498 0], [0 0.8 0.4], [0.2 0.2 0.75], [1 0.75 0.75], [0.25 0.5 0.75], [1 1 1]};
    
    for mmii = 1:4
        plot(Motifs.(strcat('motif',num2str(mmii))).syldur,...
            Motifs.(strcat('motif',num2str(mmii))).(FeaUse),...
            '.','Markersize',35,'Color',colorsME{mmii});
        for ssii = 1:length(Motifs.(strcat('motif',num2str(mmii))).syldur)
            text(Motifs.(strcat('motif',num2str(mmii))).syldur(ssii),...
                Motifs.(strcat('motif',num2str(mmii))).(FeaUse)(ssii), num2str(ssii),'Color','k')
        end
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
    NewmaxNumSylls = str2double(getNumSylls);
    oldmaxNumSylls = unique(numSylls);
    
    if maxNumSylls < unique(numSylls)
        revSyllCheck = 1;
        syCoch = menu('How many syll pairs to combine', '1', 'More than 1');
        
        switch syCoch
            case 1
                options.Resize = 'on';
                options.WindowStyle = 'normal';
                prompt = {'First Syllable' , 'Second Syllable'};
                dlg_title = 'Input';
                num_lines = 1;
                def = {'1','5'};
                sylls2cCh = inputdlg(prompt,dlg_title,num_lines,def,options);
                sylls2combine = {str2double(sylls2cCh)};
                
            case 2
                
                options.Resize = 'on';
                options.WindowStyle = 'normal';
                prompt = {'Number of combined pairs'};
                dlg_title = 'Input';
                num_lines = 1;
                def = {'2'};
                sylls2cCh = inputdlg(prompt,dlg_title,num_lines,def,options);
                numSylls2combine = str2double(sylls2cCh);
                
                sylls2combine = cell(1,numSylls2combine);
                for spi = 1:numSylls2combine
                    options.Resize = 'on';
                    options.WindowStyle = 'normal';
                    prompt = {'First Syllable' , 'Second Syllable'};
                    dlg_title = 'Input';
                    num_lines = 1;
                    def = {'1','5'};
                    sylls2cCh = inputdlg(prompt,dlg_title,num_lines,def,options);
                    sylls2combine{1,spi} = str2double(sylls2cCh);
                end
        end
        
    elseif maxNumSylls > unique(numSylls)
        
        revSyllCheck = 0;
    else
        revSyllCheck = 0;
    end
    
    
    
    %%%% FIGURE OUT WHAT TO DO WITH MISMATCH 1/19/2014
    if revSyllCheck
        
        sylDB = cell(1,maxNumSylls);
        for mosSyl = 1:4
            tempSyldb = Motifs.(iterNames{mosSyl});
            for syl = 1:numSylls(mosSyl)
                sylDB{1,syl}(mosSyl,:) = tempSyldb(syl,:);
            end
        end
        
        for syCr = 1:length(sylls2combine)
            sylDB{1,sylls2combine{syCr}(1)} = [sylDB{1,sylls2combine{syCr}(1)} ; sylDB{1,sylls2combine{syCr}(2)}];
            
            
        end
        
    else
        % maxNumSylls = max(numSylls); % Includes intro notes
        
        % Create a database wherein n x m (rows represent motif number and columns
        % represent syllable types [N motifs X A B C D syllables]
        sylDB = cell(1,oldmaxNumSylls);
        for mosSyl = 1:4
            tempSyldb = Motifs.(iterNames{mosSyl});
            for syl = 1:numSylls(mosSyl)
                sylDB{1,syl}(mosSyl,:) = tempSyldb(syl,:);
            end
        end
    end
    
    
    % Check for empty rows
    for motiC = 1:oldmaxNumSylls
        if isempty(sylDB{1,motiC}.name{1})
            sylDB{1,motiC}(1,:) = [];
        end
    end
    
    %%
    
    % Turn into while predicated on uicontrol button on figure
    % Add colors to clusters as created
    % Terminate when uicontrol button clicked
    % plot from line 27 ABOVE
    
    for mpi = 1:oldmaxNumSylls
        hold on
        plot(sylDB{1,mpi}.syldur, sylDB{1,mpi}.(FeaUse), 'r.', 'MarkerSize', 40)
        text(sylDB{1,mpi}.syldur, sylDB{1,mpi}.(FeaUse),num2str(mpi),'Color','k')
    end
    
    
    nodes = cell(1,NewmaxNumSylls);
    xcords = cell(1,NewmaxNumSylls);
    ycords = cell(1,NewmaxNumSylls);
    colorS = 'rgkycmbw';
    IN = cell(1,NewmaxNumSylls);
    for i = 1:NewmaxNumSylls
        
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
    
end

%% 7/13/2013

% Create a loop that determines where the motif clusters fall with the
% drawn clusters Align motif cluster numbers with letters

syllOrder = cell(1,maxNumSylls);
sylltest = cell(maxNumSylls,maxNumSylls);
for so = 1:maxNumSylls
    for clusTest = 1:maxNumSylls
        sylltest{so,clusTest} = sum(inpolygon(sylDB{1,clusTest}.syldur,...
            sylDB{1,clusTest}.(FeaUse),xcords{so},ycords{so}));
    end
end


%% 1/3/2015

manSylNum = zeros(1,maxNumSylls);

for sylCheck = 1:maxNumSylls
    
    syllAllIndex = find(IN{sylCheck});
    wavSampInd = syllAllIndex(1);
    wavName = PreMetaSet.filename{wavSampInd};
    dateName = PreMetaSet.name{wavSampInd};
    tStart = PreMetaSet.sylstart(wavSampInd) - 50;
    tEnd = PreMetaSet.syldur(wavSampInd) + tStart + 50;
    fileLoc = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\RawSongs\',birdNum,'\Pre\',dateName);
    
    cd(fileLoc);
    
    [amp1, fs1] = audioread(wavName);
    [~,F1,T1,P1] = spectrogram(amp1, 256,[],[],fs1, 'yaxis');
    
    time1 = T1*1000;
    
    PdB1   = 10*log10(P1);
    
    close all
    
    imagesc(time1,F1,PdB1);
    set(gca,'YDir','Normal','XTick', []);
    
    % plot where line syllable is located
    
    hold on
    line([tStart tStart],[F1(1) F1(length(F1))],'Color','k')
    line([tEnd tEnd],[F1(1) F1(length(F1))],'Color','k')
    
    % click to crop image
    
    [xp,~] = ginput(2);
    
    tIndex = time1 > xp(1) & time1 < xp(2);
    
    close all
    
    % plot cropped image with syllable lines
    
    imagesc(time1(tIndex),F1,PdB1(:,tIndex));
    set(gca,'YDir','Normal','XTick', []);
    
    hold on
    
    line([tStart tStart],[F1(1) F1(length(F1))],'Color','k')
    line([tEnd tEnd],[F1(1) F1(length(F1))],'Color','k')
    
    options.Resize = 'on';
    options.WindowStyle = 'normal';
    promtSt = sprintf('Which syllable am I: %d of %d',sylCheck,maxNumSylls);
    prompt = promtSt;
    titleSt = sprintf('Syls Used: %s', num2str(manSylNum));
    dlg_title = titleSt;
    num_lines = 1;
    def = {'1'};
    getNumSylls = inputdlg(prompt,dlg_title,num_lines,def,options);
    
    manSylNum(sylCheck) = str2double(getNumSylls);
    
    close all

end


prompt = 'Is there an intro note?';
introCheck = questdlg(prompt,dlg_title,'Yes','No','Yes');

switch introCheck
    case 'Yes'
        possibleNotes = 'iABCDEFGHIJKL';
    case 'No'
        possibleNotes = 'ABCDEFGHIJKL';
end

% 1/3/2015
%%% FIGURE OUT ORDER OF SYLLABLES

%% FIGURE OUT TO GET HERE WITHOUT ABOVE

for sol2 = 1:maxNumSylls
    
    syllOrder{sol2} = possibleNotes(manSylNum(sol2));
    
end

%% Create Cell array with indices for each syllable

syllable_indices = cell(1,maxNumSylls);

for i = 1:maxNumSylls
    
    syllable_indices{1,i} = inpolygon(PreMetaSet.syldur,PreMetaSet.(FeaUse), nodes{1,i}(:,1),nodes{1,i}(:,2));
    
end



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

% FIX how syllidds is inserted check dependancies
% FIX how wave number is inserted

PreMetaSet = horzcat(PreMetaSet,syllidds);
wavNums = StripWav(PreMetaSet.filename);
PreMetaSet = [PreMetaSet , wavNums];


%% Outputs

% Individual syllable parameter space
% Sequence of syllable IDs for order of clusters
% Parameter space for all syllables

% If logic gate hit use -append rather than save
% save new SyllIDS

Syll_Params = struct;
Syll_Params.SyllPolyIndices = syllable_indices;
Syll_Params.SyllPolygons.xCords = xcords;
Syll_Params.SyllPolygons.yCords = ycords;
Syll_Params.SyllIDS = syllOrder;
Syll_Params.FeatureUsed = FeaUse;
Syll_Params.TotalSylls = maxNumSylls;
Syll_Params.SyllMapping = sylDB;

param_file_name = strcat(birdNum,'_SyllParamSpace.mat');

Param_Data_Loc = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\ParamSpace');

if ~exist(Param_Data_Loc,'dir')
    mkdir(Param_Data_Loc)
end

close all

cd(Param_Data_Loc)

% If logic gate hit use -append rather than save
% save new SyllIDS

save(param_file_name, '-struct', 'Syll_Params')

%%
%-------------------------------------------------------------------------%
% Save Meta Pre File
%-------------------------------------------------------------------------%
fileName = strcat(birdNum,'_PreALL.mat');

cd(DS_DATA_LOC);

save(fileName,'PreMetaSet');


































