function [] = movie_show(x,y)
figure;
h = animatedline;
numpoints = length(x);
x = linspace(0,4*pi,numpoints);
for k = 1:1:numpoints
    addpoints(h,x(k),y(k))
    drawnow update
end

end