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

%% steps
% 1. dc remove, 2. carrier sync 3. symbol sync 4. bpsk demodulate
%% dc block
% signal_abs = abs(signal)-mean(abs(signal));
% signal_abs = signal_abs./max(signal_abs);

dc = dsp.DCBlocker('Algorithm','CIC','NormalizedBandwidth', 0.03);

%fvtool(dc)
signalr_dcrm = dc(signal_r);
signali_dcrm = dc(signal_i);
signalr_dcrm_p = signal_r-mean(signal_r);
signali_dcrm_p = signal_i-mean(signal_i);
figure;
subplot(2,1,1)
plot(signalr_dcrm);
hold on;
plot(signalr_dcrm_p);
subplot(2,1,2)
plot(signali_dcrm);
hold on;
plot(signali_dcrm_p);
title('DC remove')

figure;
scatter(signalr_dcrm,signali_dcrm);
hold on;
scatter(signalr_dcrm_p,signali_dcrm_p);
legend('dc-rm','dc-rm-perfect');
title('DC remove')
%% sync
normLoopBWCarrier = 0.005;      % Normalized loop bandwidth for carrier synchronizer
normLoopBWSymbol = 0.005;       % Normalized loop bandwidth for symbol synchronizer
%% carrier sync
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',normLoopBWCarrier, ...
    'Modulation','BPSK');

bb = signalr_dcrm_p+1i*signali_dcrm_p;
figure;
plot(abs(bb));
hold on;
plot(abs(signal))
syncSignal = carrierSync(bb);

scatterplot(syncSignal,2);
title('carrier sync')
%% symbol sync
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',normLoopBWSymbol, ...
    'DampingFactor',1.0, ...
    'TimingErrorDetector','Gardner (non-data-aided)');

rxSync = symbolSync(syncSignal);
scatterplot(rxSync,2);
title('symbol sync')

%% bpsk decode
rxData = pskdemod(rxSync,2);      % Demodulate
rxData = ~rxData;

rxData_show = repmat(rxData,1,samples_per_symbol);
rxData_show2 =reshape(rxData_show',1,[]);

figure;
plot(rxData_show2)
hold on;
oo = abs(bb)-mean(abs(bb));
plot(oo./max(oo));


%% preamble detection
p = [1,1,0,1,0,0,1,0,0,0,1,1]';
preamble = pskmod(p,2);
prbdet = comm.PreambleDetector(preamble);
[idx,detmet] = prbdet(rxSync);
numel(idx)
detmetSort = sort(detmet,'descend');
detmetSort(1:5)
prbdet.Threshold = 1;
idx = prbdet(rxSync)


