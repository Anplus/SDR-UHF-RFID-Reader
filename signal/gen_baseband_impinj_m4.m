function output = gen_baseband_impinj_m4(input, preamble)
%% GEN - 2 PHY
%% PHY in us
sample_rate = 2e6;
samples_per_us = sample_rate/1e6;
delim_len = 12.5*samples_per_us;
Tari_len = 25*samples_per_us;
PW_len = 9*samples_per_us;
Data0_len = Tari_len;
Data1_len = 36*samples_per_us;
RTcal_len =  Data0_len+Data1_len;
% BLF = DR/TRcal = 64/3/(85*1e-6) = 250e3;
TRcal_len = 85*samples_per_us;
%% Wait time
% T1 = max(10*Tpri,RTcal)=250us
% T2 = [3Tpri,20Tpri] = 500us
% T4 = 2*RTcal , 300 us
% Tpri = 1/BLF = TRcal/DR = 25us
cw_waitRN16_send = ones(1,(700)*samples_per_us);
cw_wait_send = ones(1,300*samples_per_us);

%% basic time structure
data_1_send = [ones(1,Data1_len-PW_len),0.1*ones(1,PW_len)];
data_0_send = [ones(1,Data0_len-PW_len),0.1*ones(1,PW_len)];
RTcal_send = [ones(1,RTcal_len-PW_len),0.1*ones(1,PW_len)];
TRcal_send = [ones(1,TRcal_len-PW_len),0.1*ones(1,PW_len)];

%% preamble
preamble_send = [0.1*ones(1,delim_len),...
                data_0_send,...
                RTcal_send,...
                TRcal_send];
            
%% fram-sync
fram_send = [0.1*ones(1,delim_len),...
             data_0_send,...
             RTcal_send];
         
%% input baseband
command_send = [];
for i = 1:1:length(input)
    if input(i) == 0
        command_send = [command_send,data_0_send];
    else
        command_send = [command_send,data_1_send];
    end
end

%% preamble
if preamble == 1
% need preamble, QUERY
    command_send = [preamble_send,command_send];
else
% need fram-sync, other command
    command_send = [fram_send,command_send];
end
%% wait Time
output = command_send;
end
