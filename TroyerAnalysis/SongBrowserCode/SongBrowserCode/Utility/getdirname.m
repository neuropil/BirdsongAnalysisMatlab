function [name pathname] = getdirname(pathname)
% [name pathaname] = getdirname(path)
% return name of bottom level directory from more complete pathname
% e.g. getdirname('Data/FtSongWav/FtSong3118/3118-20030903Ft' returns
% '3118-20030903Ft'
% second output argument returns pathname without final filessep if it ends
% with a filesep

seps = find((pathname=='/') | (pathname=='\'));
if seps(end) == length(pathname)
    pathname = pathname(1:end-1);
    name = pathname(seps(end-1)+1:end);
else
    name = pathname(seps(end)+1:end);
end