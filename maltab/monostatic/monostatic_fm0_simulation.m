clc;clear;close all;
%% signal extraction
addpath('../../data');
fd = fopen('received-fm0-40.dat');
data = fread(fd,'float32');
signal = data(1:2:end)+1i*data(2:2:end);
figure;
plot(abs(signal))

%% signal to be decode
len = 1e4;
start = 60180+1.7e4*1;
signal = signal(start:start+len);
figure;
plot(abs(signal))

% signal to fi
signal_r = real(signal);
signal_i = imag(signal);
bb = signal_r+1i*signal_i;
% figure;
% plot(abs(signal));
% hold on;
% plot(abs(bb))
scatterplot(bb,2)
title('original')

% FM0
blf = 40e3;
sample_rate = 2e6;
samples_per_symbol  = floor(1/blf*sample_rate/2);

%% steps
% 1. dc remove, 2. carrier sync 3. symbol sync 4. bpsk demodulate

%% dc block
bb_dcrm = bb-mean(bb);
figure;
plot(abs(bb_dcrm));
hold on;
plot(abs(bb));
scatterplot(bb_dcrm,2)
title('dc rm')

% %% differeniate
% bb_dcrm = bb_dcrm(2:end)-bb_dcrm(1:end-1);

%% matched filter
fd = 1/samples_per_symbol*ones(1,samples_per_symbol);
% fvtool(fd);
filteredSignal = filter(fd,1,bb_dcrm);
scatterplot(filteredSignal,2);
title('matched filter')
figure;
plot(real(filteredSignal));
hold on;
plot(real(bb_dcrm));
legend('matched filter','recevied');
% filteredSignal = bb_dcrm;

%% carrier sync
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'Modulation','BPSK');

syncSignal = carrierSync(filteredSignal);

scatterplot(syncSignal,2);
title('carrier sync')

%% symbol sync
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'DampingFactor',1, ...
    'TimingErrorDetector','Gardner (non-data-aided)');

rxSync = symbolSync(syncSignal);
scatterplot(rxSync,2);
title('symbol sync')
figure;
plot(angle(rxSync))

%% preamble detection
p = [1,1,0,1,0,0,1,0,0,0,1,1]';
prb = pskmod(p,2);
prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 1/length(p);
[idx,detmet] = prbdet(rxSync);
max(detmet)
idx = idx(1);

%% bpsk decode
rxData = pskdemod(rxSync(idx+1:end),2);      % Demodulate
rxData = ~rxData;

rxData_show = repmat([zeros(idx,1);rxData],1,samples_per_symbol);
rxData_show2 =reshape(rxData_show',1,[]);

figure;
plot(rxData_show2,'LineWidth',2)
hold on;
oo = abs(signal)-mean(abs(signal));
plot(oo./max(oo));

%% bit to symbol
sym = rxData(2:2:256)-rxData(1:2:255);
sym = ~sym;

%% CRC check
% CRC-CCITT International Standard, ITU Recommendation X.25
% The PacketCRC is computed and sent by a Tag during backscatter, protects the transmitted  PC/XPC  and  EPC, 
crc_ouput = rfid_crc16(sym(1:16+96)');
crc_ouput = crc_ouput(end-15:end)
expectedChecksum = sym(128-15:128)' % Expected FCS
checksumLength = 16;

crcGen = comm.CRCGenerator(...
    'Polynomial','X^16 + X^12 + X^5 + 1',...
    'InitialConditions',1,...
    'DirectMethod',true,...
    'FinalXOR',1);
crcSeq = crcGen(sym(1:16+96));
checkSum =  crcSeq(end-checksumLength+1:end)'
isequal(expectedChecksum,checkSum)







