function [] = write_file(input,filename)
%%
re = input;
im = zeros(1,length(input));
file = fopen(filename,'wb'); 
fwrite(file,[re;im],'float');
%%
fclose(file);
end