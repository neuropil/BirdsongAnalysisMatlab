function [] = Plot_KL_Pitch()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here



birdNum = Get_Bird_Number;

SumDataLoc = strcat('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\SummaryData\',birdNum);

cd(SumDataLoc);

KL_dataName = strcat(birdNum,'_KL_SummaryData.mat');

load(KL_dataName);

pitchKLvals = KL_allDays.KLvalues(:,strcmp('Mpitch',KL_allDays.Features));



figure

hold on
plot(find(KL_allDays.CondiIndex == 1),pitchKLvals(KL_allDays.CondiIndex == 1), 'ko-');
plot(find(KL_allDays.CondiIndex == 2),pitchKLvals(KL_allDays.CondiIndex == 2), 'bo-');
plot(find(KL_allDays.CondiIndex == 3),pitchKLvals(KL_allDays.CondiIndex == 3), 'go-');
plot(find(KL_allDays.CondiIndex == 4),pitchKLvals(KL_allDays.CondiIndex == 4), 'ro-');

% Text
textLogical = cellfun(@(x) ~isnan(x), KL_allDays.LRindex)';
textXaxis = find(cellfun(@(x) ~isnan(x), KL_allDays.LRindex));
textYaxis = pitchKLvals(textLogical);

text(textXaxis,textYaxis,KL_allDays.LRindex(cellfun(@(x) ~isnan(x), KL_allDays.LRindex)),...
    'VerticalAlignment','bottom');

% this dies on 12th iteration
xlim([0.8 KL_allDays.NumItems.numDays + 0.2]);
title(sprintf('Duration and Mean Pitch'), 'fontsize', 11);
ylabel(sprintf('KL-distance \n from Aggregate Pre Days (bits)'), 'fontsize', 10);

set(gca,'XTick', 1:1:length(KL_allDays.SongDayOrder))
set(gca,'XTickLabel', KL_allDays.SongXaxis);









end

