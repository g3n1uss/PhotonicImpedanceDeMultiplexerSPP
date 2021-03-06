function [imped_grat_final]=MainFunction(plasma_freq,absorp_coef,wavelength_res,angle_res,order_res,energy_fluxes)
%MAINFUNCTION This function computes properties of the grating realizing
%the desired energy distribution and plots the resulting configuration and
%energy spectra
%   Output: modulated impedance of the grating
%   Input: characteristics of the material such as
%       - plasma_freq - plasma frequency (can be found for any material)
%       - absorp_coef - coefficient of absoption (can be found for any material)
%       - wavelength_res - wavelength on the incident beam
%       - angle_res - incident angle
%       - order_res - the number of diffracted spectra in which we want to
%       have a resonance
%       - energy fluxes - the desired energy distribution between outgoing
%       beams


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate properties of the film such as
% Dielectric function epsilon, Unmodulated value of the impedance xi0, etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create object Surface material containing all the characteristics of the
% material at the resonant point
surface=SurfaceMaterial(wavelength_res,plasma_freq,absorp_coef);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the grat_period of the impedance grating
% sin(th_res)+order_res wavelength_res/d_res=sqrt(1+Im(xi)^2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grat_period=order_res*wavelength_res/(sqrt(1+imag(surface.xi0)^2)-sin(angle_res*pi/180));
% The following spectra will be outgoing (Nn,...,Nm)
Np=floor((1-sin(angle_res*pi/180))*grat_period/wavelength_res);
Nm=-floor((1+sin(angle_res*pi/180))*grat_period/wavelength_res);
% the number of outgoing spectra is
out_num=Np-Nm+1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the desired energy distribution is not given calculate for equally
% distributed energy in all outging spectra
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<6
    s=zeros(1,20);
    % IT SEEMS LIKE THE UPPER BOUND ON TOTAL ENERGY IS NOT KNOWN, LET
    % SAY IT EQUALS TO 0.5, THE REST IS ABSORPTED BY SPP
    % the energy in every outgoing spectra is
    en=0.5/out_num;
    for i=Nm+10:Np+10
        s(i)=en;
    end
else
    s=energy_fluxes;
end
    

% find tangential wavevectors "beta" for diffracted spectra
diffSpectra=DiffAngles(angle_res,wavelength_res,grat_period);
betas=diffSpectra.beta;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find properties of the grating from the analytical solution of the
% inverse diffraction problem. This would be the initial grating
% configuration. Later on we will correct it by minimizing the appropriate 
% functional.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% At first we have only the amplitudes of various modes of the grating
out_num_tmp=20;
uinit=AnalyticSolution(out_num_tmp,surface.xi0,s,betas,order_res).u;
psiinit=zeros(1,20);
xianal=zeros(1,20);
% the modulated impedance is xi_n=i u_n e^{i psi_n}
xianal(:)=1i*uinit(:).*exp(1i*psiinit(:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the correcting functional and then minimize it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
func=Functional(surface.xi0,betas,uinit,order_res,s);
% minimize it
funcmin=func.Minimize(); 
% construct the resulting grating
imped_grat_final=zeros(1,20);
imped_grat_final(:)=1i*funcmin.ufinal(:).*exp(1i*funcmin.psifinal(:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate data to plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% At first generate data for the initial grating obtained from the 
% analytic solution
dataGenInit=DataGenerator(order_res,wavelength_res,angle_res,surface,diffSpectra,xianal);
% data for initial grating
% along wavelength
% As output we get energy fluxes "s_nonres_w", the square module of the 
% resonance mode "abs_h_res2_w", the absoption "absorption_w"; all of them 
% are caluclated at each wavelength from "wavelength_w"
[s_nonres_w,abs_h_res2_w,absorption_w,wavelength_w,~]=dataGenInit.getDataWavelength(0);
% along angle
[s_nonres_a,abs_h_res2_a,absorption_a,~,thetas_a]=dataGenInit.getDataAngle(0);

% data for final grating
dataGenFinal=DataGenerator(order_res,wavelength_res,angle_res,surface,diffSpectra,imped_grat_final);
% along wavelength
[s_nonres_w_f,abs_h_res2_w_f,absorption_w_f,wavelength_w_f,~]=dataGenFinal.getDataWavelength(0);
% along angle
[s_nonres_a_f,abs_h_res2_a_f,absorption_a_f,~,thetas_a_f]=dataGenFinal.getDataAngle(0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actually data plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the line width
linewidth=2;
% plot the grating
% set step for plotting (could be arbitrary)
t=0:.01:1;
% construct the initial grating
grat_i=BuildGrating(uinit,psiinit,surface.xi0,t);
% label for initial grating
labelUinit=GenerateLabel('u^i',uinit);
labelXi=strcat(labelUinit,', \xi_0^{"}=',num2str(imag(surface.xi0)));
% final grating
grat_f=BuildGrating(funcmin.ufinal,funcmin.psifinal,surface.xi0,t);
% label for final grating
labelUfinal=GenerateLabel('u^f',funcmin.ufinal);
labelPsifinal=GenerateLabel('psi^f',funcmin.psifinal*180/pi);
labelXi_f=strcat(labelUfinal, labelPsifinal,', \xi_0^{"}=',...
    num2str(imag(surface.xi0)));
% set the display window to fullscreen
figure('units','normalized','outerposition',[0 0 1 1]);
% draw the initial and corrected gratings
subplot(3,2,[1,2]),plot(t,grat_i,'--k',t,grat_f,'k','LineWidth',linewidth),text(0.3,...
    imag(surface.xi0)/2,labelXi),...
    text(0.3,imag(surface.xi0)/1.5,labelXi_f),xlabel('x/d'),...
    ylabel('\xi^{"}'),legend('Grating from analytical solution','Corrected grating'),...
    title('Impedance of the grating')


% plot the resonance amplitude from then analytical solution
subplot(3,2,3), plot(wavelength_w(:),abs_h_res2_w(:),'--k',wavelength_w_f(:),...
    abs_h_res2_w_f(:),'k','LineWidth',linewidth),grid on, xlabel('\lambda, nm'),ylabel('|h_r|^2'),...
    legend('Analytical solution','Corrected solution'),...
    title('Resonance amplitude')


% plot the energy_fluxes obtained from the analitycal solution
% label for the energy_fluxes
labelS=GenerateLabel('s',s);
% label for the legend
legendlabel=cell(1,2*(out_num+1));
ind=1;
legendlabel{ind}='A^i';
ind=ind+1;
legendlabel{ind}='A^f';
for i=Nm:Np
    ind=ind+1;
    legendlabel{ind}=strcat('s^i_{',num2str(i),'}');
    ind=ind+1;
    legendlabel{ind}=strcat('s^f_{',num2str(i),'}');
end
% plot
subplot(3,2,4),
plot(wavelength_w(:),absorption_w(:),'--','LineWidth',linewidth);
hold on
plot(wavelength_w_f(:),absorption_w_f(:),'-','LineWidth',linewidth);
for i=Nm+10:Np+10
    plot(wavelength_w(:),s_nonres_w(:,i),'--','LineWidth',linewidth);
    plot(wavelength_w_f(:),s_nonres_w_f(:,i),'-','LineWidth',linewidth);
end
grid on, text(wavelength_w(10),0.8,labelS),xlabel('\lambda, nm'),...
    legend(legendlabel{:}), title('Energy fluxes of outgoing spectra')
hold off

% plot the corrected resonance harmonic
subplot(3,2,5), plot(thetas_a(:),abs_h_res2_a(:),'--k',thetas_a_f(:),...
    abs_h_res2_a_f(:),'k','LineWidth',linewidth),grid on, xlabel('\theta, degrees'),ylabel('|h_r|^2'),...
    legend('Analytical solution','Corrected solution'),...
    title('Resonance amplitude')

% plot the corrected energy_fluxes
subplot(3,2,6),
plot(thetas_a(:),absorption_a(:),'--','LineWidth',linewidth);
hold on
plot(thetas_a_f(:),absorption_a_f(:),'-','LineWidth',linewidth);
for i=Nm+10:Np+10
    plot(thetas_a(:),s_nonres_a(:,i),'--','LineWidth',linewidth);
    plot(thetas_a_f(:),s_nonres_a_f(:,i),'-','LineWidth',linewidth);
end
grid on, text(thetas_a(10),0.8,labelS),xlabel('\lambda, nm'),...
    legend(legendlabel{:}),title('Energy fluxes of outgoing spectra')
hold off
