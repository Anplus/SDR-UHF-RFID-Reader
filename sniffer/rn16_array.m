function phase_array = rn16_array(filename)
%% file
% fid = fopen('../../data/move/20180929205105_2ch.bin','rb');
fid = fopen(filename);
[B2,Count] = fread(fid,[4,6000000],'double');
fclose(fid);

%% data
array = B2(1,:)+1i*B2(2,:);
single = B2(3,:)+1i*B2(4,:); 
single_abs = abs(single);
% figure;
% plot(abs(single));
% hold on;
% plot(abs(array(1:2e4)));

%% time control
sample_rate = 6e6;
samples_per_us = sample_rate/1e6;
time_round = 21822-7347;
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
num = floor(length(array)/time_round) - 1;
phase_array = zeros(64,floor(num/64));
round_start = start;
antenna_offset = 30;
antenna_stable_time = 15;
signal_tag_preamble = gen_tag_fm0_preamble(samples_per_us)-0.5;
%% tag time
blf = 40e3;
tpri = 1/blf*1e6*samples_per_us;
halfcode_length = floor(tpri/2);

phase_num = zeros(1,64);
antenna_num_inround = floor((16+6)*25*samples_per_us/time_antenna);
%%
for i = 1:1:num-1
    round_start = round_start+time_round;
    signal_toprocess = single_abs(round_start:round_start+time_round-length(query_send));
%     figure;
%     plot(signal_toprocess);
    %tag RN16
    %min T1 = max(RTCal, 10Tpri) = max(75us,250us) =  250us;
    % decode RN16
    pre_offset = samples_per_us*10;
    ref = mean(signal_toprocess(pre_offset:samples_per_us*200));
    signal_toprocess = smooth(signal_toprocess-ref);
%%  RN16 locate
    if(max(signal_toprocess)>0)
        [acor,lag] = xcorr(signal_tag_preamble,signal_toprocess);
        [~,I] = max(abs(acor));
        lagDiff = abs(lag(I));
%         figure;
%         plot(signal_toprocess)
%         hold on;
%         plot(lagDiff:1:lagDiff+length(signal_tag_preamble)-1,max(signal_toprocess)*signal_tag_preamble);
    else
        [acor,lag] = xcorr(-signal_tag_preamble,signal_toprocess);
        [~,I] = max(abs(acor));
        lagDiff = abs(lag(I));
    end
    rn16_start = round_start+lagDiff;
%% RN16 decode
    signal_rn16 = single_abs(rn16_start:rn16_start+(16+6)*25*samples_per_us-1);
    code = zeros(1,length(signal_rn16));
    ref = (sum(signal_rn16(halfcode_length:2*halfcode_length-1))-...
        sum(signal_rn16(2*halfcode_length:3*halfcode_length-1)))/2;
    if(sum(signal_rn16(1:halfcode_length-1)>ref))
        high_one = true;
    else
        high_one = false;
    end
    for j = 1:1:floor(length(signal_rn16)/(halfcode_length))-1
        if(sum(signal_rn16(j*halfcode_length:(j+1)*halfcode_length-1))>ref)
            if(high_one)
                code(j*halfcode_length:(j+1)*halfcode_length-1) = 1;
            else
                code(j*halfcode_length:(j+1)*halfcode_length-1) = 0;
            end
        else
            if(high_one)
                code(j*halfcode_length:(j+1)*halfcode_length-1) = 0;
            else
                code(j*halfcode_length:(j+1)*halfcode_length-1) = 1;
            end
        end
    end
    
%     figure;
%     plot(rn16_start:rn16_end-1,code);
    %% antenna
    for n = 1:1:antenna_num_inround
        antenna_start = rn16_start+(n-1)*time_antenna;
        antenna_index = floor(antenna_start/time_antenna);
        antenna_index_inround = 0;
        if(mod(antenna_index,64)==0)
            antenna_index_inround = 64;
        else
            antenna_index_inround = mod(antenna_index,64);
        end
        antenna_start = antenna_index*time_antenna+antenna_offset;
        antenna_stable_start = antenna_start+antenna_stable_time;
        antenna_stable_end = antenna_start+time_antenna-antenna_stable_time;
        antenna_data = array(antenna_stable_start:antenna_stable_end);
        % data 1 index
        check_length = time_antenna-2*antenna_stable_time;
        data1_index = rn16_start+find(find(code == 1)+rn16_start < antenna_stable_end &...
            find(code == 1)+rn16_start>antenna_stable_start);
        data0_index = setdiff([antenna_stable_start:antenna_stable_end],data1_index);
        if(isempty(data1_index) || isempty(data0_index))
            continue;
        end
        phase_temp = angle((mean(imag(array(data1_index)))-mean(imag(array(data0_index))))+1i*...
                mean(real(array(data1_index)))-mean(real(array(data0_index))));

        phase_array(antenna_index_inround,phase_num(antenna_index_inround)+1) = phase_temp;
        phase_num(antenna_index_inround) = phase_num(antenna_index_inround)+1;
    
    end

%     hold on;
%     plot(abs(single(antenna_start+antenna_stable_time:antenna_start+time_antenna-antenna_stable_time)));
end
%%
% figure;
% plot(phase_array(19,:));
end





