clc;clear;close all;
%% signal extraction
addpath('../data');
fd = fopen('received-fm0-40.dat');
data = fread(fd,'float32');
signal = data(1:2:end)+1i*data(2:2:end);
figure;
plot(abs(signal))

%% signal to be decode
len = 1e4;
start = 60180+1.7e4*12-600;
signal = signal(start:start+len);
figure;
plot(abs(signal))

% signal to fi
signal_r = fi(real(signal),1,16,16);
signal_i = fi(imag(signal),1,16,16);
bb = signal_r+1i*signal_i;
figure;
plot(abs(signal));
hold on;
plot(abs(bb))

% FM0
blf = 40e3;
sample_rate = 2e6;
samples_per_symbol  = floor(1/blf*sample_rate/2);

%% steps
% 1. dc remove, 2. carrier sync 3. symbol sync 4. bpsk demodulate
%% dc block
dc = dsp.DCBlocker('Algorithm','CIC','NormalizedBandwidth', 0.03);
% fvtool(dc)
signal_dcrrm = dc(signal_r);
signal_dcirm = dc(signal_i);
bb_dcrm = signal_dcrrm+1i*signal_dcirm;
figure;
plot(abs(bb_dcrm));
hold on;
plot(abs(bb));
figure;
scatter(real(bb_dcrm),imag(bb_dcrm));

%% carrier sync
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.02, ...
    'Modulation','BPSK');

syncSignal = carrierSync(bb_dcrm);

scatterplot(syncSignal,2);
title('carrier sync')
%% symbol sync
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',samples_per_symbol, ...
    'NormalizedLoopBandwidth',0.01, ...
    'DampingFactor',1.0, ...
    'TimingErrorDetector','Gardner (non-data-aided)');

rxSync = symbolSync(syncSignal);
scatterplot(rxSync,2);
title('symbol sync')

%% preamble detection
p = [1,1,0,1,0,0,1,0,0,0,1,1]';
prb = pskmod(p,2);
prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 0.1;
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







