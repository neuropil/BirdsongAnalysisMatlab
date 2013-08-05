%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study on the sequence recovery              %
% Calculate the K-L distance for each feature %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
load Data;
load clustered_data;

feature = {'Pitch', 'FM', 'Entropy', 'Pitch Goodenss'};
f = 4;      % 2: Pitch, 3: FM, 4: Entropy, 5: Pitch Goodness
n = 4;      % number of clusters 

%%% label each note in day 1 %%%
u = x{1}(:,1);  % Duration
v = x{1}(:,f);  % one feature

in = zeros(size(x{1},1),1);
% 1: note A; 2: note B; 3: note C; 4: note D; 0: noise or call
for i = 1:n
    in = in + i*inpolygon(u,v,up{i},vp{i});
end

%%% plot the clutered scatterplot %%%%
figure(1);
color = 'brgm';
subplot(3,1,[1 2]);
plot(u(in==0),v(in==0), 'k.'); hold on;
for i = 1:n
    plot(up{i},vp{i}, [color(i) '--'], u(in==i),v(in==i), [color(i) '.']);
    xlabel('Duration (ms)', 'fontsize', 12);
    ylabel(sprintf('%s', feature{f-1}), 'fontsize', 12);   
    title('Labeled Clusters', 'fontsize', 14);
    axis tight;
    axis([10 210 -4.5 -0.9]);
    set(gca, 'ytick', -4:-1);
end

%%% calculate probability for each sequence %%%
% prepare labels for sequence analysis
bin1 = 0:n;
sbin1 = {'n', 'a', 'b', 'c', 'd'};
bin2 = [];
for i = 0:n
    bin2 = [bin2 10*i+(0:n)];
end
sbin2 = [];
for i = 0:n
    for j = 0:n
        sbin2{(n+1)*i+j+1} = [sbin1{i+1} sbin1{j+1}];
    end
end      

p1 = histc(in, bin1);
p1 = p1/sum(p1);    % probability of each cluster    
in2 = in(1:end-1)*10 + in(2:end);
in2(diff(x{1}(:,6)) ~= 0) = [];    % remove the boundary points
p2 = histc(in2, bin2);
p2 = p2/sum(p2);    % probability of each sequence 

%%% label each note for day 2 to day 12 %%%
M = length(x);      % number of sessions (before and after surgery)
for k = 1:M-1
    in = zeros(size(x{k+1},1),1);
    for i = 1:n
        in = in + i*inpolygon(x{k+1}(:,1),x{k+1}(:,f),up{i},vp{i});
    end   
    p1(:,k+1) = histc(in, bin1);
    p1(:,k+1) = p1(:,k+1)/sum(p1(:,k+1));       % probability of each cluster   
    in2 = in(1:end-1)*10 + in(2:end);
    in2(diff(x{k+1}(:,6)) ~= 0) = [];           % remove the boundry points    
    p2(:,k+1) = histc(in2, bin2);
    p2(:,k+1) = p2(:,k+1)/sum(p2(:,k+1));       % probability of each sequence 
end

%%% plot the selected sequencing distribution %%%
t = [1 4 8 12];
day = {'day 1', 'day 4', 'day 6', 'day 8'};
ind = find(max(p2(:,t),[],2) > 0.05);     % add low probability sequences together
p_new = p2(ind, :); 
p_new = [p_new; 1 - sum(p_new, 1)];  
for k = 1:4
    figure(2)
    subplot(4,1,k);
    bar(1:length(ind)+1, p_new(:,t(k)));  
    ylim([0 max(p2(:))+0.1]);
    xlim([0.5 length(ind)+1.5]); 
    set(gca, 'xtick', 0:length(ind), 'xticklabel', ' ');
    if k == 4
        set(gca, 'xtick', 1:length(ind)+1, 'xticklabel', [sbin2(ind) 'others'], 'fontsize', 12);
    end
    set(gca, 'ytick', [0 0.4], 'fontsize', 12);  
    text(length(ind)-1, 0.35, day{k}, 'fontsize', 14);
end

% remove the zero effect
p1 = p1+ 1e-6;  p1 = p1./(ones(size(p1,1),1)*sum(p1));
p2 = p2+ 1e-6;  p2 = p2./(ones(size(p2,1),1)*sum(p2)); 

%%% estimate the KL-distance of the notes recovery %%%
for k = 1:M
    E(1,k) = sum(p1(:,1).*log2(p1(:,1)+eps) - p1(:,1).*log2(p1(:,k)+eps));
    E(2,k) = sum(p2(:,1).*log2(p2(:,1)+eps) - p2(:,1).*log2(p2(:,k)+eps));
end
KL1 = E(1,:);   % K-L distance on discrete clusters
KL2 = E(2,:);   % K-L distance on sequences

%%% plot the K-L distance on sequence %%%
figure(3);
subplot(2,1,1);
plot(KL2, 'ko-', 'linewidth', 2);
axis([0.5 M+0.5 0 max(KL2+1)]); 
title('K-L distance on Sequence', 'fontsize', 12);
ylabel(sprintf('KL-distance from \n day 1 (bits)'), 'fontsize', 10);
xlabel('Session (day)', 'fontsize', 10);
set(gca,'xtick', 0:M); 

%%% calculate the recovery rate for clusters and sequences  %%%
nKL = E(:,4:end)./(E(:,4)*ones(1,M-3));
X = (0:M-4)';
Y = log(nKL)';
tau = -1./(inv(X'*X)*X'*Y);  % tau(1): clusters, tau(2): sequences



