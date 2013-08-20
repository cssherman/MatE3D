function e3d_trace(Material,Model,Output,Plotting,Source)
    
%Cleanup
cd './sac'
close(figure(1))
fclose('all');

[~,~]=unix('mv ../out* ./');
[~,~]=unix('mv ../trace* ./');
    
%Filtering config
bandpass_poles=3;  %Number of poles for the filter
bandpass_min=0.005; %Minimum size for the normalized frequency bin (reduces the sampling rate if necessary)  


for ii={'x','y','z'}
    if exist(['out.0.TV' char(ii)],'file')==2
        %% Demultiplex the trace data
        fid=fopen(['out.0.TV' char(ii)]);
            trace_num=fread(fid,1,'int');
            dt=fread(fid,1,'int');
            time=fread(fid,1,'float');
            jj=1;
            while 1
               multiplex(jj)=fread(fid,1,'int'); %#ok<AGROW>
               if multiplex(jj)==-1
                   ntraces=jj-1;
                   break
               end
               jj=jj+1;
            end

            vz_multi=fread(fid,ntraces*dt,'float');
            vz_temp=reshape(vz_multi,[ntraces dt]);
        fclose(fid);

        %Check for empty traces:
        trace_file=multiplex(1:ntraces)+1;  %What is present in the file
        trace_req=1:1:trace_num;            %What was requested
        test=ismember(trace_req,trace_file);%Comparison
        trace_fail=trace_num-sum(test);     %Number of missing traces

        %Pad empty traces with zeros:
        if trace_fail>0
            trace_miss=sort(trace_req.*(1-test));
            pad=cat(2,trace_miss(end-trace_fail+1:end)',zeros([trace_fail size(vz_temp,2)]));
        else
            pad=[];
        end

        %Sort data:
        vz_temp=cat(2,trace_file',vz_temp);
        vz_temp=cat(1,vz_temp,pad);
        vz_temp=sortrows(vz_temp,1);
        vz=vz_temp(:,2:end);                %Sorted traces
        clear vz_temp vz_multi


        %% Plot the data
        nt=1;
        for jj=1:length(Output.trace) 
            switch Output.trace{jj}.dir
                case {'X','x'}
                    comp=1;
                case {'Y','y'}
                    comp=2;
                case {'Z','z'}
                    comp=3;
            end

            %Collect info for plotting
            x=Output.trace{jj}.loc(comp):Output.trace{jj}.space:((Output.trace{jj}.N-1)*Output.trace{jj}.space+Output.trace{jj}.loc(comp));
            x=x+Model.origin(comp);
            sv=vz(nt:nt+Output.trace{jj}.N-1,:);
            nt=nt+Output.trace{jj}.N;
            fs=1./time;
            t=(1:1:dt)*time-Source{1}.off;
            nullv=sum(isnan(sv(1,:)));

            %Distance information
            delta=repmat(Output.trace{jj}.loc-Source{1}.loc,[length(x) 1]);
            delta(:,comp)=delta(:,comp)+x'-x(1);
            radius=sqrt(delta(:,1).^2+delta(:,2).^2+delta(:,3).^2);
            radius=sqrt(radius);  %Surface spreading

            %Apply the requested correction
            if Output.trace{jj}.corr>1
                corr=repmat(radius,[1 length(t)]);
                sv=corr.*sv;
            end
            if Output.trace{jj}.corr>2
                t2=repmat(t,[length(x) 1]);
                corr=exp(pi*Source{1}.freq*t2/Material{1}.atten(1));
                sv=corr.*sv;
            end

            %Setup filtering
            win=repmat(reshape(tukeywin(dt,0.1),1,1,[]),[Output.trace{jj}.N 1]);
            b_norm=2*Plotting.bandpass/fs;   
            if b_norm(1)>0 && b_norm(2)<1
                fflag='bandpass';
                resamp=max(ceil(bandpass_min/diff(b_norm)),1);      
                b_norm=2*time*resamp*Plotting.bandpass;
                ftitle=['Bandpass: (' num2str(Plotting.bandpass(1)) ',' num2str(Plotting.bandpass(2)) ') Hz'];
            elseif b_norm(1)>0 && b_norm(2)>=1
                fflag='high';
                resamp=max(ceil(bandpass_min/b_norm(1)),1);
                b_norm=2*time*resamp*Plotting.bandpass(1);
                ftitle=['Highpass: (' num2str(Plotting.bandpass(1)) ') Hz'];  
            elseif b_norm(1)<=0 && b_norm(2)<1
                fflag='low';
                resamp=max(ceil(bandpass_min/b_norm(2)),1);
                b_norm=2*time*resamp*Plotting.bandpass(2);
                ftitle=['Lowpass: (' num2str(Plotting.bandpass(2)) ') Hz'];
            else
                fflag='broad';
                resamp=1;
                ftitle=[];   
            end       

            %Resample, window, and filter the data
            nresample=floor(dt/resamp)*resamp;
            temp2=reshape(sv(:,1:nresample),Output.trace{jj}.N,resamp,[]);
            win=reshape(win(:,1:nresample),Output.trace{jj}.N,resamp,[]);
            time=resamp*time;
            t2=(1:1:nresample/resamp-nullv)*time-Source{1}.off;
            if strcmp('broad',fflag)
                fv=squeeze(temp2(:,1,:))';
            else
                [butterb,buttera]=butter(bandpass_poles,b_norm,fflag);
                fv=filter(butterb,buttera,squeeze(temp2(:,1,:)).*squeeze(win(:,1,:)),[],2)';
            end
            clear temp2 win   

            %Plot the trace
            figure(1)
                pcolor(x,t2,fv)
                shading interp
                set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)
                xlabel('Offset (km)')
                ylabel('Time (s)')
                if nullv==0
                    title({['Plot of V' char(ii) ' for Trace #' num2str(jj)];ftitle})
                else
                    title({['Plot of V' char(ii) ' for Trace #' num2str(jj)];'(Simulation failed before completion)'})
                    warning('e3d:warning','Error in Simulation!');
                end
                axis ij
                ylim([0 t2(end)])
                colormap('Gray')
                colormap(flipud(colormap));
                colorbar
                saveas(figure(1),['./trace_' num2str(jj) '_V' char(ii) '.fig'])
        end
    end
end
       
    close(figure(1))
    drawnow
    cd '..'
end