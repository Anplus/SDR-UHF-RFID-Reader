% https://ww2.mathworks.cn/help/satcom/ug/end-to-end-ccsds-telecommand-simulation-with-rf-impairments-and-corrections.html
clc;clear;close all;
%% end to end communication simulation example
% Samples per symbol
% Due to the low symbol rate and 200 KHz frequency offset, a large value of
% 200 samples per symbol must be used as a default value with
% PCM/PSK/PM modulation. For BPSK and PCM/PM/biphase-L modulation, a
% default value of 20 samples per symbol is used (due to medium and high symbol rates).
sps = 20;
% Symbol rate
% The symbol rates specified in TC for each modulation are:
% - For PCM/PSK/PM modulation, the coded symbol rates are 4000, 2000, 1000,
%   500, 250, 125, 62.5, 31.25, 15.625, or 7.8125 symbols/s (as specified in
%   CCSDS TC recommendation [6]).
% - For PCM/PM/biphase-L modulation, the coded symbol rates are 8000, 16000,
%   32000, 64000, 128000, or 256000 symbols/s.
% - For BPSK modulation, the coded symbol rates are 1000, 2000, 4000, 8000,
%   16000, 32000, 64000, 128000, 256000, 512000, 1024000, or 2048000
%   symbols/s.
symbolRate = 2048000;
cfg = ccsdsTCConfig;
cfg.ChannelCoding = "BCH";
cfg.Modulation = "BPSK";
cfg.ModulationIndex = 1.2; % Applicable with PCM/PSK/PM and PCM/PM/biphase-L. Supported range in this example is [0.2 1.5].
if strcmpi(cfg.Modulation,"PCM/PSK/PM")
    cfg.SymbolRate = symbolRate;
end
cfg.SamplesPerSymbol = sps;
normLoopBWCarrier = 0.005;      % Normalized loop bandwidth for carrier synchronizer
normLoopBWSubcarrier = 0.00005; % Normalized loop bandwidth for subcarrier synchronizer 
normLoopBWSymbol = 0.005;       % Normalized loop bandwidth for symbol synchronizer
%
numBurst  = 2;                  % Number of burst transmissions
EsNodB = 8;               % Es/No in dB
SNRIn = EsNodB - 10*log10(sps); % SNR in dB from Es/No
% Initialization of variables to store BER and number of CLTUs lost
bitsErr = zeros(length(SNRIn),1);
cltuErr = zeros(length(SNRIn),1);

% Square root raised cosine (SRRC) transmit and receive filter objects for BPSK
if strcmpi(cfg.Modulation,"BPSK")
    % SRRC transmit filter object
    txfilter = comm.RaisedCosineTransmitFilter;
    txfilter.RolloffFactor = 0.35;    % Filter rolloff
    txfilter.FilterSpanInSymbols = 6; % Filter span
    txfilter.OutputSamplesPerSymbol = sps;
    % SRRC receive filter object
    rxfilter = comm.RaisedCosineReceiveFilter;
    rxfilter.RolloffFactor = 0.35;    % Filter rolloff
    rxfilter.FilterSpanInSymbols = 6; % Filter span
    rxfilter.DecimationFactor = 1;
    rxfilter.InputSamplesPerSymbol = sps;
end

% Sample rate
if strcmpi(cfg.Modulation,"PCM/PM/biphase-L")
    % In CCSDS TC recommendation [6] section 2.2.7, coded symbol rates are
    % defined prior to biphase-L encoding.
    fs = 2*sps*symbolRate; % Biphase-L encoding has 2 symbols for each bit
else
    fs = sps*symbolRate;
end

