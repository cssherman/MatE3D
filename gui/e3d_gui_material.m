function varargout = e3d_gui_material(varargin)
% E3D_GUI Matlab Interface - Material Configuration
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

% Edit the above text to modify the response to help e3d_gui_material

% Last Modified by GUIDE v2.5 17-Jan-2013 15:50:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @e3d_gui_material_OpeningFcn, ...
                   'gui_OutputFcn',  @e3d_gui_material_OutputFcn, ...
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
function e3d_gui_material_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.configdata=load('./config/e3d_config.mat');
    handles.output = hObject;               % Choose default command line output for e3d_gui_material
    guidata(hObject, handles);              % Update handles structure
    material_initialize(hObject, handles);  %Initialize Values



%-------------------------------------------------------------------------%   
%                                                                         %
%Callback functions for button presses:                                   %
%                                                                         %
%-------------------------------------------------------------------------%
function pushbutton2_Callback(hObject, eventdata, handles)
    handles=e3d_material_update(hObject, handles);
    configdata=handles.configdata;
    save('./config/e3d_config.mat','-struct','configdata')
    close(gcbf)
    e3d_gui

function mrender_tag_Callback(hObject, eventdata, handles)
    handles=e3d_material_update(hObject, handles);
    configdata=handles.configdata;
    save('./config/e3d_config.mat','-struct','configdata')
    close(gcbf)
    e3d_render_model;

function rselect1_tag_Callback(hObject, eventdata, handles)
    handles=e3d_material_update(hObject, handles);
    rnum=str2double(get(handles.txt_region_tag,'String'));
    set(handles.txt_region_tag,'String',num2str(max(rnum-1,1)));
    e3d_select_region(hObject, handles)

function rselect2_tag_Callback(hObject, eventdata, handles)
    handles=e3d_material_update(hObject, handles);
    rnum=str2double(get(handles.txt_region_tag,'String'));
    rnum_max=str2double(get(handles.nregions_tag,'String'));
    set(handles.txt_region_tag,'String',num2str(min(rnum+1,rnum_max)));
    e3d_select_region(hObject, handles)

function ctype_tag_Callback(hObject, eventdata, handles)
    e3d_material_update(hObject, handles);

function stype_tag_Callback(hObject, eventdata, handles)
    rnum=str2double(get(handles.txt_region_tag,'String'));
    stype=get(handles.stype_tag,'Value');
    switch stype
        case 1
            handles.configdata.Material{rnum}.sd=[0,0,0];
            handles.configdata.Material{rnum}.dist=[-1.5,1,1,1];

        case 2
            handles.configdata.Material{rnum}.sd=[0.01,0.01,0];
            handles.configdata.Material{rnum}.dist=[-1.5,1,1,1];

        case 3
            handles.configdata.Material{rnum}.sd=[0.01,0.01,0];
            handles.configdata.Material{rnum}.dist=[0,1,1,1];
    end
    e3d_select_region(hObject, handles)



%-------------------------------------------------------------------------%   
%                                                                         %
%Handle the Configuration File                                            %
%                                                                         %
%-------------------------------------------------------------------------%
function nregions_tag_Callback(hObject, eventdata, handles)
    nregions=str2double(get(handles.nregions_tag,'String'));
    nregions_old=length(handles.configdata.Material);
    rnum=str2double(get(handles.txt_region_tag,'String'));

    %Save the usefull data
    Material=handles.configdata.Material(1:min(nregions,nregions_old));
    for ii=nregions_old+1:nregions
       Material{ii}=Material{1};
    end
    handles.configdata.Material=Material;

    %Update Region
    if rnum>nregions
        set(handles.txt_region_tag,'String',num2str(nregions));
    end
    e3d_select_region(hObject, handles)


