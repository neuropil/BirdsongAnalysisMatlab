function axind = getaxis(axh,curpt)
% get axis number 
pos = zeros(length(axh),4);
for i=1:length(axh)
    pos(i,:) = get(axh(i),'position');
end
axind = find(curpt(1) >= pos(:,1) & curpt(1) <= pos(:,1)+pos(:,3));
axind = intersect(axind,find(curpt(2) >= pos(:,2) & curpt(2) <= pos(:,2)+pos(:,4)));




