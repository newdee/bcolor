function [image] = ISP_after_demosaic(dm_scaled)

%% Step 7: color correction (tune mapping)
% srgbMatrix= [3.0127,	-0.069178,	-0.16943;
% 0.074491,	1.5852,	-0.3005;
% 0.15271,	0.14461,	1.0102];

 srgbMatrix=[3.0646,-0.063135,0.17633;
 -0.090025, 1.5913,-0.30726;
 0.1522,0.14375,1.0147]; 
% srgbMatrix=srgbMatrix';
%sprint("pop shape= " + str(pop.shape) + " , max= " + str(np.max(pop))  + " , min= " + str(np.min(pop)) + " , mean= " + str(np.mean(pop)))
% srgbMatrix=eye(3);
ccdm=double(dm_scaled);
[r, c, wl] = size(ccdm);
ccdm_rs=reshape(ccdm,[r*c wl]);
ccdm_corr=(srgbMatrix'*ccdm_rs');
%ccdm_corr=(ccdm_rs*srgbMatrix');
cout=reshape(ccdm_corr',[r c wl]);

%% Step 8: gamma correction
% factor = 1;
% cout = factor*double(cout);
% gamma = 2.4;
% cout(cout<0) = 0;
% cout(cout>1) = 1;
% cout_gamma = cout.^(1/gamma);
% final = uint8(cout_gamma*256);
% final = lin2rgb(cout,'OutputType','uint8','ColorSpace','adobe-rgb-1998'); %%%%%%%%%%%%%%%%% Not sure right?

final = lin2rgb(cout,'OutputType','uint8','ColorSpace','sRGB'); %%%%%%%%%%% Best matching with sRGB standard

image = final;

end
% LUT