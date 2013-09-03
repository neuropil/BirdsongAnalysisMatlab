function [dirname] = uigetdirTT(startpath,title)
% [dirname] = uigetdirTT(STARTPATH,TITLE)
% version of uigetdir that uses popup to present TITLE
% on mac systems (using filesep=='/' to assess ismac)

if filesep=='/'
    hh = helpdlg(title,title);
    dirname = uigetdir(startpath,title);
    close(hh)
else
    dirname = uigetdir(startpath,title);
end