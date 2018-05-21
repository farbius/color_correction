%% color correction algorithm
% A Rostov 21/05/2018
% a.rostov@riftek.com
%%
clc
clear all

fileID = -1;
errmsg = '';
while fileID < 0 
   disp(errmsg);
   filename = input('Open file: ', 's');
   [fileID,errmsg] = fopen(filename);
   I = imread(filename);
end
[Nx, Ny, Nz] = size(I)

alpha = 1.0;    % correction coefficient for R channel
beta  = 1.0;    % correction coefficient for G channel
gamma = 2.0;    % correction coefficient for B channel

%% write data for RTL model

display('Writing data for RTL model...');
fidR = fopen('Rdata.txt', 'w');
fidG = fopen('Gdata.txt', 'w');
fidB = fopen('Bdata.txt', 'w');

for i = 1 : Nx
    for j = 1 : Ny
      fprintf(fidR, '%x\n', I(i, j, 1));
      fprintf(fidG, '%x\n', I(i, j, 2));
      fprintf(fidB, '%x\n', I(i, j, 3));
    end
end
fclose(fidR);
fclose(fidG);
fclose(fidB);

%% write correction coefficient
R_data = zeros(1,256);
G_data = zeros(1,256);
B_data = zeros(1,256);

for i = 1 : 256
    R_data(i) = floor((((i-1)/255)^(alpha))*255);
    G_data(i) = floor((((i-1)/255)^(beta ))*255);
    B_data(i) = floor((((i-1)/255)^(gamma))*255);
end

R_data = uint8(R_data);
G_data = uint8(G_data);
B_data = uint8(B_data);

Data_table = cat(2, R_data, G_data, B_data);

fid  = fopen('Data_table.txt', 'w');
for i = 1 : 3*256
    fprintf(fid, '%x\n', Data_table(i));   
end
fclose(fid);

%% write data for RTL model
fid = fopen('parameters.vh', 'w');
fprintf(fid,'parameter Nrows   = %d ;\n', Ny);
fprintf(fid,'parameter Ncol    = %d ;\n', Nx);
fclose(fid);

%%
display('Please, start write_prj.tcl');
prompt = 'Press Enter when RTL modeling is done \n';
x = input(prompt);

% read processing data
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
for i = 1 : Nx
    for j = 1 : Ny 
       Iprocess(i, j, 1) = R(n); 
       Iprocess(i, j, 2) = G(n); 
       Iprocess(i, j, 3) = B(n); 
       n = n + 1;
 end
end
Iprocess = uint8(Iprocess);
R_in = zeros(Nx, Ny);
G_in = zeros(Nx, Ny);
B_in = zeros(Nx, Ny);
R_in = (I(:,:,1));
G_in = (I(:,:,2));
B_in = (I(:,:,3));
%%
Inew = zeros(Nx, Ny, Nz);  
Inew(:,:,1) = (double(I(:,:,1))./255).^alpha;
Inew(:,:,2) = (double(I(:,:,2))./255).^beta ;
Inew(:,:,3) = (double(I(:,:,3))./255).^gamma;

Inew(:,:,1) = floor(Inew(:,:,1).*255);
Inew(:,:,2) = floor(Inew(:,:,2).*255);
Inew(:,:,3) = floor(Inew(:,:,3).*255);
Inew = uint8(Inew);

R_new = zeros(Nx, Ny);
G_new = zeros(Nx, Ny);
B_new = zeros(Nx, Ny);
R_new = (Inew(:,:,1));
G_new = (Inew(:,:,2));
B_new = (Inew(:,:,3));

figure(1)
imshow(I);
title('Исходное изображение')

figure(2)
imshow(Inew);
title('Работа алгоритма в Matlab')

figure(3)
imshow(Iprocess);
title('Работа алгоритма в RTL модели')
display('processing done!');