[funky, f] = audioread('00001.wav');


%% 

specgram(funky, 512, f);


%% Apply 1000Hz filter


fNorm = 800 / (f/2);
[b, a] = butter(10, fNorm, 'high');
funkyHigh = filtfilt(b, a, funky);


subplot(2,1,1)
plot(funky)
subplot(2,1,2)
plot(funkyHigh);

% freqz(b,a,128,f);