function rtype_tag_Callback(hObject, eventdata, handles)
    rnum=str2double(get(handles.txt_region_tag,'String'));
    handles.configdata.Material{rnum}.type=get(handles.rtype_tag,'Value');

    %Default Geometry Options:
    switch handles.configdata.Material{rnum}.type
        case 1
            handles.configdata.Material{rnum}.geo=[0,1,0,1,0,1];

        case 2
            handles.configdata.Material{rnum}.geo=[0,0,0,1];

        case 3
            handles.configdata.Material{rnum}.geo=[0,0,0,0,0,1,1];

        case 4
            handles.configdata.Material{rnum}.geo=zeros([2 6]);

        case 5
            handles.configdata.Material{rnum}.geo=[0,0,0,180,45,1,0,0,1e9];

        case 6
            handles.configdata.Material{rnum}.geo=[0,0,0,180,zeros(1,20)];

        case 7
            handles.configdata.Material{rnum}.geo=[10,10,0,0,0,zeros(1,30)];

        case 8
            handles.configdata.Material{rnum}.geo=4;

        case 9
            handles.configdata.Material{rnum}.geo=[];
    end 
    e3d_select_region(hObject, handles)

    
function material_initialize(hObject, handles)
    
    %Material Controll:
    nmat=length(handles.configdata.Material);
    set(handles.nregions_tag,'String',num2str(nmat));
    set(handles.iparam_tag,'Value',handles.configdata.Config.degrees_free);
    set(handles.ctype_tag,'Value',handles.configdata.Config.newmodel+1);
    set(handles.multimodel_tag,'Value',handles.configdata.Config.multimodel+1);
    set(handles.oldmodel_tag,'String',handles.configdata.Path.oldmodel);
    
    %Region Selection
    set(handles.rtype_tag,'Value',handles.configdata.Material{1}.type);
    set(handles.txt_region_tag,'String','1');
    
    %Turn on/off Config.attenuation as needed
    if handles.configdata.Config.atten>0
        set(handles.txt_qp_tag,'Visible','on')
        set(handles.qp_tag,'Visible','on')
        set(handles.txt_qs_tag,'Visible','on')
        set(handles.qs_tag,'Visible','on')
    else
        set(handles.txt_qp_tag,'Visible','off')
        set(handles.qp_tag,'Visible','off')
        set(handles.txt_qs_tag,'Visible','off')
        set(handles.qs_tag,'Visible','off')
    end
    
    if handles.configdata.Config.newmodel==0
        set(handles.txt_oldmodel_tag,'Visible','off');
        set(handles.oldmodel_tag,'Visible','off');
    else
        set(handles.txt_oldmodel_tag,'Visible','on');
        set(handles.oldmodel_tag,'Visible','on');      
    end
    
    %Region 1 properties
    e3d_select_region(hObject, handles)
    
    

