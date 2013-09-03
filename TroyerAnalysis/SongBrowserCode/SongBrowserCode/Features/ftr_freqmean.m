function [mn ] = ftr_freqmean(spec,freqs,varargin)
% [mn] = ftr_freqmean(SPEC,FREQS,varargin) views each column of the spectrogram
%   as a probability distribution or weighting function and calculates the mean and 
%    standard deviation of this function. FREQS is a vector of frequencies included in
%    SPEC (in kHz)
% 
% parameter value pairs of the form 'freqrange',[.7 7] can be used to set
% the range of frequencies considered (in kHz; default [0 20]).

%  Created by Todd 8/12/09

% STANDARD FIELDS
freqstats.freqrange=[0 20]; 

freqstats = parse_pv_pairs(freqstats,varargin);
freqinds = find(freqs> freqstats.freqrange(1) & freqs<= freqstats.freqrange(2));
amp = abs(spec(freqinds,:));
mn = sum((freqs(freqinds)*ones(1,size(spec,2))).*amp)./sum(amp);

