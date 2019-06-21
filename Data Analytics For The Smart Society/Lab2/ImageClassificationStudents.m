clear all; close all; clc;

% --------------------------------------------------------------------
% Image Classes
% --------------------------------------------------------------------

Num_img_classes = 4;
Classes = categorical({'cartman' 'cowboy-hat' 'galaxy' 'hibiscus'});


% --------------------------------------------------------------------
% TRAINING AND TEST SETS
% --------------------------------------------------------------------

TrSet_size = 61;
TestSet_size = 20;

% --------------------------------------------------------------------
% FEATURE EXTRACTION
% --------------------------------------------------------------------

%load Xtrain;
%load Xtest;

% Image Parameterization
dir_train='Train_Set';
files_train=dir([dir_train, '/*.jpg']);
% Total number of images in the training set
N_Images_train=length(files_train);
% Number of horizontal and vertical blocks 
n_blocks_x = 39;
n_blocks_y = 29;
% size of each cell and gradient orientations
x_cellnum = 2; y_cellnum = 2; num_grad_or = 8;
% Preallocation of Xtrain 
Xtrain = zeros(N_Images_train*n_blocks_x*n_blocks_y,32);
counter = 1;
for k=1:N_Images_train
    % Read image
    M = imread([dir_train '/' files_train(k).name]); 
    M = im2double(M);
    % If image not grayscale convert to grayscale
    if(size(M,3) == 3)
        M = mat2gray(M);
    end
    % Resize image to 320 x 240 pixels 
    M = imresize(M,[240 320]);
    % Feature extraction
    for i = 0: n_blocks_y - 1
        for j = 0: n_blocks_x - 1
            % Extract block from image
            block = M((i*8)+1:(i*8)+16,(j*8)+1:(j*8)+16);
            % Pass block into HOG function
            H = HOG(block, x_cellnum, y_cellnum, num_grad_or);
            % Add extracted features to Xtrain
            Xtrain(counter,:) = H;
            counter = counter + 1;
        end
    end
end

% Xtest directory 
dir_test='Test_Set';
files_test=dir([dir_test, '/*.jpg']);
% Total number of images in the training set
N_Images_test=length(files_test);
% Preallocation of Xtest 
Xtest = zeros(N_Images_test*n_blocks_x*n_blocks_y,32);
counter = 1;
for k=1:N_Images_test
    % Read image
    M = imread([dir_test '/' files_test(k).name]); 
    M = im2double(M);
    %If not grayscale convert to grayscale 
    if(size(M,3) == 3)
        M = mat2gray(M);
    end
    %Resize the image 
    M = imresize(M,[240 320]);
    % Feature extraction
    for i = 0: n_blocks_y - 1
        for j = 0: n_blocks_x - 1
            % Select block and pass to HOG function
            block = M((i*8)+1:(i*8)+16,(j*8)+1:(j*8)+16);
            H = HOG(block, x_cellnum, y_cellnum, num_grad_or);
            % Add features to Xtest 
            Xtest(counter,:) = H;
            counter = counter + 1;
        end
    end
end

Num_features_per_image = size(Xtrain,1)/(TrSet_size*Num_img_classes);

% --------------------------------------------------------------------
% CREATING A VISUAL VOCABULARY
% --------------------------------------------------------------------

Vocabulary_Size = 100;

%Use kmeans to create 100 clusters based on the training data
[Cind C] = kmeans(Xtrain,Vocabulary_Size);
%load vocabulario_K100;

% --------------------------------------------------------------------
% Computing histograms
% --------------------------------------------------------------------

% Memory allocation for Histograms of visual words
Hist=zeros(Num_img_classes,TrSet_size,Vocabulary_Size);  