function e3d_select_region(hObject, handles)

    rnum=str2double(get(handles.txt_region_tag,'String'));
    set(handles.rnum_tag,'Title',['Region Number ' num2str(rnum)])
    set(handles.rtype_tag,'Value',handles.configdata.Material{rnum}.type);
    
    %Write Material Properties:
    set(handles.pvel_tag,'String',num2str(handles.configdata.Material{rnum}.vel(1)))
    set(handles.svel_tag,'String',num2str(handles.configdata.Material{rnum}.vel(2)))
    set(handles.dens_tag,'String',num2str(handles.configdata.Material{rnum}.vel(3)))
    set(handles.qp_tag,'String',num2str(handles.configdata.Material{rnum}.atten(1)))
    set(handles.qs_tag,'String',num2str(handles.configdata.Material{rnum}.atten(2)))
    set(handles.p_sdev_tag,'String',num2str(handles.configdata.Material{rnum}.sd(1)*100))
    set(handles.s_sdev_tag,'String',num2str(handles.configdata.Material{rnum}.sd(2)*100))
    set(handles.d_sdev_tag,'String',num2str(handles.configdata.Material{rnum}.sd(3)*100))
    set(handles.fdim_tag,'String',num2str(handles.configdata.Material{rnum}.dist(1)))
    set(handles.fx_tag,'String',num2str(handles.configdata.Material{rnum}.dist(2)))
    set(handles.fy_tag,'String',num2str(handles.configdata.Material{rnum}.dist(3)))
    set(handles.fz_tag,'String',num2str(handles.configdata.Material{rnum}.dist(4)))
    
    %Statistical Information Visibility
    if sum(handles.configdata.Material{rnum}.sd)==0
        set(handles.stype_tag,'Value',1);
        
        %Visibility
        set(handles.txt_p_sdev_tag,'Visible','off')
        set(handles.p_sdev_tag,'Visible','off')
        set(handles.txt_s_sdev_tag,'Visible','off')
        set(handles.s_sdev_tag,'Visible','off')
        set(handles.txt_d_sdev_tag,'Visible','off')
        set(handles.d_sdev_tag,'Visible','off')
        set(handles.txt_fdim_tag,'Visible','off')
        set(handles.fdim_tag,'Visible','off')
        set(handles.fscale_tag,'Visible','off')
        set(handles.txt_fx_tag,'Visible','off')
        set(handles.fx_tag,'Visible','off')
        set(handles.txt_fy_tag,'Visible','off')
        set(handles.fy_tag,'Visible','off')
        set(handles.txt_fz_tag,'Visible','off')
        set(handles.fz_tag,'Visible','off')
            
    else
       if handles.configdata.Material{rnum}.dist(1)==-1.5
            set(handles.stype_tag,'Value',2); 
           
            %Visibility
            set(handles.txt_p_sdev_tag,'Visible','on')
            set(handles.p_sdev_tag,'Visible','on')
            set(handles.txt_s_sdev_tag,'Visible','on')
            set(handles.s_sdev_tag,'Visible','on')
            set(handles.txt_d_sdev_tag,'Visible','on')
            set(handles.d_sdev_tag,'Visible','on')
            set(handles.txt_fdim_tag,'Visible','off')
            set(handles.fdim_tag,'Visible','off')
            set(handles.fscale_tag,'Visible','off')
            set(handles.txt_fx_tag,'Visible','off')
            set(handles.fx_tag,'Visible','off')
            set(handles.txt_fy_tag,'Visible','off')
            set(handles.fy_tag,'Visible','off')
            set(handles.txt_fz_tag,'Visible','off')
            set(handles.fz_tag,'Visible','off')
           
       else
            set(handles.stype_tag,'Value',3);
            
            %Visibility
            set(handles.txt_p_sdev_tag,'Visible','on')
            set(handles.p_sdev_tag,'Visible','on')
            set(handles.txt_s_sdev_tag,'Visible','on')
            set(handles.s_sdev_tag,'Visible','on')
            set(handles.txt_d_sdev_tag,'Visible','on')
            set(handles.d_sdev_tag,'Visible','on')
            set(handles.txt_fdim_tag,'Visible','on')
            set(handles.fdim_tag,'Visible','on')
            set(handles.fscale_tag,'Visible','on')
            set(handles.txt_fx_tag,'Visible','on')
            set(handles.fx_tag,'Visible','on')
            set(handles.txt_fy_tag,'Visible','on')
            set(handles.fy_tag,'Visible','on')
            set(handles.txt_fz_tag,'Visible','on')
            set(handles.fz_tag,'Visible','on')    
       end
    end
    
    
    %Geometry Information
    mat_vis=zeros([1 29]);
    switch handles.configdata.Material{rnum}.type
        case 1
            mat_vis(1:14)=1;

        case 2
            mat_vis(1:10)=1;

        case 3
            mat_vis(1:17)=1;
            
        case 4
            mat_vis(15)=1;
            mat_vis(29)=1;

        case 5
            mat_vis(1:12)=1;
            mat_vis(15:19)=1;
            mat_vis(22:24)=1;

        case 6
            mat_vis(1:10)=1;
            mat_vis(15)=1;
            mat_vis(29)=1;

        case 7
            mat_vis(1:5)=1;
            mat_vis(8:15)=1;
            mat_vis(29)=1;
            
        case 8
            mat_vis(1:3)=1;
            
    end 
    
   
%Visibility
    for ii=1:29
       if mat_vis(ii)==0
           set(eval(['handles.g' num2str(ii) '_tag']),'Visible','off')         
       else
           set(eval(['handles.g' num2str(ii) '_tag']),'Visible','on')
       end
    end
    
    
