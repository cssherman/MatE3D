function varargout = e3d_gui(varargin)
% E3D_GUI Matlab Interface
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

% Edit the above text to modify the response to help e3d_gui

% Last Modified by GUIDE v2.5 06-Apr-2013 12:50:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @e3d_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @e3d_gui_OutputFcn, ...
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
function e3d_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    close all
    cd(strrep(which('e3d_gui.m'),'gui/e3d_gui.m',''));
    if exist('./config/e3d_config.mat','file')==0
        e3d_default;
    end
    handles.configdata=load('./config/e3d_config.mat');  %Load config data into structure:
    handles.output = hObject;       % Choose default command line output for e3d_gui
    guidata(hObject, handles);      % Update handles structure
    e3d_restore(hObject, handles);  %Load the appropriate data into the handles

%-------------------------------------------------------------------------%   
%                                                                         %
%Callback functions for button presses:                                   %
%                                                                         %
%-------------------------------------------------------------------------%

function save_tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);

function rmovie_Tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);
    close(gcbf)
    handles.configdata=load('./config/e3d_config.mat');
    e3d_rerender(handles.configdata.Path,handles.configdata.Plotting,handles.configdata.Rerender)
    
function source_tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);
    close(gcbf)
    e3d_gui_source

function material_tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);
    close(gcbf)
    e3d_gui_material

function output_tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);
    close(gcbf)
    e3d_gui_output

function restore_tag_Callback(hObject, eventdata, handles)
    %Recreate the config file and load
    e3d_default;
    handles.configdata=load('./config/e3d_config.mat');
    
    % Update handles structure
    guidata(hObject, handles);
    e3d_restore(hObject, handles);
    
function execute_tag_Callback(hObject, eventdata, handles)
    e3d_gui_save(hObject, handles);
    close(gcbf)
    e3d_main;

function units_tag_Callback(hObject, eventdata, handles)
    handles.configdata.units=get(handles.units_tag,'Value');
    switch handles.configdata.units
        case 1
            set(handles.xunits1_tag,'String','(km)');
            set(handles.xunits2_tag,'String','(km)');
            set(handles.xunits3_tag,'String','(km)');
            set(handles.tunits1_tag,'String','(s)');
            set(handles.funits1_tag,'String','(Hz)');
            
        case 2
            set(handles.xunits1_tag,'String','(m)');
            set(handles.xunits2_tag,'String','(m)');
            set(handles.xunits3_tag,'String','(m)');
            set(handles.tunits1_tag,'String','(ms)');
            set(handles.funits1_tag,'String','(kHz)');
    end

function load_tag_Callback(hObject, eventdata, handles)
   %Request the configuration location, and load
    [loadfile,loadpath]=uigetfile('*.mat','Choose Configuration File','e3d_export.mat');
    handles.configdata=load([loadpath loadfile]);

    % Update handles structure and the gui
    guidata(hObject, handles);
    e3d_restore(hObject, handles);

function export_tag_Callback(hObject, eventdata, handles)
    [exportfile,exportpath]=uiputfile('*.mat','Save Configuration As','e3d_export.mat');
    e3d_gui_save(hObject, handles);
    [~,~]=unix(['cp ././config/e3d_config.mat ' exportpath exportfile]);    
    
    
