function [spec f t] = ftr_specgram(data,varargin)
% [spec f t] = ftr_specgram(data,varargin)
%  calculate using the spectrogram function
%    by entering params.fs in samples/msec, t is returned in msec
%    and f in kHz
%  varargin can be a parameter structure or a list of parameter/value pairs
%    window - def = 256
%    Nadvance - def =64 
%    NFFT - def = 256
%    fs - def=24414.0625 (samples per sec)

%  Created by Todd 9/6/08
if nargin==2
    params = varargin{1};
else
    params = defaultspecparams();
    params = parse_pv_pairs(params,varargin);
end

if length(data)<params.NFFT
    data = [data(:); zeros(params.NFFT-length(data),1)];
end
% pad with half window length of zeros
if length(params.window)==1
    windowlen = params.window;
else
    windowlen = length(params.window);
end
% pad = zeros(floor(windowlen/2),1);
pad = zeros(windowlen-params.Nadvance,1);
data = [pad; data; pad];
try
    [spec f t] = spectrogram(data,params.window,params.NFFT-params.Nadvance,params.NFFT,params.fs/1000);
catch
    params.window
    max(size(data))
    params.NFFT
    params.NFFT-params.Nadvance
end
    
