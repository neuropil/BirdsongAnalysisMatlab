function params = defaultspecparams()
% params = defaultspecparams()
%  returns the default spectrogram parameters in a structure
%    window (= 256)
%    Nadvance (=64) 
%    NFFT (= 256)
%    fs (=24414.0625) (samples per sec)
%    ampcut (= .01)

%  Created by Todd 9/6/08

params.window=256; 
params.Nadvance=32; 
params.NFFT=256; 
params.fs = 24414.0625;
params.ampcut = .01;
params.specfloor = .05;
params.dt = 1000*params.Nadvance/params.fs; % width of each time bin in msec
df = params.fs/(params.NFFT*1000);
params.f = df*(0:floor(params.NFFT/2)); % centers of frequency bands in kHz
