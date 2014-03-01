function varargout = SongWavFilter(varargin)
% SONGWAVFILTER MATLAB code for SongWavFilter.fig
%      SONGWAVFILTER, by itself, creates a new SONGWAVFILTER or raises the existing
%      singleton*.
%
%      H = SONGWAVFILTER returns the handle to a new SONGWAVFILTER or the handle to
%      the existing singleton*.
%
%      SONGWAVFILTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SONGWAVFILTER.M with the given input arguments.
%
%      SONGWAVFILTER('Property','Value',...) creates a new SONGWAVFILTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SongWavFilter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SongWavFilter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SongWavFilter

% Last Modified by GUIDE v2.5 06-Oct-2013 18:04:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SongWavFilter_OpeningFcn, ...
    'gui_OutputFcn',  @SongWavFilter_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SongWavFilter is made visible.
function SongWavFilter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SongWavFilter (see VARARGIN)

% Choose default command line output for SongWavFilter
handles.output = hObject;


% Remove Tick marks from .wav figures
set(handles.rawWav,'XTick',[])
set(handles.rawWav,'YTick',[])
set(handles.rawWav,'Visible','off')
set(handles.orgWav,'Visible','off')
set(handles.filWav,'Visible','off')
set(handles.newWav,'XTick',[])
set(handles.newWav,'YTick',[])
set(handles.newWav,'Visible','off')
set(handles.overWav,'Visible','off')

set(handles.filterOptions,'Enable','off')
set(handles.plotM,'Enable','off')

set(handles.stopButton,'Visible','off')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SongWavFilter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SongWavFilter_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function highpass_Callback(hObject, eventdata, handles)
% hObject    handle to highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of highpass as text
%        str2double(get(hObject,'String')) returns contents of highpass as a double


% --- Executes during object creation, after setting all properties.
function highpass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function folderOptions_Callback(hObject, eventdata, handles)
% hObject    handle to folderOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function loadFold_Callback(hObject, eventdata, handles)
% hObject    handle to folderOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Choose file in the folder location where wav files are stored
[~,handles.rawWavs,~] = uigetfile('*.wav');

% Extract value input to editable window
testForFilt = get(handles.highpass,'String');

% If User has not entered value present a window to select threshold
if strcmp(testForFilt,'NA')
    prompt = {'Enter filter value:'};
    dlg_title = 'HighPass cutoff';
    num_lines = 1;
    def = {'1000'};
    filtChange = inputdlg(prompt,dlg_title,num_lines,def);
    set(handles.highpass,'String',num2str(filtChange{:}));
end

% Extract numeric value from editable window
getFilt = get(handles.highpass,'String');

