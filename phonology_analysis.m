%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study on the phonology recovery             %
% Calculate the K-L distance for each feature %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
load Data;
    
%%% set the discretization lines %%%
M = length(data_info);
x_all = [];
for k = 1:M
    x_all = [x_all; x{k}];   % add all data together
end

l_edge = min(x_all) - eps;
u_edge = max(x_all) + eps;

N = size(x_all, 2) - 1;    % remove the last column which indicates bout numbers
NumG = 16;                 % NumG - 1 is the number of bins in each coordinate
for n = 1:N
    Edges{n} = linspace(l_edge(n), u_edge(n), NumG);
    Edges{n}(end) = Edges{n}(end) + 1e-10;      % inlcude the boundary points
end 

%%% calculate the probability in each bin %%%
for n = 1:N-1
    edges{1} = Edges{1};
    edges{2} = Edges{n+1};
    for k = 1:M
        temp = hist3(x{k}(:, [1 n+1]),'Edges', edges);
        p(:,:,k,n) = temp(1:end-1,1:end-1);    % remove the artifact in the command
        p(:,:,k,n) = p(:,:,k,n)/sum(sum(p(:,:,k,n)));       % normalization
    end
end   

% avoid zero probability (because zero is sensitive in K-L calculations)
for n = 1:N-1
    for k = 1:M
        p(:,:,k,n) = (p(:,:,k,n)+1e-6)/sum(sum(p(:,:,k,n)+1e-6)); 
    end
end

%%% estimate the K-L distance from day 1 for each feature %%%
for n = 1:N-1
    E(1,n) = sum(sum(p(:,:,1,n).*log2(p(:,:,1,n)+eps)));
    for k = 2:M
        E(k,n) = sum(sum(p(:,:,1,n).*log2(p(:,:,k,n)+eps)));
    end
end
KL = ones(M,1)*E(1,:)-E;

%%% plot the K-L distance %%%
figure(1)
feature = {'Pitch', 'FM', 'Entropy', 'Pitch Goodenss'};
for n = 1:N-1
    subplot(2,2,n);
    plot(KL(:,n), 'o-');
    xlim([0.8 M+.2]); 
    title(sprintf('Duration and %s', feature{n}), 'fontsize', 11);
    ylabel(sprintf('KL-distance \n from day 1 (bits)'), 'fontsize', 10);
    if n > 2
        xlabel('session (day)');
    end
end

%%% estimate the recovery rate %%%
nKL = KL(4:M,:)./(ones(M-3,1)*KL(4,:));  % normalized K-L distances in the recovery part

X = (0:M-4)';
Y = log(nKL);
tau = -1./(inv(X'*X)*X'*Y);     % tau: recovery rate 

%%% plot the recovery rate %%%
figure(2)
d = 0:M-4;
y = exp(-(ones(N-1,1)*d)./(tau'*ones(1,M-3)));
for n = 1:N-1
    subplot(2,2,n);
    plot(4:M, nKL(:,n), 'ko--','linewidth', 2); 
    hold on;
    plot(4:M, y(n,:), 'r-','linewidth', 2); 
    ylabel(sprintf('Nomalized \n K-L distance (a.u.)'), 'fontsize', 10);
    title(sprintf('Duration and %s', feature{n}), 'fontsize', 11);
    if n > 2
        xlabel('session (day)');
    end
    legend('KL', 'fitted');
end



