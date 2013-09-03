function founddir = finddir(dirlist)
% founddir = finddir(dirlist)
% dirlist is a cell array of directory names
% returns the first of these that are found

if ischar(dirlist)
    dirlist = {dirlist};
end
founddir = '';
for i=1:length(dirlist)
    if exist(dirlist{i},'dir')
        founddir = dirlist{i};
        return
    end
end
