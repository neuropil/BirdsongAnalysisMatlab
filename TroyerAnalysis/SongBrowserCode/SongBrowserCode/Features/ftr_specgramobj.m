function specgram = ftr_specgramobj(varargin)
% specgram = ftr_specgramobj(varargin) makes a structure for calculating
%  and displaying a spectrogram

%  Created by Todd 3/4/08
%    Edits: 

% STANDARD FIELDS
specgram.tag = 'specgram';
specgram.calcFcn = @calcFcn;
specgram.dispFcn = @dispFcn;
specgram.p = []; % parameters
specgram.pwin = []; % parameter window
specgram.d=[]; 
specgram.dispopt = {'ImageSc','SpecDiff','Peaks','TempDiff','TimeSlice','TimeSliceLog'};
specgram.h = [];
specgram.starttime=0; 
specgram.xvals=[]; 
specgram.yvals=[]; 
% SPECGRAM SPECIFIC FIELDS
% specgram.zeroinds=[];  % indices  with zero entries in specgram
specgram.windowN=256; 
specgram.window=hanning(specgram.windowN); 
specgram.Nadv=[]; 
specgram.specfloor=.05; 
specgram.windowfrac=.25; 
specgram.fs = 24414.0625;

specgram = parse_pv_pairs(specgram,varargin);

% set advance to be window frac by default
if ~isempty(specgram.Nadv)
    specgram.windowfrac = specgram.Nadv/specgram.windowN;
else
    if isempty(specgram.windowfrac)
        specgram.Nadv = round(specgram.windowN*specgram.windowfrac);
    else
        specgram.windowfrac = .25;
        specgram.Nadv = round(specgram.windowN*specgram.windowfrac);
    end    
end
    
%Set parameters    
%     % WindowN
%     ind = ParamObj('ParamStyle','Integer','Tag',[specgram.Tag '_WindowN'],'Parent',specgram.SBIndex,...
%                 'FieldName','WindowN','TagString','Window Size','Value',specgram.WindowN,...
%                 'Max',2048,'Min',128,'StepSize',16);%,'PostCallback',specgram.ReCalculate
%     specgram.Params = [specgram.Params ind];
%     % NAdvance
%     ind = ParamObj('ParamStyle','Integer','Tag',[specgram.Tag '_NAdvance'],'Parent',specgram.SBIndex,...
%                 'FieldName','NAdvance','TagString','NAdvance','Value',specgram.NAdvance,...
%                 'Max',2048,'Min',0,'StepSize',8);%,'PostCallback',specgram.ReCalculate
%     specgram.Params = [specgram.Params ind];
%     % AmpCutOff
%     ind = ParamObj('ParamStyle','Scalar','Tag',[specgram.Tag '_AmpCutoff'],'Parent',specgram.SBIndex,...
%                 'FieldName','AmpCutoff','TagString','AmpCutoff','Value',specgram.AmpCutoff,...
%                 'Max',1,'Min',0,'StepSize',.001);%,'PostCallback',specgram.ReCalculate
%     specgram.Params = [specgram.Params ind];
    
%-----------------------------------------------------------------------
function specgram = calcFcn(song,specgram,varargin)
% specgram = calcFcn(song,specgram,varargin)  function for calculating 
% [spec f t] = spectrogram(signal,window,nooverlap,nfft,fs)

specgram.fs = song.a.fs;
if min(size(song.d))==1
    song.a.chan = 1;
end
[spec, f, t] = spectrogram(song.d(:,song.a.chan),specgram.window,...
    specgram.windowN-specgram.Nadv,specgram.windowN,specgram.fs);
specgram.d = abs(spec);
specgram.xvals = specgram.starttime*[1 0 1]+1000*[t(1) diff(t(1:2)) t(end)];
specgram.yvals = [f(1) diff(f(1:2)) f(end)]/1000;

%-----------------------------------------------------------------------
function h = dispFcn(specgram,varargin)
% dispFcn(specgram,dispopt,varargin) display Spectrogram

h = [];
opt.dispopt = 'imagesc';
opt = parse_pv_pairs(opt,varargin);

if isempty(specgram.d); return; end
% set dispopt if not already done or if only have mono data

x = specgram.xvals(1):specgram.xvals(2):specgram.xvals(3);
y = specgram.yvals(1):specgram.yvals(2):specgram.yvals(3);
switch lower(opt.dispopt)
    case {' ','imagesc'}
        h = imagesc(x,y,log10(specgram.d.^2+specgram.specfloor));
%     case 'specdiff'
%         h = imagesc(specgram.xVals(1):specgram.xVals(3):specgram.xVals(2),...
%             (specgram.yVals(1):specgram.yVals(3):(specgram.yVals(2)-specgram.yVals(3)))-specgram.yVals(3)/2,...
%             diff(log10(max(specgram.Data{1},specgram.AmpCutoff))));
%     case 'tempdiff'
%         tmp = log10(max(specgram.Data{1},specgram.AmpCutoff));
%         tmpdiff = diff(tmp');
%         h = imagesc((specgram.xVals(1)+specgram.xVals(3)/2):specgram.xVals(3):(specgram.xVals(2)-specgram.xVals(3)/2),...
%             specgram.yVals(1):specgram.yVals(3):specgram.yVals(2),...
%             tmpdiff');
%     case 'peaks'
%         [peaks, peakvals] = FindPeaks(specgram.Data{1},specgram.yVals(1):specgram.yVals(3):specgram.yVals(2));
%         xvals = specgram.xVals(1):specgram.xVals(3):specgram.xVals(2);
%         dx = specgram.xVals(3);
%         for i=1:length(peaks)
%             maxpeaks = max(peakvals{i});
%             if maxpeaks>0;
%                 tmppeaks = peaks{i}(peakvals{i}>.05*maxpeaks);
%                 plot((xvals(i)+dx*[.5; -.5])*ones(1,length(tmppeaks)),[1; 1]*tmppeaks','b');
%             end
%         end
    case 'timeslice'
        range = varargin{1};
        xvals = specgram.xvals(1):specgram.xvals(2):specgram.xvals(3);
        inds = find(xvals>=range(1) & xvals<=range(2));
        if ~isempty(inds)
            h = plot(specgram.d(:,inds),specgram.yvals(1):specgram.yvals(2):specgram.yvals(3));
        else
            h = [];
        end
%     case 'timeslicelog'
%         range = varargin{1};
%         xvals = specgram.xVals(1):specgram.xVals(3):specgram.xVals(2);
%         inds = find(xvals>=range(1) & xvals<=range(2));
%         if ~isempty(inds)
%             h = plot(specgram.yVals(1):specgram.yVals(3):specgram.yVals(2),...
%                              log10(max(specgram.Data{1}(:,inds)',specgram.AmpCutoff)));
%         else
%             h = [];
%         end
end

