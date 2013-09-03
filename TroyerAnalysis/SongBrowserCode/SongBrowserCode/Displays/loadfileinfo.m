function strct = loadfileinfo(varargin)
% strct = loadfileinfo(varargin)
% user will be prompted to locate either an existing fileinfo file (.inf)
% or a bookmark file (.bmk,.dbk)
% p/v pair 'fileinfo', strct will load the new file info into existing
% strct


ldinf.name = ''; % will look for all files with standard extensions based on name
ldinf.fileinfo = ''; % used to pass entire fileinfo structure directly
ldinf.strct = ''; % will write fileinfo into this structure
ldinf.infopath = '';
ldinf.infofile = '';
ldinf.bmkpath = '';
ldinf.bmkfile = '';
ldinf.lblfile = '';
ldinf.ftrfile = '';
ldinf.specpath = '';
ldinf.ftrpath = '';
ldinf.wavpath = '';
ldinf.save = 1;
ldinf.overwrite = 0; % by default just load fileinfo into empty fields
ldinf = parse_pv_pairs(ldinf,varargin);

if isempty(ldinf.fileinfo)
    if isempty(ldinf.name) 
        [tmpfile,tmppath] = uigetfile({'*.inf;*.bmk;*.dbk','Info or Bookmark file (*.bmk;*.dbk)';'*.*','All files'},...
            'Pick info or bookmark file','Choose info or bookmark file');
        if tmpfile==0 return; end
        [tmp name ext] = fileparts(tmpfile);
        if strcmp(ext,'.bmk') | strcmp(ext,'.dbk')
            ldinf.bmkfile = tmpfile;
            ldinf.bmkpath = tmppath;
            ldinf.infopath = tmppath;
            ldinf.name = name;
        else
            load(fullfile(tmppath,tmpfile),'fileinfo','-mat');
            ldinf.infofile = tmpfile;
            ldinf.infopath = tmppath;
            ldinf.fileinfo = fileinfo;
            ldinf.save = 0;
        end
    end
end
% look for other files/directories based on name
if isempty(ldinf.fileinfo)
    if exist(fullfile(ldinf.infopath,[ldinf.name '.dbk']))==2
        ldinf.bmkpath = ldinf.infopath;
        ldinf.bmkfile = [ldinf.name '.dbk'];
    elseif exist(fullfile(ldinf.infopath,[ldinf.name '.bmk']))==2
        ldinf.bmkpath = ldinf.infopath;
        ldinf.bmkfile = [ldinf.name '.bmk'];
    end
    if exist(fullfile(ldinf.infopath,[ldinf.name '.lbl']))==2
        ldinf.lblfile = [ldinf.name '.lbl'];
        disp(['Located label file ' ldinf.lblfile]);
    end
    if exist(fullfile(ldinf.infopath,[ldinf.name '.ftr']))==2
        ldinf.ftrfile = [ldinf.name '.ftr'];
        disp(['Located feature file ' ldinf.ftrfile]);
    end
    if exist([ldinf.infopath filesep ldinf.name '_spec'])==7
        ldinf.specpath = [ldinf.name '_spec'];
        disp(['Located spec directory ' ldinf.specpath]);
    end
    if exist([ldinf.infopath filesep ldinf.name '_ftrs'])==7
        ldinf.ftrpath = [ldinf.name '_ftrs'];
        disp(['Located feature directory ' ldinf.ftrpath]);
    end
    if exist([ldinf.infopath filesep ldinf.name '_wav'])==7
        ldinf.wavpath = [ldinf.name '_wav'];
        disp(['Located wav directory ' ldinf.wavpath]);
    end
end

if ~isempty(ldinf.fileinfo)
    fileinfo = ldinf.fileinfo;
else
    fileinfo = rmfield(ldinf,{'name','fileinfo','strct','overwrite','save'});
end

if ~isempty(ldinf.strct)
    strct = ldinf.strct;
    % load matching fields from fileinfo into strct
    infofldnames = fieldnames(fileinfo);
    strctfldnames = fieldnames(strct);
    for i=1:length(infofldnames)
        mtch = strcmp(strctfldnames,infofldnames{i});
        if sum(mtch)==1
            if isempty(getfield(strct,infofldnames{i})) | ldinf.overwrite
                strct = setfield(strct,infofldnames{i},getfield(fileinfo,infofldnames{i}));
            end
        end
    end            
else
    strct = fileinfo;
end

% save
if ldinf.save
    [ldinf.infofile,ldinf.infopath] = uiputfile({'*.inf','fileinfo file (*.inf)';'*.*','All files'},...
        'Choose info file');
    if ldinf.infofile==0 return; end;
    fileinfo = strct;
    save(fullfile(ldinf.infopath,ldinf.infofile),'fileinfo');
end

