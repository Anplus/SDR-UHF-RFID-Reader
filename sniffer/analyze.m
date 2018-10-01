clc;clear;close all;
path = '../../data/signal-source-cw-move/continue/left-right/';
file_path =  path;  
img_path_list = dir(strcat(file_path, '*.bin')); 
img_num = length(img_path_list);   
file_list = cell(img_num, 1);
phase_array = [];
if img_num > 0 
    for j = 1:img_num 
        image_name = img_path_list(j).name;
        fprintf('file %s\n', strcat(file_path,image_name));
        file_list{j} = image_name;
        phase_array = [phase_array,cw_array(image_name)];
    end
end
figure;
plot(phase_array(60,:));