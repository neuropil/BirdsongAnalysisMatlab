function figh = templatedisplay(varargin)
% figh = templatedisplay(varargin)
% display set of templates loaded from temp file

tmpl.pathname = '';
tmpl.filename = '';
tmpl.dispgap = 150; % gap between displayed templates in msec
tmpl.strgap = .3; % gap for strings as fraction of entire vertical space for display
tmpl.fontsize = 12; 
tmpl.type = 'spec'; % alternative is 'ceps' or 'cepstrum' or 'both'
tmpl.figh = ''; % flags whether to generate new figure
tmpl = parse_pv_pairs(tmpl,varargin);


%% load templates
if ~exist(fullfile(tmpl.pathname,tmpl.filename))
    [tmpl.filename tmpl.pathname] = uigetfile({'*.lbl;*.mlbl','label files (*.lbl;.mlbl)'; '*.*',  'All Files (*.*)'}, 'Select label file with templates (.lbl)');
    if tmpl.filename==0; return; end
end
load(fullfile(tmpl.pathname,tmpl.filename),'-mat');
f = temps.f;

fmax = max(f); 
if ishandle(tmpl.figh)
    figh = figure(tmpl.figh);
else
    figh = figure;
end
cla; hold on
if ~isempty(temps.tmpl)
    xloc = tmpl.dispgap/2;
    for i=1:length(temps.tmpl)
        tbins = size(temps.tmpl{i},2);
        imagesc(xloc+temps.specparams.dt*(1:tbins)',tmpl.strgap+(1-tmpl.strgap)*f/fmax,log(max(temps.specparams.specfloor,abs(temps.tmpl{i}))));
        str = [num2str(i) '.' makelabelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i})];
        tt = text(xloc+temps.specparams.dt*tbins/2,3*tmpl.strgap/4,str);
            set(tt,'verticalalignment','middle','horizontalalignment','center');
        if isfield(temps,'tmplN')
            if temps.tmplN(i)>0
%                 tt = text(xloc+labels.specparams.dt*tbins/2,tmpl.strgap/4,[num2str(i) ':' num2str(templatesN(i))]);
                tt = text(xloc+temps.specparams.dt*tbins/2,tmpl.strgap/4,[num2str(temps.tmplN(i))]);
                    set(tt,'verticalalignment','middle','horizontalalignment','center');
            end
        end
        xloc = xloc+temps.specparams.dt*tbins+tmpl.dispgap;
    end
end
% if ~isempty(temps.cepstmpl{1})
%     xloc = tmpl.dispgap/2;
%     for i=1:length(temps.cepstmpl)
%         tbins = size(temps.cepstmpl{i},2);
%         imagesc(xloc+temps.specparams.dt*(1:tbins),-1+tmpl.strgap+f/(fmax*(1-tmpl.strgap)),temps.cepstmpl{i});
%         xloc = xloc+temps.specparams.dt*tbins+tmpl.dispgap;
%     end
% end
set(gca,'xlim',[0 xloc-tmpl.dispgap/2]);
% if isempty(temps.cepstmpl{1})
    set(gca,'ylim',[0 1]);
% else
%     set(gca,'ylim',[-1 1]);
% end    
title(tmpl.filename);
set(gca,'ydir','normal');
set(gca,'ytick',[]);

        
    