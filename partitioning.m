%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% label the notes using the scatterplot in day 1 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
load Data;

f = 4;      % 2: Pitch, 3: FM, 4: Entropy, 5: Pitch Goodness

u = x{1}(:,1);  % Duration
v = x{1}(:,f);  % one feature

% 2D scatterplot of Duration vs. feature
figure(1)
feature = {'Pitch', 'FM', 'Entropy', 'Pitch Goodenss'};
plot(u, v,'.');     
xlabel('Duration (ms)', 'fontsize', 12);
ylabel(sprintf('%s', feature{f-1}), 'fontsize', 12);   
axis([10 210 -4.5 -0.9]);
set(gca, 'ytick', -4:-1);
title('Scatterplot', 'fontsize', 14);

% draw polygons for each cluster (see help on 'getline')
n = 4;      % number of clusters 
pause(0.1);
for i = 1:n
    [up{i}, vp{i}] = getline('closed');
end

% save the polygonal boundaries 
% save clustered_data up vp;     % remove the comment to save the result
