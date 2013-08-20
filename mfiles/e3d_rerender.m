
function e3d_rerender(Path,Plotting,Rerender)

%Config
close all
clc
display('Rerendering files')
drawnow

%Setup
cd(Path.link)
target=dir;
nmodel=length(target)-2;

if Rerender.movie==1  %Rerender any E3D movies found in the directory
    %Create a new compression file:
    unix(['echo "#!/bin/bash" > ' Path.log 'master_comp']);
    unix(['chmod 777 ' Path.log 'master_comp']);
end

for ii=1:nmodel
    if target(ii+2).isdir==1
        cd([Path.link target(ii+2).name]);
        tmp=load('model.mat');
        display(' ')
        display(['Directory: ' pwd])
        
        for jj=1:3
            if Rerender.model==1 && jj<=tmp.Config.degrees_free %Rerender the P velocity model            
                e3d_plot(tmp.Model,Plotting,tmp.ft{ii})
            end
        end

        if Rerender.movie==1  %Rerender any E3D movies found in the directory
            unix(['echo "cd ' Path.link target(ii+2).name '/mov" >> ' Path.log 'master_comp']);
            unix(['echo "./comp" >> ' Path.log 'master_comp']);            
            e3d_movie(tmp.Config,tmp.Model,tmp.Output,tmp.Path,Plotting);
        end

        if Rerender.trace==1  %Rerender any trace files found in this directory     
            e3d_trace(Material,Model,Output,Plotting,Source);
        end

    end
end

e3d_gui
end