%Place Data
    switch handles.configdata.Material{rnum}.type
        case 1
            set(handles.g1_tag,'String','First Corner:')
            set(handles.g2_tag,'String','X0')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','Y0')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g6_tag,'String','Z0')
            set(handles.g7_tag,'String',num2str(handles.configdata.Material{rnum}.geo(5)))
            set(handles.g8_tag,'String','Second Corner:')
            set(handles.g9_tag,'String','X1')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g11_tag,'String','Y1')
            set(handles.g12_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))
            set(handles.g13_tag,'String','Z1')
            set(handles.g14_tag,'String',num2str(handles.configdata.Material{rnum}.geo(6)))

        case 2
            set(handles.g1_tag,'String','Center:')
            set(handles.g2_tag,'String','X0')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','Y0')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g6_tag,'String','Z0')
            set(handles.g7_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g8_tag,'String','Radius:')
            set(handles.g9_tag,'String','R')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))

        case 3
            set(handles.g1_tag,'String','Center of First End:')
            set(handles.g2_tag,'String','X0')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','Y0')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g6_tag,'String','Z0')
            set(handles.g7_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g8_tag,'String','Center of Second End:')
            set(handles.g9_tag,'String','X1')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))
            set(handles.g11_tag,'String','Y1')
            set(handles.g12_tag,'String',num2str(handles.configdata.Material{rnum}.geo(5)))
            set(handles.g13_tag,'String','Z1')
            set(handles.g14_tag,'String',num2str(handles.configdata.Material{rnum}.geo(6)))
            set(handles.g15_tag,'String','Radius:')
            set(handles.g16_tag,'String','R')
            set(handles.g17_tag,'String',num2str(handles.configdata.Material{rnum}.geo(7)))
            
        case 4
            set(handles.g15_tag,'String','Polynomial Coefficients:')
            set(handles.g29_tag,'RowName',{'x','y'});
            set(handles.g29_tag,'ColumnName',{'a0','a1','a2','a3','a4','a5'});
            set(handles.g29_tag,'Data',fliplr(handles.configdata.Material{rnum}.geo))
            
        case 5
            set(handles.g1_tag,'String','Point:')
            set(handles.g2_tag,'String','X0')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','Y0')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g6_tag,'String','Z0')
            set(handles.g7_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g8_tag,'String','Strike (S) / Dip (D)')
            set(handles.g9_tag,'String','S')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))
            set(handles.g11_tag,'String','D')
            set(handles.g12_tag,'String',num2str(handles.configdata.Material{rnum}.geo(5)))
            set(handles.g15_tag,'String','Roughness Wavelength (L) and Amplitude (A):')
            set(handles.g16_tag,'String','L')
            set(handles.g17_tag,'String',num2str(handles.configdata.Material{rnum}.geo(6)))
            set(handles.g18_tag,'String','A')
            set(handles.g19_tag,'String',num2str(handles.configdata.Material{rnum}.geo(7)))
            set(handles.g22_tag,'String','Thickness Below Surface (T)')
            set(handles.g23_tag,'String','T')
            set(handles.g24_tag,'String',num2str(handles.configdata.Material{rnum}.geo(9)))

        case 6
            set(handles.g1_tag,'String','Origin:')
            set(handles.g2_tag,'String','X0')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','Y0')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g6_tag,'String','Z0')
            set(handles.g7_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g8_tag,'String','Azimuth:')
            set(handles.g9_tag,'String','A')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))
            set(handles.g15_tag,'String','Cross Section:')
            set(handles.g29_tag,'RowName',{'x','y'})
            set(handles.g29_tag,'Data',reshape(handles.configdata.Material{rnum}.geo(5:end),2,[]))
            
            
        case 7
            set(handles.g1_tag,'String','Tunnel Width (W) and Height (H)')
            set(handles.g2_tag,'String','W')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            set(handles.g4_tag,'String','H')
            set(handles.g5_tag,'String',num2str(handles.configdata.Material{rnum}.geo(2)))
            set(handles.g8_tag,'String','Origin:')
            set(handles.g9_tag,'String','X0')
            set(handles.g10_tag,'String',num2str(handles.configdata.Material{rnum}.geo(3)))
            set(handles.g11_tag,'String','Y0')
            set(handles.g12_tag,'String',num2str(handles.configdata.Material{rnum}.geo(4)))
            set(handles.g13_tag,'String','Z0')
            set(handles.g14_tag,'String',num2str(handles.configdata.Material{rnum}.geo(5)))
            set(handles.g15_tag,'String','Tunnel Segment Orientations:')
            set(handles.g29_tag,'RowName',{'Azimuth','Dip','Length'})
            set(handles.g29_tag,'Data',reshape(handles.configdata.Material{rnum}.geo(6:end),3,[]))
            
        case 8
            set(handles.g1_tag,'String','Number of Gridpoints:')
            set(handles.g2_tag,'String','N')
            set(handles.g3_tag,'String',num2str(handles.configdata.Material{rnum}.geo(1)))
            
    end 
    
    %Update the gui structure
    guidata(hObject, handles);
    
     
