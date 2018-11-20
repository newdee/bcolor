close all; clear all;

input_filename='./1015/image_orig.h5';

output_name='DM_orig.h5';

png_name1='DM_orig.png';
png_name2= 'DM_orig_trans.png';
png_name3='DM_orig_gamma.png';
raw=h5read(input_filename,'/data');

raw_bayer = squeeze(raw);
pattern='bggr';
%pattern='rggb';
output_cor = ISP_until_demosaic(raw_bayer,pattern);
%output_trans = ISP_after_demosaic(output_cor);
output_trans = color_corr(output_cor);
% output = output_cor;
% output_transfer = rot90(output,2);

out_trans_gamma = lin2rgb(output_trans,'OutputType','double','ColorSpace','sRGB');



imwrite(output_cor, png_name1);
imwrite(output_trans, png_name2);

imwrite(out_trans_gamma, png_name3);
figure;
subplot(1,3,1);
imshow(png_name1);
subplot(1,3,2);
imshow(png_name2);
subplot(1,3,3);
imshow(png_name3);
%DM = permute(output_transfer,[3,2,1]);
%DM = double(DM)/255.0;

%shape = size(DM);

%h5create(output_name,'/data',[shape]);
%h5write(output_name,'/data',DM);
















