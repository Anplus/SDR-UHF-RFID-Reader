function [] = write_file(input)
%%
input = uint8(input);
file = fopen('../send.bin','wb'); 
fwrite(file,input,'uchar');
%%
fclose(file);
end