function handles=e3d_material_update(hObject, handles)

    %Material Controll:
    handles.configdata.Config.degrees_free=get(handles.iparam_tag,'Value');
    handles.configdata.Config.newmodel=get(handles.ctype_tag,'Value')-1;
    handles.configdata.Config.multimodel=get(handles.multimodel_tag,'Value')-1;
    handles.configdata.Path.oldmodel=get(handles.oldmodel_tag,'String');
    
    if handles.configdata.Config.newmodel==0
        set(handles.txt_oldmodel_tag,'Visible','off');
        set(handles.oldmodel_tag,'Visible','off');
    else
        set(handles.txt_oldmodel_tag,'Visible','on');
        set(handles.oldmodel_tag,'Visible','on');  
    end
    
    %Region Selection
    rnum=str2double(get(handles.txt_region_tag,'String'));
    handles.configdata.Material{rnum}.type=get(handles.rtype_tag,'Value');
%     
%     %Copy flag
%     handles.configdata.Material{rnum}.cf=0;
    
    %Average Material Properties:
    handles.configdata.Material{rnum}.vel(1)=str2double(get(handles.pvel_tag,'String'));
    handles.configdata.Material{rnum}.vel(2)=str2double(get(handles.svel_tag,'String'));
    handles.configdata.Material{rnum}.vel(3)=str2double(get(handles.dens_tag,'String'));
    handles.configdata.Material{rnum}.Config.atten(1)=str2double(get(handles.qp_tag,'String'));
    handles.configdata.Material{rnum}.Config.atten(2)=str2double(get(handles.qs_tag,'String'));
    
    %Statistcal Info
    handles.configdata.Material{rnum}.sd(1)=str2double(get(handles.p_sdev_tag,'String'))/100;
    handles.configdata.Material{rnum}.sd(2)=str2double(get(handles.s_sdev_tag,'String'))/100;
    handles.configdata.Material{rnum}.sd(3)=str2double(get(handles.d_sdev_tag,'String'))/100;
    handles.configdata.Material{rnum}.dist(1)=str2double(get(handles.fdim_tag,'String'));
    handles.configdata.Material{rnum}.dist(2)=str2double(get(handles.fx_tag,'String'));
    handles.configdata.Material{rnum}.dist(3)=str2double(get(handles.fy_tag,'String'));
    handles.configdata.Material{rnum}.dist(4)=str2double(get(handles.fz_tag,'String'));
    