for i=1:Num_img_classes
    for j=1:TrSet_size
        
        % Visual words asignation
        image=(i-1)*TrSet_size+j;
        i1 = (image-1)*Num_features_per_image+1;
        i2 = i1 + Num_features_per_image -1;
        % Uses KNN search to find the nearest neighbour from the visual
        % vocabulary for each feature of the image
        Cind_k = knnsearch(C,Xtrain(i1:i2,:));
        
        
        % Histogram computation
        % Histogram is generated for the features of the image
        H = hist(Cind_k,Vocabulary_Size);
        
        % Histogram normalization (sum=1)
        H = H/sum(H);
       
        % The normalised histogram is added stored for each visual word
        Hist(i,j,:) = H;
    end
end


% --------------------------------------------------------------------
% TRAINING AN IMAGE CATEGORY CLASSIFIER
% --------------------------------------------------------------------

% Label Vector
Ytrain=[];

for i=1:Num_img_classes
    for j=1:TrSet_size
        Ytrain=[Ytrain; Classes(i)];
    end
end

% Reshaped Histogram Matrix
H_Xtrain=[];
for i=1:Num_img_classes
    for j=1:TrSet_size
        H_Xtrain=[H_Xtrain; reshape(Hist(i,j,:),1,Vocabulary_Size)];
    end
end

% Classifier training
t = templateSVM('Standardize',true);
Classifier= fitcecoc(H_Xtrain,Ytrain,'Learners',t);

% --------------------------------------------------------------------
% Performance on the Training Set
% --------------------------------------------------------------------

Predicted_Y = predict(Classifier,H_Xtrain);
confMatrix = confusionmat(Ytrain,Predicted_Y)
accuracy = sum(diag(confMatrix))/sum(confMatrix(:))


% --------------------------------------------------------------------
% REAL PERFORMANCE: PERFORMANCE ON THE TEST SET
% --------------------------------------------------------------------

% --------------------------------------------------------------------
% Computing histograms
% --------------------------------------------------------------------

% Memory allocation for Histograms of visual words
Hist_Test=zeros(Num_img_classes,TestSet_size,Vocabulary_Size);  

% The code loops through each image in the test class runns knnsearch to
% find the member of the visual vocabulary that is closest to each feature
% of the image. A histogram is created for the image with relation to the
% visual vocabulary, then normalised and stored in Hist_Test 
for i=1:Num_img_classes
    for j=1:TestSet_size
        
        % Visual words asignation
        image=(i-1)*TestSet_size+j;
        i1 = (image-1)*Num_features_per_image+1;
        i2 = i1 + Num_features_per_image -1;
        Cind_k = knnsearch(C,Xtest(i1:i2,:));
        
        
        % Histogram computation
        H = hist(Cind_k,Vocabulary_Size);
        
        % Histogram normalization (sum=1)
        H = H/sum(H);
       
        Hist_Test(i,j,:) = H;
    end
end

% --------------------------------------------------------------------
% Evaluation
% --------------------------------------------------------------------

% Label Vector: Y_Test

Y_test=[];

% The labels for each of the test images are gathered 
for i=1:Num_img_classes
    for j=1:TestSet_size
        Y_test=[Y_test; Classes(i)];
    end
end

% Reshaped Histogram Matrix: H_X_Test

H_X_Test=[];

% Reshape the Hist_Test array so that it can be used with the predict
% method to classify the images 
for i=1:Num_img_classes
    for j=1:TestSet_size
        H_X_Test=[H_X_Test; reshape(Hist_Test(i,j,:),1,Vocabulary_Size)];
    end
end


% Predicted_Y_Test
% Use the SVM classifier to predict the category of the test images based
% on the histograms 
Predicted_Y_Test = predict(Classifier,H_X_Test);


% confMatrix_Test
% Generate a confusion matrix comparing the correct Y_test labels to the
% predicted values found using the SVM classifier 
%
% confMatrix_Test =
%
%    13     6     0     1
%     4    12     0     4
%     2     0    18     0
%     1     2     0    17
confMatrix_Test = confusionmat(Y_test,Predicted_Y_Test)


% accuracy_Test
% Calculate the percentage of predictions that the classifier got correct
% with an accuracy test 
% accuracy_Test =
%
%    0.7500
accuracy_Test = sum(diag(confMatrix_Test))/sum(confMatrix_Test(:))

