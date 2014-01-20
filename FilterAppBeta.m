[funky, f] = audioread('00001.wav');


%%
audioplayer(funky,f)

%%

subplot(2,1,1);
plot(funky)
title('Entire Waveform');
smallRange = 100000:100000+floor(f/100);
subplot(2,1,2);
plot(smallRange, funky(smallRange))
title('100 milliseconds');

%% 

specgram(funky, 512, f);


%%

subplot(2,1,1)
plot(funky)
axis('tight');
subplot(2,1,2)
specgram(funky,128,f);

%%

subplot(2,1,1), plot(funky(100000:150000)), axis('tight');
subplot(2,1,2), specgram(funky(100000:150000),128,f);

%% Apply 1000Hz filter


fNorm = 1000 / (f/2);
[b, a] = butter(10, fNorm, 'high');
funkyHigh = filtfilt(b, a, funky);


subplot(2,1,1)
plot(funky)
subplot(2,1,2)
plot(funkyHigh);

% freqz(b,a,128,f);