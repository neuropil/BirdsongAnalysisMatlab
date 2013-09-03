function dev = mnabsdev(x,y)
% dev = rmsdev(x,y)
% find root mean squared deviation of two matrices
% x and y must be same size

dev = (sum(sum(abs(x-y))));