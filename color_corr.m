function [image] = color_corr(img)

%srgbc=[3.0646,-0.063135,0.17633; -0.090025, 1.5913,-0.30726; 0.1522,0.14375,1.0147];

srgbc=eye(3);
[r,c,l]=size(img);
rs=reshape(img,[r*c,l]);


corr = srgbc * rs';

image = reshape(corr',[r,c,l]);

end