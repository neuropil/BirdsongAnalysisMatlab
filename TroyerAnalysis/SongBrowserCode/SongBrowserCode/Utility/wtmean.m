function [mn] = wtmean(var,wt)
% [mn] = wtmean(var,wt)
% compute weighted mean of var, where wt is the weighting
% mn = sum(var.*wt)/sum(wt)

mn = sum(var.*wt)/sum(wt);