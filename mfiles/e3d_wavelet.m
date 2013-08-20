

function e3d_wavelet(Model,Source)

%Setup:
Wc=Source.freq*2*pi;        %Dominant Source.frequency
Gd=0.05;                    %Controls corner Source.frequency
s_length=1000;              %Length to smooth beginning of record

%Find appropriate length of gauss window:
time_off=Source.off/(2*Model.dt);
time_off=min(Model.timesteps,max(0,round(time_off)));
time_buf=2*(Model.timesteps+2*time_off);

%Choose the standard deviation
sd=sqrt(-2*log(Gd)/Wc^2);
alpha=time_buf*Model.dt/sd;

%Generate and trim the window:
W=gausswin(time_buf,alpha);
W2=diff(W);                     %Take the derivative here
W3=W2(0.5*time_buf-time_off:0.5*time_buf-time_off+Model.timesteps-1);
W3(1:s_length)=W3(1:s_length).*linspace(0,1,s_length)';
W3=W3./max(W3);

%Create Header:
hd = -12345*ones(158,1);
hd(1)=Model.dt;                     % time step
hd(6)=0;                            % start time
hd(7)=(Model.timesteps-1)*Model.dt; % e
hd(8)=0;                            % o
hd(77)=6;                           % version number
hd(80)=Model.timesteps;             % number of points
hd(88)=11;                          % iztype
hd(86)=1;                           % iftype
hd(106)=1;                          % leven

%Write the file
aa=fopen('wav.sac','w');
fwrite(aa, hd(1:70), 'single');
fwrite(aa, hd(71:158), 'int');
fwrite(aa, W3,'single');
fclose(aa);

end


