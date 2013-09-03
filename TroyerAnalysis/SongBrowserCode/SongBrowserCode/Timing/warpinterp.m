function vals = warpinterp(X,warp,varargin)
% vals = warpinterp(X,warp,varargin)
% use interpolation to get values of X at time points determined by warp
% like a spectrogram, time is read out along the columns
% each row of X is assumed to be a separate value for warping 
%  (different frequency bin for spectrogram)
% warp is in units of  bins
% parameter/value pair 'pad', Y, sets the output to Y 
%    when warp=0 or warp>size(X,2)
% if pad is not specified, values are set to first/last column of X

warpint.pad = [];
warpint = parse_pv_pairs(warpint,varargin);

% if X is vector make it a row vector
if min(size(X))==1
    X = X(:)';
end
lenX = size(X,2);

% set padding
if ~isempty(warpint.pad)
    X = [warpint.pad X warpint.pad];
else
    X = [X(:,1) X X(:,end)];
end

% bound warp between 0 and lenX+1 then add 1 to align with padded X
warp = min(max(warp,0),lenX+1)+1;

warppos = ceil(warp);
warpneg = floor(warp);
warpfrac = ones(size(X,1),1)*(warp-warpneg);
warpfraccomp = 1-warpfrac; % 'complement' to warpfrac
% interpolate
vals = warpfrac.*X(:,warppos)+(1-warpfrac).*X(:,warpneg);
    
    