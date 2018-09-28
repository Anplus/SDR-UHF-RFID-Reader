clc;clear;close all;
%% file
fid = fopen('../../data/test/cw.bin','rb');
[B2,Count] = fread(fid,[4,6000000],'double');
fclose(fid);

%% data
array = B2(1,:)+1i*B2(2,:);
single = B2(3,:)+1i*B2(4,:); 
figure;
plot(abs(single));
figure;
plot(abs(array));

%%
len_each = 30*6;
num_round = floor(length(single)/len_each/64);
array_strength_round = zeros(64,num_round);
array_strength = zeros(64,1);
% round i
for i = 1:1:num_round
    % antenna j
    for j = 1:1:64
        temp = array((64*(i-1)+(j-1))*len_each+1:(64*(i-1)+(j))*len_each);
        array_strength_round(j,i) = mean(abs(temp));
    end
end
array_strength = mean(array_strength_round,2);
figure;
% heatmap(1:8, 1:8, reshape(array_strength,8,8));
pcolor(1:8,1:8,reshape(array_strength,8,8))
colormap(jet)
colorbar


