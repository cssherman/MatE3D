function [fractal]=e3d_fractal(dist,Model)

%Set up a fractal velocity/density distribution
if dist(1)==-0.5*Model.dims
    fractal=single(randn(Model.number));
    
else    
    %2Model.spacing correction
    if Model.number(2)==1  
        dist(3)=0;
    end

    %Generate a random matrix and do an fft
    v=randn(Model.number);
    fv=fftn(v);
    clear v

    %Build the spectral filter to generate the fractal (Model.spacingon't use meshgrid
    %because these can be very large and overload memory)
    f=1/(2*Model.spacing(1));
    mesh=linspace(-1,1,Model.number(1))*f;
    x=reshape(full(mesh(:)),[Model.number(1) 1 1]);
    x=x(:,ones(1,Model.number(2)),ones(Model.number(3),1));
    k=(dist(2)*x).^2;

    mesh=linspace(-1,1,Model.number(2))*f;
    x=reshape(full(mesh(:)),[1 Model.number(2) 1]);
    x=x(ones(Model.number(1),1),:,ones(Model.number(3),1));
    k=k+(dist(3)*x).^2;

    mesh=linspace(-1,1,Model.number(3))*f;
    x=reshape(full(mesh(:)),[1 1 Model.number(3)]);
    x=x(ones(Model.number(1),1),ones(Model.number(2),1),:);
    k=k+(dist(4)*x).^2;

    k=k.^(-0.25*Model.dims-0.5*dist(1));
    fk=fftshift(k);
    clear x k

    %Apply the filter and do an ifft
    fv=fk.*fv;
    clear fk 
    vx=real(ifftn(fv));
    clear fv

    %Normalize the distribution
    fdev=mean(mean(std(vx)));
    fmn=mean(mean(mean(vx)));
    fractal=single((vx-fmn)/fdev);       %Make sure the result isn't unbalanced
end

end