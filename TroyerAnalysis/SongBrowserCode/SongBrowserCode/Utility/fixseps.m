function name = fixseps(name)
% name = fixseps(name)
% converts all '\' or '/' in the string name to the filesep for the current
% system

seps = find((name=='\') | (name == '/'));
repseps = find(seps(2:end)-1==seps(1:end-1));
name(seps(repseps))=[];
seps = find((name=='\') | (name == '/'));
name(seps) = filesep;