function [N bin binN x] = historder(y,varargin)
% [N BIN BINN] = historder(Y)
%   bins the elements of Y into 40 equally spaced containers.
%   N is the number of elements in each container (like hist). 
%   BIN is an array the same size of Y that gives the index of 
%   the bin that each point of Y belongs to. As part of the binning,
%   Y is sorted.  BINN is the rank order of each element of Y within
%   it's BIN.  So BIN(5)= 3 and BINN(5) = 4 means that Y(5) is the
%   4th largest value in the 3rd bin.
%
%   [N BIN BINN] = historder(Y,M), where M is a scalar, uses M bins.
%
%   [N BIN BINN X] = historder(Y,M) also returns the bin centers in X.
%   
%   [N BIN BINN] = historder(Y,X) where X is a vector uses these values as
%   bin centers
%   [N BIN BINN] = historder(Y,X,'bintype','edges')  treats X as bin edges
%   [N BIN BINN X] = historder(Y,M,'bintype','edges') ) returns  bin edges.

params.bintype = 'centers';
params = parse_pv_pairs(params, varargin(2:end));
if nargin == 1
    x = 40;
elseif ischar(varargin{1})
    x = 40;
    params = parse_pv_pairs(params, varargin(1:end));
else
    x = varargin{1};
    params = parse_pv_pairs(params, varargin(2:end));
end

if min(size(y))==1, y = y(:); end

if isempty(y),
    if length(x) == 1,
       x = 1:double(x);
    end
    nn = zeros(size(x)); % No elements to count
    %  Set miny, maxy for call to bar below.
    miny = [];
    maxy = [];
else
    %  Ignore NaN when computing miny and maxy.
    ind = ~isnan(y);
    miny = min(y(ind));
    maxy = max(y(ind));
    %  miny, maxy are empty only if all entries in y are NaNs.  In this case,
    %  max and min would return NaN, thus we set miny and maxy accordingly.
    if (isempty(miny))
      miny = NaN;
      maxy = NaN;
    end
    if length(x) == 1
    	  if miny == maxy,
    		  miny = miny - floor(x/2) - 0.5; 
    		  maxy = maxy + ceil(x/2) - 0.5;
     	  end
        binwidth = (maxy - miny) ./ x;
        xx = miny + binwidth*(0:x);
        xx(length(xx)) = maxy;
        x = xx(1:length(xx)-1) + binwidth/2;
    else
        xx = x(:)';
        binwidth = [diff(xx) 0];
        xx = [xx(1)-binwidth(1)/2 xx+binwidth/2];
        xx(1) = min(xx(1),miny);
        xx(end) = max(xx(end),maxy);
    end
end
xx(end) = xx(end)+eps;
% find bin indexes by co-sorting data and bin edges
ynum = size(y,1);
xxnum = length(xx);
N = zeros(xxnum-1,size(y,2));
bin = zeros(size(y));
binN = zeros(size(y));

orderinds = 1:ynum+xxnum;
for j= 1:size(y,2)
    [z fwdsort] = sort([y(:,j); xx(:)]);
    [tmp backsort] = sort(fwdsort);
    for i=1:xxnum-1
        % find indices data points between bin edges in sorted data
        tmp = backsort(ynum+i)+1:backsort(ynum+i+1)-1; 
        N(i) = length(tmp);
        if N(i)>0
            bin(fwdsort(tmp)) = i;
            binN(fwdsort(tmp)) = 1:N(i);
        end
    end
    % assign bin and binN for points outside bin range
    tmp = 1:backsort(ynum+1)-1;
    bin(fwdsort(tmp)) = 0;
    binN(fwdsort(tmp)) = 1:length(tmp);
    tmp = backsort(ynum+xxnum)+1:length(z);
    bin(fwdsort(tmp)) = length(x)+1;
    binN(fwdsort(tmp)) = 1:length(tmp);
end

if strcmpi(params.bintype,'edges')
    x = xx;
end


