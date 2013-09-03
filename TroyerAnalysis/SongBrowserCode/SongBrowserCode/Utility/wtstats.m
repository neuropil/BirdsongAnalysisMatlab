function [mn variance] = wtstats(x,wt)
% [mn variance] = wtstats(x,wt)
% compute weighted mean and variance of x, where wt is the weighting
% mn = sum(x.*wt)/sum(wt)
% variance = sum((x-mn).^2.*wt)/sum(wt)

tmp = find(wt<-1e-15);
if ~isempty(tmp)
    disp('Negative weightings in wtstats');
    mn = [];
    variance = [];
end
sumwt = sum(wt);
if sumwt<0
    disp('Negative weightings in wtstats');
    mn = [];
    variance = [];
end
mn = sum(x.*wt)/sumwt;
variance = sum(((x-mn).^2).*wt)/sumwt;