%-------------------------------------------------------------------------%   
%                                                                         %
%Display or Save configuration values:                                    %
%                                                                         %
%-------------------------------------------------------------------------%
function e3d_restore(hObject, handles)
    %Model setup values
    set(handles.sx_tag,'String',num2str(handles.configdata.Model.size(1)));
    set(handles.sy_tag,'String',num2str(handles.configdata.Model.size(2)));
    set(handles.sz_tag,'String',num2str(handles.configdata.Model.size(3)));
    set(handles.ox_tag,'String',num2str(handles.configdata.Model.origin(1)));
    set(handles.oy_tag,'String',num2str(handles.configdata.Model.origin(2)));
    set(handles.oz_tag,'String',num2str(handles.configdata.Model.origin(3)));
    set(handles.dx_tag,'String',num2str(handles.configdata.Model.spacing(1)));
    set(handles.dy_tag,'String',num2str(handles.configdata.Model.spacing(2)));
    set(handles.dz_tag,'String',num2str(handles.configdata.Model.spacing(3)));
    set(handles.t_tag,'String',num2str(handles.configdata.Model.time));
    set(handles.dtct_tag,'String',num2str(handles.configdata.Model.max_dtct));
    set(handles.loopnum_tag,'String',num2str(handles.configdata.Config.loopnum));
    
    %Analysis values
    set(handles.run_tag,'Value',handles.configdata.Config.run+1);
    set(handles.acoust_tag,'Value',handles.configdata.Config.acoust);
    set(handles.atten_tag,'Value',handles.configdata.Config.atten+1);
    set(handles.dims_tag,'Value',handles.configdata.Model.dims-1);
    set(handles.units_tag,'Value',handles.configdata.Config.units);
    set(handles.mpix_tag,'String',num2str(handles.configdata.Config.multicore(1)));
    set(handles.mpiy_tag,'String',num2str(handles.configdata.Config.multicore(2)));
    set(handles.mpiz_tag,'String',num2str(handles.configdata.Config.multicore(3)));
    
    %I/O values
    set(handles.path_out_tag,'String',handles.configdata.Path.out);
    set(handles.path_log_tag,'String',handles.configdata.Path.log);
    set(handles.path_link_tag,'String',handles.configdata.Path.link);
    set(handles.path_bin_tag,'String',handles.configdata.Path.e3d_bin);
    set(handles.path_in_tag,'String',handles.configdata.Path.in);
    
    %Boundary Values
    set(handles.btype_tag,'Value',handles.configdata.Boundary.type);
    set(handles.sponge_tag,'Value',handles.configdata.Boundary.sponge+1);
    set(handles.abound_tag,'Value',handles.configdata.Boundary.atten+1);
    
    %Plotting Values
    set(handles.rmodel_tag,'Value',handles.configdata.Plotting.model+1);
    set(handles.dtime_tag,'String',num2str(handles.configdata.Plotting.dec_time));
    set(handles.rmovie_tag,'Value',handles.configdata.Plotting.movie+1);
    set(handles.dspace_tag,'String',num2str(handles.configdata.Plotting.dec_space));
    set(handles.rtrace_tag,'Value',handles.configdata.Plotting.trace+1);
    
    %Post options
    set(handles.pass1_tag,'String',num2str(handles.configdata.Plotting.bandpass(1)));
    set(handles.pass2_tag,'String',num2str(handles.configdata.Plotting.bandpass(2)));
    set(handles.rerender_model_tag,'Value',handles.configdata.Rerender.model);
    set(handles.rerender_movie_tag,'Value',handles.configdata.Rerender.movie);
    set(handles.rerender_trace_tag,'Value',handles.configdata.Rerender.trace);
      
    %Units:
    switch handles.configdata.Config.units
        case 1
            set(handles.xunits1_tag,'String','(km)');
            set(handles.xunits2_tag,'String','(km)');
            set(handles.xunits3_tag,'String','(km)');
            set(handles.tunits1_tag,'String','(s)');
            set(handles.funits1_tag,'String','(Hz)');
            
        case 2
            set(handles.xunits1_tag,'String','(m)');
            set(handles.xunits2_tag,'String','(m)');
            set(handles.xunits3_tag,'String','(m)');
            set(handles.tunits1_tag,'String','(ms)');
            set(handles.funits1_tag,'String','(kHz)');
    end
       
function e3d_gui_save(hObject, handles) 
    %Model Setup values
    handles.configdata.Model.size(1)=str2double(get(handles.sx_tag,'String'));
    handles.configdata.Model.size(2)=str2double(get(handles.sy_tag,'String'));
    handles.configdata.Model.size(3)=str2double(get(handles.sz_tag,'String'));
    handles.configdata.Model.origin(1)=str2double(get(handles.ox_tag,'String'));
    handles.configdata.Model.origin(2)=str2double(get(handles.oy_tag,'String'));
    handles.configdata.Model.origin(3)=str2double(get(handles.oz_tag,'String'));
    handles.configdata.Model.spacing(1)=str2double(get(handles.dx_tag,'String'));
    handles.configdata.Model.spacing(2)=str2double(get(handles.dy_tag,'String'));
    handles.configdata.Model.spacing(3)=str2double(get(handles.dz_tag,'String'));
    handles.configdata.Model.time=str2double(get(handles.t_tag,'String'));
    handles.configdata.Model.max_dtct=str2double(get(handles.dtct_tag,'String'));
    handles.configdata.Config.loopnum=str2double(get(handles.loopnum_tag,'String'));

    %Analysis values
    handles.configdata.Config.run=get(handles.run_tag,'Value')-1;
    handles.configdata.Config.acoust=get(handles.acoust_tag,'Value');
    handles.configdata.Config.atten=get(handles.atten_tag,'Value')-1;
    handles.configdata.Model.dims=get(handles.dims_tag,'Value')+1;
    handles.configdata.Config.units=get(handles.units_tag,'Value');
    handles.configdata.Config.multicore(1)=str2double(get(handles.mpix_tag,'String'));
    handles.configdata.Config.multicore(2)=str2double(get(handles.mpiy_tag,'String'));
    handles.configdata.Config.multicore(3)=str2double(get(handles.mpiz_tag,'String'));

    %I/O values
    handles.configdata.Path.out=get(handles.path_out_tag,'String');
    handles.configdata.Path.log=get(handles.path_log_tag,'String');
    handles.configdata.Path.link=get(handles.path_link_tag,'String');
    handles.configdata.Path.e3d_bin=get(handles.path_bin_tag,'String');
    handles.configdata.Path.in=get(handles.path_in_tag,'String');

    %Boundary Values
    handles.configdata.Boundary.type=get(handles.btype_tag,'Value');
    handles.configdata.Boundary.sponge=get(handles.sponge_tag,'Value')-1;
    handles.configdata.Boundary.atten=get(handles.abound_tag,'Value')-1;

    %Plotting Values
    handles.configdata.Plotting.model=get(handles.rmodel_tag,'Value')-1;
    handles.configdata.Plotting.dec_time=str2double(get(handles.dtime_tag,'String'));
    handles.configdata.Plotting.movie=get(handles.rmovie_tag,'Value')-1;
    handles.configdata.Plotting.dec_space=str2double(get(handles.dspace_tag,'String'));
    handles.configdata.Plotting.trace=get(handles.rtrace_tag,'Value')-1;

    %Post options
    handles.configdata.Plotting.bandpass(1)=str2double(get(handles.pass1_tag,'String'));
    handles.configdata.Plotting.bandpass(2)=str2double(get(handles.pass2_tag,'String'));
    handles.configdata.Rerender.model=get(handles.rerender_model_tag,'Value');
    handles.configdata.Rerender.movie=get(handles.rerender_movie_tag,'Value');
    handles.configdata.Rerender.trace=get(handles.rerender_trace_tag,'Value');
    
    %Units:
    switch handles.configdata.Config.units
        case 1
            set(handles.xunits1_tag,'String','(km)');
            set(handles.xunits2_tag,'String','(km)');
            set(handles.xunits3_tag,'String','(km)');
            set(handles.tunits1_tag,'String','(s)');
            set(handles.funits1_tag,'String','(Hz)');

        case 2
            set(handles.xunits1_tag,'String','(m)');
            set(handles.xunits2_tag,'String','(m)');
            set(handles.xunits3_tag,'String','(m)');
            set(handles.tunits1_tag,'String','(ms)');
            set(handles.funits1_tag,'String','(kHz)');
    end
    
    %Update the configfile:
    guidata(hObject, handles);
    configdata=handles.configdata;
    save('./config/e3d_config.mat','-struct','configdata')
  
    
