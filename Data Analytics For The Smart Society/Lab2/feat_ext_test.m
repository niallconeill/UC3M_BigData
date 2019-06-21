%% Image Parameterization
dir_train='Train_Set';
files_train=dir([dir_train, '/*.jpg']);
% Total number of images in the training set
N_Images_train=length(files_train);
n_blocks_x = 39;
n_blocks_y = 29;
x_cellnum = 2; y_cellnum = 2; num_grad_or = 8;
%Xtrain1 = [];
Xtrain2 = zeros(N_Images_train*n_blocks_x*n_blocks_y,32);
counter = 1;
for k=1:N_Images_train
    % Read image
    M = imread([dir_train '/' files_train(k).name]);
    M = im2double(M);
    if(size(M,3) == 3)
       M = rgb2gray(M);
    end
    M = imresize(M,[240 320]);
    % Feature extraction
    for j = 0: n_blocks_x - 1
        for i = 0: n_blocks_y - 1
        
            block = M((i*8)+1:(i*8)+16,(j*8)+1:(j*8)+16);
            H = HOG(block, x_cellnum, y_cellnum, num_grad_or);
            Xtrain2(counter,:) = H;
            counter = counter + 1;
        end
    end
end