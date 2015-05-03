function [] = SongCountDaysPlot()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

[songPstats,expSngPlot] = songCountsPerDay;


%%


hold on
exNames = fieldnames(songPstats);
lastLen = 1;
colors = {[0 0 0],[0 0 1],[0.45 1 0.45],[1 0.45 0.45],[0 1 0],[1 0 0]};
for pti = 1:length(fieldnames(songPstats))
    
    numCol = size(expSngPlot.(exNames{pti}),2);
      
%     patX = [lastLen:numCol+lastLen-1 , fliplr(lastLen:numCol+lastLen-1)];
%     patY = [songPstats.(exNames{pti}).dCV , fliplr(songPstats.(exNames{pti}).uCV)];
%     
%     patch(patX,patY,colors{pti},'FaceAlpha',0.5,'EdgeColor','none')
    
    for coli2 = 1:numCol
        
        tempDay = expSngPlot.(exNames{pti})(:,coli2);
        tempDayNn = tempDay(~isnan(tempDay));
        
        scatX = ones(length(tempDayNn),1)*lastLen + coli2 - 1;
        
        scatter(scatX,tempDayNn,30,repmat(colors{pti},length(tempDayNn),1),'filled');
        
    end
    
    plot(lastLen:numCol+lastLen-1,songPstats.(exNames{pti}).mean,'Color',colors{pti},'LineWidth',2)
    
    if pti == 3 || pti == 5
        continue
    else
        lastLen = lastLen + numCol;
    end
end
    
ylim([-0.05 2])
xlim([0 20])

%%% Aesthetics
line([5.5 5.5],[-0.05 2],'Color','k','LineStyle','--')
line([10.5 10.5],[-0.05 2],'Color','k','LineStyle','--')
line([12.5 12.5],[-0.05 2],'Color','k','LineStyle','--')

set(gca,'YTick',[0, 0.5, 1, 1.5, 2])
set(gca,'XTick',1:1:18)
set(gca,'XTickLabel',{'Pre1','Pre2','Pre3','Pre4','Pre5','LMAN1','LMAN2',...
    'LMAN3','LMAN4','LMAN5','HVCI1','HVCI2','HVCL1','HVCL2','HVCL3','HVCL4',...
    'HVCL5','HVCL12'});
set(gca, 'XTickLabelRotation', 45); 

ylabel('Song production as fraction of pre-baseline');

end

