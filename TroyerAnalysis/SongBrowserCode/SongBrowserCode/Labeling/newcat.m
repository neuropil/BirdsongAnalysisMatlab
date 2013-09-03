function [labels temps OK] = newcat(catstr, varargin)
% [labels temps OK] = newcat(catstr, varargin)
% add a new category to templates and labels structures
% catstr takes form a single character, a character followed by a single
% digit, or another arbitrary string (possibly ending with a digit)
% see parselabelstr

ncat.lblfile = '';
ncat.lblpath = '';
ncat.labels = [];
ncat.temps = [];
ncat.save = 1;
ncat.savelblfile = '';
ncat.savelblpath = '';
ncat.warn = 0;
ncat = parse_pv_pairs(ncat,varargin);

OK = 0;
% load labels and temps
tmptemps = ncat.temps;
labels = ncat.labels;
if isempty(labels)
    if exist(fullfile(ncat.lblpath,ncat.lblfile))~=2
        [ncat.lblfile, ncat.lblpath] = uigetfile({'*.lbl','label files';'*.*','All files'},...
            'Pick label file','Choose label file');
        if ncat.lblfile==0 temps = ''; return; end
        load(fullfile(ncat.lblpath,ncat.lblfile),'-mat');
    end
end
if ~isempty(tmptemps) | ~exist('temps')
    temps = tmptemps;
end
  
% check to see if category already exists
unknown = findlabelind(catstr,labels,'warn',0);
if unknown~=0
    if ncat.warn
        disp('Category already exists. Not creating new one.');
    end
    OK = 0;
    return;
end

% add new category to end of the list
if ~isempty(temps)
    temps.tmpl{end+1} = [];
    temps.clipinds{end+1} = [];
    temps.tmplmatches{end+1} = [];
    temps.tmploffsets{end+1} = [];
    temps.speclengths{end+1} = [];
    temps.tmplN(end+1) = 0;
end

[label label2 label3] = parselabelstr(catstr);
labels.labelkey(end+1) = label;
labels.label2key(end+1) = label2;
labels.label3key{end+1} = label3;
% labels.labelstrs{end+1} = makelabelstr(labels.labelkey(end), labels.label2key(end), labels.label3key{end});
OK=1;

if ncat.save
    fileexists = 0;
    if exist(fullfile(ncat.savelblpath,ncat.savelblfile))==2
       fileexists = 1;
    else
        [ncat.savelblfile ncat.savelblpath] = uiputfile( ...
                 {'*.lbl', 'Label File (*.lbl)'; '*.*', 'All Files (*.*)'}, 'Save labels in');
        if ncat.savelblfile==0 return; end
    end
    if fileexists
        save(fullfile(ncat.savelblpath,ncat.savelblfile),'labels','temps''-mat','-append');
    else
        save(fullfile(ncat.savelblpath,ncat.savelblfile),'labels','temps','-mat');
    end
end
    
    