%-------------------------------------------------------------------------%        
%                                                                         %
%Unused callback functions:                                               %
%                                                                         %
%-------------------------------------------------------------------------%
function varargout = e3d_gui_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function btype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sponge_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function abound_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function run_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function acoust_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dims_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function mpix_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function mpiy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function mpiz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dtct_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function path_out_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function path_log_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function path_link_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function path_bin_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function path_in_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function rmodel_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function rmovie_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dtime_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dspace_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sx_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function t_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function ox_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function oy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function oz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dx_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function dz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function units_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function loopnum_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit25_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit24_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function popupmenu20_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function popupmenu19_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function pass1_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function atten_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function pass2_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function rtrace_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function btype_tag_Callback(hObject, eventdata, handles)
    
function sponge_tag_Callback(hObject, eventdata, handles)
    
function abound_tag_Callback(hObject, eventdata, handles)

function run_tag_Callback(hObject, eventdata, handles)
    
function acoust_tag_Callback(hObject, eventdata, handles)
    
function dims_tag_Callback(hObject, eventdata, handles)
    
function edit6_Callback(hObject, eventdata, handles)

function mpix_tag_Callback(hObject, eventdata, handles)
    
function mpiy_tag_Callback(hObject, eventdata, handles)
    
function mpiz_tag_Callback(hObject, eventdata, handles)
    
function dtct_tag_Callback(hObject, eventdata, handles)
    
function path_out_tag_Callback(hObject, eventdata, handles)
    
function path_log_tag_Callback(hObject, eventdata, handles)
    
function path_link_tag_Callback(hObject, eventdata, handles)
    
function path_bin_tag_Callback(hObject, eventdata, handles)
    
function path_in_tag_Callback(hObject, eventdata, handles)
    
function rmodel_tag_Callback(hObject, eventdata, handles)
    
function rmovie_tag_Callback(hObject, eventdata, handles)
    
function dtime_tag_Callback(hObject, eventdata, handles)
    
function dspace_tag_Callback(hObject, eventdata, handles)
    
function sx_tag_Callback(hObject, eventdata, handles)
    
function sy_tag_Callback(hObject, eventdata, handles)
    
function sz_tag_Callback(hObject, eventdata, handles)
    
function t_tag_Callback(hObject, eventdata, handles)
    
function ox_tag_Callback(hObject, eventdata, handles)
    
function oy_tag_Callback(hObject, eventdata, handles)
    
function oz_tag_Callback(hObject, eventdata, handles)
    
function dx_tag_Callback(hObject, eventdata, handles)
    
function dy_tag_Callback(hObject, eventdata, handles)
    
function dz_tag_Callback(hObject, eventdata, handles)
    
function loopnum_tag_Callback(hObject, eventdata, handles)
    
function edit25_Callback(hObject, eventdata, handles)
    
function edit24_Callback(hObject, eventdata, handles)
    
function popupmenu20_Callback(hObject, eventdata, handles)
    
function popupmenu19_Callback(hObject, eventdata, handles)
    
function pass1_tag_Callback(hObject, eventdata, handles)
    
function atten_tag_Callback(hObject, eventdata, handles)
    
function pass2_tag_Callback(hObject, eventdata, handles)
    
function rtrace_tag_Callback(hObject, eventdata, handles)    
    
function rerender_movie_tag_Callback(hObject, eventdata, handles)

function rerender_model_tag_Callback(hObject, eventdata, handles)

function rerender_trace_tag_Callback(hObject, eventdata, handles)
