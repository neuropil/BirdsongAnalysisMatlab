function [stdev] = ftr_freqstd(spec,freqs,varargin)
% [mn stdev] = ftr_freqstd(SPEC,FREQS,varargin) views each column of the spectrogram
%   as a probability distribution or weighting function and calculates the 
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
f = freqs(freqinds);
amp = abs(spec(freqinds,:));
mn = sum((f(:)*ones(1,size(spec,2))).*amp)./sum(amp);
devs = (f(:)*ones(1,size(spec,2))-ones(length(f),1)*mn(:)');
stdev = sqrt(sum((devs.^2).*amp)./sum(amp));