%Geometry Data
    switch handles.configdata.Material{rnum}.type
        case 1 
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(5)=str2double(get(handles.g7_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g10_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g12_tag,'String'));
            handles.configdata.Material{rnum}.geo(6)=str2double(get(handles.g14_tag,'String'));

        case 2
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g7_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g10_tag,'String'));
            
        case 3
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g7_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g10_tag,'String'));
            handles.configdata.Material{rnum}.geo(5)=str2double(get(handles.g12_tag,'String'));
            handles.configdata.Material{rnum}.geo(6)=str2double(get(handles.g14_tag,'String'));
            handles.configdata.Material{rnum}.geo(7)=str2double(get(handles.g17_tag,'String'));
            
        case 4
            handles.configdata.Material{rnum}.geo=fliplr(get(handles.g29_tag,'Data'));
            
        case 5
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g7_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g10_tag,'String'));
            handles.configdata.Material{rnum}.geo(5)=str2double(get(handles.g12_tag,'String'));
            handles.configdata.Material{rnum}.geo(6)=str2double(get(handles.g17_tag,'String'));
            handles.configdata.Material{rnum}.geo(7)=str2double(get(handles.g19_tag,'String'));
            handles.configdata.Material{rnum}.geo(9)=str2double(get(handles.g24_tag,'String'));

        case 6
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g7_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g10_tag,'String'));
            handles.configdata.Material{rnum}.geo(5:end)=reshape(get(handles.g29_tag,'Data'),1,[]);
            
            
        case 7
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            handles.configdata.Material{rnum}.geo(2)=str2double(get(handles.g5_tag,'String'));
            handles.configdata.Material{rnum}.geo(3)=str2double(get(handles.g10_tag,'String'));
            handles.configdata.Material{rnum}.geo(4)=str2double(get(handles.g12_tag,'String'));
            handles.configdata.Material{rnum}.geo(5)=str2double(get(handles.g14_tag,'String'));
            handles.configdata.Material{rnum}.geo(6:end)=reshape(get(handles.g29_tag,'Data'),1,[]);
            
        case 8
            handles.configdata.Material{rnum}.geo(1)=str2double(get(handles.g3_tag,'String'));
            
    
    end
    
    %Update the gui structure
    guidata(hObject, handles);





%-------------------------------------------------------------------------%        
%                                                                         %
%Unused callback functions:                                               %
%                                                                         %
%-------------------------------------------------------------------------%
function varargout = e3d_gui_material_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function rselect1_tag_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

function rtype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function iparam_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function nregions_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function ctype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function multimodel_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function pvel_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function svel_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function dens_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function qp_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function qs_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function stype_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sdev_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function fdim_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function fx_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function fy_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function fz_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g3_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g5_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function g7_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g10_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g12_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g14_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g17_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g19_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g21_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g24_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g26_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function g28_tag_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function oldmodel_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit27_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit26_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit25_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function p_sdev_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function s_sdev_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function d_sdev_tag_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function iparam_tag_Callback(hObject, eventdata, handles)
    
function multimodel_tag_Callback(hObject, eventdata, handles)
    
function pvel_tag_Callback(hObject, eventdata, handles)
    
function svel_tag_Callback(hObject, eventdata, handles)
    
function dens_tag_Callback(hObject, eventdata, handles)
    
function qp_tag_Callback(hObject, eventdata, handles)
    
function qs_tag_Callback(hObject, eventdata, handles)
        
function sdev_tag_Callback(hObject, eventdata, handles)
    
function fdim_tag_Callback(hObject, eventdata, handles)
    
function fx_tag_Callback(hObject, eventdata, handles)
    
function fy_tag_Callback(hObject, eventdata, handles)
    
function fz_tag_Callback(hObject, eventdata, handles)
    
function g3_tag_Callback(hObject, eventdata, handles)
    
function g5_tag_Callback(hObject, eventdata, handles)
    
function g7_tag_Callback(hObject, eventdata, handles)
    
function g10_tag_Callback(hObject, eventdata, handles)
    
function g12_tag_Callback(hObject, eventdata, handles)
    
function g14_tag_Callback(hObject, eventdata, handles)
    
function g17_tag_Callback(hObject, eventdata, handles)
    
function g19_tag_Callback(hObject, eventdata, handles)
    
function g21_tag_Callback(hObject, eventdata, handles)
    
function g24_tag_Callback(hObject, eventdata, handles)
    
function g26_tag_Callback(hObject, eventdata, handles)
    
function g28_tag_Callback(hObject, eventdata, handles)
    
function oldmodel_tag_Callback(hObject, eventdata, handles)
    
function edit27_Callback(hObject, eventdata, handles)
    
function edit26_Callback(hObject, eventdata, handles)
    
function edit25_Callback(hObject, eventdata, handles)
    
function p_sdev_tag_Callback(hObject, eventdata, handles)
    
function s_sdev_tag_Callback(hObject, eventdata, handles)
    
function d_sdev_tag_Callback(hObject, eventdata, handles)    
    
