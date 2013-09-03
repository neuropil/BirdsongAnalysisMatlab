function oscgram = ftr_oscgramobj(varargin)
% oscgram = ftr_oscgramobj(varargin)
%  varargin is a series of property value pairs. 

%  Created by Todd 3/4/08
%    Edits: 

% STANDARD FIELDS
oscgram.tag = 'oscgram';
oscgram.calcFcn = @calcFcn;
oscgram.dispFcn = @dispFcn;
oscgram.p = []; % parameters
oscgram.pwin = []; % parameter window
oscgram.d=[]; 
oscgram.dispopts = {'Stereo','Mono','Mono Alt'};
oscgram.h = [];
oscgram.starttime = 0;
oscgram.xvals=[]; 
oscgram.yvals=[]; 
oscgram.range = [-1 1];
% OSCGRAM SPECIFIC FIELDS
oscgram.chan=1; 
oscgram.fs=24414.0625; 
oscgram.color{1}='b'; % left channel
oscgram.color{2}='r'; % right channel

oscgram = parse_pv_pairs(oscgram,varargin);

%-----------------------------------------------------------------------
function oscgram = calcFcn(song,oscgram)
% oscgram = calculate(oscgram)
% no calculation necessary since oscgram is equal to song
oscgram.d = song.d;
oscgram.fs = song.a.fs;
oscgram.chan = song.a.chan;
oscgram.xvals = oscgram.starttime*[1 0 1]+[0 1 max(size(song.d))-1]*1000/oscgram.fs;

%-----------------------------------------------------------------------
function hands = dispFcn(oscgram,varargin)
% Display(varargin)  display Song oscillogram 

hands = [];
opt.dispopt = 'stereo';
opt.normalized = 0;
opt.color = oscgram.color;
opt = parse_pv_pairs(opt,varargin);

if isempty(oscgram.d); return; end
if opt.normalized>0
    oscgram.d = opt.normalized*(oscgram.d-oscgram.range(1))/diff(oscgram.range);
end

% make sure that data is in columns
[channum chanind] = min(size(oscgram.d));
if chanind == 1
    oscgram.d = oscgram.d';
end

% set dispopt if not already done or if only have mono data
if channum == 1
    opt.dispopt = 'mono';;
end
% order indices so that chan is first
channels = 1:channum;
chanlist = [oscgram.chan channels(channels~=oscgram.chan)];

x = (oscgram.xvals(1):oscgram.xvals(2):oscgram.xvals(3))';
% display in this order
switch lower(opt.dispopt)
    case {' ','stereo'}
        chaninds = [1 2];
    case 'mono'
        chaninds = 1;
    case 'mono alt'
        chaninds = 2;
end
% if only one channel, set chaninds = 1
if size(oscgram.d,2)==1
    chaninds =1;
end
for i=1:length(chaninds)
    hands(i) = plot(x,oscgram.d(:,chanlist(chaninds(i))));
    set(hands(i),'color',opt.color{chanlist(chaninds(i))});
end
