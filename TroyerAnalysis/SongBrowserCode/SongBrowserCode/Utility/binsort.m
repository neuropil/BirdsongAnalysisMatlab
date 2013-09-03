function [N,inds] = binsort(X,edges)
% [N,inds] = binsort(X,edges)
% sort data into bins given by edges
% N is number of data points in each bin
% inds is cell array containing indexes of data that falls in each bin
% if edges is 1D vector, data is sorted into non-0verlapping bins
% if edges is 2D matrix, each pair defines the start and end point for the
% bin
% function aborts if data does not fall within edge range
% WARNING: data falling on bin edges is not treated carefully so these
% points may fall on either edge

% make data into single col vector and find length
dataN = length(X);
X = X(:);
% find size of edges
if size(edges,1)<size(edges,2)
    edges = edges';
end
if size(edges,2)==1
    edges = [edges(1:end-1) edges(2:end)];
end
edgeN = size(edges,1);
% combine data and edges and sort
allvals = [X; edges(:,1); edges(:,2)];
[sortall sortinds] = sort(allvals);
[tmp resortinds] = sort(sortinds); % gives position of original inds in sorted data
    
% initialize return variables
inds = cell(size(edges,1),1);
N = zeros(size(edges,1),1);
% make sure sorted data starts and ends with edge index
if sortinds(1)<=dataN 
    disp('Min of data less than lowest edge. Aborting binsort.'); return;
end
if sortinds(end)<=dataN 
    disp('Max of data greater than highest edge. Aborting binsort.'); return;
end
% extract sorted data
for i=1:length(inds)
    inds{i} = sortinds(resortinds(dataN+i)+1:resortinds(dataN+edgeN+i)-1);
    inds{i} = inds{i}(inds{i}<=dataN);
    N(i) = length(inds{i});
end
