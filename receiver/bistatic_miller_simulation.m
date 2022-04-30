clc;clear;close all;
%% signal extraction
addpath('../data');
fd = fopen('receiver-m4-160k-2MS.iq');
data = fread(fd,'float32');
signal = data(3:4:end)+1i*data(4:4:end);
figure;
plot(abs(signal))

%% signal to be decode
len = 2200;
start = 1306;
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
bb_dcrm = bb_dcrm(2:end)-bb_dcrm(1:end-1);
% coarse
freqComp = comm.CoarseFrequencyCompensator( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'Modulation','BPSK', ...
    'SampleRate',sample_rate, ...
    'FrequencyResolution',1);
[compensatedData,estFreqOffset] = freqComp(bb_dcrm);
freqCompInfo = info(freqComp)
specAnal = dsp.SpectrumAnalyzer('SampleRate',sample_rate,'ShowLegend',true, ...
    'ChannelNames',{'Offset Signal','Compensated Signal'});
specAnal([bb_dcrm compensatedData])
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'Modulation','BPSK');

syncSignal = carrierSync(compensatedData);

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
pilot = repmat([1,0],1,M*16);
p_o = [0,1,0,1,1,1,1];
len = length(p_o);
p = [repmat([1,0],1,M),repmat([1,0],1,M/2),~repmat([1,0],1,M/2),...
    ~repmat([1,0],1,M),~repmat([1,0],1,M/2),repmat([1,0],1,M/2)...
    repmat([1,0],1,M),~repmat([1,0],1,M/2),~repmat([1,0],1,M/2),repmat([1,0],1,M/2)];
prb = pskmod(p',2);
prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 0.03;
[idx,detmet] = prbdet(rxSync);
idx = idx(1);
%% bpsk decode
rxData = pskdemod(rxSync(idx+1:end),2);      % Demodula
rxData = ~rxData;

rxData_show = repmat([zeros(idx,1);rxData],1,samples_per_symbol);
rxData_show2 =reshape(rxData_show',1,[]);

figure;
plot(rxData_show2,'LineWidth',2)
hold on;
oo = abs(bb)-mean(abs(bb));
plot(oo./max(oo));

