function output = rfid_crc16(input)
%% crc16 for GEN2
crc = [1,1,1,1,...
        1,1,1,1,...
        1,1,1,1,...
        1,1,1,1];
for i = 1:1:length(input)
    temp = [0,0,0,0,...
            0,0,0,0,...
            0,0,0,0,...
            0,0,0,0];
    temp(2) = crc(1);
    temp(3) = crc(2);
    temp(4) = crc(3);
    temp(5) = crc(4);
    temp(6) = crc(5);
    temp(7) = crc(6);
    temp(8) = crc(7);
    temp(9) = crc(8);
    temp(10) = crc(9);
    temp(11) = crc(10);
    temp(12) = crc(11);
    temp(13) = crc(12);
    temp(14) = crc(13);
    temp(15) = crc(14);
    temp(16) = crc(15);
    if crc(16) == input(i)
        temp(1) = 0;
        if crc(5) == 0
            temp(6) = 0;
        else
            temp(6) = 1;
        end
        if crc(12) == 0
            temp(13) = 0;
        else
            temp(13) = 1;
        end
    else
        temp(1) = 1;
        if crc(5) == 1
            temp(6) = 0;
        else
            temp(6) = 1;
        end
        if crc(12) == 1
            temp(13) = 0;
        else
            temp(13) = 1;
        end
    end
    crc = temp;
end
output = [input,~crc(end:-1:1)];
end