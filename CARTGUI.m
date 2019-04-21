function varargout = CARTGUI(varargin)
% CARTGUI MATLAB code for CARTGUI.fig
%      CARTGUI, by itself, creates a new CARTGUI or raises the existing
%      singleton*.
%
%      H = CARTGUI returns the handle to a new CARTGUI or the handle to
%      the existing singleton*.
%
%      CARTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CARTGUI.M with the given input arguments.
%
%      CARTGUI('Property','Value',...) creates a new CARTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CARTGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CARTGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CARTGUI

% Last Modified by GUIDE v2.5 20-Apr-2019 10:28:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CARTGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CARTGUI_OutputFcn, ...
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


% --- Executes just before CARTGUI is made visible.
function CARTGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CARTGUI (see VARARGIN)

% Choose default command line output for CARTGUI
handles.output = hObject;
options = struct('cpthresh',0.05,'minsplit',5,'maxtree',1,'maxsplits',-1);
data = struct('datafiles',[],'treeobjects',[]);
% Update handles structure
guidata(hObject, handles);
thisdata = guidata(hObject);
thisdata.options = options;
thisdata.data = data;
guidata(hObject, thisdata);
% guidata(hObject, options);
% guidata(hObject, data);

% UIWAIT makes CARTGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CARTGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in datalist.
function datalist_Callback(hObject, eventdata, handles)
% hObject    handle to datalist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns datalist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from datalist


% --- Executes during object creation, after setting all properties.
function datalist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datalist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in treelist.
function treelist_Callback(hObject, eventdata, handles)
% hObject    handle to treelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns treelist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from treelist


% --- Executes during object creation, after setting all properties.
function treelist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to treelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loaddata.
function loaddata_Callback(hObject, eventdata, handles)
% hObject    handle to loaddata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gdata = guidata(hObject);
[filename,path]=uigetfile({'*.data;*.dat;*.txt;*.csv','Data File (*.data;*.dat;*.txt;*.csv)'});
if filename ~=0%user selected something
    cd(path)
    filedata = openData(filename);%load in data to a structure
    %update gui
    if isempty(gdata.data.datafiles)%first of the list
        set(gdata.datalist,'String',{filename});
        gdata.data.datafiles={filedata};
    else
        strings = get(gdata.datalist,'String');
        strings = [strings;{filename}];
        set(gdata.datalist,'String',strings);
        gdata.data.datafiles = [gdata.data.datafiles;{filedata}];
    end
end
guidata(hObject,gdata);


% --- Executes on button press in buildtree.
function buildtree_Callback(hObject, eventdata, handles)
% hObject    handle to buildtree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gdata = guidata(hObject);
if ~isempty(gdata.data)
    %get index of data list
    ind=get(gdata.datalist,'Value');
    data = gdata.data.datafiles{ind};
    options = gdata.options;
    %build tree
    treeObject = buildTree(data,options);
    %Update gui
    if isempty(gdata.data.treeobjects)
        gdata.data.treeobjects = {treeObject};
        set(gdata.treelist,'String',[data.filename,'_Tree']);
    else
        gdata.data.treeobjects = [gdata.data.treeobjects,{treeObject}];
        strings = get(gdata.treelist,'String');
        strings = [strings;{[data.filename,'_Tree']}];
        set(gdata.treelist,'String',strings);
    end
end
guidata(hObject,gdata);


% --- Executes on button press in predicttree.
function predicttree_Callback(hObject, eventdata, handles)
% hObject    handle to predicttree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gdata = guidata(hObject);
if ~isempty(gdata.data.datafiles) && ~isempty(gdata.data.treeobjects)
    %get index of data list
    ind=get(gdata.datalist,'Value');
    data = gdata.data.datafiles{ind};
    %get index of tree list
    ind=get(gdata.treelist,'Value');
    tree = gdata.data.treeobjects{ind};
    predictTree(tree,data);
end
guidata(hObject,gdata);


% --- Executes on button press in changesettings.
function changesettings_Callback(hObject, eventdata, handles)
% hObject    handle to changesettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gdata = guidata(hObject);
%Get user option
cpstring = get(gdata.cpthreshedit,'String');
%parse option
cpdouble = str2double(cpstring);
%validate and set
if isnan(cpdouble) || cpdouble < 0 || cpdouble > 1
    set(gdata.cpthreshedit,'String','0.05');
    gdata.options.cpthresh = 0.05;
else
    gdata.options.cpthresh = cpdouble;
end

%Get user option
minsplitstring = get(gdata.minsplitedit,'String');
%parse option
minsplitdouble = str2double(minsplitstring);
%validate and set
if isnan(minsplitdouble) || minsplitdouble < 0
    set(gdata.minsplit,'String','0.05');
    gdata.options.minsplit = 5;
else
    gdata.options.minsplit = minsplitdouble;
end

%Get user option 
maxtreestring = get(gdata.maxTreeN,'String');
%parse option
maxtreedouble = str2double(maxtreestring);
%validate and set
if isnan(maxtreedouble) || maxtreedouble <= 0
    set(gdata.maxTreeN,'String','1');
    gdata.options.maxtree = 1;
else
    gdata.options.maxtree = maxtreedouble;
end

%Get user option 
maxsplitsstring = get(gdata.maxSplitN,'String');
%parse option
maxsplitsdouble = str2double(maxsplitsstring);
%validate and set
if isnan(maxsplitsdouble)
    set(gdata.maxSplitN,'String','-1');
    gdata.options.maxsplits = -1;
else
    gdata.options.maxsplits = maxsplitsdouble;
end
guidata(hObject,gdata);



function cpthreshedit_Callback(hObject, eventdata, handles)
% hObject    handle to cpthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cpthreshedit as text
%        str2double(get(hObject,'String')) returns contents of cpthreshedit as a double


% --- Executes during object creation, after setting all properties.
function cpthreshedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cpthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minsplitedit_Callback(hObject, eventdata, handles)
% hObject    handle to minsplitedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minsplitedit as text
%        str2double(get(hObject,'String')) returns contents of minsplitedit as a double


% --- Executes during object creation, after setting all properties.
function minsplitedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minsplitedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in printtree.
function printtree_Callback(hObject, eventdata, handles)
% hObject    handle to printtree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gdata = guidata(hObject);

if isempty(gdata.data.treeobjects)
    disp('No tree to print')
else
    treeInd = get(gdata.treelist,'Value');
    if length(gdata.data.treeobjects{treeInd}) > 1
        disp('No printing for multi-trees')
    else
        tree = gdata.data.treeobjects{treeInd}.printTree;
        disp(tree)
    end
end



function maxTreeN_Callback(hObject, eventdata, handles)
% hObject    handle to maxTreeN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxTreeN as text
%        str2double(get(hObject,'String')) returns contents of maxTreeN as a double


% --- Executes during object creation, after setting all properties.
function maxTreeN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxTreeN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxSplitN_Callback(hObject, eventdata, handles)
% hObject    handle to maxSplitN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxSplitN as text
%        str2double(get(hObject,'String')) returns contents of maxSplitN as a double


% --- Executes during object creation, after setting all properties.
function maxSplitN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxSplitN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
