function output = gen_baseband_slow_query
%% GEN - 2 PHY
%% PHY in us
sample_rate = 6e6;
samples_per_us = sample_rate/1e6;
delim_len = 12.5*samples_per_us;
% Tari =25us
Tari_len = 25*samples_per_us;
PW_len = 12*samples_per_us;
Data0_len = Tari_len;
Data1_len = 2*Tari_len;
RTcal_len = Data0_len+Data1_len;
% BLF = 40Khz, Tpri = 25us, DR = 8, TRcal = DR/BLF = 8/40e3 = 200us
TRcal_len = 200*samples_per_us;
%% basic time structure
data_1_send = [ones(1,Data1_len-PW_len),0*ones(1,PW_len)];
data_0_send = [ones(1,Data0_len-PW_len),0*ones(1,PW_len)];
RTcal_send = [ones(1,RTcal_len-PW_len),0*ones(1,PW_len)];
TRcal_send = [ones(1,TRcal_len-PW_len),0*ones(1,PW_len)];

%% preamble
preamble_send = [0*ones(1,delim_len),...
                data_0_send,...
                RTcal_send,...
                TRcal_send];
%% input baseband
command_send = [];
input = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0];
for i = 1:1:length(input)
    if input(i) == 0
        command_send = [command_send,data_0_send];
    else
        command_send = [command_send,data_1_send];
    end
end

%% preamble
command_send = [preamble_send,command_send];
%% wait Time
output = command_send;
end