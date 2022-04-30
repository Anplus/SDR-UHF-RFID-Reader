clc;clear;close all;

%% load file
% setting_file = fopen('./rfid-setting-impinj-m4.json');
setting_file = fopen('./rfid-setting-slow.json');
setting = fscanf(setting_file,'%s');
config = jsondecode(setting);

%% basic setting
select_command = [1,0,1,0];
select_target = [0,0,0];
select_action = [0,0,0];
select_truncate = 0;
query_command = [1,0,0,0];
query_target = 0;
query = [];
%% read json file
RFID_SETTING = config.RFID_SETTING;
send = [];
for i=1:1:length(RFID_SETTING)
    inventory_current = RFID_SETTING(i);
    %% select
    % check if select enable
    if (isfield(inventory_current,'Select'))
        select_current = inventory_current.Select;
        for j = 1:1:length(select_current)
            select_current_membank = select_current.MEMBANK;
            select_current_pointer = select_current.POINTER;
            select_current_length = select_current.LENGTH;
            select_current_mask = select_current.MASK;
            select = [select_command,...
                        select_target,...
                        select_action,...
                        select_current_membank'...
                        select_current_pointer'...
                        select_current_length'...
                        select_current_mask'...
                        select_truncate];
            select = rfid_crc16(select);
            send = [send,gen_baseband(select,0)];
        end
    end
    %% query
    query_current = inventory_current.Query;
    query_current_dr = query_current.DR;
    query_current_m = query_current.M;
    query_current_trext = query_current.TRext;
    query_current_sel = query_current.SEL;
    query_current_session = query_current.SESSION;
    query_current_q = query_current.Q;
    query = [query_command,...
            query_current_dr,...
            query_current_m',...
            query_current_trext,...
            query_current_sel',...
            query_current_session',...
            query_target,...
            query_current_q'];
    query = rfid_crc5(query);
    send = [send,gen_baseband_slow(query,1)];
%     send = [send,gen_baseband_impinj_m4(query,1)];
end
%%
% query 673us
% wait RN16 700us
sample_rate = 2e6;
samples_per_us = sample_rate/1e6;
wait_rn16 = ones(1,700*samples_per_us);
antenna_switch_time = 30; 
to_usrp = [];
to_usrp = [send,...
            ones(1,(64*antenna_switch_time)*samples_per_us-length(send)),...
            ones(1,10*antenna_switch_time*samples_per_us)];

% power-up
% to_usrp = [ones(1,10000),to_usrp];
%%
figure;
plot(to_usrp);
axis([1 length(to_usrp) -0.1 1.1]);
filename = '../send-slow.dat';
write_file(to_usrp,filename);

%% 
f = fopen(filename,'r'); 
data = fread(f, [2,inf],'float'); 
figure;
plot(abs(data(1,:)+1i*data(2,:)));