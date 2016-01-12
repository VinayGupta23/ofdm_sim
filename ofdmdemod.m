function [y_LS, y_MMSE, H_LS, H_MMSE] = ofdmdemod(x, nFFT, nCP, pilotLocs, pilot, SNR)
%OFDMDEMOD Summary of this function goes here
%   Detailed explanation goes here

if mod(length(x),nFFT+nCP) ~= 0
    error('The data cannot be suitably reshaped for OFDM demodulation.');
end

nOfdmSyms = length(x)/(nCP+nFFT);

rxParallel = reshape(x,nFFT+nCP,nOfdmSyms);
% Removing cyclic prefix and performing FFT
rxGroups = rxParallel(nCP+1:end,:);
for k = 1:nOfdmSyms
    if nnz(pilotLocs == k) > 0
        temp = fft(rxGroups(:,k));
        H_LS_est = LS_estimate(temp,pilot);
        % H_MMSE_est = MMSE_estimate(temp,pilot,SNR);
        % For now, setting MMSE = LS.
        H_MMSE_est = H_LS_est; % MMSE function has errors.
    else
        demodGroups1(:,k) = H_LS_est.*fft(rxGroups(:,k));
        demodGroups2(:,k) = H_MMSE_est.*fft(rxGroups(:,k));
    end
end
% Removing pilots and retreiving message
demodGroups1(:,pilotLocs) = [];
demodGroups2(:,pilotLocs) = [];
y_LS = demodGroups1(:);
y_MMSE = demodGroups2(:);

if nargout > 2
    H_LS = 1 ./ H_LS_est;
    H_MMSE = 1 ./ H_MMSE_est;
end

end
