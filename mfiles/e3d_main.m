%
% Chris Sherman
% Dept. of Civil and Environmental Engineering
% University of California Berkeley
% cssherman@berkeley.edu
%
%
% E3D is an explicit 2D/3D elastic finite difference wave propagation code
% developed by Shawn Larsen at Lawrence Livermore National Laboratory.
% This code has been developed to serve as a MATLAB interface to E3D.  The
% primary gui for this code is called e3d_gui.  
%
%
% Reference:
% Larsen, S., et al. (2001). Next-generation numerical modeling: Incorporating 
%    elasticity, anisotropy and Config.attenuation. Los Alamos National Lab., NM (US).


%% Set up Workspace
clear all
close all
clc
drawnow
load('./config/e3d_config.mat');       %Read configuration file, and write log information
Path.startpath=pwd;        %Remember the old path

%Write some things into the logfiles
[~,~]=unix(['rm ' Path.log 'master_comp']);
[~,~]=unix(['echo "#!/bin/bash" > ' Path.log 'master_comp']);
[~,~]=unix(['chmod 777 ' Path.log 'master_comp']);
[~,~]=unix(['echo "New set of E3D models for ' Path.user  ' " >> ' Path.log 'e3d_log.txt']);

%Link the output files to a centralized directory
if ~strcmp('Path.link','') 
    link=1;
    if isempty(dir([Path.link '1*']))
        mkdir(Path.link)
        link_off=99;
    else
        dlist=dir([Path.link '*']);
        link_off=str2double(dlist(end).name);
    end
else
    link=0;
end

%Write progress to a waitbar
wb=waitbar(0,'Test');
set(wb,'outerposition',[0 790 350 100])
wb2=get(findobj(wb,'Type','axes'),'Title');
set(wb2,'FontSize',Plotting.fontsize,'FontName',Plotting.font)


%% Main Loop
for loop=1:Config.loopnum
try
    
%% Book keeping  
%Modify configuration for each loop
e3d_update; 
wmsg=['Model # ' num2str(loop) ' out of ' num2str(Config.loopnum)];

%Create and cd to workspace
if isempty(dir([Path.out date '/1*']))
    mkdir([Path.out date '/100'])
    cd([Path.out date '/100'])
    base_loc=100;
else
    dlist=dir([Path.out date '/*']);
    base_loc=str2double(dlist(end).name)+1;
    mkdir([Path.out date '/' num2str(base_loc)])
    cd([Path.out date '/' num2str(base_loc)])
end

%Link files
if link==1
   [~,~]=unix(['ln -s ' Path.out date '/' num2str(base_loc) ' ' Path.link num2str(loop+link_off)]);
end
    
%Write to the logfile
[~,~]=unix(['echo "Analysis # ' num2str(loop) ' " >> ' Path.log 'e3d_log.txt']);
[~,~]=unix(['echo "   location:  ' Path.out date '/' num2str(base_loc) ' " >> ' Path.log 'e3d_log.txt']);
[~,~]=unix(['echo "' Path.log_msg  '" >> ' Path.log 'e3d_log.txt']);
[~,~]=unix(['echo " " >> ' Path.log 'e3d_log.txt']);

%Create directories to hold ouptuts and a bash script to handle movie compression
mkdir('mov');
mkdir('sac');
[~,~]=unix('echo "#!/bin/bash" >> ./mov/comp');
[~,~]=unix('chmod 777 ./mov/comp');
[~,~]=unix(['echo "cd ' Path.out date '/' num2str(base_loc) '/mov" >> ' Path.log 'master_comp']);
[~,~]=unix(['echo "./comp" >> ' Path.log 'master_comp']);
[~,~]=unix(['echo "rm ./comp" >> ' Path.log 'master_comp']);


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

%Record the location of the first model, and link to it if requested (multimodel==1)
if loop==1
   Path.firstmodel=[Path.out date '/' num2str(base_loc) '/'];
end
if Config.multimodel==1 && loop>1
    Path.oldmodel=Path.firstmodel;
    Config.newmodel=1;
    Plotting.mov=0;
end

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
    if Boundary.atten==1 && Config.atten==1 %Attenuating boundary
        region=e3d_locate(Model,8,Boundary.atten_thick);
        save('region_atten.mat','region','-v7.3')
        clear region  
    end
    if Boundary.damp_rand==1                %Damp heterogeneity for stability
        region=e3d_locate(Model,8,4);
        save('region_damp_rand.mat','region','-v7.3')
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
            if Boundary.damp_rand==1
                load('region_damp_rand.mat')
                fractal=(1-region).*fractal;
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
            load('region_atten.mat')
            velocity=(1-region).*velocity+region.*Boundary.atten_val;
        end
        clear region

        %Record the min, max, and average model parameters
        Model.v_max(ii)=max(max(max(velocity)));
        Model.v_min(ii)=min(min(min(velocity)));
        Model.v_avg(ii)=mean(mean(mean(velocity)));

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
    
    %Load the old config file and copy important variables
    tmp=load([Path.oldmodel 'config.mat']);
    Model.v_max=tmp.Model.v_max;
    Model.v_min=tmp.Model.v_min;
    Model.v_avg=tmp.Model.v_avg;
    clear tmp
