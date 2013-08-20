function e3d_plot_tmp(Model,Plotting,type)
   
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


%Flip the model, and add a small amount of randomness to make surf/hist work
v=double(flipdim(v,3))+rand(size(v))*1e-10;

%Create plotting vectors (down = -Z):
[y,x,z]=meshgrid(linspace(Model.origin(2),Model.origin(2)+Model.size(2),Model.number(2)),linspace(Model.origin(1),Model.origin(1)+Model.size(1),Model.number(1)),-1*linspace(Model.origin(3)+Model.size(3),Model.origin(3),Model.number(3)));

%Plot limits
lim_x=[Model.origin(2)-.05*Model.size(2),Model.origin(2)+1.05*Model.size(2)];
lim_y=[Model.origin(1)-.05*Model.size(1),Model.origin(1)+1.05*Model.size(1)];
lim_z=-1*[Model.origin(2)+1.05*Model.size(3),Model.origin(3)-0.05*Model.size(3),];

%Create edgelines
p3x=[Model.origin(1),Model.origin(1),Model.origin(1)+Model.size(1),Model.origin(1),Model.origin(1)];
p3y=[Model.origin(2)+Model.size(2),Model.origin(2),Model.origin(2),Model.origin(2),Model.origin(2)];
p3z=zeros([1 5]);
p3z(5)=-1*Model.size(3);

%Create cylinder
[x1, x2, x3] = cylinder(0.1);
c = ones(size(x1));


%Render the model
fig = figure(1);
set(fig, 'PaperPosition',[0 0 3.5 2.75])
set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)


%Cube Plot
ii=Model.number(3);
aa = surf(y(:,:,ii),x(:,:,ii),z(:,:,ii),v(:,:,ii));  %Z-face
hold on
bb = surf(squeeze(y(:,2,2:ii)),squeeze(x(:,2,2:ii)),squeeze(z(:,2,2:ii)),squeeze(v(:,2,2:ii)));  %X-face
cc = surf(squeeze(y(2,:,2:ii)),squeeze(x(2,:,2:ii)),squeeze(z(2,:,2:ii)),squeeze(v(2,:,2:ii)));  %Y-Face
dd = surf(x3, x2+1, x1-0.4, c);
plot3(p3y,p3x,p3z,'k')
plot3([1 1 0 0 0 1 1], [0 0 0 2 2 2 0], [0 -1 -1 -1 0 0 0], 'k')
plot3([0.5 0.5], [0 2], [0 0], 'k:')
plot3([0.5 0.5], [2 2], [0, 0.3], 'b')
plot3([0.45 0.5 0.55], [2 2 2], [0.05 0 0.05], 'b')
shading flat
axis equal
set(gca,'FontSize',Plotting.fontsize,'FontName',Plotting.font)

set(aa, 'FaceAlpha', 0.5);
set(bb, 'FaceAlpha', 0.5);
set(cc, 'FaceAlpha', 0.5);

xlim(lim_x)
ylim(lim_y)
zlim(lim_z)
caxis([2.7 3.2])
axis off
hold off
view(gca,[-51.5 20])

%Save movie and block figure
saveas(figure(1),['Model_' type '_block.fig'])
print(figure(1),'-depsc','-r300','./tunnel.eps')
print(figure(1),'-dtiff','-r300','./tunnel.tif')


    

end
