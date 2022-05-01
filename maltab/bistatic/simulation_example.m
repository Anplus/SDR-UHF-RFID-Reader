% https://ww2.mathworks.cn/help/satcom/ug/end-to-end-ccsds-telecommand-simulation-with-rf-impairments-and-corrections.html
%% end to end communication simulation example
clc;clear;close all;
%%
M = 2;         % Modulation order for BPSK
nSym = 5000;  % Number of symbols in a packet
sps = 100;       % Samples per symbol
timingErr = 2; % Samples of timing error
snr = 10;      % Signal-to-noise ratio (dB)

txfilter = comm.RaisedCosineTransmitFilter(...
    'OutputSamplesPerSymbol',sps);
rxfilter = comm.RaisedCosineReceiveFilter(...
    'InputSamplesPerSymbol',sps,'DecimationFactor',1);

symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',sps, ...
    'NormalizedLoopBandwidth',0.01, ...
    'DampingFactor',1.0, ...
    'TimingErrorDetector','Early-Late (non-data-aided)');

data = randi([0 M-1],nSym,1);
modSig = pskmod(data,M);

fixedDelay = dsp.Delay(timingErr);
fixedDelaySym = ceil(fixedDelay.Length/sps); % Round fixed delay to nearest integer in symbols

% txSig = txfilter(modSig);
txSig = repmat(modSig,1,sps);
txSig =reshape(txSig',1,[])';
delayedSig = fixedDelay(txSig);

rxSig = awgn(delayedSig,snr,'measured');

% rxSample = rxfilter(rxSig);
rxSample2 = rxSig;
scatterplot(rxSample2(1:end),2)
title('rx')

rxSample = filter(1/sps*ones(1,sps),1,rxSig);

figure;
plot(real(rxSample));
hold on;
plot(real(rxSig))
legend('rx','tx');

scatterplot(rxSample(1:end),2)
title('rx with matched filter')

rxSync2 = symbolSync(rxSample2);
scatterplot(rxSync2(1:end),2)
title('sync without matched filter')
rxData_show = repmat(rxSync2,1,sps);
rxData_show2 =reshape(rxData_show',1,[]);

figure;
plot(real(delayedSig));
hold on;
plot(real(rxData_show2));
legend('o','correct without matched filter');

rxSync = symbolSync(rxSample);
scatterplot(rxSync(1:end),2)
title('sync')
rxData_show = repmat(rxSync,1,sps);
rxData_show2 =reshape(rxData_show',1,[]);

figure;
plot(real(delayedSig));
hold on;
plot(real(rxData_show2));
legend('o','correct');
