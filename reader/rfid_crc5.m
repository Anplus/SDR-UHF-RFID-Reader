function output = rfid_crc5(input)
%% crc5 for GEN2
crc = [1,0,0,1,0];
for i = 1:1:17
    temp = [0,0,0,0,0];
    temp(5) = crc(4);
    if crc(5) == 1
        if input(i) == 1
            temp(1) = 0;
            temp(2) = crc(1);
            temp(3) = crc(2);
            temp(4) = crc(3);
        else
            temp(1) = 1;
            temp(2) = crc(1);
            temp(3) = crc(2);
            if crc(3) == 1
                temp(4) = 0;
            else
                temp(4) = 1;
            end
        end
    else
        if input(i) == 1
            temp(1) = 1;
            temp(2) = crc(1);
            temp(3) = crc(2);
            if crc(3) == 1
                temp(4) = 0;
            else
                temp(4) = 1;
            end
        else
            temp(1) = 0;
            temp(2) = crc(1);
            temp(3) = crc(2);
            temp(4) = crc(3);
        end 
    end
    crc = temp;
end
output = [input,crc(end:-1:1)];
end