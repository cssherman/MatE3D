function [region]=e3d_locate(Model,type,geometry)

%Deterimine the locaiton of the materials in the grid
%Set up location matrix
region=single(zeros(Model.number));
[y,x,z]=meshgrid(linspace(0,Model.number(2)-1,Model.number(2)),linspace(0,Model.number(1)-1,Model.number(1)),linspace(0,Model.number(3)-1,Model.number(3)));
x=x*Model.spacing(1)+Model.origin(1);
y=y*Model.spacing(2)+Model.origin(2);
z=z*Model.spacing(3)+Model.origin(3);



%% Locate materials:
switch type
    case 1
%         display(['Region - Rectangle'])
        
        region=x>=geometry(1) & x<=geometry(2) & y>=geometry(3) & y<=geometry(4) & z>=geometry(5) & z<=geometry(6);
        
    case 2
%         display(['Region - Sphere'])
        
        x=x-geometry(1);
        y=y-geometry(2);
        z=z-geometry(3);
        
        test=x.^2+y.^2+z.^2;
        region=test<=geometry(4)^2;
        
    case 3
%         display(['Region  - Cylinder'])
        
        %Transforms:
        dx=geometry(4)-geometry(1);
        dy=geometry(5)-geometry(2);
        dz=geometry(6)-geometry(3);
        thz=atan2(dy,dx);
        thy=atan2(dz,sqrt(dx^2+dy^2));
        [x,y,z]=e3d_transform(Model.number,x-geometry(1),y-geometry(2),z-geometry(3),thz,thy,0,0,0);
        
        %Logicals
        test=sqrt((geometry(4)-geometry(1))^2+(geometry(5)-geometry(2))^2+(geometry(6)-geometry(3))^2)+.01;
        region=(y.^2+z.^2)<=(geometry(7))^2 & x>=0 & x<=test;
        
        
    case 4
%         display(['Region - Area Under Polynomial']) 
        tX=polyval(geometry(1,:),x);
        tY=polyval(geometry(2,:),y);
        test=tX.*tY;
        region=z<=test;
        
    case 5
        %Check to see if all information supplied
        if isempty(geometry(6))
            geometry(6)=1;
            geometry(7)=0;
            geometry(8)=0;
            geometry(9)=1e9;  %Thickness
        end
        
        %Transforms:
        thz=geometry(4)*pi/180-pi/2;
        thy=geometry(5)*pi/180;
        [x,~,z]=e3d_transform(Model.number,x-geometry(1),y-geometry(2),z-geometry(3),thz,thy,0,0,0);
        tR=abs(x);
        wl=2*pi/geometry(6);
        test=geometry(7)*sin(wl*tR); %Add waviness
        
        %Logicals
        if geometry(8)==0
%             display(['Region - Area Below Surface'])
            region=(z+test<=0 & z+test>=-1*geometry(9));
        else
%             display(['Region - Area Above Surface'])
            region=(z+test>=0 & z+test<=geometry(9));
        end
        
    case 6
        segments=((length(geometry)-4)/2)-1;
%         display(['Region - Area Above Piecewise Surface (' num2str(segments) ' segments)'])
        thz=geometry(4)*pi/180;
        thy=0;
        [x,~,z]=e3d_transform(Model.number,x-geometry(1),y-geometry(2),z-geometry(3),thz,thy,0,0,0);
        
        for count=1:segments
            xstart=geometry(2*count+3);
            zstart=geometry(2*count+4);
            xend=geometry(2*count+5);
            zend=geometry(2*count+6);            
            seg_slope=(zend-zstart)/(xend-xstart);
            test=z-seg_slope*(x-xstart)-zstart;
            region=region+(x>=xstart & x<=xend & test>=0);
        end
        region=sign(region);
        
    case 7
        segments=(length(geometry)-5)/3;
%         display(['Region - Tunnel (' num2str(segments) ' segments)'])
        
        %Initial Stuff
        width=geometry(1);
        height=geometry(2);
        x=x-geometry(3);
        y=y-geometry(4);
        z=z-geometry(5);
        thz_old=0;
        thy_old=0;
        
        for count=1:segments
           %Transform based upon tunnel geometry
           thz=geometry(3+count*3)*pi/180;
           thy=geometry(4+count*3)*pi/180;
           L=geometry(5+count*3);
           [x,y,z]=e3d_transform(Model.number,x,y,z,thz,thy,thz_old,thy_old,sign(count-1));
           
           %Tweaks to length to get proper closure of tunnel:
           if count>1
              thz_old=geometry(3+(count-1)*3)*pi/180;
              thy_old=geometry(4+(count-1)*3)*pi/180;
              Lback1=min((width*tan(0.5*(thz-thz_old)))^2,width^2);
              Lback2=min((height*tan(0.5*(thy-thy_old)))^2,height^2);
              Lback=-0.5*sqrt(Lback1^2+Lback2^2);
           else
               Lback=0;
           end
           
           if count<segments
              thz_new=geometry(3+(count+1)*3)*pi/180;
              thy_new=geometry(4+(count+1)*3)*pi/180;
              Lup1=min((width*tan(0.5*(thz_new-thz)))^2,width^2);
              Lup2=min((height*tan(0.5*(thy_new-thy)))^2,height^2);
              Lup=0.5*sqrt(Lup1^2+Lup2^2);
           else
               Lup=0;
           end
           
           %Logicals
           region=region+(x>=Lback & x<=L+Lup & abs(y)<=0.5*width & abs(z)<=0.5*height);
           
           %Update position and reset coordinates
           x=x-L;
           thz_old=thz;
           thy_old=thy;
        end
            region=sign(region);
            
    case 8
%         if rnumber>0
%             display(['Region - Open Box (' num2str(geometry) ' gridpoints)'])
%         else
%             display(['Attenuating Boundary Condition - (' num2str(geometry) ' gridpoints)'])
%         end
        
                
        %Open box to improve boundary conditions:
        region(1:geometry,:,:)=1;
        region(end-geometry:end,:,:)=1;
        
        if Model.number(2)>1
            region(:,1:geometry,:)=1;
            region(:,end-geometry:end,:)=1;
        end
        
        region(:,:,end-geometry:end)=1;
        
    case 9
%         display(['Region - Entire Domain'])
        region(:,:,:)=1;
end


end