for iSNR = 1:length(SNRIn)

    % Set the random number generator to default
    rng default

    % SNR value in the loop
    SNRdB = SNRIn(iSNR);

    % Initialization of error computing parameters
    totNumErrs = 0;
    numErr = 0;
    totNumBits = 0;
    cltuLost = 0;

    for iBurst = 1:numBurst

        % Acquisition sequence with 800 octets
        acqSeqLength = 6400;
        acqBits = repmat([0;1], 0.5*acqSeqLength, 1); % Alternating ones and zeros with zero as starting bit, starting bit can be either zero or one

        % CCSDS TC Waveform for acquisition sequence
        % Maximum subcarrier frequency offset specified in CCSDS TC is
        % ±(2*1e-4)*fsc, where fsc is the subcarrier frequency
        subFreqOffset = 3.2; % Subcarrier frequency offset in Hz
        subPhaseOffset = 4;  % Subcarrier phase offset in degrees
        % Frequency offset in Hz
        if strcmpi(cfg.Modulation,'PCM/PSK/PM')
            % Signal modulation along with subcarrier frequency and phase offset
            acqSymb = HelperCCSDSTCSubCarrierModulation(acqBits,cfg,subFreqOffset,subPhaseOffset); 
        else
            % Signal modulation as per the specified scheme in CCSDS telecommmand
            % Subcarrier impairments are not applicable with BPSK and PCM/PM/biphase-L
            cfg.DataFormat = 'acquisition sequence';
            acqSymb = ccsdsTCWaveform(acqBits,cfg);
            cfg.DataFormat = 'CLTU';
        end

        % CCSDS TC waveform for CLTU
        transferFramesLength = 640;                   % Number of octets in the transfer frame
        inBits = randi([0 1],transferFramesLength,1); % Bits in the TC transfer frame
        if strcmpi(cfg.Modulation,'PCM/PSK/PM')
            % Encoded bits after TC synchronization and channel coding sublayer operations
            [~,encBits] = ccsdsTCWaveform(inBits,cfg);
            % Signal modulation along with subcarrier frequency and phase offset
            waveSymb = HelperCCSDSTCSubCarrierModulation(encBits,cfg,subFreqOffset,subPhaseOffset);
        else
            waveSymb = ccsdsTCWaveform(inBits,cfg);
        end

        % CCSDS TC waveform with acquisition sequence and CLTU
        waveform = [acqSymb;waveSymb];

        % Transmit filtering for BPSK
        if strcmpi(cfg.Modulation,'BPSK')
            % Pulse shaping using SRRC filter
            data = [waveform;zeros(txfilter.FilterSpanInSymbols,1)];
            txSig = txfilter(data);
        else
            txSig = waveform;
        end
       
        % Add carrier frequency and phase offset
        freqOffset = 200000;  % Frequency offset in Hz
        phaseOffset = 20;     % Phase offset in degrees
        if fs <= (2*(freqOffset+cfg.SubcarrierFrequency)) && strcmpi(cfg.Modulation,'PCM/PSK/PM')
            error('Sample rate must be greater than twice the sum of frequency offset and subcarrier frequency');
        elseif fs <= (2*freqOffset)
            error('Sample rate must be greater than twice the frequency offset');
        end
        pfo = comm.PhaseFrequencyOffset('FrequencyOffset',freqOffset, ...
            'PhaseOffset',phaseOffset,'SampleRate',fs);
        txSigOffset = pfo(txSig);

        % Timing offset as an integer number of samples
        timingErr = 5;        % Timing error must be <= 0.4*sps
        delayedSig  = [zeros(timingErr,1);txSigOffset]; 

        % Pass the signal through an AWGN channel
        rxSig = awgn(complex(delayedSig),SNRdB,'measured',iBurst);

        % Coarse carrier frequency synchronization
        if strcmpi(cfg.Modulation,'PCM/PSK/PM')
             % Coarse carrier frequency synchronization for PCM/PSK/PM
            coarseSync = HelperCCSDSTCCoarseFrequencyCompensator('FrequencyResolution',100,...
                'SampleRate',fs);
        else
            % Coarse carrier frequency synchronization for BPSK and PCM/PSK/biphase-L
            coarseSync = comm.CoarseFrequencyCompensator( ...
                'Modulation','BPSK','FrequencyResolution',100, ...
                'SampleRate',fs);
        end
        
        % Compensation for coarse frequency offset
        [rxCoarse,estCoarseFreqOffset] = coarseSync(rxSig);
        
        % Receive filtering 
        if strcmpi(cfg.Modulation,'BPSK')
            % SRRC receive filtering for BPSK
            rxFiltDelayed = rxfilter(rxCoarse);
            rxFilt = rxFiltDelayed(rxfilter.FilterSpanInSymbols*sps+1:end);
        else
            % Low-pass filtering for PCM/PSK/PM and PCM/PSK/biphase-L
            % Filtering is done with a lowpass filter to reduce the effect of
            % noise to the carrier phase tracking loop
            b = fir1(40,0.3); % Coefficients for 40th-order lowpass filter with cutoff frequency = 0.3*fs/2
            rxFiltDelayed = filter(b,1,[rxCoarse;zeros(0.5*(length(b)-1),1)]);
            % Removal of filter delay
            rxFilt = rxFiltDelayed(0.5*(length(b)-1)+1:end);
        end
        
        % Fine frequency and phase correction
        if strcmpi(cfg.Modulation,'BPSK')
            fineSync = comm.CarrierSynchronizer('SamplesPerSymbol',sps, ...
                'Modulation','BPSK','NormalizedLoopBandwidth',normLoopBWCarrier);
        else
            fineSync = HelperCCSDSTCCarrierSynchronizer('SamplesPerSymbol', ...
                cfg.SamplesPerSymbol,'NormalizedLoopBandwidth',normLoopBWCarrier);
        end
        [rxFine,phErr] = fineSync(rxFilt);

        % Subcarrier frequency and phase correction
        if strcmpi(cfg.Modulation,'PCM/PSK/PM')
            subSync = HelperCCSDSTCSubCarrierSynchronizer('SamplesPerSymbol',sps, ...
                'NormalizedLoopBandwidth',normLoopBWSubcarrier);
            [rxSub,subCarPhErr] = subSync(real(rxFine));
        else
            rxSub = real(rxFine);
        end

        % Timing synchronization and symbol demodulation
        timeSync = HelperCCSDSTCSymbolSynchronizer('SamplesPerSymbol',sps, ...
            'NormalizedLoopBandwidth',normLoopBWSymbol);
        [rxSym,timingErr] = timeSync(rxSub);
         
        % Search for start sequence and bit recovery
        bits = HelperCCSDSTCCLTUBitRecover(rxSym,cfg,'Error Correcting',0.8);
        bits = bits(~cellfun('isempty',bits)); % Removal of empty cell array contents
       
        % Length of transfer frames with fill bits
        if strcmpi(cfg.ChannelCoding,'BCH')
            messageLength = 56;
        else
            messageLength = 0.5*cfg.LDPCCodewordLength;
        end
        frameLength = messageLength*ceil(length(inBits)/messageLength);
        
        if (isempty(bits)) || (length(bits{1})~= frameLength) ||(length(bits)>1)
            cltuLost = cltuLost + 1;
        else
            numErr = sum(abs(double(bits{1}(1:length(inBits)))-inBits));
            totNumErrs = totNumErrs + numErr;
            totNumBits = totNumBits + length(inBits);
        end
    end
    bitsErr(iSNR) = totNumErrs/totNumBits;
    cltuErr(iSNR) = cltuLost;

    % Display of bit error rate and number of CLTUs lost
    fprintf([['\nBER with ', num2str(SNRdB+10*log10(sps)) ],' dB Es/No : %1.2e\n'],bitsErr(iSNR));
    fprintf([['\nNumber of CLTUs lost with ', num2str(SNRdB+10*log10(sps)) ],' dB Es/No : %d\n'],cltuErr(iSNR));
end
