clc;
clear all;
close all hidden;

% OFDM Parameters
nFFT = 64; nCP = 8;
nDataSyms = 100; pilotFreq = 4;

% Random Message Constellation
M = 4; nMsgSyms = nFFT * nDataSyms;
msg = randi([0, M-1],nMsgSyms,1);
qpskSig = pskmod(msg,M);
pilot = pskmod(randi([0 M-1],nFFT,1),M);

% OFDM Modulation with block type pilots
[ofdmTx, nOfdmSyms, pilotLocs] = ofdmmod(qpskSig,nFFT,nCP,pilotFreq,pilot);

% Pilot Visual Representation
pilots(1:nFFT,pilotLocs) = 1;
viewpilots(pilots);

% Channel description
taps = 3; % Three-Path Rayleigh channel
ts = 1e-5; dopplerMax = 10;
powerDb = -1*linspace(0,(taps-1)*3,taps);
chan = rayleighchan(ts, dopplerMax, (0:taps-1).*ts, powerDb); 
chan.StoreHistory = true; % Allow states to be stored
chan.ResetBeforeFiltering = true;
SNR = 1:0.5:20; % AWGN ratios

% Channel transmission and demodulation with error analysis
for k = 1:length(SNR)
    % Passing through channel
    temp = filter(chan,ofdmTx);
    ofdmRx = awgn(temp,SNR(k),'measured'); % Adding AWGN

    % Demodulation
    [y_LS, y_MMSE, H_LS, H_MMSE] = ofdmdemod(ofdmRx,nFFT,nCP,pilotLocs,pilot,SNR(k));
    demod_LS = pskdemod(y_LS,M);
    demod_MMSE = pskdemod(y_MMSE,M);

    % Error rate
    SER(1,k) = nnz(msg ~= demod_LS) / nMsgSyms;
    SER(2,k) = nnz(msg ~= demod_MMSE) / nMsgSyms;
end

% Constellation of received data and estimated output:
scatterplot(ofdmRx(:));
title('Received signal constellation');
scatterplot(y_LS(:)); axis(2.5*[-1 1 -1 1])
title('Estimated signal constellation using LS');
% scatterplot(y_MMSE(:)); axis(2.5*[-1 1 -1 1])
% title('Estimated signal constellation using MMSE');

% Analysing error characteristics
figure; semilogy(SNR,smooth(SER(1,:)));
xlabel('SNR (in dB)'); ylabel('Symbol Error Rate');
fprintf('The SER at %d dB SNR is:\n',SNR(end));
disp(SER(1,end));

% Comparision of channel estimate and actual channel
H_actual = fft(chan.PathGains(end,:),nFFT);
figure; hold on;
plot(0:nFFT-1,abs(H_actual),'Linewidth',2);
plot(0:nFFT-1,abs(H_LS),'r:x','MarkerSize',7);
legend('actual','estimated (LS)'); title('Channel Frequency Response');
xlabel('frequency'); ylabel('magnitude');

% Channel Visualization
plot(chan);
