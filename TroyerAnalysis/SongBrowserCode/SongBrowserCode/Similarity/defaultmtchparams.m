function mtchparams = defaultmtchparams
% mtchparams = defaultmtchparams
% return the default parameters for calculating clip matches
% mtchparams.offsettype = 'fracsmall'; 
% mtchparams.offset = 5; % +- offset to consider in msec
% mtchparams.offsetfrac = .05; % +- offset in terms of fraction of smaller spec
% mtchparams.metric = @mnsqrdev;
% mtchparams.freqrange = [];
% mtchparams.note = 'Initial match params, created by Todd 2/10/2010.';

mtchparams.offsettype = 'fracsmall'; 
mtchparams.offset = 6; % +- offset to consider in bins
mtchparams.offsetfrac = .4; % +- offset in terms of fraction of smaller spec
mtchparams.metric = @mnabsdev;
mtchparams.freqrange = [1 7]; % in kHz
mtchparams.note = 'Initial match params, created by Todd 2/10/2010.';