clc;clear;close all;
dbstop if error;
%% file
fid = fopen('../../data/signal-source-cw-move/continue/left-right/20181001170220_2ch.bin','rb');
[B2,Count] = fread(fid,[4,6000000],'double');
fclose(fid);

%% data
array = B2(1,:)+1i*B2(2,:);
single = B2(3,:)+1i*B2(4,:); 
single_abs = abs(single);
figure;
plot(abs(single));

figure;
plot(abs(array));

%% time control
sample_rate = 6e6;
samples_per_us = sample_rate/1e6;
time_antenna_switch = samples_per_us*30*64;
time_antenna = samples_per_us*30;

%% locate start 
% slow : query 
query_send = gen_baseband_slow_query-0.5;
% figure;
% plot(preamble_send);
% corr
[acor,lag] = xcorr(query_send,single_abs(1:3*length(query_send)));
[~,I] = max(abs(acor));
lagDiff = abs(lag(I));
start = lagDiff+length(query_send);

%% phase extraction 
num = floor(length(array)/time_antenna_switch) - 1;
phase = zeros(64,floor(num/64));
round_start = start;
antenna_offset = 30;
antenna_stable_time = 15;
for i = 1:1:num
    round_start = round_start+(i-1)*time_antenna_switch;
    signal_toprocess = single_abs(round_start:round_start+time_antenna_switch-length(query_send));
    figure;
    plot(signal_toprocess);
    %tag RN16
    %min T1 = max(RTCal, 10Tpri) = max(75us,250us) =  250us;
    % decode RN16
    pre_offset = samples_per_us*10;
    ref = mean(signal_toprocess(pre_offset:samples_per_us*200));
    signal_toprocess = signal_toprocess-ref;
    edge = diff(signal_toprocess);
    edge_ref = 2e-4;
    [,rise_edge] = round_start+pre_offset+find(edge(pre_offset:end)>edge_ref);
    [,down_edge] = round_start+pre_offset+find(edge(pre_offset:end)<-edge_ref);
    rise_edge = collect_edge(rise_edge,samples_per_us*11);
    down_edge = collect_edge(down_edge,samples_per_us*11);
    % 
    rn16_start = min([rise_edge,down_edge]);
    rn16_end = max([rise_edge,down_edge]);
    code = zeros(1,rn16_end-rn16_start);   
    if(rise_edge(1)<down_edge(1))
        % up
        for j = 1:1:length(rise_edge)
            code(rise_edge(j)-rn16_start+1:down_edge(j)-rn16_start-1) = 1;
        end
    else
        % down
        for j = 1:1:length(down_edge)
            code(down_edge(j)-rn16_start+1:rise_edge(j)-rn16_start-1) = 1;
        end
    end
    figure;
    plot(rn16_start:rn16_end-1,code);
    %% antenna
    antenna_index = floor(rn16_start/time_antenna);
    antenna_index_inround = floor(antenna_index/64)+1;
    antenna_start = antenna_index*time_antenna+antenna_offset;
    antenna_stable_start = antenna_start+antenna_stable_time;
    antenna_stable_end = antenna_start+time_antenna-antenna_stable_time;
    antenna_data = array(antenna_stable_start:antenna_stable_end);
    figure;
    plot(antenna_stable_start:antenna_stable_end,abs(antenna_data));
    % data 1 index
    check_length = time_antenna-2*antenna_stable_time;
    data1_index = rn16_start+find(find(code == 1)+rn16_start < antenna_stable_end &...
        find(code == 1)+rn16_start>antenna_stable_start);
    data0_index = setdiff([antenna_stable_start:antenna_stable_end],data1_index);
    phase_temp = (mean(imag(array(data1_index)))-mean(imag(array(data0_index))))/...
            (mean(real(array(data1_index)))-mean(real(array(data0_index))));
    
    phase(antenna_index_inround,floor(i/64)+1) = phase_temp;
%     hold on;
%     plot(abs(single(antenna_start+antenna_stable_time:antenna_start+time_antenna-antenna_stable_time)));
end
%%
figure;
plot(phase(1,:));





