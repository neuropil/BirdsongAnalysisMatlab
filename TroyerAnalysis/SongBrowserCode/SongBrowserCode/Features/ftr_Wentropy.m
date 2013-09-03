function Wentropy = ftr_Wentropy(spec,freqs,varargin)
% Wentropy = ftr_Wentropy(SPEC,FREQS,varargin) views each column of the spectrogram
%   as a probability distribution or weighting function and calculates the mean and 
%    standard deviation of this function. FREQS is a vector of frequencies included in
%    SPEC (in kHz)
% 
% parameter value pairs of the form 'freqrange',[.7 7] can be used to set
% the range of frequencies considered (in kHz; default [0 20]).

%  Created by Todd 8/12/09

% STANDARD FIELDS
ent.freqrange=[0 20]; 
ent.minspec=1e-10; 
ent = parse_pv_pairs(ent,varargin);
freqinds = find(freqs> ent.freqrange(1) & freqs<= ent.freqrange(2));
spec = max(abs(spec(freqinds,:)),ent.minspec); % make non-zero minimum

geomn = exp(mean(log(spec)));
mn = mean(spec);
Wentropy = log(geomn./mn);