% Create new folder to hold modified wav files
handles.newDir = strcat(handles.rawWavs,getFilt,'kHz\');

% Change text on screen to indicate where files where be saved
set(handles.wavLoc,'String',handles.newDir);

% If new directory does not exist, then create it
if ~exist(handles.newDir,'dir')
    mkdir(handles.newDir)
end

% Change directory to raw wav location
cd(handles.rawWavs);

% Get cell array of wav file names
rawWavList = dir('*.wav');
handles.rawWavList = {rawWavList.name};

% set(handles.filterOptions,'Enable','on')
set(handles.plotM,'Enable','on')
set(handles.folderOptions,'Enable','off')

guidata(hObject, handles);

% --------------------------------------------------------------------
function filterOptions_Callback(hObject, eventdata, handles)
% hObject    handle to filterOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function runFilt_Callback(hObject, eventdata, handles)
% hObject    handle to filterOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Get pass value to use for filter
testForFilt = get(handles.highpass,'String');
% Get new directory to save processed wav files
testForLoad = get(handles.wavLoc,'String');

% Double check filter threshold
if strcmp(testForFilt,'NA')
    prompt = {'Enter filter value:'};
    dlg_title = 'HighPass cutoff';
    num_lines = 1;
    def = {'1000'};
    filtChange = inputdlg(prompt,dlg_title,num_lines,def);
    set(handles.highpass,'String',num2str(filtChange{:}));
end

% Convert filter value from string to numeric
filterValue = str2double(get(handles.highpass,'String'));

% Show stop button which will delete all current created files
set(handles.stopButton,'Visible','on')


if strcmp(testForLoad,'New Folder Location')
    warndlg('Load File Location!');
else
    plotType = get(handles.spWav,'Checked');
    
    switch plotType
        case 'off'
            set(handles.spWav,'Enable','off')
            
            set(handles.folderOptions,'Enable','off')
            set(handles.filterOptions,'Enable','off')
            set(handles.plotM,'Enable','off')
            
            axes(handles.overWav);
            for wi = 1:numel(handles.rawWavList)
                
                cd(handles.rawWavs)
                [rawW, rawW2] = audioread(handles.rawWavList{wi});
                
                maxY = max(rawW);
                minY = min(rawW);
                
                set(handles.wavName,'String',[]);
                cla(handles.overWav)
                set(handles.wavName,'String',handles.rawWavList{wi});
                %         specgram(rawW, 512, rawW2);
                
                fNorm = filterValue / (rawW2/2);
                [b, a] = butter(10, fNorm, 'high');
                rawHighFilt = filtfilt(b, a, rawW);
                
                plot(rawW)
                
                set(handles.overWav,'XTick',[])
                set(handles.overWav,'YTick',[])
                set(handles.overWav,'Ylim',[minY maxY]);
                set(handles.overWav,'Xlim',[0 numel(rawW)]);
                set(handles.overWav,'Visible','off')
                
                pause(0.15)
                
                hold on
                
                plot(rawHighFilt,'Color',[1 1 1])
                
                pause(0.3)
                
                cd(handles.newDir)
                
                audiowrite(handles.rawWavList{wi},rawHighFilt,rawW2)
                
                if get(handles.stopButton,'Value') == 1
                    set(handles.stopButton,'Value', 0)
                    
                    wavNames = ls;
                    wavNames = wavNames(3:end,:);
                    
                    delete_All(handles.newDir,wavNames);
                    
                    cd(handles.rawWavs)
                    rmdir(handles.newDir)
                    
                    cla(handles.overWav)
                    set(handles.wavName,'String',[]);
                    set(handles.wavLoc,'String',[]);
                    set(handles.highpass,'String','NA');
                    
                    set(handles.ovWav,'Checked','off')
                    set(handles.spWav,'Enable','on')
                    
                    set(handles.filterOptions,'Enable','off')
                    set(handles.plotM,'Enable','off')
                    
                    break 
                end
                
            end
            
            set(handles.folderOptions,'Enable','on')
            set(handles.filterOptions,'Enable','off')
            set(handles.plotM,'Enable','off')
            set(handles.stopButton,'Visible','off')
            cla(handles.overWav)
            set(handles.orgWav,'Visible','off')
            set(handles.wavLoc,'String',[])
            set(handles.wavName,'String',[])
            
            set(handles.highpass,'String','NA');
            
            set(handles.ovWav,'Checked','off')
            set(handles.spWav,'Enable','on')
            
            cd(handles.rawWavs)
            
        case 'on'
            
            set(handles.ovWav,'Enable','off')
            
            set(handles.folderOptions,'Enable','off')
            set(handles.filterOptions,'Enable','off')
            set(handles.plotM,'Enable','off')
            
            for wi = 1:numel(handles.rawWavList)
                
                cd(handles.rawWavs)
                [rawW, rawW2] = audioread(handles.rawWavList{wi});
                
                
                set(handles.wavName,'String',[]);
                cla(handles.rawWav)
                cla(handles.newWav)
                
                set(handles.wavName,'String',handles.rawWavList{wi});
                
                maxY = max(rawW);
                minY = min(rawW);
                
                %         specgram(rawW, 512, rawW2);
                
                fNorm = filterValue / (rawW2/2);
                [b, a] = butter(10, fNorm, 'high');
                rawHighFilt = filtfilt(b, a, rawW);
                
                axes(handles.rawWav);
                plot(rawW)
                set(handles.rawWav,'XTick',[])
                set(handles.rawWav,'YTick',[])
                set(handles.rawWav,'Ylim',[minY maxY]);
                set(handles.rawWav,'Xlim',[0 numel(rawW)]);
                set(handles.rawWav,'Visible','off')
                
                axes(handles.newWav);
                plot(rawHighFilt,'k')
                set(handles.newWav,'XTick',[])
                set(handles.newWav,'YTick',[])
                set(handles.newWav,'Ylim',[minY maxY]);
                set(handles.newWav,'Xlim',[0 numel(rawW)]);
                set(handles.newWav,'Visible','off')
                
                pause(0.25)
                
%                 set(handles.wavName,'String',handles.rawWavList{wi});
                
                cd(handles.newDir)
                
                audiowrite(handles.rawWavList{wi},rawHighFilt,rawW2)
                
                if get(handles.stopButton,'Value') == 1
                    set(handles.stopButton,'Value', 0)
                    
                    wavNames = ls;
                    wavNames = wavNames(3:end,:);
                    
                    delete_All(handles.newDir,wavNames);
                    
                    cd(handles.rawWavs)
                    rmdir(handles.newDir)
                    
                    cla(handles.newWav)
                    cla(handles.rawWav)
                    set(handles.wavName,'String',[]);
                    set(handles.wavLoc,'String',[]);
                    set(handles.highpass,'String','NA');
                    
                    set(handles.spWav,'Checked','off')
                    set(handles.ovWav,'Enable','on')
                    
                    break 
                end
                
            end
            
            set(handles.folderOptions,'Enable','on')
            set(handles.filterOptions,'Enable','off')
            set(handles.plotM,'Enable','off')
            set(handles.stopButton,'Visible','off')
            
            % Clear Plot area 
            set(handles.rawWav,'Visible','off')
            set(handles.orgWav,'Visible','off')
            set(handles.filWav,'Visible','off')
            set(handles.newWav,'Visible','off')
            cla(handles.newWav)
            cla(handles.rawWav)
            set(handles.orgWav,'Visible','off')
            set(handles.filWav,'Visible','off')
            set(handles.wavLoc,'String',[])
            set(handles.wavName,'String',[])
            
            set(handles.highpass,'String','NA');
            
            set(handles.spWav,'Checked','off')
            set(handles.ovWav,'Enable','on')
            
            cd(handles.rawWavs)
            
            

    end    
end

% Create transfer and delete function
qstring = 'Do you want to replace original wavs with filtered wavs?';
qtitle = 'Transfer and Replace';
delChoice = questdlg(qstring,qtitle,'Yes','No','Yes');

if strcmp(delChoice,'Yes')
    % cd to original wavs
    cd(handles.rawWavs)
    % Get raw wav names
    rawWavList = dir('*.wav');
    rawWavNames = {rawWavList.name};
    raw2delete = char(rawWavNames);
    % Delete original wavs
    delete_All(handles.rawWavs,raw2delete);
    
    %%% Transfer new files to old location
    
    % cd to new wavs location
    cd(handles.newDir)
    % Get raw wav names
    newWavList = dir('*.wav');
    newWavNames = {newWavList.name};
    % Move files
    move_All(handles.rawWavs,newWavNames);
    % Remove new directory
    rmdir(handles.newDir)
    
end




guidata(hObject, handles);





% --------------------------------------------------------------------
function plotM_Callback(hObject, eventdata, handles)
% hObject    handle to plotM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function spWav_Callback(hObject, eventdata, handles)
% hObject    handle to spWav (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Checked','on')
set(handles.ovWav,'Checked','off')

set(handles.rawWav,'XTick',[])
set(handles.rawWav,'YTick',[])
set(handles.rawWav,'Visible','off')
set(handles.orgWav,'Visible','on')
set(handles.filWav,'Visible','on')
set(handles.newWav,'XTick',[])
set(handles.newWav,'YTick',[])
set(handles.newWav,'Visible','off')
set(handles.overWav,'Visible','off')
set(handles.orgWav,'String','Original Wav')

set(handles.filterOptions,'Enable','on')
set(handles.plotM,'Enable','off')

% --------------------------------------------------------------------
function ovWav_Callback(hObject, eventdata, handles)
% hObject    handle to ovWav (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Checked','on')
set(handles.spWav,'Checked','off')

set(handles.overWav,'XTick',[])
set(handles.overWav,'YTick',[])
set(handles.overWav,'Visible','off')

set(handles.rawWav,'Visible','off')
set(handles.orgWav,'Visible','off')
set(handles.filWav,'Visible','off')
set(handles.newWav,'Visible','off')

set(handles.orgWav,'Visible','on')
set(handles.orgWav,'String','Overlay Wavs')

set(handles.filterOptions,'Enable','on')
set(handles.plotM,'Enable','off')


% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stopButton


% --------------------------------------------------------------------
function batchP_Callback(hObject, eventdata, handles)
% hObject    handle to batchP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.ovWav,'Enable','off')

set(handles.folderOptions,'Enable','off')
set(handles.filterOptions,'Enable','off')
set(handles.plotM,'Enable','off')

testForFilt = get(handles.highpass,'String');

if strcmp(testForFilt,'NA')
    prompt = {'Enter filter value:'};
    dlg_title = 'HighPass cutoff';
    num_lines = 1;
    def = {'1000'};
    filtChange = inputdlg(prompt,dlg_title,num_lines,def);
    set(handles.highpass,'String',num2str(filtChange{:}));
end

getFilt = get(handles.highpass,'String');
filterValue = str2double(get(handles.highpass,'String'));

allFilesLoc = uigetdir;

cd(allFilesLoc);

foldDirectory = dir;
foldnames1 = {foldDirectory.name};
foldNs = foldnames1(3:end);

for fi = 1:length(foldNs)
    
    loopDir = strcat(allFilesLoc,'\',foldNs{fi},'\');
    newDir = strcat(loopDir,getFilt,'kHz\');
    cd(loopDir)
    
    rawWavList = dir('*.wav');
    rawWavListPro = {rawWavList.name};
    
    set(handles.wavLoc,'String',foldNs{fi})
    
    for rwi = 1:numel(rawWavListPro)
        cd(loopDir)
        
        [rawW, rawW2] = audioread(rawWavListPro{rwi});
        
        maxY = max(rawW);
        minY = min(rawW);
        
        set(handles.wavName,'String',[]);
        cla(handles.overWav)
        set(handles.wavName,'String',rawWavListPro{rwi});
        %         specgram(rawW, 512, rawW2);
        
        fNorm = filterValue / (rawW2/2);
        [b, a] = butter(10, fNorm, 'high');
        rawHighFilt = filtfilt(b, a, rawW);
        
        plot(rawW)
        
        set(handles.overWav,'XTick',[])
        set(handles.overWav,'YTick',[])
        set(handles.overWav,'Ylim',[minY maxY]);
        set(handles.overWav,'Xlim',[0 numel(rawW)]);
        set(handles.overWav,'Visible','off')
        
%         pause(0.1)
        
        hold on
        
        plot(rawHighFilt,'Color',[1 1 1])
        
        pause(0.15)
        
        if ~exist(newDir,'dir')
            mkdir(newDir)
        end
        cd(newDir)
        
        audiowrite(rawWavListPro{rwi},rawHighFilt,rawW2)
    end
    
    cd(loopDir)
    % Get raw wav names
    rawWavList = dir('*.wav');
    rawWavNames = {rawWavList.name};
    % Delete original wavs
    delete_All(loopDir,rawWavNames);
    
    %%% Transfer new files to old location
    
    % cd to new wavs location
    cd(newDir)
    % Get raw wav names
    newWavList = dir('*.wav');
    newWavNames = {newWavList.name};
    % Move files
    move_All(loopDir,newWavNames);
    % Change back to outer directory
    cd(loopDir)
    % Remove new directory
    rmdir(newDir)
    
end


set(handles.folderOptions,'Enable','on')
set(handles.filterOptions,'Enable','off')
set(handles.plotM,'Enable','off')
set(handles.stopButton,'Visible','off')
cla(handles.overWav)
set(handles.orgWav,'Visible','off')
set(handles.wavLoc,'String',[])
set(handles.wavName,'String',[])


set(handles.highpass,'String','NA');

set(handles.spWav,'Checked','off')
set(handles.ovWav,'Enable','on')

guidata(hObject, handles);



