function [labelind] = findlabelind(labelstr,labels,varargin)
% [labelind] = findlabelind(labelstr,labels)
% return labelind of label described by labelstr
% labels is assumed to have field labelkey, label2key, label3key

fndlblind.warn = 1;
fndlblind = parse_pv_pairs(fndlblind,varargin);

if ischar(labelstr)
    labelstr = {labelstr};
    if ~iscell(labelstr)
        disp('ERROR. First argument in findlabelind is neither string nor cell array'); return;
    end
end
labelind = zeros(size(labelstr));
for i=1:length(labelind)
    [tmplabel tmplabel2 tmplabel3] = parselabelstr(labelstr{i});
    tmp = find((lower(tmplabel) == lower(labels.labelkey)) & ...
            tmplabel2 == labels.label2key & strcmp(tmplabel3,labels.label3key));
    if isempty(tmp)
        if fndlblind.warn
            disp(['Can''t find label ' labelstr{i} '. Setting labelind to zero']); 
        end
    else
        labelind(i) = tmp;
    end
end
