function varargout = e3d_gui_source(varargin)
% E3D_GUI Matlab Interface - Source Configuration
%   
% Chris Sherman
% Dept. of Civil and Environmental Engineering
% University of California Berkeley
% cssherman@berkeley.edu
%
% E3D is an explicit 2D/3D elastic finite difference wave propagation code
% developed by Shawn Larsen at Lawrence Livermore National Laboratory.
% This code has been developed to serve as a MATLAB interface to E3D.  The
% primary gui for this code is called e3d_gui.

% Edit the above text to modify the response to help e3d_gui_source

% Last Modified by GUIDE v2.5 06-Apr-2013 11:19:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @e3d_gui_source_OpeningFcn, ...
                   'gui_OutputFcn',  @e3d_gui_source_OutputFcn, ...
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


%-------------------------------------------------------------------------%
%                                                                         %
%Initialization:                                                          %
%                                                                         %
%-------------------------------------------------------------------------%
function e3d_gui_source_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    handles.configdata=load('./config/e3d_config.mat');
    guidata(hObject, handles);
    source_initialize(hObject, handles);


%-------------------------------------------------------------------------%
%                                                                         %
%Handle Button Pushes                                                     %
%                                                                         %
%-------------------------------------------------------------------------%
function pushbutton1_Callback(hObject, eventdata, handles)
    source_save(hObject, handles)
    rsource=str2double(get(handles.rsource_tag,'String'));
    set(handles.rsource_tag,'String',num2str(max(1,rsource-1)))
    source_update(hObject, handles)

function pushbutton2_Callback(hObject, eventdata, handles)
    source_save(hObject, handles)
    rsource=str2double(get(handles.rsource_tag,'String'));
    nsource=str2double(get(handles.nsource_tag,'String'));
    set(handles.rsource_tag,'String',num2str(min(nsource,rsource+1)))
    source_update(hObject, handles)

function stype_tag_Callback(hObject, eventdata, handles)
    rsource=str2double(get(handles.rsource_tag,'String'));
    handles.configdata.Source{rsource}.type=get(handles.stype_tag,'Value');
    guidata(hObject, handles);
    source_update(hObject, handles)

function nsource_tag_Callback(hObject, eventdata, handles)
    rsource=str2double(get(handles.rsource_tag,'String'));
    nsource_old=length(handles.configdata.Source);
    nsource=str2double(get(handles.nsource_tag,'String'));

    %Save the usefull data
    Source=handles.configdata.Source(1:min(nsource,nsource_old));
    for ii=nsource_old+1:nsource
       Source{ii}=Source{1};
    end
    handles.configdata.Source=Source;

    %Update Region
    if rsource>nsource
        set(handles.rsource,'String',num2str(nsource));
    end

    guidata(hObject, handles);
    source_update(hObject, handles)

function pushbutton3_Callback(hObject, eventdata, handles)
    source_save(hObject, handles)
    close(gcbf)
    e3d_gui

function source_initialize(hObject, handles)
    set(handles.nsource_tag,'String',num2str(length(handles.configdata.Source)))
    set(handles.rsource_tag,'String','1')
    set(handles.rsource2_tag,'Title','Source 1')
    source_update(hObject, handles)


    
