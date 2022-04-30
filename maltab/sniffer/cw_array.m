function phase_array = cw_array(filename)
%% file
% fid = fopen('../../data/signal-source-cw-move/still-n210.bin','rb');
% fid = fopen('../../data/signal-source-cw-move/continue/left-right/20181001170220_2ch.bin','rb');
fid = fopen(filename,'rb');
[B2,Count] = fread(fid,[4,6000000],'double');
fclose(fid);

%% data
array = B2(1,:)+1i*B2(2,:);
single = B2(3,:)+1i*B2(4,:); 
% figure;
% plot(abs(single));
% figure;
% plot(abs(array));

%% time control
sample_rate = 6e6;
samples_per_us = sample_rate/1e6;
time_antenna_switch = samples_per_us*30*64;
time_antenna = samples_per_us*30;
time_antenna_stable_offset = 15;
time_antenna_offset = 30; 
antenna_num = floor(length(array)/time_antenna);
phase_array = zeros(64,floor(antenna_num/64));
antenna_index = 1;
for i = 1:1:antenna_num-1
    if(mod(i,64)==0)
        antenna_index = 64;
    else
        antenna_index = mod(i,64);
    end
    time_start = (i-1)*time_antenna+time_antenna_offset+1;
    signal_toprocess = array(time_start+time_antenna_stable_offset:...
        time_start+time_antenna-1-time_antenna_stable_offset);
%     X = [real(signal_toprocess);imag(signal_toprocess)]';
%     [idx,C] = kmeans(X,1,'Distance','cityblock');
%     phase_array(antenna_index, floor(i/64)+1) = atan(C(2)/C(1));
    phase_array(antenna_index, floor(i/64)+1) = mean(angle(signal_toprocess));
end

end
% figure;
% plot(((phase_array(16,:))));
% 
% mean_array = mean(phase_array,2);
% std_array = std(phase_array,0,2);
% 
% figure;
% shadedErrorBar(1:length(mean_array),mean_array,std_array,'lineprops','g');
% %%
% len_each = 30*6;
% num_round = floor(length(array)/len_each/64);
% array_strength_round = zeros(64,num_round);
% array_strength = zeros(64,1);
% % round i
% for i = 1:1:num_round
%     % antenna j
%     for j = 1:1:64
%         temp = array((64*(i-1)+(j-1))*len_each+1:(64*(i-1)+(j))*len_each);
%         array_strength_round(j,i) = mean(abs(temp));
%     end
% end
% array_strength = mean(array_strength_round,2);
% figure;
% % heatmap(1:8, 1:8, reshape(array_strength,8,8));
% pcolor(1:8,1:8,reshape(array_strength,8,8))
% colormap(jet)
% colorbar
%%



