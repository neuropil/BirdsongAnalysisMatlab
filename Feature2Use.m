function [FeaUse] = Feature2Use()

% THINGS TO DO
%-----------------------------------------------------------------------%
% remove rows that exceed duration cutoff
%-----------------------------------------------------------------------%

[birdNum] = Get_Bird_Number;

cd(strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\',birdNum));

load(strcat(birdNum,'_PreALL.mat'));

figure('units','normalized','outerposition',[0 0 1 1])

ylabelS = {'Pitch','Amplitude','FM','Entropy','Amp Mod', 'Pitch Good'};
plotY = {'Mpitch','Mamp','MFM','Mentropy','MAM','MpitchG'};
titleS = {'Mean pitch','Mean Amp','Mean FM','Mean Entropy','Mean AM','Mean Pitch Good'};

syldrMean = mean(PreMetaSet.syldur);
syldrSD = std(PreMetaSet.syldur);
syldurCutoff = syldrMean + syldrSD*3;

for i = 1:6
    subplot(3,2,i);
    
    FeatMean = mean(PreMetaSet.(plotY{i}));
    FeatSD = std(PreMetaSet.(plotY{i}));
    FeatCutoff = FeatMean + FeatSD*3;
    
    cutoff_index = PreMetaSet.syldur < syldurCutoff & PreMetaSet.(plotY{i}) < FeatCutoff;
    
    x = PreMetaSet.syldur(cutoff_index);
    y = PreMetaSet.(plotY{i})(cutoff_index);
    
    X = [x,y];
    hist3(X,[25 25],'FaceAlpha',.65);
    set(gcf,'renderer','opengl');
    set(get(gca,'child'),'FaceColor','interp','CDataMode',...
        'auto');
    
    xlabel('Duration (ms)');
    ylabel(ylabelS{i});
    title(titleS{i});
end
    
features = {'Pitch','Amplitude','FM','Entropy','Amp Modulation','Pitch Goodness'};

pause;

featureSel = listdlg('ListString', features,...
    'SelectionMode', 'single',...
    'ListSize', [95 125],...
    'PromptString', 'Select FEATURE to Sort');

featureOut = plotY{featureSel};


% EntVal = input('What entropy was used for SAP: ');
% AmpVal = input('What amplitude was used for SAP: ');


FeaUse = featureOut;
% Features_DB.SAP_Entropy = EntVal;
% Features_DB.SAP_Amplitude = AmpVal;

save

cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\FeatureInformation');

saVeName = strcat(birdNum,'_FeatureMeta.mat');

save(saVeName,'FeaUse');

close all





