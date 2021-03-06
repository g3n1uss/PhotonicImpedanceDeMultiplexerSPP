classdef DataGenerator
    %DATAGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        res;
        lambda_res;
        theta_res;
        obj_surface;
        obj_grating;
        xi;
    end
    
    methods
        function obj=DataGenerator(r,lambda_res,theta_res,surface,grating,xis)
            obj.res=r;
            obj.lambda_res=lambda_res;
            obj.theta_res=theta_res;
            obj.obj_surface=surface;
            obj.obj_grating=grating;
            obj.xi=xis;
        end
        
        function [s_nonres,abs_h_res2,absorption,wavelength,thetas]=getDataWavelength(obj,method)
            wavelengthStep=0.1;
            % range in wavelength - 2% from the resonance wavelength
            initWavel=floor(0.98*obj.lambda_res);
            finalWavel=ceil(1.02*obj.lambda_res);
            m=(finalWavel-initWavel)/wavelengthStep;
            wavelength=zeros(1,m);
            wavelength(1)=initWavel;
            
            thetas=0;
        
            bts=zeros(m,20);
            h_nonres=zeros(m,20);
            s_nonres=zeros(m,20);
            h_res=zeros(1,m);
            abs_h_res2=zeros(1,m);
            absorption=zeros(1,m);
            
            % isolRes=IsolatedResonance(obj.res);
        
            %   Calculate wavelength dependence
            for p=1:m
                betastmp=obj.obj_grating.getBetas(obj.theta_res,wavelength(p),obj.obj_grating.d);
                bts(p,:)=betastmp;
 
                %   Calculate diffracted harmonics using resonance perturbation theory
                
                if(method==0)
                    %   Solving using linear algebra
                    [D,V]=BuildEqSystem(betastmp,obj.xi,obj.obj_surface.xi0);
                    h_nonres(p,:)=D\V;
                    h_res(p)=h_nonres(p,obj.res+10);
                    abs_h_res2(p)=abs(h_res(p))^2;
                    
                elseif(method==1)
                    %   Calculate h_r
                    epsnew=obj.obj_surface.getEps(wavelength(p));
                    h_r=isolRes.getHRes(obj.xi,bts(p,:),1/sqrt(epsnew));
                    h_res(p)=h_r;
                    abs_h_res2(p)=abs(h_res(p))^2;
                    % CHANGE NEXT TWO FUNCTIONS
                    nonRes=DiffractedHarmIsolRes();
                    hN=nonRes.calcNonRes(r, h_res(p),xi,surf_diffr.xi_0,angl.beta);
                    h_nonres(p,:)=hN.h_N;
                end
                
                %   Absorption by SPP. Accordingly the energy conservation law
                %   s_{tot}=1-absoption
                absorption(p)=abs_h_res2(p)*real(obj.obj_surface.xi0)/bts(p,10);
                
                
                %   Compute fluxes
                fluxes=zeros(1,20);
                for N=1:20
                    fluxes(N)=real(betastmp(N))*abs(h_nonres(p,N))^2/betastmp(10);
                end
                s_nonres(p,:)=fluxes;
                %   Next step into wavelength
                if(p<m)
                    wavelength(p+1)=wavelength(p)+wavelengthStep;
                end
                
            end
            
        end
        
        
        function [s_nonres,abs_h_res2,absorption,wavelength,thetas]=getDataAngle(obj,method)
            % range in angle - 10% from the resonance angle
            angleStep=0.01;
            initialAngle=0.9*obj.theta_res;
            finalAngle=1.1*obj.theta_res;
            m=(finalAngle-initialAngle)/angleStep;
            thetas=zeros(1,m);
            thetas(1)=initialAngle;
            
            wavelength=obj.lambda_res;
            
            bts=zeros(m,20);
            h_nonres=zeros(m,20);
            s_nonres=zeros(m,20);
            h_res=zeros(1,m);
            abs_h_res2=zeros(1,m);
            absorption=zeros(1,m);
            
            % isolRes=IsolatedResonance(obj.res);
            
            %   Calculate wavelength dependence
            for p=1:m
                betastmp=obj.obj_grating.getBetas(thetas(p),obj.lambda_res,obj.obj_grating.d);
                bts(p,:)=betastmp;
                
                %   Calculate diffracted harmonics using resonance perturbation theory
                
                if(method==0)
                    %   Solving using linear algebra
                    [D,V]=BuildEqSystem(betastmp,obj.xi,obj.obj_surface.xi0);
                    h_nonres(p,:)=D\V;
                    h_res(p)=h_nonres(p,obj.res+10);
                    abs_h_res2(p)=abs(h_res(p))^2;
                    
                elseif(method==1)
                    %   Calculate h_r
                    epsnew=obj.obj_surface.getEps(wavelength(p));
                    h_r=isolRes.getHRes(obj.xi,bts(p,:),1/sqrt(epsnew));
                    h_res(p)=h_r;
                    abs_h_res2(p)=abs(h_res(p))^2;
                    % CHANGE NEXT TWO FUNCTIONS
                    nonRes=DiffractedHarmIsolRes();
                    hN=nonRes.calcNonRes(r, h_res(p),xi,surf_diffr.xi_0,angl.beta);
                    h_nonres(p,:)=hN.h_N;
                end
                
                %   Absorption by SPP. Accordingly the energy conservation law
                %   s_{tot}=1-absoption
                absorption(p)=abs_h_res2(p)*real(obj.obj_surface.xi0)/bts(p,10);
                
                
                %   Compute fluxes
                fluxes=zeros(1,20);
                for N=1:20
                    fluxes(N)=real(betastmp(N))*abs(h_nonres(p,N))^2/betastmp(10);
                end
                s_nonres(p,:)=fluxes;
                %   Next step into angle
                if(p<m)
                    thetas(p+1)=thetas(p)+angleStep;
                end
                
            end
            
        end
    end
    
end

