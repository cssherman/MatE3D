
%Clear the old configuration data:
clear Path Config Boundary Model Source Plotting Rerender Output Material


%% Define important paths
[~,Path.user]=unix('echo $USER');                %Get the username from the shell
Path.e3d_bin='/usr/local/SeismicTools/E3D/bin/'; %Path to E3D bins
Path.in='E3D_in.txt';                            %Name of E3D input file
Path.link='~/SeismicTools/E3D/Link/';            %Location to link long test runs
Path.log='~/Dropbox/MATLAB/E3D_gui/';            %Location to put logfiles, aux. scripts, etc. 
Path.log_msg='Test Model';                       %Message to write to the e3d_log file for each run
Path.oldmodel='/home/user/SeismicTools/E3D/';    %Path to old model (if options 1 or 2 selected for newmodel)
Path.out='~/SeismicTools/E3D/Results/';          %Location to place output files
                           

%% Analysis                          
%Basic config Options                     
Config.acoust=1;          %Type of model 1=elastic, 2=acoustic
Config.atten=0;           %Model attenuation: 0=off, 1=on
Config.degrees_free=1;    %Number of parameters to generate independantly (1=p, 2=p,s, 3=p,s,dens)
Config.loopnum=1;         %Number of times to loop through the analysis
Config.multicore=[1,1,1]; %Number of parallel grids to use [prod(multicore) must equal number of nodes]
Config.multimodel=0;      %Generate the only the first model for a series of runs (1=yes, 0=no)
Config.newmodel=0;        %How to build the velocity model (0=create new, 1=copy existing, 2=modify existing)
Config.run=1;             %Run E3D after writing input files (1=run)
Config.units=1;           %Type of input units (1=km, s, km/s, Hz;  2=m, ms, km/s, kHz)
                             
%Boundary Conditions
Boundary.type=3;          %Boundary type:  1=reflecting, 2=quiet, 3=surface(z=0)
Boundary.sponge=0;        %Sponge=1 turns on sponge boundaries  (Innefficient E3D algorithm)
Boundary.atten=1;         %Create a box of attenuating material to prevent reflections from the side and bottom of the model
Boundary.atten_thick=25;  %Number of grid points for attenuating box
Boundary.atten_val=5;     %Attenuation value for box
Boundary.damp_rand=1;     %Remove intrinsic heterogeneity within 4 gridpoints of the boundaries for stability (1=yes)

% Model Parameters
Model.dims=3;             %Number of spatial dimensions
Model.size=[1,1,1];       %Total grid size (x,y,z)                            
Model.spacing=[1,1,1]*.005;%Grid spacing (dx,dy,dz)  (right now dx=dy=dz)                  
Model.number=[1,1,1]*200; %Number of elements (nx,ny,nz)                    
Model.origin=[0,0,0];     %Location of first element (ox,oy,oz)                      
Model.time=1;             %Analysis Time
Model.max_dtct=.1;        %Minimum dt/ct for analysis

% Sources
Source{1}.type=5;  %Type: 1=P, 2=S, 4=Moment Tensor, 5=Force, 6=Point Fault, 7=Finite Fault 
Source{1}.amp=1e20;                      %Amplitude (dyne-cm or dyne)
Source{1}.freq=10;                      %Frequency (Hz)
Source{1}.off=(2/Source{1}.freq);        %Time offset (s)
Source{1}.loc=[0.5,0.5,0];               %Location (x,y,z)
Source{1}.wav=1;                         %Wavelet (0=ricker, 1=gaussian)
Source{1}.F=[0,0,1];                     %Force vector  (Type 5)
Source{1}.M=[1,2,3,4,5,6];               %Seismic moment (Type 4)           
Source{1}.orient=[56,41,106,4,5,6,7,8,9];%Fault orientation (Type 6,7)



