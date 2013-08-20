
function e3d_movie(Config,Model,Output,Path,Plotting)

%cleanup
close(figure(1))
fclose('all');
cd './mov/'

%Size config
hres=480;               %Video resolution (Standard is 480, 720, or 1280)
aratio=[4/3,16/9];      %Choices for aspect ratio (Standard is 4:3 or 16:9)

%Movie name pointers
mfile_types={'Vx','Vy','Vz','Txx','Tyy','Tzz','Txy','Txz','Tyz','FP','FS'};
mfile_off=10;
nmov=length(Output.movie);

%Filtering/Scaling configuration
bandpass_poles=3;       %Number of poles for the filter
bandpass_min=0.005;     %Minimum size for the normalized frequency bin (reduces the sampling rate if necessary)  
scale_length=30;        %Time length to change scale over
load('rb_map.mat');     %Load a custom colormap

%Look at system memory in case a file is too large to load at once:
sysmem=30;              %Size of system memory (gb)
maxmem=0.35;            %Percent of memory allowed to read a file at a single time
floatsize=7.5e-9;       %gb/float
writestep=100;          %How often to write the movie
mov(1:writestep) = struct('cdata', [],'colormap', []);  %Movie placeholder

%Remove old movie files, write to the compression file, and create the progress bar
[~,~]=unix('rm ./*_.avi');
unix(['echo "' Path.log 'e3d_comp.sh ' num2str(nmov) '" > ./comp']);
unix('chmod 775 ./comp');
wm=waitbar(0,'Reading movie files...');
set(wm,'outerposition',[0 675 350 100])
wm2=get(findobj(wm,'Type','axes'),'Title');
set(wm2,'FontSize',Plotting.fontsize,'FontName',Plotting.font)


