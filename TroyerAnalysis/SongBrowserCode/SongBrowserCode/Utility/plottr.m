function h = plottr(x,y,alpha,varargin)
% h = plottr(x,y,alpha,varargin)
% plot semi transparent lines using patch object
% varargin can be used to set color

x = x(:);
y = y(:);
h = patch([x(1:end-1); flipud(x)],[y(1:end-1); flipud(y)],'k','edgealpha',alpha,'facecolor','none');
if ~isempty(varargin)
    set(h,'edgecolor',varargin{1});
end