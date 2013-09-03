function  calcftrslice(varargin)
% calcftrslice(varargin)
% also calculate amplitude, mean and std freq, and entropy

calftrsl.specpath = [];
calftrsl.ftrlist = {'amp','entropy','Wentropy','freqmean','freqstd','FFgood','ampdiff'};
calftrsl.freqrange = [.7 7];
calftrsl = parse_pv_pairs(calftrsl,varargin);

% make directory to save features into and save ftrlist
if ~exist(calftrsl.specpath,'dir')
    calftrsl.specpath = uigetdir('Get spectrogram directory','Get spectrogram directory');
end
load(fullfile(calftrsl.specpath,'specparams.mat'),'specparams');
load(fullfile(calftrsl.specpath,'speclens.mat'),'speclens');

% make _ftrs directory if needed
if ~exist([calftrsl.specpath(1:end-4) 'ftrs'],'dir')
    mkdir([calftrsl.specpath(1:end-4) 'ftrs']);
end
ftrpath = [calftrsl.specpath(1:end-4) 'ftrs'];
[upper name ext] = fileparts(ftrpath);
name = name(1:end-5);

sliceftrlist = calftrsl.ftrlist;
freqrange = calftrsl.freqrange;

wb = waitbar(0,'Calculating feature values');
% set directory if local
for i=1:length(speclens)
    load(fullfile(calftrsl.specpath,[name '_spec_' num2str(i) '.mat']),'-mat');
    sliceftrs = zeros(size(spec,2),length(sliceftrlist));
    for j=1:length(sliceftrlist)
        switch sliceftrlist{j}
            case {'amp'}
                sliceftrs(:,j) = amp;
            case {'ampdiff'}
                sliceftrs(:,j) = amp-amp2;
            case {'entropy','Wentropy','freqmean','freqstd'}
                sliceftrs(:,j) = eval(['ftr_' calftrsl.ftrlist{j} '(abs(spec),f,''freqrange'',calftrsl.freqrange);'])';
            case {'FFgood'}
                [tmp sliceftrs(:,j)] = ftr_cepsFF(abs(spec),f,'freqrange',calftrsl.freqrange);
            otherwise
                disp(['No specification to calculate feature ' calftrsl.ftrlist{j} '. Skipping.']);
        end
    end
    save(fullfile(ftrpath,[name '_ftr_' num2str(i) '.mat']),'sliceftrs','sliceftrlist','specparams','freqrange','-mat');
    waitbar(i/length(speclens),wb); 
end

if ishandle(wb) close(wb); end

        
    
    

    
    