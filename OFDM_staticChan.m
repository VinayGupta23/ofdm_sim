clc;
clear all;
close all;

% OFDM Parameters
nFFT = 32; nCP = 8; nDataSyms = 20;
pilotFreq = 4; nPilotSyms = ceil(nDataSyms/(pilotFreq-1));
nOfdmSyms = nDataSyms + nPilotSyms;

% Random Message Constellation
M = 4; nMsgSyms = nFFT * nDataSyms;
msg = randi([0, M-1],nMsgSyms,1);
qpskSig = pskmod(msg,M);
pilotSym = pskmod(1,M);

% Serial to parallel conversion
msgGroups = reshape(qpskSig,nFFT,nDataSyms);
% Adding block pilots
ofdmIn = [];
pilotLocs = [];
for i = 1:size(msgGroups,2)
    if mod(i,pilotFreq-1) == 1
        ofdmIn = [ofdmIn pilotSym*ones(nFFT,1)];
        pilotLocs = [pilotLocs size(ofdmIn,2)];
    end
    ofdmIn = [ofdmIn msgGroups(:,i)];
end

% Pilot Visual Representation
pilots(1:nFFT,pilotLocs) = 1;
spy(pilots);
title('Pilot locations');
xlabel('time');
ylabel('frequency');

% IFFT and addition of cyclic prefix
ofdmSyms = ifft(ofdmIn);
ofdmWithCP = [ofdmSyms(end-nCP+1:end,:); ofdmSyms];
% Parallel to serial conversion
ofdmTx = ofdmWithCP(:).';

% Transmission through multipath channel (3-tap)
channel = [randn+j*randn, (randn+j*randn)/2, (randn+j*randn)/4];
ofdmRx = conv(ofdmTx, channel);
ofdmRx = ofdmRx(1:length(ofdmTx));
% Adding AWGN
ofdmRx = awgn(ofdmRx,10,'measured');

% Demodulation
rxParallel = reshape(ofdmRx,nCP+nFFT,nOfdmSyms);
% Removing cyclic prefix and performing FFT
rxGroups = rxParallel(nCP+1:end,:);
for k = 1:nOfdmSyms
    demodGroups(:,k) = fft(rxGroups(:,k)) ./ fft(channel.',nFFT);
end
% Removing pilots and retreiving message
demodGroups(:,pilotLocs) = [];
demod = pskdemod(demodGroups(:),M);

% Constellation of received data and estimated output:
scatterplot(rxGroups(:));
title('Received signal constellation');
scatterplot(demodGroups(:));
title('Estimated signal constellation');

% Error rate
SER = nnz(msg ~= demod) / nMsgSyms;
disp('SER = ');
disp(SER);
