function pathname = striproot(pathname,varargin)
% pathname = striproot(pathname,varargin)
% strips the root directory from the beginning of the pathname
% The following are optional parameter value pairs with their defaults:
% rootdir = {'/Volumes/troyerlab','Z:','/Users/toddtroyer/Documents/Lab'};
%   list of root directories that will be stripped
% if no matches are found, pathname is returned
% fixseps = 1; changes the fileseparation characters to the
% current system
% nolastsep=1; if pathname ends in a filesep character, this
% is removed

% strip.rootdir = {'/Volumes/Groups','/Volumes/troyerlab','Z:','Y:','/Users/toddtroyer2/Documents/LAB'};
strip.rootdir = rootdirlist;
strip.fixseps = 1;
strip.nolastsep = 1;
strip = parse_pv_pairs(strip,varargin);

if strip.fixseps
    pathname = fixseps(pathname);
end
rootfound = 0;
for i=1:length(strip.rootdir)
    if strncmpi(fixseps(pathname),fixseps(strip.rootdir{i}),length(strip.rootdir{i}));
        pathname = pathname(length(strip.rootdir{i})+2:end);
        rootfound = 1;
        break
    end
end
if pathname(1)~= filesep
    pathname = [filesep pathname];
end
if strip.nolastsep
    if (pathname(end)=='\') | (pathname(end) == '/')
        pathname(end) = [];
    end
end

