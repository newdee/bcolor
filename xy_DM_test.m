close all; clear all;

input_filename='./1015/image_orig.h5';

output_name='DM_orig.h5';

png_name='DM_orig.png';

raw=h5read(input_filename,'/data');

raw_bayer = squeeze(raw);
% pattern='bggr';
pattern='rggb';
output_tmp = ISP_until_demosaic(raw_bayer,pattern);
output = ISP_after_demosaic(output_tmp);
output = output_tmp;
%output_transfer = rot90(output,2);
output_transfer = output;

imwrite(output_transfer, png_name);

%DM = permute(output_transfer,[3,2,1]);
%DM = double(DM)/255.0;

%shape = size(DM);

%h5create(output_name,'/data',[shape]);
%h5write(output_name,'/data',DM);
















