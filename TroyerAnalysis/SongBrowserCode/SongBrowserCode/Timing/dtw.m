function  [warp,range,M,Dpath,Dcum,move] = dtw(template,exemplar,varargin)
% [warp,range,M,Dpath,Dcum,move] = dtw(template,examplar,varargin)
% calculate DTW map for examplar vs. template
% varargin can be used to set the following parameter/value pairs
% mlim - specifies bounds on dtw in terms of deviation from uniform timing
%   if 0<=mlim<1, mlim specifies fraction of template length
%   otherwise, mlim specifies number of bins 
%   default is mlim = .25
% bounary - specifies extent and cost along edges that terminate path
%    default is boundary = zeros(mlim,1);
% interpolate - flags whether to interpolate exmplar values to match length
%   of template (cubic spline interpolation, default = 1)

%% set defaults
params.metric = @rtmnsqrdev2;
params.mlim = ceil(.25*size(template,2));
params.boundary = [];
params.interpolate = 1;
params.freqinds = 1:size(template,1);
params = parse_pv_pairs(params,varargin);

if params.mlim>0 && params.mlim<1
    params.mlim = ceil(.25*size(template,2));
end
if isempty(params.boundary)
    params.boundary = zeros(params.mlim,1);
end

%% interpolate exemplar
scale = 1;
if params.interpolate
    try
        scale = size(exemplar,2)/size(template,2);
        exemplar = spline(.5:size(exemplar,2),exemplar,(.5:size(template,2))*scale);
    catch
        [size(exemplar,2) size(template,2)]
    end
        
end
    
%% calculate distance matrix
M = zeros(size(exemplar,2),size(template,2));
diffsize = size(exemplar,2)-size(template,2);
mlimpos = max(params.mlim,params.mlim+diffsize);
mlimneg = max(params.mlim,params.mlim-diffsize);
for j=1:size(template,2)
    imin = max(1,j-mlimneg);
    imax = min(size(exemplar,2),j+mlimpos);
    M(imin:imax,j) = feval(params.metric,template(:,j),exemplar(:,imin:imax));
end
    

%% run DTW
 [warp,range,Dcum,move] = dtwmex(M,params.mlim,params.boundary);
%  [warp,range,Dcum,move] = dtw(M,params.mlim,params.boundary);

% find match along path
Dpath = zeros(size(warp));
for i=1:length(warp)
    if warp(i)>0
        if floor(warp(i))==warp(i);
            Dpath(i) = M(warp(i),i);
        else
            Dpath(i) = (M(floor(warp(i)),i)+M(floor(warp(i))+1,i))/2;
        end
    end
end

% rescale warp and range
if params.interpolate % do this?
    warp = warp*scale;
    range(:,2) = range(:,2)*scale;
end

 
 
 
 