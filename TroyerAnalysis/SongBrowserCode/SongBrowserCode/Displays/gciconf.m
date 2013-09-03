function clipinds = gciconf(confuse,row,col)
% clipinds = gciconf(confuse,row,col)
% get clipinds from specified locations in confusion matrix
% if row and column are strings, return clips in that location
% if row and col are cell arrays of string retrun all clips in those
% locations

if ~isnumeric(row) 
    tmp.labelkey = confuse.rowlabelkey;
    tmp.label2key = confuse.rowlabel2key;
    tmp.label3key = confuse.rowlabel3key;
    rowinds = findlabelind(row,tmp);
end
if ~isnumeric(col) 
    tmp.labelkey = confuse.collabelkey;
    tmp.label2key = confuse.collabel2key;
    tmp.label3key = confuse.collabel3key;
    colinds = findlabelind(col,tmp);
end
clipinds = [];
for i=1:length(rowinds)
    clipinds = [clipinds; confuse.clipinds{rowinds(i),colinds(i)}(:)];
end