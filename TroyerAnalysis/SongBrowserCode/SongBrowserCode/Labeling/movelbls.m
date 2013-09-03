function [labels labellist] = movelbls(clipinds, cat, varargin)
% labels = movelbls(CLIPINDS, cat, varargin)
% renames labels for CLIPINDS to category CAT
% returns new labels structure with remade label key
% parmater/value pairs can be used to specify lblpath and lbllblfile
% Also, 'numbering', 0 will turn off numbering of each item
% 'save',0 to turn off (prompted) save of new labels structure

lblmv.lblfile = '';
lblmv.lblpath = '.';
lblmv.numbering = 1;
lblmv.save = 1;
lblmv.savelblfile = '';
lblmv.savelblpath = '';
lblmv = parse_pv_pairs(lblmv,varargin);


% get file 
if exist(fullfile(lblmv.lblpath,lblmv.lblfile))~=2
    [lblmv.lblfile lblmv.lblpath] = uigetfile({'*.lbl;*.mlbl','Label files (*.lbl,*.mlbl)';'*.*','All files (*.*)'},'Choose label file');
    if lblmv.lblfile==0 return; end
end
load(fullfile(lblmv.lblpath,lblmv.lblfile),'-mat');

if ischar(cat)
    catstr = cat;
    cat = findlabelind(cat,labels);
    if cat==0
        disp(['Couldn''t find label index for category ' catstr]);
        return
    end
elseif numel(cat) ~= 1
    disp('''cat'' arguments must have one index'); 
end

% rewrite labels
oldlabelinds = [labels.a.labelind];
for j=1:length(clipinds)
    labels.a(clipinds(j)).labelind = cat;
    labels.a(clipinds(j)).label = labels.labelkey(cat);
    labels.a(clipinds(j)).label2 = labels.label2key(cat);
    labels.a(clipinds(j)).label3 = labels.label3key(cat);
    oldlabelinds(clipinds(j)) = cat;
end

% make list
labellist = cell(length(labels.labelkey),1);
for i=1:length(labels.labelkey)
    if lblmv.numbering
        labellist{i} = [num2str(i) '. '];
    end
    %labellist{i} = [labellist{i} labelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i})]; 
    %matt chgd 3/14
    labellist{i} = [labellist{i} makelabelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i})];
end

% save file
if lblmv.save
    fileexists = 0;
    if exist(fullfile(lblmv.savelblpath,lblmv.savelblfile))==2
       fileexists = 1;
    else
        [lblmv.savelblfile lblmv.savelblpath] = uiputfile( ...
                 {'*.lbl', 'Label File (*.lbl)'; '*.*', 'All Files (*.*)'}, 'Save labels in');
        if lblmv.savelblfile==0 return; end
    end
    if fileexists
        save(fullfile(lblmv.savelblpath,lblmv.savelblfile),'labels','-mat','-append');
    else
        save(fullfile(lblmv.savelblpath,lblmv.savelblfile),'labels','-mat');
    end
end
