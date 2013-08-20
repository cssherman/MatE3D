function e3d_plot(Model,Plotting,type)
   
close(figure(1))
fclose('all');
drawnow

%Plotting title
switch type
    case 'pvel'
        plot_title='P Velocity Distribution (km/s)';
        
    case 'svel'
        plot_title='S Velocity Distribution (km/s)';
        
    case 'rdens'
        plot_title='Density Distribution (g/cc)';
        
    case 'qp'
        plot_title='Qp Distribution';
        
    case 'qs'
        plot_title='Qs Distribution';
end

% Read in model file
v=single(zeros(Model.number));
fid=fopen([type '.pv']);
    for yy=1:Model.number(2)
        for zz=1:Model.number(3)
            v(:,yy,zz)=fread(fid,Model.number(1),'single');
        end
    end
fclose(fid);


if Model.number(2)==1
    v=double(v);
    x=linspace(Model.origin(1),Model.origin(1)+Model.size(1),Model.number(1));
    y=-1*linspace(Model.origin(3)+Model.size(3),Model.origin(3),Model.number(3));
    
    save('test.mat')
    figure(1)
        pcolor(x,y,flipud(squeeze(v)'))
        shading interp
        caxis([min(min(min(v)))-0.01 max(max(max(v)))+0.01])
        title(plot_title)
        colorbar
        xlabel('X (km)')
        ylabel('Z (km)')
        axis equal
        saveas(figure(1),['Model_' type '.fig'])
        
    
else
    %Open a video writer
    avi=VideoWriter(['./mov/Model_' type '_temp.avi']);
    open(avi);
    
    %Flip the model, and add a small amount of randomness to make surf/hist work
    v=double(flipdim(v,3))+rand(size(v))*1e-10;

    %Create plotting vectors (down = -Z):
    [y,x,z]=meshgrid(linspace(Model.origin(2),Model.origin(2)+Model.size(2),Model.number(2)),linspace(Model.origin(1),Model.origin(1)+Model.size(1),Model.number(1)),-1*linspace(Model.origin(3)+Model.size(3),Model.origin(3),Model.number(3)));

    %Plot limits
    lim_x=[Model.origin(2)-.05*Model.size(2),Model.origin(2)+1.05*Model.size(2)];
    lim_y=[Model.origin(1)-.05*Model.size(1),Model.origin(1)+1.05*Model.size(1)];
    lim_z=-1*[Model.origin(2)+1.05*Model.size(3),Model.origin(3)-0.05*Model.size(3),];
    v_min=min(min(v,[],1),[],2)-0.1;
    v_max=max(max(v,[],1),[],2)+0.1;
    lim_v1=1e6;
    lim_v2=0;

    %Decimation steps
    dstep=floor(max(1,Plotting.dec_space));
    nstep=floor(Model.number(3)/dstep);
    fstep=Model.number(3)-nstep*dstep;
    zstep=Model.spacing(3)*dstep;

    %Create edgelines
    p3x=[Model.origin(1),Model.origin(1),Model.origin(1)+Model.size(1),Model.origin(1),Model.origin(1)];
    p3y=[Model.origin(2)+Model.size(2),Model.origin(2),Model.origin(2),Model.origin(2),Model.origin(2)];
    p3z=ones([1 5])*-1*(Model.origin(3)+Model.size(3));
    p3z(1:4)=p3z(1:4)+fstep*Model.spacing(3)+zstep;

    %Generate histogram
    dv=max(abs(0.1*mean(mean(std(v)))),0.01);
    v_bin=min(min(min(v))):dv:(max(max(max(v)))+0.01);
    v_temp=reshape(v,Model.number(1)*Model.number(2),Model.number(3));
    v_hist=cumsum(hist(v_temp,v_bin),2);
    v_hist2=repmat(linspace(Model.number(1)*Model.number(2),prod(Model.number),Model.number(3)),[length(v_bin) 1]);
    v_norm=v_hist./v_hist2;
    clear v_temp v_hist v_hist2

    %Render the model
    mov(1:nstep-2) = struct('cdata', [],'colormap', []);
    plot_step=1;
    figure(1)
    set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)
    for ii=fstep+2*dstep:dstep:Model.number(3)
        %Update edgelines and plot limits
        p3z(1:4)=p3z(1:4)+zstep;
        lim_v1=min(lim_v1,v_min(ii));
        lim_v2=max(lim_v2,v_max(ii));

        %Cube Plot
        subplot(1,5,1:4)
        surf(y(:,:,ii),x(:,:,ii),z(:,:,ii),v(:,:,ii))  %Z-face
        hold on
        surf(squeeze(y(:,1,1:ii)),squeeze(x(:,1,1:ii)),squeeze(z(:,1,1:ii)),squeeze(v(:,1,1:ii)))  %X-face
        surf(squeeze(y(1,:,1:ii)),squeeze(x(1,:,1:ii)),squeeze(z(1,:,1:ii)),squeeze(v(1,:,1:ii)))  %Y-Face
        plot3(p3y,p3x,p3z,'k')  %Edgelines
        shading interp
        axis equal
        set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)
        xlim(lim_x)
        ylim(lim_y)
        zlim(lim_z)
        caxis([lim_v1 lim_v2])
        title(plot_title)
        colorbar
        xlabel('Y (km)')
        ylabel('X (km)')
        zlabel('Z (km)')
        hold off

        %Histogram plot
        sub2=subplot(1,5,5,'YTick',zeros(1,0));
        box(sub2,'on');
        barh(v_bin,v_norm(:,ii),'FaceColor',[0 0 1],'EdgeColor','none','BarWidth',1)
        ylim([lim_v1 lim_v2])
        ylabel('Vp (km/s)')
        xlabel('P(Vp)')

        %Grab movie frame
        drawnow
        mov(plot_step)=getframe(figure(1));
        plot_step=plot_step+1;
    end

    %Save movie and block figure
    saveas(figure(1),['Model_' type '_block.fig'])
    writeVideo(avi,mov)
    
    %Cleanup
    close(figure(1))
    close(avi)
    drawnow
    unix(['echo "ffmpeg -i Model_' type '_temp.avi -y -sameq Model_' type '.avi" >> ./mov/comp']);
    unix(['echo "rm Model_' type '_temp.avi" >> ./mov/comp']);
end

end
