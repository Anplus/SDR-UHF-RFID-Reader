function [] =  fft_show(data,Fs)
L = length(data);     % Length of signal
%%
Y = fft(data);
P2 = abs(Y/L);
P1 = fftshift(P2);
f = Fs*(-L/2:(L/2)-1)/L/1e3;
figure;
plot(f,10*log(P1)) 
title('Spectrum of RFID Signal')
xlabel('f (KHz)')
ylabel('Power(dB)')
end