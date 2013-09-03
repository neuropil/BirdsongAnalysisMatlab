function amp = ftr_amp(spec,freqs,varargin)
% amp = ftr_amp(SPEC,FREQS,varargin) calculates the amplitude using the columns
% of the spectrogram SPEC.  FREQS is a vector of frequencies included in
% SPEC (in kHz)
% 
% parameter value pairs of the form 'freqrange',[.7 7] can be used to set
% the range of frequencies considered (in kHz; default [0 20]).

%  Created by Todd 8/12/09

% STANDARD FIELDS
amp.freqrange=[0 20]; 

amp = parse_pv_pairs(amp,varargin);
freqinds = find(freqs> amp.freqrange(1) & freqs<= amp.freqrange(2));
amp = sqrt(sum(abs(spec(freqinds,:)).^2));

