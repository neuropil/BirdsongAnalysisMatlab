function [f df] = FFTspacing(n,dt)
% [f df] = FFTspacing(N,DT)
% computes the frequencies and frequency spacing of an N point
% FFT applied to a signal with spacing DT

df = 1/(n*dt);
f = df*(0:floor(n/2));