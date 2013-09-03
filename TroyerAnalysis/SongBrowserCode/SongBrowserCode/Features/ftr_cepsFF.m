function [FF goodFF] = ftr_cepsFF(spec,f,varargin)
% [FF goodFF] = ftr_cepsFF(ceps,p,varargin)
%  fundamental frequency based on cepstrum
% FF is the peak of the real (cosine) part of the cepstrum
% goodFF is determined as the power at multiples of the FF 
%  divided by the sum of the power at multiples of FF plus
%  the power at pts between the peaks of multiples of the FF
% quadriatic interpolation near peak is used to estimate the true peak
% frequency
% 

%  Created by Todd 3/4/08
%    Edits: 

% function [FF goodFF] = ftr_cepsFF(ceps,p,varargin)

cepsFF.NFFT=4096; 
cepsFF.specfloor=.05; 
cepsFF.freqrange= [.5 2]; 
cepsFF.specparams = defaultspecparams; 
cepsFF = parse_pv_pairs(cepsFF,varargin);
cepsFF.NFFT = max(cepsFF.NFFT,size(spec,1));

% f = cepsFF.specparams.f;

logspec = log(max(abs(spec),cepsFF.specfloor));
% use derivative filter
logspec = (logspec(2:end,:)-logspec(1:end-1,:));
cepstrum = (fft(logspec,cepsFF.NFFT));
n = 1+floor(size(cepstrum,1)/2);
cepstrum = cepstrum(1:n,:);
% depends on freq resolution of specgram
df = diff(f(1:2));
p = [0 df*cepsFF.NFFT./(1:n-1)];

pinds = find(p<=1/cepsFF.freqrange(1) & p>=1/cepsFF.freqrange(2));
ptmp = p(pinds);
FF = zeros(1,size(cepstrum,2));
goodFF = zeros(1,size(cepstrum,2));
goodFF2 = zeros(1,size(cepstrum,2));
for i=1:size(cepstrum,2);
    [mx ind] = max(abs(cepstrum(pinds,i)));
    FF(i) = 1/ptmp(ind);
%     goodFF(i) = mx./mean(abs(cepstrum(pinds,i)));
    goodFF(i) = mx;
%     goodFF2(i) = sum(imag(cepstrum(pinds,i)))/sum(abs(cepstrum(pinds,i)));
%     figure(3)
%     plot(ptmp,abs(cepstrum(pinds,i)))
%     title(['FF = ' num2str(FF(i))])
%     pause
   
end