end
delete('region*.mat')

%Plot the model files with open degrees of freedom
for ii=1:3
   if Plotting.model>0 && ii<=Config.degrees_free
        e3d_plot(Model,Plotting,ft{ii})
   end
end


%% Determine E3D inputs
%Time step size (Courant condition)
if min(Model.number)>1
    courant=0.494;
else
    courant=0.606;
end
Model.dt=Model.max_dtct*courant*Model.spacing(1)/Model.v_max(1);
Model.dt=str2double(sprintf('%1.0e',Model.dt));     %Limit the number of significant digits on the timestep
Model.timesteps=ceil(Model.time/Model.dt);

%Grid and input file size
gridsize={num2str(max(Model.number(1)-1,1)),num2str(max(Model.number(3)-1,1)),num2str(max(Model.number(2)-1,1))}; %n, m, l
inputsize={num2str(Model.number(1)-1),num2str(Model.number(3)-1),num2str(Model.number(2)-1)};    %n2, m2, l2

%Seismic sources
freqlim=[1/(2*Model.dt),Model.v_min(1)/(10*Model.spacing(1))]; %Frequency limit (Nyquist and dispersion)
fmax=0;
fmean=0;
for ii=1:length(Source)
    %Check to see if the source frequency is too largepen 
    if Source{ii}.freq>min(freqlim)
        Source{ii}.freq=min(freqlim); %#ok<*SAGROW>
        warning('e3d:warning','Desired source frequency too large... Reducing f')
    end
    %Track the mean and max frequency:
    fmax=max(Source{ii}.freq,fmax);
    fmean=fmean+Source{ii}.freq;
end
fmean=fmean/length(Source);

%Seismogram traces
if ~isempty(Output.trace)
    ntrace=1;
    %Create the trace records:
    for ii=1:length(Output.trace)
        switch Output.trace{ii}.dir
            case {'X','x'}
                comp=1;
            case {'Y','y'}
                comp=2;
            case {'Z','z'}
                comp=3;
        end

        if Output.trace{ii}.N~=0
            tracefile_temp=repmat(Output.trace{ii}.loc,[Output.trace{ii}.N 1]);
            tracefile_temp(:,comp)=linspace(Output.trace{ii}.loc(comp),(Output.trace{ii}.N-1)*Output.trace{ii}.space+Output.trace{ii}.loc(comp),Output.trace{ii}.N);
            tracefile(ntrace:ntrace+Output.trace{ii}.N-1,:)=tracefile_temp;
            ntrace=ntrace+Output.trace{ii}.N;
        end
    end

    %Offset:
    tracefile(:,1)=tracefile(:,1)-Model.origin(1);
    tracefile(:,2)=tracefile(:,2)-Model.origin(2);
    tracefile(:,3)=tracefile(:,3)-Model.origin(3);

    %Check to see if seismograms are in the grid:
    test=sum(tracefile(:,1)>Model.size(1))+sum(tracefile(:,2)>Model.size(2))+sum(tracefile(:,3)>Model.size(3));
    if test>0
        warning('e3d:warning','Some of the seismograms fall outside of the grid');
    end
end

%Save the model parameters:
save('model.mat','Path','Config','Boundary','Model','Source','Plotting','Rerender','Output','Material');

    
    
