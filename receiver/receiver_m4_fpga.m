clc;clear;close all;
%% signal extraction
addpath('../data');
fd = fopen('received-m4.iq');
data = fread(fd,'float32');
signal = data(1:4:end)+1i*data(2:4:end);
figure;
plot(abs(signal))

%% signal to be decode
offset = 100;
len = 4200+offset;
start = 5900-offset;
signal = signal(start:start+len);

% signal to fi
signal_r = fi(real(signal),1,16,12);
signal_i = fi(imag(signal),1,16,12);
bb = signal_r+1i*signal_i;
figure;
plot(abs(signal));
hold on;
plot(abs(bb))

% FM0
blf = 40e3;
sample_rate = 1e6;
samples_per_symbol  = floor(1/blf*sample_rate/2);

%% steps
% 1. dc remove, 2. carrier sync 3. symbol sync 4. bpsk demodulate
%% dc block
% signal_abs = abs(signal)-mean(abs(signal));
% signal_abs = signal_abs./max(signal_abs);

dc = dsp.DCBlocker('Algorithm','CIC','NormalizedBandwidth', 0.03);

%fvtool(dc)
signal_dcrrm = dc(signal_r);
signal_dcirm = dc(signal_i);
signalr_dcrm_p = signal_r-mean(signal_r);
signali_dcrm_p = signal_i-mean(signal_i);
bb_dcrm = signalr_dcrm_p+1i*signali_dcrm_p;
figure;
plot(abs(bb_dcrm));
figure;
subplot(2,1,1)
plot(signal_dcrrm);
hold on;
plot(signalr_dcrm_p);
subplot(2,1,2)
plot(signal_dcirm);
hold on;
plot(signali_dcrm_p);
