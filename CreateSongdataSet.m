function [songDataset] = CreateSongdataSet(sap_xlsfile,~,~)


colTitles = {'name','duration','start','amplitude','pitch',...
    'FM','AM^2','entropy','pitch goodness', 'mean freq',...
    'pitch','FM','entropy','pitch goodness',...
    'mean freq','AM','file name'};

searchstr = sap_xlsfile(2,:);

colNum = zeros(length(colTitles),1);
for colcount = 1:length(colTitles)
    colNum(colcount) = find(strcmp(colTitles(colcount),searchstr),1,'first');
end

begin = colNum(1);
last = colNum(end-1);
fnaCol = colNum(end);

if isnan(sap_xlsfile{end,1})
    lastrow = length(sap_xlsfile) - 1;
else
    lastrow = lenght(asp_xlsfile);
end

sapXlsTrans = sap_xlsfile(1:lastrow,begin:last);
sapXlsTrans(1:lastrow,17) = sap_xlsfile(1:lastrow,fnaCol);
sapXlsTrans(1:2,:) = [];

NewcolTitles = {'name','syldur','sylstart','Mamp','Mpitch',...
    'MFM','MAM','Mentropy','MpitchG', 'Mfreq',...
    'Vpitch','VFM','Ventropy','Vpitchg',...
    'Vfreq','VAM','filename'};

sapXlsTitles = vertcat(NewcolTitles , sapXlsTrans);

%%

songDataset = cell2dataset(sapXlsTitles);