%% Input File    
%Write the input file for E3D:
fid=fopen(Path.in,'w');
    
    %Add the grid size, time step size, and analysis options
    if Boundary.sponge==1
        fprintf(fid,'\n %s',['grid n=' gridsize{1} ' m=' gridsize{2} ' l=' gridsize{3} ' dh=' num2str(Model.spacing(1)) ' damp=10 adamp=0.95 model=' num2str(Config.acoust) ' b=' num2str(Boundary.type) ]);
    else
        fprintf(fid,'\n %s',['grid n=' gridsize{1} ' m=' gridsize{2} ' l=' gridsize{3} ' dh=' num2str(Model.spacing(1)) ' model=' num2str(Config.acoust) ' b=' num2str(Boundary.type) ]);
    end
    if Config.atten==1
        fprintf(fid,'%s',' q=1');
    end
    if prod(Config.multicore)>1
        fprintf(fid,'\n %s',['parallel nx=' num2str(Config.multicore(1)) ' ny=' num2str(Config.multicore(2)) ' nz=' num2str(Config.multicore(3))]);
    end
    fprintf(fid,'\n %s',['time t=' num2str(Model.timesteps) ' dt=' sprintf('%1.0e',Model.dt)]);

    %Add velocity and attenuation
    fprintf(fid,'\n %s',['block p=' num2str(Material{1}.vel(1)) ' s=' num2str(Material{1}.vel(2)) ' r=' num2str(Material{1}.vel(3))]);  %These values get overidden, but are necessary to run.
    if Config.atten==1  
        fprintf(fid,'%s',[' Qp=' num2str(Material{1}.atten(1)) ' Qs=' num2str(Material{1}.atten(2)) ' Qf=' num2str(fmean)]);
    end
    for ii=1:n_inputs
        fprintf(fid,'\n %s',['vfile type=' ft2{ii} ' file="' ft{ii} '.pv" n1=0 n2=' inputsize{1} ' m1=0 m2=' inputsize{2} ' l1=0 l2=' inputsize{3}]);
    end
    
    %Add source terms
    for ii=1:length(Source)
        fprintf(fid,'\n %s',['source type=' num2str(Source{ii}.type) ' amp=' num2str(Source{ii}.amp,'%1.5e') ' x=' num2str(Source{ii}.loc(1)-Model.origin(1)) ' y=' num2str(Source{ii}.loc(2)-Model.origin(2)) ' z=' num2str(Source{ii}.loc(3)-Model.origin(3))]);
        switch Source{ii}.type
            case 4  %Moment Tensor
                fprintf(fid,'%s',[' Mxx=' num2str(Source{ii}.M(1)) ' Myy=' num2str(Source{ii}.M(2)) ' Mzz=' num2str(Source{ii}.M(3)) ' Mxy=' num2str(Source{ii}.M(4)) ' Mxz=' num2str(Source{ii}.M(5)) ' Myz=' num2str(Source{ii}.M(6))]);

            case 5  %Force
                fprintf(fid,'%s',[' Fx=' num2str(Source{ii}.F(1)) ' Fy=' num2str(Source{ii}.F(2)) ' Fz=' num2str(Source{ii}.F(3))]);

            case 6  %Point Fault
                fprintf(fid,'%s',[' strike=' num2str(Source{ii}.orient(1)) ' dip=' num2str(Source{ii}.orient(2)) ' rake=' num2str(Source{ii}.orient(3))]);

            case 7  %Finite Fault
                fprintf(fid,'%s',[' strike=' num2str(Source{ii}.orient(1)) ' dip=' num2str(Source{ii}.orient(2)) ' rake=' num2str(Source{ii}.orient(3)) ' length=' num2str(Source{ii}.orient(4)) ' width=' num2str(Source{ii}.orient(5)) ' depth=' num2str(Source{ii}.orient(6)) ' s0=' num2str(Source{ii}.orient(7)) ' d0=' num2str(Source{ii}.orient(8)) ' v=' num2str(Source{ii}.orient(9))]);
        end
        switch Source{ii}.wav
            case 0  %Ricker
                fprintf(fid,'%s',[' t0=' num2str(Source{ii}.off) ' freq=' num2str(Source{ii}.freq)]);
            case 1  %Integral of Ricker
                e3d_wavelet(Model,Source{ii})
                fprintf(fid,'%s',' file="wav.sac"');
        end
    end
    
    %Add seismogram and movie outputs
    if ~isempty(Output.trace)
        dlmwrite('trace',tracefile,' ') 
        fprintf(fid,'\n %s',['traces file="out" tfile="trace" sample=' num2str(Plotting.dec_time) ' mode=7']);
    end
    for ii=1:length(Output.movie) 
        switch Output.movie{ii}.dir
            case {'X','x'}
                comp=1;
                plane='x';
            case {'Y','y'}
                comp=2;
                plane='y';
            case {'Z','z'}
                comp=3;
                plane='z';
        end
        loc=Output.movie{ii}.loc-Model.origin(comp);
        fprintf(fid,'\n %s',['image movie=' num2str(Plotting.dec_time) ' sample=' num2str(Plotting.dec_space) ' ' plane '=' num2str(loc) ' mode=' num2str(Output.movie{ii}.type) ' file="' plane '_' num2str(Output.movie{ii}.loc) '"']);
    end
fclose(fid);


%% Run E3D
if Config.run==1
    waitbar(1,wb,{wmsg;'Sending model to E3D'})
    display(['Model #' num2str(loop)])
    display('----------')
    display(['T = ' num2str(Model.timesteps) ' steps'])
    display(' ')
    
    %Choose basic or mpi run
    if prod(Config.multicore)==1
        unix([ Path.e3d_bin 'e3d ' Path.in]);
    else
        unix(['mpirun -np ' num2str(prod(Config.multicore)) ' --cpus-per-proc 1 ' Path.e3d_bin 'e3d ' Path.in]);
    end
    
    %Render files
    if Plotting.trace==1
        e3d_trace(Material,Model,Output,Plotting,Source);
    end  
    if Plotting.movie==1
        e3d_movie(Config,Model,Output,Path,Plotting);
    end
    
    clc
end

catch ME
    display('Error detected... moving to next model')
    display(ME.message)
    pause(5)
%     send_gmail('username@berkeley.edu','E3D Error',['Model #' num2str(loop) ': ' ME.message])
    
end
end

%Cleanup
close(wb)
cd(Path.startpath)
% send_gmail('username@berkeley.edu','E3D Status',[num2str(Config.loopnum) ' Simulations Completed Successfuly!'])
e3d_gui
