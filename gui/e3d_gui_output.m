function varargout = e3d_gui_output(varargin)
% E3D_GUI Matlab Interface - Output Configuration
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

% Edit the above text to modify the response to help e3d_gui_output

% Last Modified by GUIDE v2.5 06-Apr-2013 13:38:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @e3d_gui_output_OpeningFcn, ...
                   'gui_OutputFcn',  @e3d_gui_output_OutputFcn, ...
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
function e3d_gui_output_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.configdata=load('./config/e3d_config.mat');  %Load the handles.configdata:
    handles.output = hObject;                   % Choose default command line output for e3d_gui_output
    guidata(hObject, handles);                  % Update handles structure
    output_initialize(hObject, handles);        %Load the appropriate data into the handles:
    output_update(hObject, handles)

 
    
    
%-------------------------------------------------------------------------%
%                                                                         %
%Handle Button Pushes                                                     %
%                                                                         %
%-------------------------------------------------------------------------%
function pushbutton1_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    close(gcbf)
    e3d_gui

function pushbutton2_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    rtrace=str2double(get(handles.rtrace_tag,'String'));
    ntrace=str2double(get(handles.ntrace_tag,'String'));
    set(handles.rtrace_tag,'String',num2str(max(0,max(sign(ntrace),rtrace-1))))
    output_update(hObject, handles)

function pushbutton3_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    rtrace=str2double(get(handles.rtrace_tag,'String'));
    ntrace=str2double(get(handles.ntrace_tag,'String'));
    set(handles.rtrace_tag,'String',num2str(min(ntrace,rtrace+1)))
    output_update(hObject, handles)

function pushbutton4_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    rmovie=str2double(get(handles.rmovie_tag,'String'));
    nmovie=str2double(get(handles.nmovie_tag,'String'));
    set(handles.rmovie_tag,'String',num2str(max(0,max(sign(nmovie),rmovie-1))))
    output_update(hObject, handles)

function pushbutton5_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    rmovie=str2double(get(handles.rmovie_tag,'String'));
    nmovie=str2double(get(handles.nmovie_tag,'String'));
    set(handles.rmovie_tag,'String',num2str(min(rmovie+1,nmovie)))
    output_update(hObject, handles)   
    
function mdir_tag_Callback(hObject, eventdata, handles)
    ii=round(get(handles.mdir_tag,'Value'));
    mplane={'X=','Y=','Z='};
    set(handles.txt_mpos_tag,'String',mplane{ii})
    
    
function ntrace_tag_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    ntrace=str2double(get(handles.ntrace_tag,'String'));
    ntrace_old=length(handles.configdata.Output.trace);
    rtrace=str2double(get(handles.rtrace_tag,'String'));

    %Save the usefull data:
    Output.trace=handles.configdata.Output.trace(1:min(ntrace,ntrace_old));

    %Add new traces:
    for ii=ntrace_old+1:ntrace
       Output.trace{ii}.loc=[0,0,0];
       Output.trace{ii}.dir='X';
       Output.trace{ii}.N=10;
       Output.trace{ii}.space=1;
       Output.trace{ii}.corr=1;
    end
    handles.configdata.Output.trace=Output.trace;

    %Update Trace
    if rtrace>ntrace
        set(handles.trace_tag,'String',num2str(max(0,ntrace)));
    end

    %Update gui
    guidata(hObject, handles);
    output_update(hObject, handles)

function nmovie_tag_Callback(hObject, eventdata, handles)
    materials_save(hObject, handles)
    nmovie=str2double(get(handles.nmovie_tag,'String'));
    nmovie_old=length(handles.configdata.Output.movie);
    rmovie=str2double(get(handles.rmovie_tag,'String'));

    %Save the usefull data:
    Output.movie=handles.configdata.Output.movie(1:min(nmovie,nmovie_old));
    for ii=nmovie_old+1:nmovie
       Output.movie{ii}.type=11;
       Output.movie{ii}.dir='X';
       Output.movie{ii}.loc=0;
    end
    handles.configdata.Output.movie=Output.movie;

    %Update Trace
    if rmovie>nmovie
        set(handles.rmovie_tag,'String',num2str(max(0,nmovie)));
    end

    %Update handles
    guidata(hObject, handles);
    output_update(hObject, handles)


function output_initialize(hObject, handles)
    %Trace info
    ntrace=length(handles.configdata.Output.trace);
    set(handles.ntrace_tag,'String',num2str(ntrace))
    
    if ntrace>0
        set(handles.rtrace_tag,'String','1')
        set(handles.rtrace2_tag,'Title','Trace 1')
    else
        set(handles.rtrace_tag,'String','0')   
    end
    
    %Movie info
    nmovie=length(handles.configdata.Output.movie);
    set(handles.nmovie_tag,'String',num2str(nmovie))
    
    if nmovie>0
        set(handles.rmovie_tag,'String','1')
        set(handles.rmovie2_tag,'Title','Trace 1')
    else
        set(handles.rmovie_tag,'String','0')   
    end
    
 
       
