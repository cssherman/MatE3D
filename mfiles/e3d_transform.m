function [X2,Y2,Z2]=e3d_transform(N,X,Y,Z,thz,thy,thz_old,thy_old,back)

    %Create rotation matrix
    R1=[cos(thz),sin(thz),0;-1*sin(thz),cos(thz),0;0,0,1];
    R2=[cos(thy),0,sin(thy);0,1,0;-1*sin(thy),0,cos(thy)];
    Rforward=single(R2*R1);
    
    if back==1
        Rb1=[cos(thz_old),sin(thz_old),0;-1*sin(thz_old),cos(thz_old),0;0,0,1];
        Rb2=[cos(thy_old),0,sin(thy_old);0,1,0;-1*sin(thy_old),0,cos(thy_old)];
        Rback=single(Rb2*Rb1);
        Rback=Rback^-1;
    else
        Rback=1;
    end
    R=Rforward*Rback;
    
    %Apply the transform to each point in the grid:
    X2=R(1,1)*X+R(1,2)*Y+R(1,3)*Z;
    Y2=R(2,1)*X+R(2,2)*Y+R(2,3)*Z;
    Z2=R(3,1)*X+R(3,2)*Y+R(3,3)*Z;
        
end