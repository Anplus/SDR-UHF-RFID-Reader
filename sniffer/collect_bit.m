function [oneset,zeroset] = collect_bit(rise_edge,down_edge)
oneset = [];
zeroset = [];
% start from above cw
if (rise_edge(1)<down_edge(1))
    for i = 1:1:min(length(rise_edge),length(down_edge))
        oneset = [oneset,rise_edge(i),down_edge(i)];
        zeroset = [zeroset,down_edge(i),rise_edge(i)];
    end
else
    for i = 1:1:min(length(rise_edge),length(down_edge))
        oneset = [oneset,down_edge(i),rise_edge(i)];
        zeroset = [zeroset,rise_edge(i),down_edge(i)];
    end
end

end