function [songPstats,expSngPlot] = songCountsPerDay()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Change directory to data set folder
mainFold = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\';
cd(mainFold);

% Get list of bird folders
dirFolds = dir;

birdsTab = struct2table(dirFolds);
birds = birdsTab.name(3:end);

sngFracProd = struct;
sngFracProd.leftlesion = struct;
sngFracProd.rightlesion = struct;
sngFracProd.leftinfuse = struct;
sngFracProd.rightinfuse = struct;
sngFracProd.lmanAb = struct;
for bi = 1:length(birds)
   
    tempBirdLoc = strcat(mainFold,birds{bi});
    
    cd(tempBirdLoc);
    
    daydir = dir('*.mat');
    dayTable = struct2table(daydir);
    dayList = dayTable.name;
    
    lmCount = 1;
    preCount = 1;
    hvcalCount = 1;
    hvcarCount = 1;
    hvcilCount = 1;
    hvcirCount = 1;
    
    for di = 1:length(dayList)
       
        tempDay = dayList{di};
        
        if ~isempty(regexp(tempDay,'HVC ?Left ?Lesion','match'))
            
            load(tempDay)
            sngFracProd.leftlesion.(strcat('b',birds{bi})).songCount(hvcalCount) = max(songDataset.WavNumber);
            sngFracProd.leftlesion.(strcat('b',birds{bi})).songDate{hvcalCount} = tempDay;
            hvcalCount = hvcalCount + 1;
            
        elseif ~isempty(regexp(tempDay,'HVC ?Right ?Lesion','match'))
            
            load(tempDay)
            sngFracProd.rightlesion.(strcat('b',birds{bi})).songCount(hvcarCount) = max(songDataset.WavNumber);
            sngFracProd.rightlesion.(strcat('b',birds{bi})).songDate{hvcarCount} = tempDay;
            hvcarCount = hvcarCount + 1;
            
        elseif ~isempty(regexp(tempDay,'HVC ?Left ?Infusion','match'))
            
            load(tempDay)
            sngFracProd.leftinfuse.(strcat('b',birds{bi})).songCount(hvcilCount) = max(songDataset.WavNumber);
            sngFracProd.leftinfuse.(strcat('b',birds{bi})).songDate{hvcilCount} = tempDay;
            hvcilCount = hvcilCount + 1;
            
        elseif ~isempty(regexp(tempDay,'HVC ?Right ?Infusion','match'))
            
            load(tempDay)
            sngFracProd.rightinfuse.(strcat('b',birds{bi})).songCount(hvcirCount) = max(songDataset.WavNumber);
            sngFracProd.rightinfuse.(strcat('b',birds{bi})).songDate{hvcirCount} = tempDay;
            hvcirCount = hvcirCount + 1;
            
        elseif ~isempty(regexp(tempDay,'Post ?LMAN','match'))
            
            load(tempDay)
            sngFracProd.lmanAb.(strcat('b',birds{bi})).songCount(lmCount) = max(songDataset.WavNumber);
            sngFracProd.lmanAb.(strcat('b',birds{bi})).songDate{lmCount} = tempDay;
            lmCount = lmCount + 1;
            
        elseif ~isempty(regexp(tempDay,'Pre_','match'))
            
            load(tempDay)
            sngFracProd.preSongs.(strcat('b',birds{bi})).songCount(preCount) = max(songDataset.WavNumber);
            sngFracProd.preSongs.(strcat('b',birds{bi})).songDate{preCount} = tempDay;
            preCount = preCount + 1;
            
        elseif ~isempty(regexp(tempDay,'PreALL','match'))
            
             load(tempDay)
             preDays = unique(PreMetaSet.name);
             pdBase = zeros(length(preDays),1);
             for pdi = 1:length(preDays)
                 tempPdind = ismember(PreMetaSet.name,preDays{pdi});
                 pdBase(pdi) = max(PreMetaSet.WavNumber(tempPdind));
             end
             sngFracProd.baseline.(strcat('b',birds{bi})) = mean(pdBase);
 
        end
    end
    
    expTypes = {'preSongs','lmanAb','leftlesion','rightlesion','leftinfuse','rightinfuse'};
    % Sort by day
    for ddi = 1:6
        
        bnames = fieldnames(sngFracProd.(expTypes{ddi}));
        if isempty(bnames) || ~ismember(strcat('b',birds{bi}),bnames)
            continue
        else
           
            expDays = sngFracProd.(expTypes{ddi}).(strcat('b',birds{bi})).songDate;
            daydates = zeros(length(expDays),2);
            for dday = 1:length(expDays)   
                dayParts = strsplit(expDays{dday},{'_','.'});
                daydates(dday,1) = str2double(dayParts{3}(1:2));
                daydates(dday,2) = str2double(dayParts{3}(3:4));
            end
            
            if sum(diff(daydates(:,1))) == 0;
                [~ , newOrder] = sort(daydates(:,2));
                sngFracProd.(expTypes{ddi}).(strcat('b',birds{bi})).songDate = expDays(newOrder);
            elseif max(diff(daydates(:,1))) > 4
                indexHigh = daydates(:,1) > 8;
                [~,hsortI] = sort(daydates(indexHigh,2));
                newHigh = find(indexHigh);
                newOrder = [newHigh(hsortI)' , find(~indexHigh)'];
                sngFracProd.(expTypes{ddi}).(strcat('b',birds{bi})).songDate = expDays(newOrder);
            end

        end
        
        % Get percent difference from baseline
        sngFracProd.(expTypes{ddi}).(strcat('b',birds{bi})).perPre =...
            sngFracProd.(expTypes{ddi}).(strcat('b',birds{bi})).songCount/...
            sngFracProd.baseline.(strcat('b',birds{bi})); 
    end
