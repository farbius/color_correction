%% color correction algorithm
% A Rostov 21/05/2018
% a.rostov@riftek.com
%%
clc
clear 
% 
fileID = -1;
errmsg = '';
while fileID < 0 
   disp(errmsg);
   filename = input('Open file: ', 's');
   [fileID,errmsg] = fopen(filename);
   I = imread(filename);
end
[Nx, Ny, Nz] = size(I);
display('Writing data for RTL model...');
fidR = fopen('Rdata.txt', 'w');
fidG = fopen('Gdata.txt', 'w');
fidB = fopen('Bdata.txt', 'w');

zerI = zeros(Nx, Ny, Nz);

Iwr = cat(1, I, zerI, I, zerI);

for i = 1 : 4*Nx
    for j = 1 : Ny
      fprintf(fidR, '%x\n', Iwr(i, j, 1));
      fprintf(fidG, '%x\n', Iwr(i, j, 2));
      fprintf(fidB, '%x\n', Iwr(i, j, 3));
    end
end
fclose(fidR);
fclose(fidG);
fclose(fidB);

%%
fid = fopen('parameters.vh', 'w');
fprintf(fid,'parameter Nrows   = %d ;\n', Ny);
fprintf(fid,'parameter Ncol    = %d ;\n', Nx);
fclose(fid);

%%
display('Please, start write_prj.tcl');
prompt = 'Press Enter when RTL modeling is done \n';
x = input(prompt);


I_data = zeros(Nx, Ny, Nz);
I_data = (I);
 R_vector = zeros(1, Nx*Ny);
 G_vector = zeros(1, Nx*Ny);
 B_vector = zeros(1, Nx*Ny);
 
Rmax = max(max(I_data(:, :, 1)))
Gmax = max(max(I_data(:, :, 2)))
Bmax = max(max(I_data(:, :, 3)))

 
Rmin = min(min(I_data(:, :, 1)))
Gmin = min(min(I_data(:, :, 2)))
Bmin = min(min(I_data(:, :, 3)))
 

R_c = floor(255/(Rmax - Rmin))
G_c = floor(255/(Gmax - Gmin))
B_c = floor(255/(Bmax - Bmin))

I_d = zeros(Nx, Ny, Nz);

for i = 1 : Nx
    for j = 1 : Ny 
       I_d(i, j, 1) = floor((I_data(i, j, 1) - Rmin)*R_c); 
       I_d(i, j, 2) = floor((I_data(i, j, 2) - Gmin)*G_c); 
       I_d(i, j, 3) = floor((I_data(i, j, 3) - Bmin)*B_c); 
    end
end

 I_d     = uint8(I_d);
 

%% read processing data
 fidR = fopen(fullfile([pwd '\color_correction.sim\sim_1\behav\xsim'],'Rs_out.txt'), 'r');
 fidG = fopen(fullfile([pwd '\color_correction.sim\sim_1\behav\xsim'],'Gs_out.txt'), 'r');
 fidB = fopen(fullfile([pwd '\color_correction.sim\sim_1\behav\xsim'],'Bs_out.txt'), 'r');


R = zeros(1, Nx*Ny);
G = zeros(1, Nx*Ny);
B = zeros(1, Nx*Ny);
  R = fscanf(fidR,'%d');  
  G = fscanf(fidG,'%d');  
  B = fscanf(fidB,'%d');  
fclose(fidR);
fclose(fidG);
fclose(fidB);

Iprocess = zeros(Nx, Ny, 3);
n = 1;
for i = 1 : Nx - 1;
    for j = 1 : Ny 
       Iprocess(i, j, 1) = R(n + 0*201851); 
       Iprocess(i, j, 2) = G(n + 0*201851); 
       Iprocess(i, j, 3) = B(n + 0*201851); 
       n = n + 1;
 end
end
Iprocess = uint8(Iprocess);
figure(444), imhist(I  (:,:,2),64),      title('before processing')
figure(555), imhist(I_d(:,:,2),64),      title('after processing Matlab')
figure(666), imhist(Iprocess(:,:,2),64), title('after processing HDL')


figure(1)
imshow(I);
title('before processing')


figure(2)
imshow(I_d);
title('after processing Matlab')
% 
figure(3)
imshow(Iprocess);
title('after processing HDL')


