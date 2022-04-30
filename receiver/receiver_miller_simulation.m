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
signal_r = real(signal);
signal_i = imag(signal);
bb = signal_r+1i*signal_i;
figure;
plot(abs(signal));
hold on;
plot(real(bb));
plot(imag(bb));

%% PHY setting
blf = 160e3;
M = 4;
sample_rate = 2e6;
samples_per_symbol  = floor(1/blf*sample_rate/2);


%% steps
% 1. dc remove, 2. carrier sync 3. symbol sync 4. bpsk demodulate
%% dc block
% signal_abs = abs(signal)-mean(abs(signal));
% signal_abs = signal_abs./max(signal_abs);

%fvtool(dc)
signalr_dcrm_p = signal_r-mean(signal_r);
signali_dcrm_p = signal_i-mean(signal_i);
bb_dcrm = bb-mean(bb);
scatterplot(bb_dcrm,2)
%% carrier sync
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'Modulation','BPSK');

syncSignal = carrierSync(bb_dcrm);

scatterplot(syncSignal,2);
title('carrier sync')
%% symbol sync
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'DampingFactor',1.0, ...
    'TimingErrorDetector','Early-Late (non-data-aided)');

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
oo = abs(signal)-mean(abs(signal));
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

