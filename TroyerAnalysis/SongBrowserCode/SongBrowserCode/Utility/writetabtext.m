function OK = writetabtext(inputs,varargin)
% OK = writetabtext(INPUTS,varargin) write data from a structure array
%  into a tab separated text file (readable by Excel)
%  INPUTS is either a structure array or array of structures 
% varargin is a list of param/value pairs to specify options:
%   filename = '';  to store data (if empty, will prompt user)
%   fid = []; can specify file using file ID 
%   writefields = 1; flags whether to write rieldnames on first line
%   write2file = 1; set to zero if you don't want to save info to file
%   write2screen = 1; by default write to the screen as well
%   fieldnames = {}; by default writetabtext uses the field names of the
%     structure.  User can specify alternate list using a cell array


% Todd, 8/22/08

%% set inputs and do some error checking
params.fid = [];
params.filename = '';
params.fieldnames = {};
params.format = '';
params.writefields = 1; % by default, write fields in first row
params.write2file = 1; % by default, write to file
params.write2screen = 1; % by default, write to screen as well
params = parse_pv_pairs(params,varargin);

%% determine if inputs are in structure of arrays or array of structures
if length(inputs) ==1 % structure of arrays
    isstructarray = 0;
    rownum = length(getfield(inputs,params.fieldnames{1}));
else
    isstructarray = 1;
    rownum = length(inputs);
end

% set fieldnames to those from inputs by default
if isempty(params.fieldnames)
    params.fieldnames = fieldnames(inputs);
end
if isempty(params.format) % get format from inputs
    for f = 1:length(params.fieldnames)
        if ~isfield(inputs(1),params.fieldnames{f})
            disp(['Can''t find field ' params.fieldnames{f} ', aborting.']);
            return
        else
            if  isinteger(getfield(inputs(1),params.fieldnames{f}))
                params.format = [params.format '%d'];
            elseif  isnumeric(getfield(inputs(1),params.fieldnames{f}))
                params.format = [params.format '%f'];
            elseif iscell(getfield(inputs(1),params.fieldnames{f}))
                params.format = [params.format '%s'];
            else
                error([fielnames{f} ' is neither numeric nor cell array of strings.']);
            end
        end
    end
end
percentlocs = find(params.format=='%');
if length(percentlocs)~=length(params.fieldnames)
    error('Format string must have the same number of elements as fields specified');
end

    
%% open file
if params.write2file
    if ~isempty(params.fid) % assume fid defined external to this function
        externalfid = 1;
    else
        externalfid = 0;
        if isempty(params.filename)
            [filename pathname] = uigetfile({'*.txt','text-files (*.txt)';  '*.*',  'All Files (*.*)'}, 'Pick a filename');
            if filename==0 return; end
            params.filename = fullfile(pathname,filename);
        end
        params.fid = fopen(params.filename,'w');
    end
end

% set up tab delimiters and line delimiter for last field
delim = '';
for f=1:length(params.fieldnames)
    delim = [delim '\t'];
end
delim(end) = 'n';

% write fieldnames on first row
if params.writefields
    for f = 1:length(params.fieldnames)
        if params.write2file
            fprintf(params.fid,['%s' delim(2*f-1:2*f)],params.fieldnames{f});
        end
        if params.write2screen
            fprintf(1,['%s' delim(2*f-1:2*f)],params.fieldnames{f});
        end
    end
end
for i=1:rownum
    if isstructarray
        for f = 1:length(params.fieldnames)
            if params.write2file
                fprintf(params.fid,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs(i).' params.fieldnames{f}]));
            end
            if params.write2screen
                fprintf(1,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs(i).' params.fieldnames{f}]));
            end
        end
    else
%         tmpinput = getfield(inputs,params.fieldnames{f});
        for f = 1:length(params.fieldnames)
            if params.format(2*f)=='s'
                if params.write2file
                    fprintf(params.fid,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs.' params.fieldnames{f} '{i}']));
                end
                if params.write2screen
                    fprintf(1,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs.' params.fieldnames{f} '{i}']));
                end
            else
                if params.write2file
                    fprintf(params.fid,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs.' params.fieldnames{f} '(i)']));
                end
                if params.write2screen
                    fprintf(1,[params.format(2*f-1:2*f) delim(2*f-1:2*f)],eval(['inputs.' params.fieldnames{f} '(i)']));
                end
           end
        end
    end
end
if params.write2file
    fclose(params.fid);
end