%-------------------------------------------------------------------------%
%                                                                         %
%Handle Configuration File                                                %
%                                                                         %
%-------------------------------------------------------------------------%   
function output_update(hObject, handles)
       
    %Trace Info
    rtrace=str2double(get(handles.rtrace_tag,'String'));
    if rtrace>0
        set(handles.rtrace2_tag,'Visible','on')
        set(handles.rtrace2_tag,'Title',['Trace ' num2str(rtrace)])
        switch handles.configdata.Output.trace{rtrace}.dir
            case 'X'
                rdir=1;
            case 'Y'
                rdir=2;
            case 'Z'
                rdir=3;
        end
        
        set(handles.tdir_tag,'Value',rdir)
        set(handles.tox_tag,'String',num2str(handles.configdata.Output.trace{rtrace}.loc(1)))
        set(handles.toy_tag,'String',num2str(handles.configdata.Output.trace{rtrace}.loc(2)))
        set(handles.toz_tag,'String',num2str(handles.configdata.Output.trace{rtrace}.loc(3)))
        L=handles.configdata.Output.trace{rtrace}.space*handles.configdata.Output.trace{rtrace}.N;
        set(handles.tlength_tag,'String',num2str(L))
        set(handles.tspace_tag,'String',num2str(handles.configdata.Output.trace{rtrace}.space))
        set(handles.corr_tag,'Value',handles.configdata.Output.trace{rtrace}.corr)
        
    else
        set(handles.rtrace2_tag,'Visible','off')  
    end
    
    %Movie Info
    rmovie=str2double(get(handles.rmovie_tag,'String'));
    if rmovie>0
        set(handles.rmovie2_tag,'Visible','on')
        set(handles.mtype_tag,'Value',handles.configdata.Output.movie{rmovie}.type-10)
        set(handles.rmovie2_tag,'Title',['Movie ' num2str(rmovie)])
        switch handles.configdata.Output.movie{rmovie}.dir
            case 'X'
                mdir=1;
                mtxt='X=';
            case 'Y'
                mdir=2;
                mtxt='Y=';
            case 'Z'
                mdir=3;
                mtxt='Z=';
        end
        
        set(handles.mdir_tag,'Value',mdir)
        set(handles.mpos_tag,'String',num2str(handles.configdata.Output.movie{rmovie}.loc))
        set(handles.txt_mpos_tag,'String',mtxt)
    else
        set(handles.rmovie2_tag,'Visible','off')  
    end
    
function materials_save(hObject, handles)
       
    %Trace Info
    rtrace=str2double(get(handles.rtrace_tag,'String'));
    if rtrace>0
        
        rdir=get(handles.tdir_tag,'Value');
        switch rdir
            case 1
                handles.configdata.Output.trace{rtrace}.dir='X';
            case 2
                handles.configdata.Output.trace{rtrace}.dir='Y';
            case 3
                handles.configdata.Output.trace{rtrace}.dir='Z';
        end
        
        handles.configdata.Output.trace{rtrace}.loc(1)=str2double(get(handles.tox_tag,'String'));
        handles.configdata.Output.trace{rtrace}.loc(2)=str2double(get(handles.toy_tag,'String'));
        handles.configdata.Output.trace{rtrace}.loc(3)=str2double(get(handles.toz_tag,'String'));
        L=str2double(get(handles.tlength_tag,'String'));
        handles.configdata.Output.trace{rtrace}.space=str2double(get(handles.tspace_tag,'String'));   
        if handles.configdata.Output.trace{rtrace}.space==0
            handles.configdata.Output.trace{rtrace}.N=1;
        else
            handles.configdata.Output.trace{rtrace}.N=round(L/handles.configdata.Output.trace{rtrace}.space);
        end
        handles.configdata.Output.trace{rtrace}.corr=get(handles.corr_tag,'Value');
    end
    
    %Movie Info
    rmovie=str2double(get(handles.rmovie_tag,'String'));
    if rmovie>0
        handles.configdata.Output.movie{rmovie}.type=get(handles.mtype_tag,'Value')+10;
        switch get(handles.mdir_tag,'Value')
            case 1
                handles.configdata.Output.movie{rmovie}.dir='X';
            case 2
                handles.configdata.Output.movie{rmovie}.dir='Y';
            case 3
                handles.configdata.Output.movie{rmovie}.dir='Z';
        end
        handles.configdata.Output.movie{rmovie}.loc=str2double(get(handles.mpos_tag,'String'));
     
    end
    
    %Update configfile:
    guidata(hObject, handles);
    configdata=handles.configdata;
    save('./config/e3d_config.mat','-struct','configdata')
        
    
    
    
%-------------------------------------------------------------------------%
%                                                                         %
%Unused Autogen Functions                                                 %
%                                                                         %
%-------------------------------------------------------------------------%
function varargout = e3d_gui_output_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function nmovie_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function mdir_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function mpos_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function ntrace_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function tdir_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function tox_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function toy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function toz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function tlength_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function tspace_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function mtype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function corr_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function mpos_tag_Callback(hObject, eventdata, handles)
 
function tdir_tag_Callback(hObject, eventdata, handles)

function tox_tag_Callback(hObject, eventdata, handles)

function toy_tag_Callback(hObject, eventdata, handles)
    
function toz_tag_Callback(hObject, eventdata, handles)

function tlength_tag_Callback(hObject, eventdata, handles)
    
function tspace_tag_Callback(hObject, eventdata, handles)

function mtype_tag_Callback(hObject, eventdata, handles)
    
function corr_tag_Callback(hObject, eventdata, handles)
