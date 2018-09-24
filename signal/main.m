clc;
clear;
close all;

%% load file
setting_file = fopen('../rfid-setting.json');
% setting_file = fopen('./setting-test.json');
setting = fscanf(setting_file,'%s');
config = jsondecode(setting);

%% basic setting
select_command = [1,0,1,0];
select_target = [0,0,0];
select_action = [0,0,0];
select_truncate = 0;
query_command = [1,0,0,0];
query_dr = 0;
query_m = [0,0];
query_trext = 0;
query_target = 0;

%% read json file
RFID_SETTING = config.RFIDSETTING;
send = [];
for i=1:1:length(RFID_SETTING)
    inventory_current = RFID_SETTING(i);
    select_current = inventory_current.Select;
    query_current = inventory_current.Query;
    %% select
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
    %% query
    query_current_sel = query_current.SEL;
    query_current_session = query_current.SESSION;
    query_current_q = query_current.Q;
    query = [query_command,...
            query_dr,...
            query_m,...
            query_trext,...
            query_current_sel',...
            query_current_session',...
            query_target,...
            query_current_q'];
    query = rfid_crc5(query);
    send = [send,gen_baseband(query,1)];
end

%% repeat
times = 1;
to_usrp = [];
for i = 1:1:times
    to_usrp = [to_usrp, send];
end
%power-up
to_usrp = [ones(1,10000),to_usrp];
%%
plot(to_usrp);
axis([1 length(to_usrp) -0.1 1.1]);
write_file(to_usrp);
