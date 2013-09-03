function uictrlh = uictrlrow(uictrlh,figh,xgaps,xpos,ypos,varargin)
% position a row of uicontrols

p.verticalalignment = 'middle';
p.horizontalalignment = 'center';
p = parse_pv_pairs(p,varargin);

% check size and reshape xgaps
xgaps = xgaps(1:length(uictrlh)-1);
xgaps = xgaps(:);

% get height and width of fig
set(figh,'units','points');
figptspos = get(figh,'position');
set(figh,'units','normalized');

% get info about uicontrols
pos = zeros(length(uictrlh),4);
for i=1:length(uictrlh)
    pos(i,:) = get(uictrlh(i),'position');
end
widths = pos(:,3);
maxheight = max(pos(:,4));

% calc total size in points
totallen = sum(widths)+sum(xgaps);
ctrllen = sum(widths);
% % if panel is too small, shrink to fit
if totallen>figptspos(3)
    if ctrllen>figptspos(3)
        widths = widths*(figptspos(3)/ctrllen);
        xgaps = zeros(size(xgaps));
    else
        xgaps = xgaps*(figptspos(3)-ctrllen)/sum(xgaps);
    end
%     textmarg = textmarg*(ptspos(3)/totallen);
end
totallen = sum(widths)+sum(xgaps);

% find x positions in pts from left of string of ctrls

% find new positions
newpos = zeros(size(pos));

% horizontal
horpts = xpos*figptspos(3); % horizontal position of anchor in points
xptspos = [0; cumsum(widths(1:end-1))+cumsum(xgaps)]; 
newpos(:,3) = widths;  
switch lower(p.horizontalalignment)
    case {'middle','center'}
        newpos(:,1) = horpts-totallen/2+xptspos;
    case 'left'
        newpos(:,1) = horpts+xptspos;
    case 'right'
        newpos(:,1) = horpts-totallen+xptspos;
    otherwise % if user sets unrecognized argument, use middle
        newpos(:,1) = horpts-totallen/2+xptspos;
end
        
% vertical
vertpts = ypos*figptspos(4); % vertical position of anchor in points
newpos(:,4) = pos(:,4); % retain old heights
switch lower(p.verticalalignment)
    case {'middle','center'}
        newpos(:,2) = vertpts-pos(:,4)/2;
    case 'top'
        newpos(:,2) = vertpts-pos(:,4);
    case 'bottom'
        newpos(:,2) = vertpts;
    otherwise % if user sets unrecognized argument, use middle
        newpos(:,2) = vertpts-pos(:,4)/2;
end
        
% set new positions
for i=1:length(uictrlh)
    set(uictrlh(i),'position',newpos(i,:));
end
