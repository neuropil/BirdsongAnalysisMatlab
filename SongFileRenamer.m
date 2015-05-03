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
getLastDay = @(x) str2double(x{length(x)}(1:5));

% Fix finding wrong filenames
% 1st Check
dayIndex = cell2mat(cellfun(@(x) length(get1stDay(getDayNames(getDayDir(x)))) ~= 9, dayNames,...
    'UniformOutput',false));

% 2nd Check
dayIndex2 = cellfun(@(x) ~(getLastDay(getDayNames(getDayDir(x))) == length(getDayNames(getDayDir(x)))), dayNames);

days2assess = unique([dayNames(dayIndex) dayNames(dayIndex2)]);

%%

if isempty(days2assess)
    return
else
    for i = 1:length(days2assess)
        
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
            
            if strcmp(newname,fnames{i2})
                continue
            else
                movefile(fnames{i2},newname)
            end
        end
    end
end