end

% SUMMARIZE OVER ALL BIRDS

% PRE 1-5
% POSTLMAN 1-5
% POST L IHVC 1-2
% POST R IHVC 1-2
% POST L UHVC 1-5,10
% POST R UHVC 1-5,10
seqExps = {'preSongs','lmanAb','leftinfuse','rightinfuse','leftlesion','rightlesion'};
bFnames = fieldnames(sngFracProd.preSongs);

expSngPlot = struct;
expSngPlot.Pre = zeros(length(bFnames),5);
expSngPlot.LMAN = zeros(length(bFnames),5);
expSngPlot.HVCIL = zeros(length(bFnames),2);
expSngPlot.HVCIR = zeros(length(bFnames),2);
expSngPlot.HVCAL = zeros(length(bFnames),6);
expSngPlot.HVCAR = zeros(length(bFnames),6);
for expI = 1:length(seqExps)
    
    for bfi = 1:length(bFnames)
        
        switch seqExps{expI}
            case 'preSongs'
                expSngPlot.Pre(bfi,:) = sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre;
            case 'lmanAb'
                if ~ismember(bFnames{bfi},fieldnames(sngFracProd.(seqExps{expI})))
                    expSngPlot.LMAN(bfi,:) = nan;
                else
                    expSngPlot.LMAN(bfi,:) = sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre;
                end
            case 'leftinfuse'
                if ~ismember(bFnames{bfi},fieldnames(sngFracProd.(seqExps{expI})))
                    expSngPlot.HVCIL(bfi,:) = nan;
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) < 2
                    expSngPlot.HVCIL(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre , nan];
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) > 2
                    endVal = numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre);
                    expSngPlot.HVCIL(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(endVal)];
                else
                    expSngPlot.HVCIL(bfi,:) = sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:2);
                end 
            case 'rightinfuse'
                if ~ismember(bFnames{bfi},fieldnames(sngFracProd.(seqExps{expI})))
                    expSngPlot.HVCIR(bfi,:) = nan;
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) < 2
                    expSngPlot.HVCIR(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre , nan];
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) > 2
                    endVal = numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre);
                    expSngPlot.HVCIR(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(endVal)];
                else
                    expSngPlot.HVCIR(bfi,:) = sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:2);
                end
            case 'leftlesion'
                if ~ismember(bFnames{bfi},fieldnames(sngFracProd.(seqExps{expI})))
                    expSngPlot.HVCAL(bfi,:) = nan;
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) >= 14
                    expSngPlot.HVCAL(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:5) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(14)];
                else
                    endVal = numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre);
                    expSngPlot.HVCAL(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:5) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(endVal)];
                end
            case 'rightlesion'
                if ~ismember(bFnames{bfi},fieldnames(sngFracProd.(seqExps{expI})))
                    expSngPlot.HVCAR(bfi,:) = nan;
                elseif numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre) >= 14
                    expSngPlot.HVCAR(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:5) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(14)];
                else
                    endVal = numel(sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre);
                    expSngPlot.HVCAR(bfi,:) = [sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(1:5) , sngFracProd.(seqExps{expI}).(bFnames{bfi}).perPre(endVal)];
                end
                
        end
    end
end

expFlds = fieldnames(expSngPlot);
songPstats = struct;
for exfI = 1:length(expFlds)
    tempMat = expSngPlot.(expFlds{exfI});
    
    if size(tempMat,2) > 3
        
        nonnanInd = ~isnan(tempMat);
        submatrix = reshape(tempMat(nonnanInd == 1), max(sum(nonnanInd,1)), max(sum(nonnanInd,2)));
        
        [songPstats.(expFlds{exfI}).mean, songPstats.(expFlds{exfI}).std, CIs,~] = normfit(submatrix);
        songPstats.(expFlds{exfI}).sem = songPstats.(expFlds{exfI}).std/sqrt(size(submatrix,1));
        
        songPstats.(expFlds{exfI}).uCV = CIs(2,:);
        songPstats.(expFlds{exfI}).dCV = CIs(1,:);
        songPstats.(expFlds{exfI}).median = median(submatrix);
        
    else
        
        for coli = 1:size(tempMat,2)
            
            sumVector = tempMat(~isnan(tempMat(:,coli)),coli);
            
            [songPstats.(expFlds{exfI}).mean(:,coli), songPstats.(expFlds{exfI}).std(:,coli), CIs,~] = normfit(sumVector);
            songPstats.(expFlds{exfI}).sem(:,coli) = songPstats.(expFlds{exfI}).std(:,coli)/sqrt(size(sumVector,1));
            
            songPstats.(expFlds{exfI}).uCV(:,coli) = CIs(2,:);
            songPstats.(expFlds{exfI}).dCV(:,coli) = CIs(1,:);
            songPstats.(expFlds{exfI}).median(:,coli) = median(sumVector);
            
        end
    end
    
    switch expFlds{exfI}
        case 'Pre'
            songPstats.Pre.dayNums = 1:5;
        case 'LMAN'
            songPstats.LMAN.dayNum = 1:5;
        case 'HVCIL'
            songPstats.HVCIL.dayNum = 1:2;
        case 'HVCIR'
            songPstats.HVCIL.dayNum = 1:2;
        case 'HVCAL'
            songPstats.HVCIL.dayNum = [1:5,12];
        case 'HVCAR'
            songPstats.HVCIL.dayNum =[ 1:5,12];
    end
end




end % END of MAIN FUNCTION

