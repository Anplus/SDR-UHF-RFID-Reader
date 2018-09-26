clc;clear;close all;
%% file
fid = fopen('../../data/20180926175027_2ch.bin','rb');
[B2,Count] = fread(fid,[4,6000000],'double');
fclose(fid);

%% data
array = B2(1,:)+1i*B2(2,:);
single = B2(3,:)+1i*B2(4,:); 
figure;
plot(abs(single));
figure;
plot(abs(array));