%% Main
for ii=1:nmov
    %Determine movie location, name
    switch Output.movie{ii}.dir
        case {'X','x'}
            plane='x';
            dir1=[2,3];
            labels={'Y','Z'};
            zflag='ij';
            ngrids=Config.multicore(2)*Config.multicore(3);
        case {'Y','y'}          
            plane='y';
            dir1=[1,3];
            labels={'X','Z'};
            zflag='ij';
            ngrids=Config.multicore(1)*Config.multicore(3);
        case {'Z','z'}        
            plane='z';
            dir1=[1,2];
            labels={'X','Y'};
            zflag='equal';
            ngrids=Config.multicore(1)*Config.multicore(2);
    end    
    movfile=[plane '_' num2str(Output.movie{ii}.loc) '.' char(mfile_types(Output.movie{ii}.type-mfile_off))];
    mtitle=[char(mfile_types(Output.movie{ii}.type-mfile_off)) ' for ' plane '=' num2str(Output.movie{ii}.loc) '  t='];
    
    %Open the movie writer, and move the file into the appropriate directory
    avi=VideoWriter(['./temp_' num2str(ii) '.avi']); %#ok<TNMLP>
    open(avi);
    if exist(['../' movfile],'file')==2
        unix(['mv ../' movfile ' ./' movfile]);
    end
    
    %Rerender movie file
    if exist(['./' movfile],'file')==2
        
        %Read from the movie file
        fid=fopen(movfile);
        x=fread(fid,1,'int');
        y=fread(fid,1,'int');
        t=fread(fid,1,'int');
        dt=fread(fid,1,'float');
        sx=fread(fid,1,'int');
        sy=fread(fid,1,'int');
        sxo=fread(fid,1,'int');
        syo=fread(fid,1,'int');
        f=fread(fid,1,'int');
        col=round((x-1)/f+1);
        row=round((y-1)/f+1);
        submax=floor(sysmem*maxmem/(col*row*floatsize));
        temp2=zeros([col row min(submax,t)]);

        %Setup plotting vectors, counters, scale
        Xscale=linspace(1,col,col)*Model.spacing(dir1(1))*f+Model.origin(dir1(1));
        Yscale=linspace(1,row,row)*Model.spacing(dir1(2))*f+Model.origin(dir1(2));
        Cwin=gausswin(scale_length);
        nt=1;
        subcount=1;
        timestamp=1;
        if Output.movie{ii}.type<14
            Ascale=20;
        elseif Output.movie{ii}.type<20
            Ascale=1e3;
        else
            Ascale=20;
        end


        while nt<=t
            %Read data from each subgrid
            waitbar(nt/t,wm,['Reading movie file #' num2str(ii) '...'])
            while nt<t && subcount<submax
                for sub=1:ngrids
                    nx=floor((sx-1)/f+1);
                    ny=floor((sy-1)/f+1);
                    nxo=floor(sxo/f);
                    nyo=floor(syo/f);
                    temp=fread(fid,nx*ny,'float');
                    temp2(1+nxo:nxo+nx,1+nyo:nyo+ny,subcount)=reshape(temp,nx,ny);
                    sx=fread(fid,1,'int');
                    sy=fread(fid,1,'int');
                    sxo=fread(fid,1,'int');
                    syo=fread(fid,1,'int');
                    f=fread(fid,1,'int');  
                end
                nt=nt+1;
                subcount=subcount+1;
            end


            %Setup filtering
            bandpass_norm=2*dt*Plotting.bandpass;
            if bandpass_norm(1)>0 && bandpass_norm(2)<1
                fflag='bandpass';
                resamp=max(ceil(bandpass_min/diff(bandpass_norm)),1);      
                bandpass_norm=2*dt*resamp*Plotting.bandpass;
                ftitle=['Bandpass: (' num2str(Plotting.bandpass(1)) ',' num2str(Plotting.bandpass(2)) ') Hz'];

            elseif bandpass_norm(1)>0 && bandpass_norm(2)>=1
                fflag='high';
                resamp=max(ceil(bandpass_min/bandpass_norm(1)),1);
                bandpass_norm=2*dt*resamp*Plotting.bandpass(1);
                ftitle=['Highpass: (' num2str(Plotting.bandpass(1)) ') Hz'];  

            elseif bandpass_norm(1)<=0 && bandpass_norm(2)<1
                fflag='low';
                resamp=max(ceil(bandpass_min/bandpass_norm(2)),1);
                bandpass_norm=2*dt*resamp*Plotting.bandpass(2);
                ftitle=['Lowpass: (' num2str(Plotting.bandpass(2)) ') Hz'];

            else
                fflag='broad';
                resamp=1;
                ftitle=[];   
            end   

            %Resample, window, and filter the data
            nr=floor(subcount/resamp)*resamp; 
            if ~strcmp('broad',fflag)
                temp2=temp2(:,:,1:nr);
                temp2=reshape(temp2(:,:,1:nr),col,row,resamp,[]);
                temp2=squeeze(temp2(:,:,1,:));
                dt=resamp*dt;
                win=repmat(reshape(tukeywin(nr/resamp,0.1),1,1,[]),[col row 1]);
                temp2=temp2.*win;
                [butterb,buttera]=butter(bandpass_poles,bandpass_norm,fflag);
                temp2=filter(butterb,buttera,temp2,[],3);
                clear win
            end  

            %Choose the colorscale and aspect ratio
            cscale=squeeze(max(max(abs(temp2),[],1),[],2));
            cscale=conv(cscale,Cwin,'same')/Ascale;
            aratio_file=col/row;
            [~,I]=min(abs(aratio-aratio_file));
            aratio_render=aratio(I);
            
            %Setup the plot
            if timestamp==1
                fhandle=figure(1);
                set(fhandle,'outerposition',[1 150 round(hres*aratio_render) hres])
                set(fhandle,'Renderer','zbuffer')
                colormap(rb_map)
                h1=pcolor(Xscale,Yscale,temp2(:,:,1)');
                shading interp
                set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)
                xlabel(labels{1})
                ylabel(labels{2})
                axis equal
                axis(zflag);
                axis manual
                xlim([min(Xscale),max(Xscale)])
                ylim([min(Yscale),max(Yscale)])
                clim=[-1 1]*max(cscale(1),1e-9);
                caxis(clim);
                colorbar
                wcount=1;
            end
            
            %Render the file
            waitbar(timestamp/t,wm,['Rendering movie file #' num2str(ii) '...'])   
            for j=1:nr  
                set(h1,'CData',temp2(:,:,j)')
                clim=[-1 1]*max(cscale(j),1e-9);
                caxis(clim)
                title({[mtitle num2str(timestamp*dt,'%10.3f') ' ms'],ftitle})
                drawnow
                mov(wcount)=getframe(fhandle);
                
                %Write the video periodically
                if wcount==writestep
                    writeVideo(avi,mov);
                    wcount=0;
                    waitbar(timestamp/t,wm)
                end
               
                %Update counters
                wcount=wcount+1;
                timestamp=timestamp+1;   
            end

            %Update counters
            subcount=1;
            nt=nt+1;
        end
        
        %Finish writing, close the file, and update the compression file
        if wcount>1
            writeVideo(avi,mov(1:wcount-1));
        end
        close(avi);
        fclose(fid);
        close(fhandle);
        unix(['echo "mv ./mov_' num2str(ii) '.avi ./' plane '_' num2str(Output.movie{ii}.loc) '_' char(mfile_types{Output.movie{ii}.type-mfile_off}) '_.avi" >> ./comp']); 
    end
end

close(wm)
close(figure(1))
drawnow
cd ..

end

