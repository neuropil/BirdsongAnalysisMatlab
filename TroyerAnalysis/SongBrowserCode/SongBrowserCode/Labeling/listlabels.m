function labellist = listlabels(varargin)
% labellist = listlabels(varargin)
% return cell array of strings for each category
% parmater/value pairs:
%  'labels' - specify labels structure
%   pathname/filename - specify file to load labels structure from
%   'numbering', 0 - turn off numbering of each category
%   'count', 1 - turn on reporting the numbers in each category

lbllst.labels = '';
lbllst.filename = '';
lbllst.pathname = '.';
lbllst.numbering = 1;
lbllst.count = 1;
lbllst = parse_pv_pairs(lbllst,varargin);

if isempty(lbllst.labels)
    % get file 
    if ~(exist(fullfile(lbllst.pathname,lbllst.filename))==2)
        [lbllst.filename lbllst.pathname] = uigetfile({'*.lbl;*.mlbl','Label files (*.lbl,*.mlbl)';'*.*','All files (*.*)'},'Choose label file');
        if lbllst.filename==0 return; end
    end
    load(fullfile(lbllst.pathname,lbllst.filename),'-mat');
else
    labels = lbllst.labels;
end

% make list
labellist = cell(length(labels.labelkey),1);
for i=1:length(labels.labelkey)
    if lbllst.numbering
        labellist{i} = [num2str(i) '.'];
    end
    %matt 9/7/2011  chged labelstr.m to makelabelstr.m below;
    labellist{i} = [labellist{i} makelabelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i})];
    if lbllst.count
        labellist{i} = [labellist{i} '(' num2str(sum([labels.a.labelind]==i)) ')'];
    end
end