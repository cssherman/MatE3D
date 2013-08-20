%
%   Chris Sherman
%   Dept. of Civil and Environmental Engineering
%   University of California Berkeley
%   cssherman@berkeley.edu
%
%
% E3D is an explicit 2D/3D elastic finite difference wave propagation code
% developed by Shawn Larsen at Lawrence Livermore National Laboratory (2001).
% This code has been developed to serve as a MATLAB interface to E3D.  To
% use this code, edit the configuration file "e3d_config", and then
% execute the file "e3d_main".
%
%
% Stripped down version to render velocity models

%% Set up Workspace
clear all
close all
drawnow
loop=1;
load e3d_config.mat;       %Read configuration file, and write log information
e3d_update                 %Make any requested changes to the input file
oldpath=pwd;               %Remember the old path

if isempty(dir('./render'))
    mkdir('./render') 
    mkdir('./render/mov')
else
    [~,~]=unix('rm -r ./render/*');
    mkdir('./render/mov')
end
cd('./render')

%Write progress to a waitbar
wb=waitbar(0,'Test');
set(wb,'outerposition',[0 790 350 100])
wb2=get(findobj(wb,'Type','axes'),' ');
set(wb2,'FontSize',Plotting.fontsize,'FontName',Plotting.font)


%% Build Model 
%Check model dimensions
Model.number=round((Model.size)./(Model.spacing));  
if Model.dims==2
    Model.number(2)=1;
    Model.size(2)=Model.number(2)*Model.spacing(2);
end

%Naming convention for velocity/attenuation files
ft={'pvel','svel','rdens','qp','qs'};
ft2={'p','s','r','Qp','Qs'};
ft3={'P-wave velocity file','S-wave velocity file','Density file','Qp file','Qs file'};

%Choose which input files to write based upon the model
if Config.acoust==2
    Config.atten=0;
    Config.degrees_free=1;
    n_inputs=1;
elseif Config.atten==0
    n_inputs=3;
else
    n_inputs=5;
end

%% Write or link to material property files
if Config.newmodel==0 || Config.newmodel==2
    
    %Determine the number of steps to build the model
    n_regions=length(Material);
    wh_steps=(n_regions+1)*(n_inputs+1);
    
    %Determine material/boundary locations within model
    for ii=1:n_regions
        waitbar(ii/wh_steps,wb,{wmsg;['Locating Region #' num2str(ii) '...']})
        region=e3d_locate(Model,Material{ii}.type,Material{ii}.geo);
        save(['region_' num2str(ii) '.mat'],'region','-v7.3')
        clear region
    end
    if Boundary.atten==1 && Config.atten==1
        region=e3d_locate(Model,8,Boundary.atten_thick,-1);
        save('region_bound.mat','region','-v7.3')
        clear region  
    end
    
    %Placeholders
    velocity=single(zeros(Model.number));
    Model.v_max=single(zeros([1 5]));
    Model.v_min=single(zeros([1 5]));
    
    for ii=1:n_inputs
        %Generate a fractal distribution if the degree of freedom is avaiable
        if ii<=Config.degrees_free
            waitbar((n_regions+1)*ii/wh_steps,wb,{wmsg;'Generating material distribution...'})
            fractal=single(zeros(Model.number));
            for jj=1:n_regions   
                fractal_tmp=e3d_fractal(Material{jj}.dist,Model);
                load(['region_' num2str(jj) '.mat'])
                fractal=(1-region).*fractal+region.*fractal_tmp;
            end
            clear region fractal_tmp
        end

        %Read the old model file if requested
        if Config.newmodel==2
            waitbar((n_regions+1)*ii/wh_steps,wb,{wmsg;'Reading old model...'})
            fid=fopen([Path.oldmodel ft{ii} '.pv']);
                for yy=1:Model.number(2)
                    for zz=1:Model.number(3)
                        velocity(:,yy,zz)=fread(fid,Model.number(1),'single');
                    end
                end
            fclose(fid);
        end

        %Apply the mean, standard deviation to the distribution by region
        for jj=1:n_regions
            waitbar(((n_regions+1)*ii+jj)/wh_steps,wb,{wmsg;['Writing ' ft3{ii} '...']})
            if ii>3
                mn=Material{jj}.atten(ii-3);
                sd=0;
            else
                mn=Material{jj}.vel(ii);
                sd=Material{jj}.sd(ii);
            end
            load(['region_' num2str(jj) '.mat'])
            velocity=(1-region).*velocity+region.*(sd.*fractal+1)*mn;
        end
        if ii>3 && Boundary.atten==1
            load('region_bound.mat')
            velocity=(1-region).*velocity+region.*Boundary.atten_val;
        end
        clear region

        %Write to the model file
        fid=fopen([ft{ii} '.pv'],'w');
            for yy=1:Model.number(2)
                for zz=1:Model.number(3)
                        fwrite(fid,velocity(:,yy,zz),'single');
                end
            end
        fclose(fid);
    end
    clear velocity fractal
    
else   
    %Link to an existing velocity model:
    waitbar(1,wb,{wmsg;'Linking to existing model'})
    [~,~]=unix(['ln -s ' Path.oldmodel '*.pv  ./']);
    
end
delete('region*.mat')

%Plot the model files with open degrees of freedom
waitbar(1,wb,{wmsg;'Plotting results...'})
for ii=1:3
   if Plotting.model>0 && ii<=Config.degrees_free
        e3d_plot(Model,Plotting,ft{ii})
   end
end

%Cleanup
delete('*.pv');
close(wb)
cd(Path.startpath)
e3d_gui
