%% Obtain wave form for syllable example


%%

cd('C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\RawSongs\904\Pre\904_1112');


%%


[amp, fs, nbits] = wavread('00001.wav');
[S,F,T,P] = spectrogram(amp, 256,[],[],fs, 'yaxis');

time = T*1000;

syl1 = find(time > songDataset.sylstart{1} & time < songDataset.sylstart{1} + songDataset.syldur{1});
  
figure('units','normalized','outerposition',[0 0 1 1])
surf(T(1:1300),F,10*log10(P(:,1:1300)),'edgecolor','none'); axis tight; 
view(0,90);
ylim([0 1.5e+04])


% hold on
% surf(T(syl1),F,10*log10(P(:,syl1)),'edgecolor','none'); axis tight; 
% view(0,90);

hold on 
line([T(syl1(1)) T(syl1(1))], [0 1.5e+04])

line([T(syl1(end)) T(syl1(end))], [0 1.5e+04])