%% Outputs
%Plotting Options:
Plotting.bandpass=[0,1e5];  %Post-processing movie bandpass
Plotting.dec_space=5;       %Decimate output spatial dimensions
Plotting.dec_time=10;       %Decimate output time dimension
Plotting.model=1;           %Plot velocity model
Plotting.movie=1;           %Render any movies
Plotting.trace=1;           %Render any traces
Plotting.font='Helvetica';  %Plotting font
Plotting.fontsize=12;       %Plotting font size

%Rerender Options:
Rerender.model=0;           %Rerender input models
Rerender.movie=0;           %Rerender movies
Rerender.trace=0;           %Rerender traces

%Seismographs
Output.trace{1}.dir='Z';               %Direction of trace;
Output.trace{1}.loc=[0.5,.5,0];        %Location of first seismogram;
Output.trace{1}.N=Model.number(3);     %Number of seismograms
Output.trace{1}.space=Model.spacing(1);%Spacing of seismograms
Output.trace{1}.corr=1;                %Corrections (1=no, 2=spreading, 3=spreading+damping)

%Movies location/type:
Output.movie{1}.dir='Z';    %Plane
Output.movie{1}.loc=0;      %Location in plane
Output.movie{1}.type=13;    %Movie type: 11-Vx, 12-Vy, 13-Vz, 14-Txx, 15-Tyy, 16-Tzz, 17-Txy,  
                            %            18-Txz, 19-Tyz, 20-P pot., 21-S pot.



%% Material Properties
Material{1}.vel=[3,1.73,2.7];
Material{1}.sd=[.01,.01,0];
Material{1}.atten=[40,40];
Material{1}.dist=[0,1,1,1];
Material{1}.type=9;           
Material{1}.geo=[];
Material{1}.cf=0;

Material{2}.vel=[3,1.73,2.7];   
Material{2}.sd=[0,0,0];
Material{2}.atten=[40,40];
Material{2}.dist=[0,1,1,1,1];
Material{2}.type=1;           
Material{2}.geo=[0,Model.size(1)/2,0,Model.size(2)/2,0,Model.size(3)/2];


%Average Material Properties:
%   Material{n}.vel=[pvel_mn,svel_mn,dens_mn]     
%   pvel,svel = p/s wave velocity (km/s)
%   dens = density (g/cc)

%Standard Deviation of Material Properties:
%   Material{n}.sd=[pvel_sd,svel_sd,dens_sd]     
%   pvel_sd,svel_sd = p/s wave velocity (decimal %)
%   dens_sd = density (decimal %)

%Statistical Distribution of Material Properties 
%   Material{n}.dist=[fdim, fX, fY, fZ]:
%   fdim = dimension of self-affine fractal used to generate the spatial
%          distribution (reference in e3d_locate).  Choosing fdim=-1.5
%          results in a completely random distribution.  Choosing a higher
%          fdim results in greater spatial correlation (fdim is usually
%          less than 0).
%   fX, fY, fZ = scaling factors to adjust the aspect ratio of the fractal.
%          choosing fX=fY=fZ=1 will result in a "normal" fractal pattern.
%          Reducing one of these values will "flatten" the fractal the
%          appropriate dimension.  When it reaches zero, the velocity
%          distribution is incoherent in that direction.

%Attenuation Characteristics:
%   Material{n}.atten=[qp, qs]
%   qp, qs = Quality factor for p and s waves
%
%   From Lay and Wallace:
%       Shale -         Qa=30, Qb=10
%       Sandstone -     Qa=58, Qb=31
%       Granite -       Qa=250, Qb=70-150
%       Peridotite (mid mantle) -   Qa=360, Qb=200
%       Peridotite (lower mantle) - Qa=1200, Qb=520
%       Peridotite (Outer core) -   Qa=8000, Qb=0