%-------------------------------------------------------------------------%
%                                                                         %
%Handle Configuration File                                                %
%                                                                         %
%-------------------------------------------------------------------------%    
function source_update(hObject, handles)  
    rsource=str2double(get(handles.rsource_tag,'String'));
    set(handles.stype_tag,'Value',handles.configdata.Source{rsource}.type)
    set(handles.swav_tag,'Value',handles.configdata.Source{rsource}.wav+1)
    set(handles.samp_tag,'String',num2str(handles.configdata.Source{rsource}.amp,'%1.5e'))
    set(handles.sfreq_tag,'String',num2str(handles.configdata.Source{rsource}.freq))
    set(handles.soff_tag,'String',num2str(handles.configdata.Source{rsource}.off))
    set(handles.spx_tag,'String',num2str(handles.configdata.Source{rsource}.loc(1)))
    set(handles.spy_tag,'String',num2str(handles.configdata.Source{rsource}.loc(2)))
    set(handles.spz_tag,'String',num2str(handles.configdata.Source{rsource}.loc(3)))

    %type: 1=P, 2=S, 4=Moment Tensor, 5=Force, 6=Point Fault, 7=Finite Fault
    %Orient: {strike,dip,rake,length,width,depth,s0,d0,v}
    source_vis=zeros([1 21]);
    source_txt={'-','-','-','-','-','-','-','-','-','-','-','-'};
    switch handles.configdata.Source{rsource}.type            
        case 4
            source_txt={'Moment','Mxx','Myy','Mzz','-','Mxy','Mxz','Myz','-','-','-','-'};
            source_vis(1:14)=1;
            source_vis(8)=0;
            set(handles.s3_tag,'String',num2str(handles.configdata.Source{rsource}.M(1)))
            set(handles.s5_tag,'String',num2str(handles.configdata.Source{rsource}.M(2)))
            set(handles.s7_tag,'String',num2str(handles.configdata.Source{rsource}.M(3)))
            set(handles.s10_tag,'String',num2str(handles.configdata.Source{rsource}.M(4)))
            set(handles.s12_tag,'String',num2str(handles.configdata.Source{rsource}.M(5)))
            set(handles.s14_tag,'String',num2str(handles.configdata.Source{rsource}.M(6)))
            
        case 5
            source_txt={'Force','Fx','Fy','Fz','-','-','-','-','-','-','-','-'};
            source_vis(1:7)=1;
            set(handles.s3_tag,'String',num2str(handles.configdata.Source{rsource}.F(1)))
            set(handles.s5_tag,'String',num2str(handles.configdata.Source{rsource}.F(2)))
            set(handles.s7_tag,'String',num2str(handles.configdata.Source{rsource}.F(3)))
            
        case 6
            source_txt={'Orientation','S','D','R','Dimensions','L','W','D','Etc','S0','D0','V'};
            source_vis(1:21)=1;
            set(handles.s3_tag,'String',num2str(handles.configdata.Source{rsource}.orient(1)))
            set(handles.s5_tag,'String',num2str(handles.configdata.Source{rsource}.orient(2)))
            set(handles.s7_tag,'String',num2str(handles.configdata.Source{rsource}.orient(3)))
            set(handles.s10_tag,'String',num2str(handles.configdata.Source{rsource}.orient(4)))
            set(handles.s12_tag,'String',num2str(handles.configdata.Source{rsource}.orient(5)))
            set(handles.s14_tag,'String',num2str(handles.configdata.Source{rsource}.orient(6)))
            set(handles.s17_tag,'String',num2str(handles.configdata.Source{rsource}.orient(7)))
            set(handles.s19_tag,'String',num2str(handles.configdata.Source{rsource}.orient(8)))
            set(handles.s21_tag,'String',num2str(handles.configdata.Source{rsource}.orient(9)))
    end

    %Visibility
    for ii=1:21
       if source_vis(ii)==0
           set(eval(['handles.s' num2str(ii) '_tag']),'Visible','off')         
       else
           set(eval(['handles.s' num2str(ii) '_tag']),'Visible','on')
       end
    end

    %Tags
    loc=[1,2,4,6,8,9,11,13,15,16,18,20];
    for ii=1:length(loc)
        set(eval(['handles.s' num2str(loc(ii)) '_tag']),'String',source_txt{ii})
    end
    

