function [figh n bin binn] = histclick(y,varargin)
%  [N BIN BINN] = histclick(Y,M)
% Plot histogram in clickable figure.  Clicking on the histogram will save a 
%  variables clickhistind  and clickhistval to the workspace. Data is stored in order so that
%  the index for smaller values are obtained for clicking on the bottom of
%  each bar.
%  By default, M is 40 bins.  See help historder.

histclick.bintype = 'centers';
histclick.data = y;
histclick.n = [];
histclick.bincenters = [];
histclick.binedges = [];
histclick.binN = [];
histclick.figh = [];
histclick.axh = [];
histclick.barh = [];
histclick = parse_pv_pairs(histclick, varargin(2:end));

% make figure if necessary
if ishandle(histclick.figh)
    figure(histclick.figh);
else
    histclick.figh = figure;
end
set(histclick.figh,'WindowButtonUpFcn',@buttupFcn);

% sort out arguments as in historder
if nargin == 1
    x = 40;
elseif ischar(varargin{1})
    x = 40;
    if strcmpi(varargin{1},'bintype')
        histclick.bintype = varargin{2};
    end
else
    x = varargin{1};
    if nargin>2 && strcmpi(varargin{2},'bintype')
        histclick.bintype = varargin{3};
    end
end

% calculate histogram and get bins and indices
[histclick.n bin histclick.binn x] = historder(histclick.data,x,'bintype',histclick.bintype);
% get both bin edges and centers
if strcmpi(histclick.bintype,'centers')
    histclick.bincenters = x;
    histclick.binedges = [min(y)-eps; (bin(1:end-1)+bin(2:end))/2; max(y)+eps];
else
    histclick.binedges = x;
    histclick.bincenters = (x(1:end-1)+x(2:end))/2;
end

histclick.barh = bar(histclick.binedges,histclick.data);


% --------------------------------------------------------------------
function buttupFcn(hco,eventStruct)
% button up function, general to fig

histclick = get(hco,'userdata');
curpt = get(histclick.axh,'currentpoint');
% if pt to the right or left of histogram, do notthing
if curpt(1,1)<histclick.binedges(1) || curpt(1,1)>histclick.binedges(end)
    return
end
bin = min(find(curpt(1,1)>histclick.binedges));
binind = ceil(curpt(1,1));
% if pt is above or below bar, do nothing
if binind<1 || binind>histclick.n(bin)
    return
end
% locate data pt
tmp = find(histclick.bin==bin);
tmpind = find(histclick.binn(tmp)==binind);
histclickind = tmp(tmpind);
histclickval = histclick.data(histclickind);
% write to workspace


