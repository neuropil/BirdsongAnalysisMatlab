function [templates] = calcalltemplates(varargin)
% [templates] = calcalltemplates(varargin)
% create an averaged template for cagtegories in .lbl file
% 

caltmpl.lblpath = ''; 
caltmpl.lblfile = '';
caltmpl.cats = '';
caltmpl.mtchparams = defaultmtchparams;
caltmpl.iterations = 1; % number of cycles of aligning and averaging
caltmpl.display = 1;
caltmpl.prompt = 1;
caltmpl.makelabelkey=0;
caltmpl = parse_pv_pairs(caltmpl,varargin);

temps = [];

%% get filename and load lbl and clips
if ~exist(fullfile(caltmpl.lblpath,caltmpl.lblfile))
    [caltmpl.lblfile caltmpl.lblpath] = uigetfile({'*.lbl;*.mlbl','label file (*.lbl;*.mlbl)'; '*.*',  'All Files (*.*)'}, 'Select label file');
    if caltmpl.lblfile ==0 return; end
end
load(fullfile(caltmpl.lblpath,caltmpl.lblfile),'labels','-mat');
[name caltmpl.lblpath] = getdirname(caltmpl.lblpath);
clippath = caltmpl.lblpath;
if ~(exist(fullfile(clippath,labels.clipfile))==2)
    [labels.clipfile clippath] = uigetfile({'*.dbk;*.bmk','bookmark files (*.dbk;*.bmk)'; '*.*',  'All Files (*.*)'}, 'Select bookmark file with clip info.');
    if labels.clipfile==0; return; end
end
% make label key if needed
if length(labels.labelkey)~=length(unique([labels.a.label]))
    caltmpl.makelabelkey = 1;
end
if caltmpl.makelabelkey
    labels = makelabelkey(labels);
    save(fullfile(caltmpl.lblpath,caltmpl.lblfile),'labels','-append','-mat');
end
    
% load(fixseps(fullfile([caltmpl.rootdir filesep striproot(labels.clippath)],labels.clipfile)),'clips','-mat');
load(fullfile(clippath,labels.clipfile),'clips','-mat');

%% initialize data
catnum = length(labels.labelkey);
tmpl = cell(catnum,1);
offsets = cell(catnum,1);

% initialize variables
tmpl = cell(catnum,1);
tmploffsets = cell(catnum,1);
tmplmatches = cell(catnum,1);
tmplN = zeros(catnum,1);
clipinds = cell(catnum,1);
speclengths = cell(catnum,1);

% get list of category indices
if isempty(caltmpl.cats)
    catinds = 1:length(labels.labelkey);
elseif iscell(caltmpl.cats)
    catinds = findlabelind(caltmpl.cats,labels);
else
    catinds = caltmpl.cats;
end

[path name ext] = fileparts(labels.clipfile);
%% load parameters
specpath = [caltmpl.lblpath filesep name '_spec'];
if ~exist(specpath)
    specpath = uigetdir('Load spec directory','Load spec directory');
    if specpath==0 return; end
end
load(fullfile(specpath,'specparams.mat'));

%% calucate templates
wb = waitbar(0,'Calculating templates');
for i=catinds
    clipinds{i} = find([labels.a.labelind] == i);
    if isempty(clipinds{i})
        disp(['No clips in category ' num2str(i) '.'])
    else
        specarr = cell(length(clipinds{i}),1);
        speclengths{i} = zeros(length(clipinds{i}),1);
        labelstr = makelabelstr(labels.labelkey(i),labels.label2key(i),labels.label3key{i});
        wb2 = waitbar(0,['Loading specs for category ' labelstr ' (n= ' num2str(length(clipinds{i})) ').']);
        for j=1:length(clipinds{i} )
%             load(fullfile([caltmpl.rootdir striproot(caltmpl.lblpath) filesep name '_spec'],[name '_spec_' num2str(clipinds{i}(j)) '.mat']));
            load(fullfile(specpath,[name '_spec_' num2str(clipinds{i}(j)) '.mat']));
    %         load(fullfile([caltmpl.lblpath name '_spec'],[name '_' num2str(clipinds{i}(j))]));
            specarr{j} = spec(:,edges(1):edges(2));
            speclengths{i}(j) = size(spec,2);
            waitbar(j/length(clipinds{i}),wb2); 
        end
        close(wb2)

        %% calculate templates
        [tmpspec  tmpoff tmpmatch] = avgslidespec(specarr,'iterations',caltmpl.iterations,'mtchparams',caltmpl.mtchparams);
        tmpl{i} = tmpspec;
        tmploffsets{i} = tmpoff;
        tmplmatches{i} = tmpmatch;
        tmplN(i) = length(specarr);
    end
    waitbar(i/catnum,wb); 
end
close(wb)
   
%% save templates
temps.clipinds = clipinds;
temps.tmpl = tmpl;
temps.tmploffsets = tmploffsets;
temps.tmplmatches = tmplmatches;
temps.speclengths = speclengths;
temps.tmplN = tmplN;
temps.specparams = specparams;
temps.f = specparams.f;
temps.labelkey = labels.labelkey;
temps.label2key = labels.label2key;
temps.label3key = labels.label3key;

if caltmpl.prompt
    ans=questdlg(['Save templates to ' caltmpl.lblfile '?'],'Save templates?','Yes','No','No');
else
    ans = 'Yes';
end
if strcmpi(ans, 'Yes') 
    save(fullfile(caltmpl.lblpath,caltmpl.lblfile),'temps','-append','-mat'); 
end

if caltmpl.display
    templatedisplay('filename',caltmpl.lblfile,'pathname',caltmpl.lblpath);
end


