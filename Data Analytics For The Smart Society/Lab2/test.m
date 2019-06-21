%% Image Parameterization

dir_train='Train_Set';
files_train=dir([dir_train, '/*.jpg']);
% Total number of images in the training set
N_Images_train=length(files_train);
n_blocks_x = 39;
n_blocks_y = 29;
x_cellnum = 2; y_cellnum = 2; num_grad_or = 8;
%Xtrain = [];
Xtrain1 = zeros(N_Images_train*n_blocks_x*n_blocks_y,32);
for k=1:N_Images_train
    % Read image
    M = imread([dir_train '/' files_train(k).name]);
    if(size(M,3) == 3)
        M = rgb2gray(M);
    end
    M = imresize(M,[320 240]);
    M = im2double(M);
    % Feature extraction
    H = HOG(M, x_cellnum, y_cellnum, num_grad_or);
            %Xtrain = [Xtrain, H]; 
            Xtrain1(k,:) = H;
end