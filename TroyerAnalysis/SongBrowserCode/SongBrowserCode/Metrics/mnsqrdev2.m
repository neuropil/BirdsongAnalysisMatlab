function devs = mnsqrdev2(x,y)
% devs = mnsqrdev2(x,y)
% find mean squared deviation of vector x with columns of matrix y
% results are vector of length the number of column of y

x = x(:)*ones(1,size(y,2));
devs = sum((x-y).^2);