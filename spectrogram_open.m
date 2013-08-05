%% Prepare the workspace
clear all; close all; clc;

%% Load the signal and compute the SPD.
[amp, fs, nbits] = wavread('00001.wav');
[S,F,T,P] = spectrogram(amp, 256,[],[],fs, 'yaxis');

%% Find the joint time frequency componemts above -80dB
PdB   = 10*log10(P);
meanF = zeros(size(PdB,1),1);
for n = 1:1:size(PdB,2)
    
    Index = find(PdB(:,n) > -90);

    meanF(n) = mean(F(Index));
    %pause
end

%% Filter the meanF signal
for i = 2:1:length(meanF)-1
    meanF(n) = (meanF(n-1) + 2*meanF(n) + meanF(n-1)) / 4;
end
 
%% Plot the image and mean F
hfig  = figure(1);
haxes = axes;
imagesc(T,F,PdB);
set(haxes,'YDir','Normal');
colorbar;

xlabel('time [s]');
ylabel('frequency [Hz]');


hold on;

    plot(T,meanF);
hold off;