function source_save(hObject, handles)
    rsource=str2double(get(handles.rsource_tag,'String'));  
    handles.configdata.Source{rsource}.type=get(handles.stype_tag,'Value');
    handles.configdata.Source{rsource}.wav=get(handles.swav_tag,'Value')-1;
    handles.configdata.Source{rsource}.amp=str2double(get(handles.samp_tag,'String'));
    handles.configdata.Source{rsource}.freq=str2double(get(handles.sfreq_tag,'String'));
    handles.configdata.Source{rsource}.off=str2double(get(handles.soff_tag,'String'));
    handles.configdata.Source{rsource}.loc(1)=str2double(get(handles.spx_tag,'String'));
    handles.configdata.Source{rsource}.loc(2)=str2double(get(handles.spy_tag,'String'));
    handles.configdata.Source{rsource}.loc(3)=str2double(get(handles.spz_tag,'String'));
    
    %Save the old data for the source type
    switch handles.configdata.Source{rsource}.type            
        case 4
            handles.configdata.Source{rsource}.M(1)=str2double(get(handles.s3_tag,'String'));
            handles.configdata.Source{rsource}.M(2)=str2double(get(handles.s5_tag,'String'));
            handles.configdata.Source{rsource}.M(3)=str2double(get(handles.s7_tag,'String'));
            handles.configdata.Source{rsource}.M(4)=str2double(get(handles.s10_tag,'String'));
            handles.configdata.Source{rsource}.M(5)=str2double(get(handles.s12_tag,'String'));
            handles.configdata.Source{rsource}.M(6)=str2double(get(handles.s14_tag,'String'));
           
        case 5
            handles.configdata.Source{rsource}.F(1)=str2double(get(handles.s3_tag,'String'));
            handles.configdata.Source{rsource}.F(2)=str2double(get(handles.s5_tag,'String'));
            handles.configdata.Source{rsource}.F(3)=str2double(get(handles.s7_tag,'String'));
            
        case 6
            handles.configdata.Source{rsource}.orient(1)=str2double(get(handles.s3_tag,'String'));
            handles.configdata.Source{rsource}.orient(2)=str2double(get(handles.s5_tag,'String'));
            handles.configdata.Source{rsource}.orient(3)=str2double(get(handles.s7_tag,'String'));
            handles.configdata.Source{rsource}.orient(4)=str2double(get(handles.s10_tag,'String'));
            handles.configdata.Source{rsource}.orient(5)=str2double(get(handles.s12_tag,'String'));
            handles.configdata.Source{rsource}.orient(6)=str2double(get(handles.s14_tag,'String'));
            handles.configdata.Source{rsource}.orient(7)=str2double(get(handles.s17_tag,'String'));
            handles.configdata.Source{rsource}.orient(8)=str2double(get(handles.s19_tag,'String'));
            handles.configdata.Source{rsource}.orient(9)=str2double(get(handles.s20_tag,'String'));         
    end

    guidata(hObject, handles);
    configdata=handles.configdata;
    save('./config/e3d_config.mat','-struct','configdata')
    
    
           
%-------------------------------------------------------------------------%
%                                                                         %
%Unused Autogen Functions                                                 %
%                                                                         %
%-------------------------------------------------------------------------%        
function varargout = e3d_gui_source_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function nsource_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function stype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function swav_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function samp_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sfreq_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function spx_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function spy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function spz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s3_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function s5_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s7_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s10_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function s12_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s14_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s17_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s19_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s21_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function soff_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

 
function swav_tag_Callback(hObject, eventdata, handles)

function samp_tag_Callback(hObject, eventdata, handles)
 
function sfreq_tag_Callback(hObject, eventdata, handles)
 
function spx_tag_Callback(hObject, eventdata, handles)

function spy_tag_Callback(hObject, eventdata, handles)

function spz_tag_Callback(hObject, eventdata, handles)

function s3_tag_Callback(hObject, eventdata, handles)
    
function s5_tag_Callback(hObject, eventdata, handles)
 
function s7_tag_Callback(hObject, eventdata, handles)
 
function s10_tag_Callback(hObject, eventdata, handles)
    
function s12_tag_Callback(hObject, eventdata, handles)
 
function s14_tag_Callback(hObject, eventdata, handles)
 
function s17_tag_Callback(hObject, eventdata, handles)
 
function s19_tag_Callback(hObject, eventdata, handles)
 
function s21_tag_Callback(hObject, eventdata, handles)
 
function soff_tag_Callback(hObject, eventdata, handles)
