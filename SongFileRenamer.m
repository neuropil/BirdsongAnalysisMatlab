function [] = SongFileRenamer()

folder2assess = uigetdir;

cd(folder2assess)

folderDir = dir;
dayNames = {folderDir.name};
dayNames = dayNames(3:end);

% currentFolder = pwd;

%% Delete txt files out of folders

for dayI = 1:length(dayNames)
    tempFold = strcat(folder2assess,'\',dayNames{dayI});
    cd(tempFold)
    
    txtFilesD = dir('*.log');
    txtFiles = {txtFilesD.name};
    
    for ti = 1:length(txtFiles)
       delete(txtFiles{ti}); 
    end
end


%% Figure out which folders need renaming

getDayDir = @(x) dir(strcat(folder2assess,'\',x,'\*.wav'));
getDayNames = @(x) {x.name};
get1stDay = @(x) x{1};

% Fix finding wrong filenames
dayIndex = cell2mat(cellfun(@(x) length(get1stDay(getDayNames(getDayDir(x)))) ~= 9, dayNames,...
    'UniformOutput',false));

days2assess = dayNames(dayIndex);

%%

for i = 1:sum(dayIndex)
    
    dayofInt = days2assess{i};
    
    cd(strcat(folder2assess,'\',dayofInt))
    
    fdir = dir('*.WAV');
    
    fnames = {fdir.name};
    
    numFiles = numel(fnames);
    
    for i2 = 1:numFiles
        
        getLen = length(num2str(i2));
        pad = num2str(zeros(1, 5-getLen));
        pad(pad==' ') = '';
        newname = strcat(pad,num2str(i2),'.wav');
        
        movefile(fnames{i2},newname)
    end  
end






