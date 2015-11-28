% Analysis Plan

% List of Resources
% Optics DEBSCAN algorithm
% MFILES: 
% 1. optics_algorithm.m
% 2. dbscan.m 
% 3. dbscan2.m
% 4. estNeighborhoodRadius.m
% WEBSITES:
% 1. http://en.wikipedia.org/wiki/OPTICS_algorithm
% 2. http://en.wikipedia.org/wiki/Spanning_tree
% 3. https://github.com/alexgkendall/OPTICS_Clustering
% 4. http://chemometria.us.edu.pl/download/optics.py

% Bivariate Ellipse
% MFILES
% 1. bivariateEllipse.m
% 2. plsregress.m
% WEBSITES
% 1. http://www.mathworks.com/matlabcentral/fileexchange/37863-blended-3d-poly2mask
% 2. http://blogs.mathworks.com/steve/2015/04/03/displaying-a-color-gamut-surface/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+SteveOnImageProcessing+%28Steve+on+Image+Processing%29
% 3. http://www.mathworks.com/help/matlab/ref/boundary.html
% 4. http://www.mathworks.com/help/stats/plsregress.html
% 5. https://imdevsoftware.wordpress.com/



% 1. Create directory for test animal (i.e. 904)

testFold = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\914';

cd(testFold)

%%

% 2. Calculate parameters of song space
load('914_PreALL.mat')

%%

Xmin = quantile(PreMetaSet.syldur,0.001);
Ymin = quantile(PreMetaSet.Mpitch,0.001);
Xmax = quantile(PreMetaSet.syldur,0.999);
Ymax = quantile(PreMetaSet.Mpitch,0.999);

plot(PreMetaSet.syldur,PreMetaSet.Mpitch,'.');
xlim([Xmin Xmax]);
ylim([Ymin Ymax]);


%% 

% 3. Normalize

% dataSet = [PreMetaSet.syldur,PreMetaSet.Mamp, PreMetaSet.Mpitch, PreMetaSet.MFM, PreMetaSet.Mentropy, PreMetaSet.MpitchG];

dataSet = [PreMetaSet.syldur, PreMetaSet.Mpitch, PreMetaSet.Mentropy, PreMetaSet.MpitchG];

ndataset = zeros(size(dataSet));

for di = 1:size(dataSet,2)
    
    tempCol = dataSet(:,di);
    
    % val - min(x) / max(x) - min(x)
    ndataset(:,di) = (tempCol - min(tempCol)) / (max(tempCol) - min(tempCol));
    
end


%%

% 4. PCA

[coeff,score,latent] = pca(ndataset);

pc1 = score(:,1);
pc2 = score(:,2);
pc3 = score(:,3);

%%
figure;

scatter3(pc1,pc2,pc3,'.')
scatter(pc1,pc2)

% ROWS are consistent with observations - COLUMNS are relatively
% meaningless besides ordered by variance explained.


%%
randSel = randperm(length(pc1),round(length(pc1)*0.15));

testDB3 = [pc1(randSel),pc2(randSel),pc3(randSel)];
testDB2 = [pc1(randSel),pc2(randSel)];

testDB2eq = zeros(length(testDB2),length(testDB2));
for i = 1:length(testDB2)
    ob = testDB2(i,:);
    testDB2eq(:,i) =  transpose(eqdist(ob(1:2),testDB2(:,1:2)));
    
end

%%
opts = statset('Display','final');
[idx,C] = kmeans(testDB2,4,'Distance','cityblock',...
    'Replicates',5,'Options',opts);
figure;

colors = 'rbgc';
for i = 1:max(idx)
plot(testDB2(idx==i,1),testDB2(idx==i,2),strcat(colors(i),'.'),'MarkerSize',3)

hold on
end
plot(C(:,1),C(:,2),'kx',...
     'MarkerSize',15,'LineWidth',3)
title 'Cluster Assignments and Centroids'
hold off

%%
x = testDB2;
y = C;
[n,d]=knnsearch(x,y,'k',550,'distance','minkowski','p',5);
[ncb,dcb] = knnsearch(x,y,'k',550,'distance','chebychev');

%%

gscatter(x(:,1),x(:,2))
line(y(:,1),y(:,2),'marker','x','color','k',...
   'markersize',10,'linewidth',2,'linestyle','none')
line(x(n,1),x(n,2),'color',[.5 .5 .5],'marker','o',...
   'linestyle','none','markersize',10)
line(x(ncb,1),x(ncb,2),'color',[.5 .5 .5],'marker','p',...
   'linestyle','none','markersize',10)
legend('setosa','versicolor','virginica','query point',...
'minkowski','chebychev','Location','best')



%%
aveEq = mean(testDB2eq);
sEq = sort(aveEq);

plot(sEq)

%%

figure;

scatter3(pc1(randSel),pc2(randSel),pc3(randSel),'.')
scatter(pc1(randSel),pc2(randSel),'.')

%%


[class,type]=dbscanChrom(testDB,2,0.001);

% Double check if these clusters make sense!!!

% ADD 3D polygon from Steve Image Guy's blog

%
C = max(class);
ptID = class;
cla
% plot(ds(:,1),ds(:,2),'.')

colorMap = colormap(jet);
cSteps = round(linspace(1,64,C));
colorS = colorMap(cSteps,:);


% r = 1;
% b = 0.2;
% g = 0.1;
cCount = zeros(C,1);

for i = 1:C
   
    hold on
    scatter3(testDB(ptID == i,1),testDB(ptID == i,2),testDB(ptID == i,3),10,colorS(i,:))
%     
%     r = r - 0.075;
%     b = b + 0.05;
%     g = g + 0.05;
    
    cCount(i) = sum(ptID == i);
    
    
    
end


%%

[class,type]=dbscanChrom(testDB2,4,0.00004);
cla
max(class)
C = max(class);
ptID = class;
colorMap = colormap(jet);
cSteps = round(linspace(1,64,C));
colorS = colorMap(cSteps,:);


% r = 1;
% b = 0.2;
% g = 0.1;
cCount = zeros(C,1);

for i = 1:C
   
    hold on
    scatter(testDB2(ptID == i,1),testDB2(ptID == i,2),5,colorS(i,:))
%     
%     r = r - 0.075;
%     b = b + 0.05;
%     g = g + 0.05;

    
    
    
end

%%

% 5. From aggregate plot use Optic algorthim to differentiate note
% boundaries

% Test parameters of debscan2

load('914_Pre_0313.mat')

plot(songDataset.syldur, songDataset.Mpitch,'.')

testDB = [songDataset.syldur, songDataset.Mpitch];

%%

addpath('C:\Users\Dr. JT\Desktop\Thompson_2016_BirdsongAnalysis')

%%
cla

[class,type]=dbscan2(testDB,12,[]);

unique(class)

colSteps = 1:round(64/11):64;
jetCol = jet;

indexClus = class';
for i = 1:max(unique(class))
    
    indBool = indexClus == i;
    
    baseCol = jetCol(colSteps(i),:);
    
    plot(testDB(indBool,1),testDB(indBool,2),'.','Color',baseCol)
    
    hold on
    
    
end



























