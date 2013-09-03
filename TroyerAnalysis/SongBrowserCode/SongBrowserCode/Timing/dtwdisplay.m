function dtwdisplay(temp,exemp,M,warp,range,dt,freqs,varargin)
% dtwdisplay(temp,exemp,M,warp,range,dt)
% display outcome of DTW.  Assume M is distance matrix for template and
% exemplar

%% set defaults
params.scaled = 1;
params = parse_pv_pairs(params,varargin);

warpcolor = 'g';
warplinewidth = 2;
fontsize = 10;
labelfontsize = 12;

%% matrix and warping
dtwaxis = axes('position',[.35 .35 .55 .55]);
hold on
imagesc(dt*(.5:size(temp,2)),dt*(.5:size(exemp,2)),M);
set(dtwaxis,'ydir','normal')
axis('tight')
p = plot(dt*(range(1)-.5:range(2)),dt*warp(range(1):range(2)));
    set(p,'color',warpcolor,'linewidth',warplinewidth);
set(dtwaxis,'xtick',[],'ytick',[])

%% plot template and exemplar
tempaxis = axes('position',[.35 .1 .55 .225]);
if min(size(temp))==1
    plot(dt*(.5:size(temp,2)),temp);
else
    imagesc(dt*(.5:size(temp,2)),freqs,temp);
end
set(tempaxis,'yaxislocation','right')
set(tempaxis,'ydir','normal','xdir','normal')
ylabel('kHz','fontsize',labelfontsize);
xlabel('Template time (msec)','fontsize',labelfontsize);

exempaxis = axes('position',[.1 .35 .225 .55]);
if min(size(exemp))==1
    plot(exemp,dt*(.5:size(exmp,2)));
else
    imagesc(freqs,dt*(.5:size(exemp,2)),exemp');
end
set(exempaxis,'xaxislocation','top','xdir','reverse')
xlabel('kHz','fontsize',labelfontsize);
set(exempaxis,'ydir','normal')
ylabel('Exemplar time (msec)','fontsize',labelfontsize);