function menu = menu_export(figh)
% create File menu and related actions
% actions created (function handle Action.XXX):
%    OpenSongFile, OpenBird, OpenSoundFile, OpenBmkFile
%    NewBmkFile, LoadLabel, AddLabel, AddLabelScheme, SBExit
%    


menu.export = uimenu('parent',figh,'label','Export');
% menu.exptarg = uimenu('parent',menu.export,'label','Target');
menu.exptarg = uimenu('parent',menu.export,'label','Target = New Fig');
% menu.exptarg_template = uimenu('parent',menu.exptarg,'label','Template','callback',{@exptarg_cb,'template'},'checked','on');
% menu.exptarg_template = uimenu('parent',menu.exptarg,'label','Template','callback',{@exptarg_cb,'template'});
menu.exptarg_fig = uimenu('parent',menu.exptarg,'label','New Fig','callback',{@exptarg_cb,'fig'});
menu.exptarg_wav = uimenu('parent',menu.exptarg,'label','Wav File','callback',{@exptarg_cb,'wav'});
menu.exptarg_global = uimenu('parent',menu.exptarg,'label','tmpsong Var','callback',{@exptarg_cb,'global'});
menu.inclbl = uimenu('parent',menu.export,'label','Labels = Yes');
menu.inclbl_yes = uimenu('parent',menu.inclbl,'label','Yes','callback',{@inclbl_cb,'yes'});
menu.inclbl_no = uimenu('parent',menu.inclbl,'label','No','callback',{@inclbl_cb,'no'});
menu.selected = uimenu('parent',menu.export,'label','Selected','callback',{@export_cb,'select'});
menu.song = uimenu('parent',menu.export,'label','Song','callback',{@export_cb,'song'});
menu.printcurfig = uimenu('parent',menu.export,'label','Print Current Fig','callback',{@print_cb,'curfig'});
menu.printpreview = uimenu('parent',menu.export,'label','Print Preview','callback',{@print_cb,'preview'});

%--------------------------------
function exptarg_cb(hco,eventStruct,arg)
exptarg = get(hco,'parent');
set(exptarg,'label',['Target = ' get(hco,'label')]);

%--------------------------------
function inclbl_cb(hco,eventStruct,arg)
inclbl = get(hco,'parent');
set(inclbl,'label',['Labels = ' get(hco,'label')]);

%--------------------------------
function export_cb(hco,eventStruct,arg)

figh = gcf;
view = get(figh,'userdata');

if ~isfield(view,'song')
    disp('Can''t find song structure.  No export.');
else
    % get data vector in appropriate channel
    switch min(size(view.song.d))
        case 0
            disp('No song data. Cannot export');
            return
        case 1
            data = view.song.d(:);
        case 2
            try
                data = view.song.d(:,view.song.a.chan);
            catch
                disp('Cannot resolve channel in stereo data. No export');
                return
            end
    end    
    % if exporting selected portion, select data
    if strcmpi(arg(1:4),'Sele') 
        tmplim = view.selectlim;
    else % chop off buffers
        tmplim = [0 view.song.a.length];
    end
        samplelims = round((tmplim-view.timebuffer(1))*view.song.a.fs/1000);
        samplelims(1) = max(floor(samplelims(1)),1);
        samplelims(2) = min(ceil(samplelims(2)),length(data));
        data = data(samplelims(1):samplelims(2));
    % export to appropriate place
%     if strcmp(get(view.menu_export.exptarg_template,'checked'),'on')
    switch get(view.menu_export.inclbl,'label')
        case 'Labels = Yes'
            labels = view.song.labels'
        case 'Labels = No'
            labels = [];
    end
    switch get(view.menu_export.exptarg,'label')
        case 'Target = New Fig'
            figure
%             dispspec(data,view.song.a.fs);
            dispspeclbl(data,view.song.clips,'labels',labels,'offset',tmplim(1));
        case 'Target = Template'
            if isfield(view,'template')
                if isempty(view.template)
                    disp('No template function specified'); return;
                end
            end
            if ~ishandle(view.templateh)
                [template view.templateh] = feval(view.template);
            end
            feval(view.template,'feval',view.templateh,'addexemplar',view.templateh,'',data,1);
    %     elseif strcmp(get(view.menu_export.exptarg_wav,'checked'),'on')
        case 'Target = Wav File'
            [filename, pathname] = uiputfile('*.wav', 'Save as');
            if filename==0; return; end
            if exist(fullfile(pathname,filename)); delete(fullfile(pathname,filename)); end
            wavwrite(data,view.song.a.fs,16,fullfile(pathname,filename));
    %     elseif strcmp(get(view.menu_export.exptarg_global,'checked'),'on')
        case 'Target = tmpsong Var'
%             inp = inputdlg('Choose a name for global variable','Choose Global Variable');
            assignin('base','tmpsong',data);
            disp('Song data written to ''tmpsong'' variable in workspace.');
        otherwise
            disp('Error: no output target selected'); return;
    end
end
            
%--------------------------------
function print_cb(hco,eventStruct,arg)

switch arg
    case 'curfig'  
        print(gcf);
    case 'preview' 
        printpreview(gcf)
end
            