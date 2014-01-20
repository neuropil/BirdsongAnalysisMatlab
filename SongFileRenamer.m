% Rename files in days in a particular condition (i.e. Post LMAN)

folderDir = dir;
dayNames = {folderDir.name};
dayNames = dayNames(3:end);

currentFolder = pwd;

%%

days2run = cellfun(@(x) ~isempty(strfind(x,'rename')), dayNames);
dayIndex = find(days2run);

for i = 1:sum(days2run)
    
    dayofInt = dayNames{dayIndex(i)};
    
    cd(strcat(pwd,'\',dayofInt))
    
    fdir = dir('*.WAV');
    
    fnames = {fdir.name};
    
    numFiles = numel(fnames);
    
    for i2 = 1:numFiles
        % Get the file name (minus the extension)
%         [~, f] = fileparts(fnames{i2});
        
        getLen = length(i2);
        newname = num2str(i2);
        
        while getLen < 5
            newname = [num2str(0) newname];
            getLen = length(newname);
        end
        
        tempName = strcat(newname,'.WAV');
        
        movefile(fnames{i2},tempName)
    end  
end

