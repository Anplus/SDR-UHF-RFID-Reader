clc;clear;close all;
%%
path = '../../data/move/';
addpath(path);
file_path =  path;  
data_path_list = dir(strcat(file_path, '*.bin')); 
data_num = length(data_path_list);   
file_list = cell(data_num, 1);
phase_array = [];
%%
if data_num > 0 
    for j = 1:data_num 
        data_name = data_path_list(j).name;
        fprintf('file %s\n', strcat(file_path,data_name));
        file_list{j} = data_name;
        phase_array = [phase_array,rn16_array(data_name)];
    end
end
figure;
plot(phase_array(36,:));
figure;
plot(phase_array(36,:)-phase_array(60,:))