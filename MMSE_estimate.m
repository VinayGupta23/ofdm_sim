function H = MMSE_estimate(y,x,SNR)
%MMSE_ESTIMATE Summary of this function goes here
%   Detailed explanation goes here

N = length(x);
H_LS = LS_estimate(y,x);
g = ifft(H_LS);
X = diag(x);

Rgg=cov(g);
t = 0:N-1;
F = exp(-2j*pi*t'*t/N);
snr = 10^(SNR/10);

H = 1./ fft(Rgg*F'*X'*pinv(X*F*Rgg*F'*X' + (1/snr)*eye(N))*y);

end