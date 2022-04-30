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

figure;
plot(abs(signal))

%% PHY setting
blf = 160e3;
sample_rate = 8e6;
samples_per_symbol  = floor(1/blf*sample_rate/4);
M = 4;

signal_r = fi(real(signal),1,16,12);
signal_i = fi(imag(signal),1,16,12);

%% dc block
% signal_abs = abs(signal)-mean(abs(signal));
% signal_abs = signal_abs./max(signal_abs);

dc = dsp.DCBlocker('Algorithm','CIC','NormalizedBandwidth', 0.03);

%fvtool(dc)
signal_dcrrm = dc(signal_r);
signal_dcirm = dc(signal_i);
figure;
plot(signal_dcrrm);
hold on;
plot(signal_r-mean(signal_r));
figure;
plot(signal_dcirm);
hold on;
plot(signal_i-mean(signal_i));

figure;
scatter(signal_dcrrm,signal_dcirm);
hold on;
scatter(signal_r,signal_i);
legend('dc-rm','o');

%% carrier sync
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'Modulation','BPSK');

bb = signal_dcrrm+1i*signal_dcirm;
bb = double(real(bb))+1i*double(imag(bb));
syncSignal = carrierSync(bb);

figure;
scatter(real(syncSignal),imag(syncSignal))
title('carrier sync')

%% symbol sync
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'TimingErrorDetector','Gardner (non-data-aided)');

rxSync = symbolSync(syncSignal);
figure;
scatter(real(rxSync),imag(rxSync))
title('symbol sync')
%% bpsk demodulate
bpskDemodulator = comm.BPSKDemodulator;
rxData = bpskDemodulator(rxSync);       % Demodulate

rxData_show = repmat(rxData,1,samples_per_symbol);
rxData_show2 =reshape(rxData_show',1,[]);
figure;
plot(rxData_show2);
hold on;
plot(real(bb)./max(real(bb)));
legend('decode','signal');

%% preamble detection
preamble = [1,1,0,1,0,0,1,0,0,0,1,1]';
prbdet = comm.PreambleDetector(preamble,'Input','Bit','Detections','First');
idx = prbdet(rxData)

