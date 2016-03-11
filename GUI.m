function varargout = GUI(varargin)
% GUI MATLAB code for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 06-May-2014 15:25:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_OutputFcn, ...
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


% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI (see VARARGIN)

% Choose default command line output for GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
RefreshConfigId();

load('guiProperties'); %loads *innerLabel*
set(findobj('Tag', 'fileFilter'),'String',innerLabel);


% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.form);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnUnitTests.
function btnUnitTests_Callback(hObject, eventdata, handles)
% hObject    handle to btnUnitTests (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
unitTests

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over btnUnitTests.
function btnUnitTests_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to btnUnitTests (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rb12robot.
function rb12robot_Callback(hObject, eventdata, handles)
% hObject    handle to rb12robot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb12robot


% --- Executes on button press in rb3robot.
function rb3robot_Callback(hObject, eventdata, handles)
% hObject    handle to rb3robot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb3robot

% --- Executes on button press in butRunSimulation.
function butRunSimulation_Callback(hObject, eventdata, handles)
% hObject    handle to butRunSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   label = get(findobj('Tag', 'fileFilter'),'String');
   id = get(findobj('Tag', 'numId'),'String');
    sure = get(findobj('Tag', 'rbImSure'),'Value');
    if(sure==1)
        runSimulation(str2double(strtrim(id)),0,label);
    end
% --- Executes on button press in butShowGraph.
function butShowGraph_Callback(hObject, eventdata, handles)
% hObject    handle to butShowGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    fileNames = get(findobj('Tag', 'lstFiles'),'UserData')
    selections = get(findobj('Tag', 'lstFiles'),'Value')


    id = get(findobj('Tag', 'numId'),'String');
    %fileFilter = get(findobj('Tag', 'fileFilter'),'String');
    fileFilter = '';

    rbSimIter = get(findobj('Tag', 'rbSimIter'),'Value');
    rbIndivIter = get(findobj('Tag', 'rbIndivIter'),'Value');
    rbIncorAct = get(findobj('Tag', 'rbIncorAct'),'Value');
    rbFalseRwd = get(findobj('Tag', 'rbFalseRwd'),'Value');
    rbTau1 = get(findobj('Tag', 'rbTau1'),'Value');
    
    
    robot12 = get(findobj('Tag', 'rb12robot'),'Value');
    robot3  = get(findobj('Tag', 'rb3robot'),'Value');
    robot8  = get(findobj('Tag', 'rb8robot'),'Value');
        
        
    %Configuration.Instance(str2double(strtrim(id)));
    winName =  get(findobj('Tag', 'windowHandle'),'String');
    if(winName == 'null')
        winHand = figure();
        set(findobj('Tag', 'windowHandle'),'String',num2str(winHand));
    end

    winHand =  str2double(get(findobj('Tag', 'windowHandle'),'String'));    
    
    figure(winHand);

    hold on;
    %sr.GraphResults(graphtype,100,[0 100 0 100],id);
    
    if(rbSimIter == 1)
        graphtype = 1;
        sizes = [2500 15000];
        sizes2 = [100 300];
        
    elseif (rbIndivIter == 1)
        graphtype = 2;
        sizes = [2500*3 50000];
        sizes2 = [100 300];
    elseif (rbIncorAct == 1)
        graphtype = 6;
        sizes = [1 1];
        sizes2 = [300 300];
    elseif (rbFalseRwd == 1)
        graphtype = 7;
        sizes = [10 10];
        sizes2 = [300 300];
    elseif (rbTau1 == 1)
             graphtype = 13;
        sizes = [2000 9000];
        sizes2 = [100 300];
        
    end
    if( robot8 > 0)
        robot12 = 1
    end
    runsTxt = get(findobj('Tag', 'txtRuns'),'String');
    runs = str2double(strtrim(runsTxt));

    axis = [0 sizes2(robot12+1) 0 sizes(robot12+1)];
    style=1;
    sr = SimResults();
    
    sr.GraphResults(graphtype,runs,axis,id,fileFilter,style,selections);
    
    
% --- Executes during object creation, after setting all properties.
function uipanel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


%Reads in all the configuration parameters from the GUI interface and
%assigns each one a value to form the configuration number
function RefreshConfigId()
    configId = 0;

    timeLimitOn = get(findobj('Tag', 'rbTimeLimitOn'),'Value');
    timeLimitOff = get(findobj('Tag', 'rbTimeLimitOff'),'Value');

    comSenOff = get(findobj('Tag', 'rbComSenOff'),'Value');
    comSenOn = get(findobj('Tag', 'rbComSenOn'),'Value');
    
    rbDistRwdOff = get(findobj('Tag', 'rbDistRwdOff'),'Value');
    rbDistRwdOn = get(findobj('Tag', 'rbDistRwdOn'),'Value');
    % Hint: get(hObject,'Value') returns toggle state of rb12robot
    robot12 = get(findobj('Tag', 'rb12robot'),'Value');
    robot8 = get(findobj('Tag', 'rb8robot'),'Value');
    robot3 = get(findobj('Tag', 'rb3robot'),'Value');
    
    noise000 =  get(findobj('Tag', 'rbNoise000'),'Value');
    noise005 =  get(findobj('Tag', 'rbNoise005'),'Value');
    noise010 =  get(findobj('Tag', 'rbNoise010'),'Value');
    noise020 =  get(findobj('Tag', 'rbNoise020'),'Value');
    noise040 =  get(findobj('Tag', 'rbNoise040'),'Value');
    
    simIter =  get(findobj('Tag', 'rbSimIter'),'Value');
    indivIter =  get(findobj('Tag', 'rbIndivIter'),'Value');
    falseRwd =  get(findobj('Tag', 'rbFalseRwd'),'Value');
    incorrectAct =  get(findobj('Tag', 'rbIncorAct'),'Value');
    
    lalliance =  get(findobj('Tag', 'rbLalliance'),'Value');
    lallianceOld =  get(findobj('Tag', 'rbLAllOld'),'Value');
    
    rsla =  get(findobj('Tag', 'rbRsla'),'Value');
    qaq =  get(findobj('Tag', 'rbQaq'),'Value');
    qlearning =  get(findobj('Tag', 'rbQlearning'),'Value');
    
    coopOn =  get(findobj('Tag', 'rbCoopOn'),'Value');
    coopOff =  get(findobj('Tag', 'rbCoopOff'),'Value');
    coopCautious =  get(findobj('Tag', 'rbCoopCautious'),'Value');

    crowdOn =  get(findobj('Tag', 'rbCrowdOn'),'Value');
    crowdOff =   get(findobj('Tag', 'rbCrowdOff'),'Value');
    
    pfOn =  get(findobj('Tag', 'rbPfOn'),'Value');
    pfOff =   get(findobj('Tag', 'rbPfOff'),'Value');
    
    advOn =  get(findobj('Tag', 'rbAdvExcOn'),'Value');
    advOff =   get(findobj('Tag', 'rbAdvExcOff'),'Value');
    advAgg =   get(findobj('Tag', 'rbAdvExcAgg'),'Value');

    invOn =  get(findobj('Tag', 'rbInvRwdOn'),'Value');
    invOff =   get(findobj('Tag', 'rbInvRwdOff'),'Value');

    
    pf = sum([pfOff pfOn].*[1 2],2);
    adv = sum([advOff advOn advAgg].*[1 2 3],2);
    
    inv = sum([invOff invOn].*[1 2],2);
    
    robotNum = sum([robot12 robot3 robot8].*[1 2 3],2);
    noiseNum = sum([noise000 noise005 noise010 noise020 noise040].*[1 2 3 4 5],2);
    
    teamLearning = sum([qlearning lalliance rsla qaq lallianceOld].*[1 2 3 4 5],2);
    coop = sum([coopOn coopOff coopCautious].*[1 2 3],2);
    crowd = sum([crowdOn crowdOff ].*[1 2],2);
    
    number =  sum([robotNum noiseNum teamLearning coop crowd pf adv inv] .* [1 10 100 1000 10000 100000 1000000 10000000],2);
    
    %these properties are added later, kinda hacked in. Terrible.
    if(rbDistRwdOn == 1)
        number =  rbDistRwdOn*(10^8)+number;
    end
    if(comSenOn == 1)
        number =  comSenOn   *(10^9)+number;
    end
    if(timeLimitOff == 1)
        number =  timeLimitOff   *(10^10)+number;
    end
    
    
    set(findobj('Tag', 'numId'),'String',num2str(number ));
    set(findobj('Tag', 'numSimulations'),'String',num2str(1));
    if(robot3 == 1)
        set(findobj('Tag', 'txtRuns'),'String',num2str(100));
    else
        set(findobj('Tag', 'txtRuns'),'String',num2str(300));
    end
    
    
    PopulateFileListbox(num2str(number ),'lstFiles','results',1);

    function PopulateFileListbox(filter,listboxName,subDir,isData)
    sr = SimResults();
    if(isData==1)
        [listingIter] = sr.GetFileNames(filter,'',subDir);
    else
        if(~isempty(subDir))
            cd(subDir);
        end
        [listingIter] = dir(strcat('*',filter,'*'));
        if(~isempty(subDir))
            cd('..');
        end
    end
    %if(size(listingIter,1) > 0 && size(listingIter,2) > 0 )
    prev_list =[];
    prev_vals =[];
    
    set(findobj('Tag', listboxName),'String',prev_list  );
    set(findobj('Tag', listboxName), 'Value',prev_vals);    
    handles.fileLabels = [];
    lblsize = 0;
    for z = 1:size(listingIter,1)
        if (size(listingIter(z).name,2) > lblsize)
            lblsize = size(listingIter(z).name,2);
        end
        
    end
    z=0;
    for z = 1:size(listingIter,1)
        prev_list = get(findobj('Tag', listboxName),'String');
        prev_vals = get(findobj('Tag', listboxName),'Value');
        label = listingIter(z).name;
        if (size(label,2) < lblsize)
            label((size(label,2)+1):lblsize) = '_';
        end
        disp(strcat(':',label,':'))

        if(isData ==1)
            load(strcat('results\',listingIter(z).name) );
            handles.fileLabels = [handles.fileLabels; label];
            if(size(iterDat,1) < 10)
                padding = '00';
            elseif(size(iterDat,1) < 100)
                padding = '0';
            else
                padding = '';
            end



            label = strcat(label ,':',padding,num2str(size(iterDat,1)));
        else
            label = strcat(label );
            handles.fileLabels = [handles.fileLabels; label];
            
        end
        new_list = [prev_list; label];
        new_vals = [prev_vals z];
        
        set(findobj('Tag', listboxName),'String',new_list );
        set(findobj('Tag', listboxName), 'Value',new_vals);    
    end
    set(findobj('Tag', listboxName),'UserData',handles.fileLabels );
        %end

% --- Executes when selected object is changed in uipanel4.
function uipanel4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel4 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel3.
function uipanel3_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel3 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel5.
function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel7.
function uipanel7_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel7 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel8.
function uipanel8_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel8 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes when selected object is changed in uipanel9.
function uipanel9_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel9 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes on button press in rbImSure.
function rbImSure_Callback(hObject, eventdata, handles)
% hObject    handle to rbImSure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbImSure


% --- Executes on button press in showSimulation.
function showSimulation_Callback(hObject, eventdata, handles)
% hObject    handle to showSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    id = get(findobj('Tag', 'numId'),'String');
    sure = get(findobj('Tag', 'rbImSure'),'Value');
    label = 'test'
    if(sure==1)
        runSimulation(str2double(strtrim(id)),1,label);
    end



function fileFilter_Callback(hObject, eventdata, handles)
% hObject    handle to fileFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileFilter as text
%        str2double(get(hObject,'String')) returns contents of fileFilter as a double
innerLabel = get(findobj('Tag', 'fileFilter'),'String');
save('guiProperties','innerLabel','-append'); %loads *innerLabel*


% --- Executes during object creation, after setting all properties.
function fileFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function uipanel8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function txtRuns_Callback(hObject, eventdata, handles)
% hObject    handle to txtRuns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRuns as text
%        str2double(get(hObject,'String')) returns contents of txtRuns as a double


% --- Executes during object creation, after setting all properties.
function txtRuns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRuns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnNewGraph.
function btnNewGraph_Callback(hObject, eventdata, handles)
% hObject    handle to btnNewGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
winHand = figure();
        set(findobj('Tag', 'windowHandle'),'String',num2str(winHand));


% --- Executes during object creation, after setting all properties.
function form__OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mygui (see VARARGIN)


% --- Executes during object creation, after setting all properties.
function windowHandle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowHandle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function form_CreateFcn(hObject, eventdata, handles)
% hObject    handle to form (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function numId_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in lstFiles.
function lstFiles_Callback(hObject, eventdata, handles)
% hObject    handle to lstFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstFiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstFiles


% --- Executes during object creation, after setting all properties.
function lstFiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel10.
function uipanel10_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel10 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% --- Executes on button press in btnResume.
function btnResume_Callback(hObject, eventdata, handles)
% hObject    handle to btnResume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    label = get(findobj('Tag', 'fileFilter'),'String');
    id = get(findobj('Tag', 'numId'),'String');
    sure = get(findobj('Tag', 'rbImSure'),'Value');
    resume = 1;
    fileNames = get(findobj('Tag', 'lstFiles'),'UserData');
    selections = get(findobj('Tag', 'lstFiles'),'Value');
    selection = fileNames(selections(1),:);
    
    dotMatExtensionLocation1 = strfind(selection, '_iter');
    dotMatExtensionLocation2 = strfind(selection, '_blob');
    dotMatExtensionLocation = max([dotMatExtensionLocation1 dotMatExtensionLocation2]);
    
    selection = selection(1:dotMatExtensionLocation  );

    if(sure==1)
        runSimulation(str2double(strtrim(id)),0,label,resume,selection);
    end
    set(findobj('Tag', 'rbImSure'),'String',0);

% --- Executes on button press in btnDelete.
function btnDelete_Callback(hObject, eventdata, handles)
% hObject    handle to btnDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fileNames = get(findobj('Tag', 'lstFiles'),'UserData');
    selections = get(findobj('Tag', 'lstFiles'),'Value');
    selection = fileNames(selections(1),:);
    
    dotMatExtensionLocation1 = strfind(selection, '_iter');
    dotMatExtensionLocation2 = strfind(selection, '_blob');
    dotMatExtensionLocation = max([dotMatExtensionLocation1 dotMatExtensionLocation2]);
    
    selection = selection(1:dotMatExtensionLocation  );

    
    cd('results');
    
    fileList = dir(strcat('*',selection,'*'));
    
    for i=1:size(fileList,1)
        fileName = fileList(i).name;
        movefile(fileName,strcat('removed\',fileName));
    end
    cd('..');
    RefreshConfigId();
       
    
    
    


% --- Executes on selection change in lstGraphTypes.
function lstGraphTypes_Callback(hObject, eventdata, handles)
% hObject    handle to lstGraphTypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstGraphTypes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstGraphTypes
    fileNames = get(findobj('Tag', 'lstGraphTypes'),'UserData');
    selections = get(findobj('Tag', 'lstGraphTypes'),'Value');
    selection = fileNames(selections(1),:);
    
    dotMatExtensionLocation = strfind(selection, '.mat');
    
    selection = selection(1:dotMatExtensionLocation -1 );
    
    LoadSelectionInMatrix(selection);
    
function [tbl,data] = LoadSelectionInMatrix(selection)
    load(selection);
    nameLocation = strfind(selection, '_graph');
    
    
    boxName= selection(1:nameLocation  -1 );
    set(findobj('Tag', 'txtGraphLabel'),'String',boxName);
    
    columnname =   {'Style', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'Legend lbl', 'Metric'};
    columnformat = { {'ignore' 'normal' '-' '-.' '--' ':' 'B-' 'B-.' 'B--' 'B:'}, ...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...    
    'char', {'SimIter' 'TotActi' 'SimIterStd' 'TotActiStd' 'SimIterBound' 'TotActiBound' ... 
    'SimIterDev' 'TotActiDev' 'AvgReward' 'AvgRewardStd' 'StdTime' 'StdEffort' 'CoopRate' 'IncorAct' 'FalseRwd' 'ReadErr' } };


    columneditable =  [true false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    true true ]; 

    tbl = findobj('Tag', 'tblGraphProperties');

    set(tbl,'Units','normalized');
    set(tbl,'Data',dat);
    set(tbl,'ColumnName',columnname);
    set(tbl,'ColumnFormat',columnformat);
    set(tbl,'ColumnEditable', columneditable);
    
    csz =0.5;
    
    set(tbl,'ColumnWidth', {70 30 csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    200 80 80});

    set(tbl,'RowName',[]);
    
    set(tbl,'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
    set(findobj('Tag', 'txtXaxisLabel'),'String',XAxisLabel);
    set(findobj('Tag', 'txtYaxisLabel'),'String',YAxisLabel);
    set(findobj('Tag', 'txtLabel'),'String',graphLabel);

    set(findobj('Tag', 'txtXGraph'),'String',XLimit);
    set(findobj('Tag', 'txtYGraph'),'String',YLimit);
    set(findobj('Tag', 'txtRunsGraph'),'String',RunLimit);
    data = get(tbl,'Data');

% --- Executes during object creation, after setting all properties.
function lstGraphTypes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstGraphTypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnNewGraphType.
function btnNewGraphType_Callback(hObject, eventdata, handles)
% hObject    handle to btnNewGraphType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name = get(findobj('Tag', 'txtGraphLabel'),'String');
if(isempty(name))
disp('Aborted Create');
    return;
end


dat =  {...
  'normal', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    'ignore', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'legend',  'SimIter';...
    };
columnname =   {'Style', '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','', 'Legend lbl', 'Metric'};
columnformat = { {'ignore' 'normal' '-' '-.' '--' ':' 'B-' 'B-.' 'B--' 'B:'}, ...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...
    'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char',...    
    'char', {'SimIter' 'TotActi' 'SimIterStd' 'TotActiStd' 'SimIterBound' 'TotActiBound' ... 
    'SimIterDev' 'TotActiDev' 'AvgReward' 'AvgRewardStd' 'StdTime' 'StdEffort' 'CoopRate' 'IncorAct' 'FalseRwd' 'ReadErr' }};


columneditable =  [true false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    false false false false false false false false false false false false false false false ... 
    true true]; 
tbl = findobj('Tag', 'tblGraphProperties');

set(tbl,'Units','normalized');
set(tbl,'Data',dat);
set(tbl,'ColumnName',columnname);
set(tbl,'ColumnFormat',columnformat);
set(tbl,'ColumnEditable', columneditable);

XAxisLabel = 'Default X';
YAxisLabel = 'Default Y';
graphLabel = 'Default Title';
XLimit = '300';
YLimit = '150000';
RunLimit= '300';



set(findobj('Tag', 'txtXaxisLabel'),'String', XAxisLabel);
set(findobj('Tag', 'txtYaxisLabel'),'String', YAxisLabel);
set(findobj('Tag', 'txtLabel'),'String', graphLabel);

set(findobj('Tag', 'txtXGraph'),'String', XLimit);
set(findobj('Tag', 'txtYGraph'),'String', YLimit);
set(findobj('Tag', 'txtRunsGraph'),'String', RunLimit);


csz =0.5;
set(tbl,'ColumnWidth', {70 30 csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    csz csz csz csz csz csz csz csz csz csz csz csz csz csz csz ...
    200 80});

set(tbl,'RowName',[]);

set(tbl,'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));

    QuickSave();
    PopulateFileListbox('_graph_data.mat','lstGraphTypes','',0);



function SaveGraphType(dat,name,XAxisLabel,YAxisLabel,graphLabel,XLimit,YLimit,RunLimit)
save(strcat(name,'_graph_data'),'name');
save(strcat(name,'_graph_data'),'dat','-append');
save(strcat(name,'_graph_data'),'XAxisLabel','-append');
save(strcat(name,'_graph_data'),'YAxisLabel','-append');
save(strcat(name,'_graph_data'),'graphLabel','-append');
save(strcat(name,'_graph_data'),'XLimit','-append');
save(strcat(name,'_graph_data'),'YLimit','-append');
save(strcat(name,'_graph_data'),'RunLimit','-append');


function txtGraphLabel_Callback(hObject, eventdata, handles)
% hObject    handle to txtGraphLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGraphLabel as text
%        str2double(get(hObject,'String')) returns contents of txtGraphLabel as a double


% --- Executes during object creation, after setting all properties.
function txtGraphLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGraphLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnSetGraphRow.
function btnSetGraphRow_Callback(hObject, eventdata, handles)
% hObject    handle to btnSetGraphRow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    tbl = findobj('Tag', 'tblGraphProperties');
    data = get(tbl,'Data');
    indSel = get(tbl,'UserData');
    UpdateGraphTypeData('fileList',indSel,data{indSel(1),indSel(2)});

function UpdateGraphTypeData(from,ind,cellDat)
    
    fileNames = get(findobj('Tag', 'lstGraphTypes'),'UserData');
    selections = get(findobj('Tag', 'lstGraphTypes'),'Value');
    

    for selCount=1:size(selections,2)
        if(selections(selCount) > 0)
            selectId = selections(selCount);
            selection = fileNames(selectId,:);

            dotMatExtensionLocation = strfind(selection, '.mat');

            selection = selection(1:dotMatExtensionLocation -1 );
            SetGraphRow(selection,from,ind,cellDat);
        end
    end


function SetGraphRow(name,from,ind,cellDat)

    
    [tbl, data] = LoadSelectionInMatrix(name);

    fileNames = get(findobj('Tag', 'lstFiles'),'UserData');
    selections = get(findobj('Tag', 'lstFiles'),'Value');
    
    if(from == 'fileList')
        count = 2;
        sizeCols = 60;
        indRow = ind(1);
        for i=2:(sizeCols +1)
            data{indRow,i} = '';
        end

        count = 2;
        for i=1:size(selections,2)
            if(selections(i) > 0) 
                selection = fileNames(selections(i),:);

                dotMatExtensionLocation1 = strfind(selection, '_iter');
                dotMatExtensionLocation2 = strfind(selection, '_blob');
                dotMatExtensionLocation = max([dotMatExtensionLocation1 dotMatExtensionLocation2]);
                selection = selection(1:dotMatExtensionLocation-1);
                data{indRow,count} = selection;
                count = count +1;

                if count > 60
                    break;
                end
            end
        end
    else
        disp('here')
            data{ind(1),ind(2)} = cellDat;
    end
    cellDat
    set(tbl,'Data',data);
    QuickSave();



% --- Executes when entered data in editable cell(s) in tblGraphProperties.
function tblGraphProperties_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tblGraphProperties (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

    tbl = findobj('Tag', 'tblGraphProperties');
    data = get(tbl,'Data');
    indSel = get(tbl,'UserData');
    UpdateGraphTypeData('cellData',indSel,data{indSel(1),indSel(2)});

%{
name = get(findobj('Tag', 'txtGraphLabel'),'String');
if(isempty(name))
disp('Aborted Alter');
    return;
end
tbl = findobj('Tag', 'tblGraphProperties');

dat = get(tbl,'Data');

QuickSave();

%}

% --- Executes on button press in btnSaveGraphType.
function btnSaveGraphType_Callback(hObject, eventdata, handles)
% hObject    handle to btnSaveGraphType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
QuickSave();
    PopulateFileListbox('_graph_data.mat','lstGraphTypes','',0);


% --- Executes on button press in btnDeleteGraphType.
function btnDeleteGraphType_Callback(hObject, eventdata, handles)
% hObject    handle to btnDeleteGraphType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name = get(findobj('Tag', 'txtGraphLabel'),'String');
if(isempty(name))
disp('Aborted Delete ');
    return;
end

delete(strcat(name,'_graph_dat*.mat'));
PopulateFileListbox('_graph_data.mat','lstGraphTypes','',0);


function QuickSave()
    name = get(findobj('Tag', 'txtGraphLabel'),'String');
    if(isempty(name))
        disp('Quick Save Fail');
        return;
    end

    name 

    dat= get(findobj('Tag', 'tblGraphProperties'),'Data');
    SaveGraphType(dat,name,get(findobj('Tag', 'txtXaxisLabel'),'String'),...
    get(findobj('Tag', 'txtYaxisLabel'),'String'),...
    get(findobj('Tag', 'txtLabel'),'String'),...
    get(findobj('Tag', 'txtXGraph'),'String'),...
    get(findobj('Tag', 'txtYGraph'),'String'),....
    get(findobj('Tag', 'txtRunsGraph'),'String'));

function txtXaxisLabel_Callback(hObject, eventdata, handles)
% hObject    handle to txtXaxisLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtXaxisLabel as text
%        str2double(get(hObject,'String')) returns contents of txtXaxisLabel as a double

QuickSave();


% --- Executes during object creation, after setting all properties.
function txtXaxisLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtXaxisLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtYaxisLabel_Callback(hObject, eventdata, handles)
% hObject    handle to txtYaxisLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtYaxisLabel as text
%        str2double(get(hObject,'String')) returns contents of txtYaxisLabel as a double
QuickSave();


% --- Executes during object creation, after setting all properties.
function txtYaxisLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtYaxisLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtLabel_Callback(hObject, eventdata, handles)
% hObject    handle to txtLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtLabel as text
%        str2double(get(hObject,'String')) returns contents of txtLabel as a double
QuickSave();


% --- Executes during object creation, after setting all properties.
function txtLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in graphGraphType.
function graphGraphType_Callback(hObject, eventdata, handles)
% hObject    handle to graphGraphType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    QuickSave();
    fileNames = get(findobj('Tag', 'lstGraphTypes'),'UserData');
    selections = get(findobj('Tag', 'lstGraphTypes'),'Value');

    
    uitableData = {};
    meansstds = [];
    meansstdsc = [];

    for selCount=1:size(selections,2)
        selectId = selections(selCount);
        selection = fileNames(selectId,:);

        dotMatExtensionLocation = strfind(selection, '.mat');
        nameLocation = strfind(selection, '_graph');

        selection = selection(1:dotMatExtensionLocation -1 );
        load(selection);
        axis = [0 str2num(XLimit) 0 str2num(YLimit)];
        runs = str2num(RunLimit);
        legendIds = [];
        
        figure();
        clf('reset');
        dataAll = [];        
        count = 1;
        tblSize = 0;
        for j=1:size(dat,1)
                if(strcmp(dat{j,1},'ignore')==0)
                    tblSize = tblSize +1;
                end
        end
       % uitableData = zeros{tblSize^2, 6};
        %In this loop we print and save a graph
        for j=1:size(dat,1)
           fileList = {};
            fileId = 2;
            %if we should display
            if(strcmp(dat{j,1},'ignore')==0)

                %get all the data file names -> fileList
                while(fileId <= 62 && ~isempty(dat{j,fileId}))
                    fileList{fileId-1,1} = dat{j,fileId};
                    dispDat = dat{j,fileId};
                    fileId = fileId +1;
                end
                %and get the style -> (width,style)
                style  =dat{j,1};
                if(strcmp(dat{j,1},'normal')==1)
                    style = '-';
                end
                styleFront = dat{j,1};
                width = 0.5;
                if(styleFront(1)=='B')
                    width = 1.5;
                    dat{j,1} = styleFront(2:size(styleFront,2));
                end
                graphtype=dat{j,63};
                %figure out the data type -> graphtype
                if(strcmp(graphtype,'SimIter')==1)
                    graphtype = 1;
                elseif(strcmp(graphtype,'TotActi')==1)
                    graphtype =2;
                elseif(strcmp(graphtype,'SimIterStd')==1)
                    graphtype = 3;
                elseif(strcmp(graphtype,'TotActiStd')==1)
                    graphtype =4;
                elseif(strcmp(graphtype,'SimIterBound')==1)
                    graphtype =5;
                elseif(strcmp(graphtype,'TotActiBound')==1)
                    graphtype =6;
                elseif(strcmp(graphtype,'SimIterDev')==1)
                    graphtype =7;
                elseif(strcmp(graphtype,'TotActiDev')==1)
                    graphtype =8;
                elseif(strcmp(graphtype,'AvgReward')==1)
                    graphtype =9;
                elseif(strcmp(graphtype,'AvgRewardStd')==1)
                    graphtype =10;
                elseif(strcmp(graphtype,'StdTime')==1)
                    graphtype =11;
                elseif(strcmp(graphtype,'StdEffort')==1)
                    graphtype =12;
                elseif(strcmp(graphtype,'CoopRate')==1)
                    graphtype =13;
                elseif(strcmp(graphtype,'IncorAct')==1)
                    graphtype =14;
                elseif(strcmp(graphtype,'FalseRwd')==1)
                    graphtype =15;
                elseif(strcmp(graphtype,'ReadErr')==1)
                    graphtype =16;
                else
                    graphtype =1;
                end
                legendIds = [legendIds j];
                %then graph
                [m, s,dataCore,dataIn,mc,sc] = ShowGraphLine(graphtype,axis,300,style,fileList,width );
                
                meansstds = [meansstds; m s];
                meansstdsc = [meansstdsc; mc sc];
                size(dataAll)
                size(dataCore)                
                for k=1:2
                    
                    if(size(dataCore,k) >size (dataAll,k) && size(dataAll,k) > 0)
                        if(k==1)
                            dataCore = dataCore(1:size(dataAll,k),:);
                            
                        else %k==2 trials number
                            sz2 = size(dataAll,2);
                            szE = size(dataCore,2);
                            lent = szE - sz2;
                            dataAll(:,sz2:szE,:) = 0;
                            %dataCore = dataCore(:,1:size(dataAll,k),:);
                        end
                    end
                    if(size(dataCore,k) <size (dataAll,k))
                        if(k==1)
                            dataAll = dataAll(1:size(dataCore,k),:);
                        else%k==2 trials number
                            sz2 = size(dataCore,2);
                            szE = size(dataAll,2);
                            lent = szE - sz2;
                            dataCore(:,sz2:szE) = 0;
                            %dataAll = dataAll(:,1:size(dataCore,k),:);
                        end
                    end
                end
                size(dataAll)
                size(dataCore)
                
                dataAll(:,:,count) = dataCore;
                count = count +1;
                
            end
            
        end
        
        
        %legendEntries = [];
        legend(dat{legendIds,62});
        title(graphLabel);

        xlabel(XAxisLabel );
        ylabel(YAxisLabel);
        print (gcf, '-dbmp', strcat(selection,'.bmp')); 
        for con= 0:1
            if(con == 0)
                disp('Total Tests')
                sz = 1:(size(dataAll,1)-100);
            else
                disp('Converged Tests (last 100 iterations)')
                sz = (size(dataAll,1)-100):size(dataAll,1);
            end

            if(get(findobj('Tag', 'chkMeans'),'Value')==1)

                figure();
                if(con == 0)
                    data = meansstds;
                else
                    data = meansstdsc;
                end
                
                
                [ordering,orderingKeys]= sort(data(:,1));
                
                MeanStdGraph(data(orderingKeys,:));
                set(gcf, 'color', 'white'); 
                grid on;
                %legend(dat{legendIds,17});
                labelList = {};
                newIds = legendIds(:,orderingKeys);
                
                for i=1:size(newIds ,2)
                    labelList{i} =  dat{newIds (i),62};
                end
                set(gca,'XTickLabel',labelList);                
                %xlabel('Approaches');
                if(con == 0)
                    ylabel(strcat(YAxisLabel,' Learning Means'));
                    print (gcf, '-dbmp', strcat(selection,'_means_all.bmp')); 
                else
                    ylabel(strcat(YAxisLabel,' Converged Means'));
                    print (gcf, '-dbmp', strcat(selection,'_means_converged.bmp')); 
                end
            end
            
            shownVals = zeros(size(dataAll,3)  ,size(dataAll,3)  );
           
            tableIndex = 1;
                for i= 1:size(dataAll,3)
                    for j= 1:size(dataAll,3)     
                        if(i~= j && shownVals(i,j)==0 && shownVals(j,i)==0)
                            
                            shownVals(i,j)=1;
                            shownVals(j,i)=1;
                            showTT = 0;
                            if(get(findobj('Tag', 'chkTT'),'Value')==1)
                                figure();
                                showTT =1;
                            end
                            [tt,ttProfile,pVal,pValProfile,dof ...
                                ,dofProfile,ttCountedPercentage ...
                                pValAll,dofAll] = UnPairedTTest(dataAll(sz,:,i),dataAll(sz,:,j),0.05,showTT );
                            a = [];
                            b = []; 
                            pre = [];
                            for k=1:100
                                disp(strcat('Debug-',num2str(k)))
                                a = [a dataAll(sz(k),:,i)'];
                                b = [b dataAll(sz(k),:,j)'];
                            end
                            
                            for k=1:100
                                new = [ ttProfile(k)';...
                                pValProfile(k)';...
                                dofProfile(k)'];
                                pre = [pre new];
                            end
                            a(1,1)
                            b(1,1)
                            save('debugStatDat', 'a');
                            save('debugStatDat', 'b','-append');
                            save('debugStatDat', 'pre','-append');
                            
                            mean1 = num2str(meansstds(i,1));
                            std1 = num2str(meansstds(i,2));
                            leg1 = '';
                            %leg1=strcat(dat{legendIds(i),62},'(',mean1(1:5),',',std1(1:5),')');

                            mean2 = num2str(meansstds(j,1));
                            std2 = num2str(meansstds(j,2));
                            leg2 = '';
                            %eg2=strcat(dat{legendIds(j),62},'(',mean2(1:5),',',std2(1:5),')');
                            if(get(findobj('Tag', 'chkTT'),'Value')==1)
                                legend([leg1 leg2 ]);

                                title(strcat(num2str(con),':(',dat{legendIds(i),62},')and('...
                                    ,dat{legendIds(j),62},')tt:',num2str(tt),')pVal:',num2str(pVal)...
                                    ,')percentBelow p<0.05:',num2str(ttCountedPercentage),'pVal:',num2str(pVal)...
                                    ,'dof:',num2str(dof)...
                                    ,'pValAll:',num2str(pValAll)...
                                    ,'dofAll:',num2str(dofAll)));
                            end
                            disp(strcat( dat{legendIds(i),62}, dat{legendIds(j),62}));
                            disp(strcat('(',num2str(ttCountedPercentage),',',num2str(pVal),',',num2str(dof),')'));
                            
                            if(con == 0)
                                uitableData{tableIndex,con*4+1} = strcat( dat{legendIds(i),62},' vs. ', dat{legendIds(j),62});
                                adjust = 1;
                            else
                                adjust =0;
                            end
                            
                            old = digits(2);
                            uitableData{tableIndex,con*4+1+adjust} = pValAll;
                            uitableData{tableIndex,con*4+2+adjust} = ttCountedPercentage;
                            uitableData{tableIndex,con*4+3+adjust} = dofAll;
                            digits(old);
                            tableIndex = tableIndex +1;
                            
                            %disp(strcat('[1,',num2str(pValAll),',',num2str(dofAll),']'));
                            %disp(strcat('Paired TT:', dat{legendIds(i),17}));
                            %disp(strcat('Paired TT:', dat{legendIds(i),17}));
                            %disp(strcat('Paired TT:', dat{legendIds(i),17}, ':and:',dat{legendIds(j),17},':is:',num2str(tt),':mintt:',num2str(min(ttprofile))));
                            %disp(strcat('Mean :', dat{legendIds(i),17},':', num2str(meansstds(i,1))));
                            %disp(strcat('STD :', dat{legendIds(i),17},':', num2str(meansstds(i,2))));
                            %disp(strcat('Mean :', dat{legendIds(j),17},':', num2str(meansstds(j,1))));
                            %disp(strcat('STD :', dat{legendIds(j),17},':', num2str(meansstds(j,2))));
                        end      
                    end
                end
            end
        end
    if(get(findobj('Tag', 'chkMatrix'),'Value')==1)
        f = figure('Position', [100 100 752 350]);
        t = uitable('Parent', f, 'Position', [25 25 700 200]);
        set(t, 'Data', uitableData);
    end %%
    
    
        
function [totalMean, totalVariance,dataCore,dataIn,totalMeanConverged,totalVarianceConverged] = ShowGraphLine(graphtype,axisIn,runs,style,fileList,width )
    %winName =  get(findobj('Tag', 'windowHandle'),'String');
    %if(winName == 'null')
    %    winHand = figure();
    %    set(findobj('Tag', 'windowHandle'),'String',num2str(winHand));
    %end

    %winHand =  str2double(get(findobj('Tag', 'windowHandle'),'String'));    
    
    %figure(winHand);
    if(graphtype == 15)
        axisIn(3)=1.4;
    end
    
    axis(axisIn);
    
    hold on;
    grid on;
    
    movingAveragePointsIndividual = 1;
    movingAveragePoints = 10;
    sr = SimResults();
    
    %sr.GraphResults(graphtype,100,[0 100 0 100],id);
    %movingAveragePointsIndividual = 10;
    try
        sr.Load('',runs,[],[],0.00000001,movingAveragePointsIndividual,fileList);
    catch err
        
        cd('..');
           rethrow(err);        
    end    
        
    dataIn2 = [];
    totalMean = 0;
    totalMeanConverged = 0;
    totalVarianceConverged = 0;
    
    totalVariance = 0;
    begin = size(sr.avgRms)-100;
    theend = size(sr.avgRms,1);
    if(begin < 1)
        begin = 1;
    end

    if(graphtype == 1)
        dataIn = sr.avgRms;
        dataCore = sr.rawRms;

        totalMean = sum(dataIn,1)/size(dataIn,1);
        totalVariance = sum(sr.stdRms,1)/size(sr.stdRms,1);
        totalMeanConverged = sum(dataIn(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdRms(begin:theend),1)/(size(begin:theend,2));
        
    elseif(graphtype == 2)
        dataIn = sr.avgActionsTarg;
        dataCore = sr.rawActionsTarg;
        totalMean = sum(dataIn,1)/size(dataIn,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(dataIn(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2));
        
    elseif(graphtype == 3)
        dataIn = sr.avgRms + sr.stdRms*2;
        dataCore = sr.rawRms;
        totalMean = sum(sr.avgRms,1)/size(sr.avgRms,1);
        totalVariance = sum(sr.stdRms,1)/size(sr.stdRms,1);
        totalMeanConverged = sum(sr.avgRms(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdRms(begin:theend),1)/(size(begin:theend,2));
                
        %dataIn2 = sr.stdRms + dataIn;
    elseif(graphtype == 4)
        dataIn = sr.avgActionsTarg +  sr.stdActionsTarg*2 ;
        dataCore = sr.rawActionsTarg;
        totalMean = sum(sr.avgActionsTarg,1)/size(sr.avgActionsTarg,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(sr.avgActionsTarg(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2));
           
        %dataIn2 = sr.stdActionsTarg + dataIn;
    elseif(graphtype == 5)
        dataIn = sr.avgActionsTarg;
        dataIn2 = sr.maxRms + dataIn;
        dataCore = sr.rawActionsTarg;
        totalMean = sum(sr.avgActionsTarg,1)/size(sr.avgActionsTarg,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(sr.avgActionsTarg(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2));

    elseif(graphtype == 6)
        dataIn = sr.avgActionsTarg;
        dataCore = sr.rawActionsTarg;
        
        dataIn2 = sr.maxActions + dataIn;
        totalMean = sum(sr.avgActionsTarg,1)/size(sr.avgActionsTarg,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(sr.avgActionsTarg(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2));
        
    elseif(graphtype == 7)
        dataIn = sr.avgRms;
        dataIn2 = sr.absDevRms;
        dataCore = sr.rawRms;
        
    elseif(graphtype == 8)
        dataIn = sr.avgActionsTarg;
        dataIn2 = sr.absDevActions;
        dataCore = sr.rawActionsTarg;
        totalMean = sum(sr.avgActionsTarg,1)/size(sr.avgActionsTarg,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(sr.avgActionsTarg(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2));
        
    elseif(graphtype == 9)
        dataIn = sr.rwdPerLearnTarg;
        dataCore = [];
        totalMean = sum(sr.rwdPerLearnTarg,1)/size(sr.rwdPerLearnTarg,1);
        totalVariance = sum(sr.stdRwdPerLearnTarg,1)/size(sr.stdRwdPerLearnTarg,1);
        totalMeanConverged = sum(sr.rwdPerLearnTarg(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdRwdPerLearnTarg(begin:theend),1)/(size(begin:theend,2));

    elseif(graphtype == 10)
        dataIn = sr.rwdPerLearnTarg - sr.stdRwdPerLearnTarg.*2;
        dataCore = [];
    elseif(graphtype == 11)
        dataIn = sr.stdRms;
        dataCore = sr.stdRms;
        totalMean = sum(sr.avgRms,1)/size(sr.avgRms,1);
        totalVariance = sum(sr.stdRms,1)/size(sr.stdRms,1);
        totalMeanConverged = sum(sr.avgRms(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdRms(begin:theend),1)/(size(begin:theend,2));
        
        %dataIn2 = sr.stdRms + dataIn;
    elseif(graphtype == 12)
        dataIn = sr.stdActionsTarg;
        dataCore = sr.stdActionsTarg;

        totalMean = sum(sr.avgActionsTarg,1)/size(sr.avgActionsTarg,1);
        totalVariance = sum(sr.stdActionsTarg,1)/size(sr.stdActionsTarg,1);
        totalMeanConverged = sum(sr.avgActionsTarg(begin:theend),1)/(size(begin:theend,2)-100);
        totalVarianceConverged = sum(sr.stdActionsTarg(begin:theend),1)/(size(begin:theend,2)-100);
                
        %dataIn2 = sr.stdActionsTarg + dataIn;
    elseif(graphtype == 13)
        dataIn = sr.avgActionsCoop;
        dataCore = [];
        totalMean = sum(sr.avgActionsCoop,1)/size(sr.avgActionsCoop,1);
        totalVariance = sum(sr.stdActionsCoop,1)/size(sr.stdActionsCoop,1);
        totalMeanConverged = sum(sr.avgActionsCoop(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdActionsCoop(begin:theend),1)/(size(begin:theend,2));
                        %dataIn2 = sr.stdActionsTarg + dataIn;
    elseif(graphtype == 14) %Incorrect Action
        dataIn = sr.avgIncorrectAction;
        dataCore = [];
        totalMean = sum(sr.avgIncorrectAction,1)/size(sr.avgIncorrectAction,1).*0;
        totalVariance = sum(sr.avgIncorrectAction,1)/size(sr.avgIncorrectAction,1).*0;
        totalMeanConverged = sum(sr.avgIncorrectAction(begin:theend),1)/(size(begin:theend,2)).*0;
        totalVarianceConverged = sum(sr.avgIncorrectAction(begin:theend),1)/(size(begin:theend,2)).*0;
                        %dataIn2 = sr.stdActionsTarg + dataIn;
    elseif(graphtype == 15) %Expected False Reward
        dataIn = sr.avgExpectedFalseReward;
        dataCore = [];
        
        totalMean = sum(sr.avgExpectedFalseReward,1)/size(sr.avgExpectedFalseReward,1).*0;
        totalVariance = sum(sr.avgExpectedFalseReward,1)/size(sr.avgExpectedFalseReward,1).*0;
        totalMeanConverged = sum(sr.avgExpectedFalseReward(begin:theend),1)/(size(begin:theend,2)).*0;
        totalVarianceConverged = sum(sr.avgExpectedFalseReward(begin:theend),1)/(size(begin:theend,2)).*0;
                        %dataIn2 = sr.stdActionsTarg + dataIn;
    elseif(graphtype == 16) %Average Reading Error Distance
        dataIn = sr.avgExpectedChangeDistance;
        dataCore = [];
        totalMean = sum(sr.avgExpectedChangeDistance,1)/size(sr.avgExpectedChangeDistance,1).*0;
        totalVariance = sum(sr.avgExpectedChangeDistance,1)/size(sr.avgExpectedChangeDistance,1).*0;
        totalMeanConverged = sum(sr.avgExpectedChangeDistance(begin:theend),1)/(size(begin:theend,2)).*0;
        totalVarianceConverged = sum(sr.avgExpectedChangeDistance(begin:theend),1)/(size(begin:theend,2)).*0;

    else
        dataIn = sr.avgRms;
        dataCore = sr.rawRms;
        totalMean = sum(sr.avgRms,1)/size(sr.avgRms,1);
        totalVariance = sum(sr.stdRms,1)/size(sr.stdRms,1);
        totalMeanConverged = sum(sr.avgRms(begin:theend),1)/(size(begin:theend,2));
        totalVarianceConverged = sum(sr.stdRms(begin:theend),1)/(size(begin:theend,2));
    end
    
    
    datNoise = removeOutliers(dataIn,0.00000001,movingAveragePoints);
    
    plot([datNoise],style,'color','k','LineWidth',width);
    if(~isempty(dataIn2))
        datNoise2 = removeOutliers(dataIn2 ,0.00000001,movingAveragePoints);
        plot([datNoise2],style,'color','k','LineWidth',width);
    end


    set(gcf,'color','white');
    
    



% --- Executes during object creation, after setting all properties.
function graphGraphType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to graphGraphType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function txtRunsGraph_Callback(hObject, eventdata, handles)
% hObject    handle to txtRunsGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRunsGraph as text
%        str2double(get(hObject,'String')) returns contents of txtRunsGraph as a double
QuickSave();

% --- Executes during object creation, after setting all properties.
function txtRunsGraph_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRunsGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtYGraph_Callback(hObject, eventdata, handles)
% hObject    handle to txtYGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtYGraph as text
%        str2double(get(hObject,'String')) returns contents of txtYGraph as a double
QuickSave();

% --- Executes during object creation, after setting all properties.
function txtYGraph_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtYGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtXGraph_Callback(hObject, eventdata, handles)
% hObject    handle to txtXGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtXGraph as text
%        str2double(get(hObject,'String')) returns contents of txtXGraph as a double
QuickSave();

% --- Executes during object creation, after setting all properties.
function txtXGraph_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtXGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function [tt,ttprofile,pVal,pValProfile ]= PairedTTest(data1,data2)
    newSize = size(data1,1);
    data1New = 0;
    data2New = 0;
    
    for h=0:size(data1,2)-1
        begin_ = 1 + h*newSize;
        end_ = (h+1)*newSize;
        data1New(begin_:end_,1) =data1(:,h+1);
        data2New(begin_:end_,1) =data2(:,h+1);

    end
    data1 = data1New;
    data2 = data2New;
    if(sum(sum(data1,1),2)==0)
        fasfasfa;
    end
    if(sum(sum(data2,1),2)==0)
        fasfasfa;
    end
    disp (strcat('Datapoints:',num2str(h)));

    n = size(data1,1);
    data1A = sum(data1,1)/n;
    data2A = sum(data2,1)/n;
    
    movingAverage1 = removeOutliers(data1,0.00000001,10);
    movingAverage2 = removeOutliers(data2,0.00000001,10);
    data1Hat = data1 - movingAverage1;
    data2Hat = data2 - movingAverage2;

    
    dataMinus = data1Hat - data2Hat;
    dataMinusSquared = dataMinus.^2;  

    %dataMinusSquaredMoving =  removeOutliers(dataMinusSquared,0.00000001,5).*5;

    
    tt = (data1A - data2A).*sqrt((n*(n-1))/(sum(dataMinusSquared,1)));
    hold on;
    plot(movingAverage1,'b' );
    hold on;
    plot(movingAverage2,'r' );
    hold on;
    plot(data1,'o','color','b');
    hold on;
    plot(data2,'o','color','r');
    hold on;
    plot(data1A.*ones(1,size(movingAverage1,1)),'b' );
    hold on;
    plot(data2A.*ones(1,size(movingAverage2,1)),'r' );
    hold on;
    drawnow;
    
    %tt = (movingAverage1 - movingAverage2).*sqrt((n*(n-1))./(dataMinusSquaredMoving));
    %tt = abs(tt);
    %tt = sum(tt,1)/n;
    ttprofile = 0;
    pVal = 1-tcdf(abs(tt),n-1); 

function [tt,ttProfile,pVal,pValProfile,dof,dofProfile,ttCountedPercentage,pValAll,dofAll ]= UnPairedTTest(data1,data2,alpha,show)
    
    foundZeros =1;
    while (foundZeros == 1)
        foundZeros = 0;
        for i=1:size(data1,2)
            if(sum(data1(:,i),1)==0)
                foundZeros = 1;
                data1(:,i) = [];
                break;
            end
        end
        for i=1:size(data2,2)
            if(sum(data2(:,i),1)==0)
                foundZeros = 1;
                data2(:,i) = [];
                break;
            end
        end
        if(foundZeros == 0)
            break;
        end
    end
    disp('Error Debug N')
    size(data1)
    size(data2)
    disp('Error Debug End')
    
    data1Avg = sum(data1,2)/size(data1,2);
    data2Avg = sum(data2,2)/size(data2,2);
    
    n = size(data1,1);
    nDof1 = size(data1,2);
    nDof2 = size(data2,2);
    %nDof = 40;
    
    data1A = sum(data1Avg,1)/n;
    data2A = sum(data2Avg,1)/n;

    diff1 = bsxfun(@minus,data1, data1Avg);
    diff2 = bsxfun(@minus,data2, data2Avg);

    var1 = sum(diff1.^2,2)/size(diff1,2);
    var2 = sum(diff2.^2,2)/size(diff2,2);
    var1 = var1 + (var1 ==0).*0.00000001;
    var2 = var2 + (var2 ==0).*0.00000001;
    
    
    v1 = nDof1-1;
    v2 = nDof2-1;
    
    sd1 = sqrt(var1);
    sd2 = sqrt(var2);
    
    varCom = (var1/nDof1+ var2/nDof2);
    varCom2 = ((var1.^2)/(v1.*nDof1.^2)+(var2.^2)/(v2.*nDof2.^2));
    
    dofProfile = (varCom .^2)./(varCom2);    
    ttProfile = (data1Avg - data2Avg)./sqrt(varCom );
    
    pValProfile = (1-tcdf(abs(ttProfile),dofProfile)).*2; 
    
    ttCountedIndicies = (pValProfile < alpha);
    
    ttCountedPercentage = sum(ttCountedIndicies,1)/n;

    dof = sum(dofProfile .*ttCountedIndicies,1)/sum(ttCountedIndicies,1);
    tt = sum(ttProfile .*ttCountedIndicies,1)/sum(ttCountedIndicies,1);
    pVal = sum(pValProfile .*ttCountedIndicies,1)/sum(ttCountedIndicies,1);
    pValAll = sum(pValProfile,1)/n;
    dofAll = sum(dofProfile,1)/n;
    
    if(show == 1)
        hold on;
        plot(data1Avg,'b' );
        hold on;
        plot(data2Avg,'r' );
        hold on;

        for i=1:size(data1,2)
            plot(data1(:,i),'o','color','b');
            hold on;
        end
        for i=1:size(data2,2)
            plot(data2(:,i),'o','color','b');
            hold on;
        end
        drawnow;
    end
    
    ttprofile = 0;
    

function MeanStdGraph(meanstds)
barwitherr(meanstds(:,2),meanstds(:,1),'w')    
        %bar(meanstds(:,1))
    %meanstds(:,2)


% --- Executes on button press in chkGraph.
function chkGraph_Callback(hObject, eventdata, handles)
% hObject    handle to chkGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkGraph


% --- Executes on button press in chkTT.
function chkTT_Callback(hObject, eventdata, handles)
% hObject    handle to chkTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkTT


% --- Executes on button press in chkMeans.
function chkMeans_Callback(hObject, eventdata, handles)
% hObject    handle to chkMeans (see GCBO)9999999999999999999997


% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMeans


% --- Executes on button press in rbLAllOld.
function rbLAllOld_Callback(hObject, eventdata, handles)
% hObject    handle to rbLAllOld (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();


% Hint: get(hObject,'Value') returns toggle state of rbLAllOld


% --- Executes on button press in rbAdvExcAgg.
function rbAdvExcAgg_Callback(hObject, eventdata, handles)
% hObject    handle to rbAdvExcAgg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();
% Hint: get(hObject,'Value') returns toggle state of rbAdvExcAgg


% --- Executes on button press in rbComSenOff.
function rbComSenOff_Callback(hObject, eventdata, handles)
% hObject    handle to rbComSenOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();
% Hint: get(hObject,'Value') returns toggle state of rbComSenOff


% --- Executes on button press in rbComSenOn.
function rbComSenOn_Callback(hObject, eventdata, handles)
% hObject    handle to rbComSenOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();
% Hint: get(hObject,'Value') returns toggle state of rbComSenOn


% --- Executes during object creation, after setting all properties.
function uipanel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in btnGraphRefresh.
function btnGraphRefresh_Callback(hObject, eventdata, handles)
% hObject    handle to btnGraphRefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PopulateFileListbox('_graph_data.mat','lstGraphTypes','',0);


% --- Executes on button press in chkMatrix.
function chkMatrix_Callback(hObject, eventdata, handles)
% hObject    handle to chkMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMatrix


% --- Executes when selected object is changed in uipanel11.
function uipanel11_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel11 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rbTimeLimitOn.
function rbTimeLimitOn_Callback(hObject, eventdata, handles)
% hObject    handle to rbTimeLimitOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();
% Hint: get(hObject,'Value') returns toggle state of rbTimeLimitOn


% --- Executes on button press in rbTimeLimitOff.
function rbTimeLimitOff_Callback(hObject, eventdata, handles)
% hObject    handle to rbTimeLimitOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshConfigId();
% Hint: get(hObject,'Value') returns toggle state of rbTimeLimitOff
