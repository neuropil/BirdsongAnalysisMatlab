function [str] = makelabelstr(label,label2,label3)
% [str] = makelabelstr(label,label2,label3)
% return label string based on info in label variables
% if label variables have length > 1 then str is a cell array of strings

str = cell(length(label),1);
if ~iscell(label3)
    label3 = {label3};
end
for i=1:length(str)
    str{i} = '';
    if label(i) ~= ' '
        if label(i)=='+' | label(i)=='='
            str{i} = label3{i};
        else
            str{i} = maplabelchar(label(i));
        end
        if label2 ~= 1
            str{i} = [str{i} num2str(label2(i))];
        end
    end
end

if length(str)==1
    str = str{1};
end
