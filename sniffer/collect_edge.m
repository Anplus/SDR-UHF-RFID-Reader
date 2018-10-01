function output = collect_edge(input,taps)
len = length(input);
output = [input(1)];
for i = 2:1:len
    if(input(i)>output(end)+taps)
        output = [output, input(i)];
    end
end
end