function signal_tag_preamble = gen_tag_fm0_preamble(samples_per_us)
% BLF = 40Khz, Tpri = 25us
Tpri = 25;
tag_preamble_code = [1,0,1,0,2,1];
signal_tag_preamble = [];
flag = 0;
for i = 1:length(tag_preamble_code)
    if(tag_preamble_code(i) == 1)
        if (flag == 0)
            signal_tag_preamble = [signal_tag_preamble,ones(1,Tpri*samples_per_us)];
            flag = 1;
        else
            signal_tag_preamble = [signal_tag_preamble,zeros(1,Tpri*samples_per_us)];
            flag = 0;
        end
    elseif (tag_preamble_code(i) == 0)
        if (flag == 0)
            signal_tag_preamble = [signal_tag_preamble,ones(1,floor(Tpri/2*samples_per_us)),zeros(1,floor(Tpri/2*samples_per_us))];
            flag = 0;
        else
            signal_tag_preamble = [signal_tag_preamble,zeros(1,floor(Tpri/2*samples_per_us)),ones(1,floor(Tpri/2*samples_per_us))];
            flag = 1;
        end
    elseif (tag_preamble_code(i) == 2)
        % violation
        if (flag == 0)
            signal_tag_preamble = [signal_tag_preamble,zeros(1,(Tpri)*(samples_per_us))];
            flag = 0;
        else
            signal_tag_preamble = [signal_tag_preamble,ones(1,(Tpri)*(samples_per_us))];
            flag = 1;
        end
    end
end
signal_tag_preamble = signal_tag_preamble';
end