function [ofdmTx, nOfdmSyms, pilotLocs] = ofdmmod(m, nFFT, nCP, pilotFreq, pilot)
%OFDMMOD Summary of this function goes here
%   Detailed explanation goes here

if mod(length(m),nFFT) ~= 0
    error('The data cannot be suitably reshaped for OFDM modulation.');
end

nDataSyms = length(m)/nFFT;
nPilotSyms = ceil(nDataSyms/(pilotFreq-1));
nOfdmSyms = nDataSyms + nPilotSyms;

% Serial to parallel conversion
msgGroups = reshape(m,nFFT,nDataSyms);
% Adding block pilots
ofdmIn = []; pilotLocs = [];
for i = 1:size(msgGroups,2)
    if mod(i,pilotFreq-1) == 1
        ofdmIn = [ofdmIn pilot];
        pilotLocs = [pilotLocs size(ofdmIn,2)];
    end
    ofdmIn = [ofdmIn msgGroups(:,i)];
end

% IFFT and addition of cyclic prefix
ofdmSyms = ifft(ofdmIn);
ofdmWithCP = [ofdmSyms(end-nCP+1:end,:); ofdmSyms];
% Parallel to serial conversion
ofdmTx = ofdmWithCP(:).';

end