%Location and geometry of Materials:
%   Material{n}.type=type;
%   Material{n}.geo=[g1,g2,...,gm];
%   
%   type=1;  Rectangle
%       creates a right-rectangle for x0<=X<=x1, y0<=Y<=y1, z0<=Z<=z1
%       geo=[x0,x1,y0,y1,z0,z1]
%
%   type=2;  Sphere
%       creates sphere of radius R and center (x0,y0,z0)
%       geo=[x0,y0,z0,R]
%
%   type=3;  Cylinder
%       creates a cylinder or radius R betwwen endpoints (x0,y0,z0) and (x1,y1,z1)
%       geo=[x0,y0,z0,x1,y1,z1,R]
%
%   type=4;  Area beneath generic polynomial
%       creates a region defined by a polynomial z=f(x)*g(y), where
%       f(x)=p1*x^n + p2*x^(n-1) + ... + pn*x + p(n+1)
%       g(y)=q1*y^n + q2*y^(n-1) + ... + qn*y + q(n+1)
%       geo=[p1,p2,...,pn,p(n+1);q1,q2,...,qn,q(n+1)]
%
%   type=5;  Area above/below a surface
%       creates a region above (dir=1) or below (dir=0) a surface with thickness=th, defined by
%       a point (x0,y0,z0), strike (ccws from x-axis), dip (downward), and waviness (wavelenght=L, amplitude=A). 
%       geo=[x0,y0,z0,strike,dip,L,A,dir,th];
%
%   type=6;  Area above piece-wise surface
%       creates a region beneath a surface defined by extruding a line (normal to its azimuth).
%       The line has origin: (x0,y0,z0), azimuth (ccws from x-axis), and 
%       distance/elevation pairs (L0,E0,L1,E1,...,Ln,En)
%       geo=[x0,y0,z0,azimuth,L0,E0,L1,E1,...,Ln,En];
%
%   type=7;  Region inside a piece-wise tunnel.
%       creates a piecewise tunnel with width W, height H, starting point
%       (x0,y0,z0), and azimuth(ccws from x-axis)/dip(downward)/length pairs 
%       (A0,D0,L0,A1,D1,L1,...,An,Dn,Ln)
%       geo=[W,H,x0,y0,z0,A0,D0,L0,A1,D1,L1,...,An,Dn,Ln]
%
%   type=8;  Open box.
%       creates a region on N-grid points along the sides and bottom of a
%       model.
%       geo=[N];
%
%   type=9;  Entire Domain.
%       Overwrites the entire domain
%       geo=[];


%% Example: 
%         A cylindrical region with reduced velocity and Q is passing
%         between points (0,0,0) and (1,1,1), and has radius 0.1.
%         The velocity distribution within each region is homogeneous
%
%         Plot the vertical velocity along plane Z=0, and P potential
%         along plane X=0.75.  Place 100 seismograms in the y-direction starting
%         from point (1,2,3) with spacing 0.1.  Apply no corrections.
%
%
% Material{1}.vel=[5,3,2.65];
% Material{1}.sd=[0,0,0];
% Material{1}.dist=[-1.5,1,1,1];
% Material{1}.atten=[250,150];
% Material{1}.type=9;           
% Material{1}.geo=[];
% 
% Material{2}.vel=[4,2.5,2.65];
% Material{2}.sd=[0,0,0];
% Material{2}.dist=[-1.5,1,1,1];
% Material{2}.atten=[250,70];
% Material{2}.type=3;           
% Material{2}.geo=[0,0,0,1,1,1,0.1];  
%
% Output.movie{1}.type=13;
% Output.movie{1}.dir='Z';
% Output.movie{1}.loc=0;
% 
% Output.movie{2}.type=20;
% Output.movie{2}.dir='X';
% Output.movie{2}.loc=0.75;
%
% Output.trace{1}.loc=[1,2,3];
% Output.trace{1}.dir='Y';
% Output.trace{1}.N=100;
% Output.trace{1}.space=0.1;
% Output.trace{1}.corr=0;


%% Cleanup
save('./config/e3d_config.mat','Path','Config','Boundary','Model','Source','Plotting','Rerender','Output','Material');
clear Path Config Boundary Model Source Plotting Rerender Output Material

