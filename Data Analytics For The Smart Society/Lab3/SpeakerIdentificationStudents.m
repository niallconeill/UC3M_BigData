%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  LAB EXERCISE 2. SPEAKER IDENTIFICATION
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Configuration variables (***TO BE COMPLETED***)
nspk = 16;       % Number of speakers  
fs = 16000;         % Sampling frequency
ncomp = 20;      % Numero de componentes MFCC
wst = 0.02;        % Window size (seconds)
fpt = 0.01;        % Frame period (seconds) 
ws = fs*wst;         % Window size (samples)
fp = fs*fpt;         % Frame period (samples)
ngauss = 8;     % Number of gaussians in the GMM models

% Other configuration variables
nbands = 40;   % Number of filters in the filterbank

% Lists of training and testing speech files
nomlist_train = 'list_train.txt';
nomlist_test{1} = 'list_test1.txt';
nomlist_test{2} = 'list_test2.txt';

rng(0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TRAINING STAGE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Preallocation of array to store GMM
GMM_Array{1,nspk} = [];

% Speaker GMM models building
for i=1:nspk
    
    % Loading of the training files for speaker "i"
    x = load_train_data(nomlist_train, i);
      
    % Feature extraction
    cepstra = melfcc(x, fs, 'wintime',wst,'hoptime',...
        fpt, 'numcep',ncomp);
      
    % Speaker GMM models building for speaker "i"
    fprintf('Building GMM model of speaker %d\n', i);
    
    % Fit GMM using extracted features with a diagonal covariance matrix
    GMM = fitgmdist(cepstra',ngauss, 'CovarianceType', 'diagonal',...
        'Options', statset('MaxIter', 200));
    
    GMM_Array{1,i} = GMM;

end  % for i=1:nspk

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TEST STAGE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Speaker identification process
for t=1:size(nomlist_test,2)
     
   % Reading of the list containing the speech test files 
   fid = fopen(nomlist_test{t});
   if fid < 0
      fprintf('File %s does not exist\n', nomlist_test{t});
      return
   end
   info_test = textscan(fid, '%s%f');
   nfiles_test = length(info_test{1}); % number of test files
   actual_spk = int16(info_test{2});   % speaker label of each test file
   
   % Preallocation of array for predictions
   pred_labels = zeros(1,nfiles_test, 'int16');
   
   fclose(fid);
   
   % Loop for each test file
   for k=1:nfiles_test
      % Loading of the test files
      fname_test = info_test{1}{k};  % name of the test file
      
      % Reading of the wav test file "fname_test"
      wav_data = audioread(fname_test); 

      % Feature extraction
      cepstra_test = melfcc(wav_data, fs, 'wintime',wst,'hoptime',...
        fpt, 'numcep',ncomp);

      % Log-likelihood computation of each model for the current test file
      % Preallocation of array to store log likelihoods
      log_likelihoods = zeros(1,length(GMM_Array));
      
      for i=1:length(GMM_Array)
        % Fit a pdf using for each GMM using the extracted test features
        y = pdf(GMM_Array{i},cepstra_test');
        
        % Calculate the maximum log likelihood for the pdf and store it 
        log_likelihoods(i) = sum(log(y));
      end
          
      % Selection of the identified speaker
      % The speaker with the largest log likelihood will be the selected
      % speaker 
      [Max,Index] = max(log_likelihoods);
      pred_labels(k) = Index;
       
      
   end  % for k=1:nfiles_test

   % Computation of the identification accuracy
   accuracy = (length(find(actual_spk == pred_labels'))/nfiles_test) * 100
   
   % clean files = 98.125% accuracy and noisy files = 58.125%
   
end % t=1:size(nomlist_test,2),
   


   

