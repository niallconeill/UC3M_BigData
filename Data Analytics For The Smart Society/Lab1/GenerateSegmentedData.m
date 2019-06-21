%% Segmentation and Feature Extraction 
% Data - Data that you wish to segment and calculate features for
% no_of_segments - the number of data files in your cell, eg in the training
% set this will be 8
% labelled - boolean determining whether the data is labelled or not 
function seg_data = GenerateSegmentedData(data, no_of_segments, labelled)

seg_data = cell(no_of_segments,1);

for i = 1:no_of_segments
    data{i,1} = data{i,1}';
    if(labelled == true)
        data{i,2} = data{i,2}';
    end
    no_of_windows = floor(length(data{i,1})/24)-1;
    data_temp = cell(no_of_windows,1);
    label_temp = cell(no_of_windows,1);
    
    for j = 1:no_of_windows-1
        temp = ((j * 24)+1:(j *24)+48);
        window_data = data{i,1}(temp,:);
        label_data = [];
        if (labelled == true)
           label_data = data{i,2}(temp,:); 
        end
        
        %% Any windows with more than one label are ignored 
        if(length(unique(label_data)) == 1 || labelled == false)
            window_params = calculate_parameters(window_data);
            data_temp(j,1) = {window_params};
            label_temp(j,1) = {unique(label_data)};
        end
    end
    %% Removes empty cases that result from when windows have more than one label
    data_temp = data_temp(~cellfun('isempty',data_temp));
    label_temp = label_temp(~cellfun('isempty',label_temp));
    final = [data_temp label_temp];
    seg_data(i,1) = {final};
     
end

    function params = calculate_parameters(window_data)
      
        %% Calculate the Mean of each of the accelerator and gyroscope 
        %% components
        
        accelz_mean = mean(window_data(:,1));
        accelxy_mean = mean(window_data(:,2));
        gyrox_mean = mean(window_data(:,3));
        gyroy_mean = mean(window_data(:,4));
        gyroz_mean = mean(window_data(:,5));
        
        %% Calculate the Standard Deviation of each of the components
        accelz_std = std(window_data(:,1));
        accelxy_std = std(window_data(:,2));
        gyrox_std = std(window_data(:,3));
        gyroy_std = std(window_data(:,4));
        gyroz_std = std(window_data(:,5));
        
        %% Root Mean Square of each of the components
        accelz_rms = rms(window_data(:,1));
        accelxy_rms = rms(window_data(:,2));
        gyrox_rms = rms(window_data(:,3));
        gyroy_rms = rms(window_data(:,4));
        gyroz_rms = rms(window_data(:,5));
        
        %% Max - Min of each of the components
        
        accelz_minmax = max(window_data(:,1)) - min(window_data(:,1));
        accelxy_minmax = max(window_data(:,2)) -  min(window_data(:,2));
        gyrox_minmax = max(window_data(:,3)) - min(window_data(:,3));
        gyroy_minmax = max(window_data(:,4)) - min(window_data(:,4));
        gyroz_minmax = max(window_data(:,5)) -  min(window_data(:,5));

        
        %% Spectral energy of the components 
        
        fourier = fft(window_data, length(window_data));
        pow = fourier.*conj(fourier);
        accelz_speceng = sum(pow(:,1))/length(window_data);
        accelxy_speceng = sum(pow(:,2))/length(window_data);
        gyrox_speceng = sum(pow(:,3))/length(window_data);
        gyroy_speceng = sum(pow(:,4))/length(window_data);
        gyroz_speceng = sum(pow(:,5))/length(window_data);
        
        %% Spectral Entropy of the components
               
        accelz_ent = getEntropy(fourier(:,1));
        accelxy_ent = getEntropy(fourier(:,2));
        gyrox_ent = getEntropy(fourier(:,3));
        gyroy_ent = getEntropy(fourier(:,4));
        gyroz_ent = getEntropy(fourier(:,5));
        
        %% Signal Magnitude Area of the gyroscope
        
        SMA = sum(abs(window_data(:,3)) + abs(window_data(:,4)) + abs(window_data(:,5)))/length(window_data);
     
        %% Correlations between axis of accelerometer and gyroscope
        
        corr = corrcoef(window_data);
        accelxyz_corr = corr(1,2);
        gyroxy_corr = corr(3,4);
        gyroxz_corr = corr(3,5);
        gyroyz_corr = corr(4,5);
        
        %% Average Tilt Angle of the gyroscope 
        
        tilt_angle = sum(acos(window_data(:,5)./sqrt(window_data(:,3).^2 + window_data(:,4).^2 + window_data(:,5).^2)))/length(window_data);
        
        %params = [];
         params  = [accelz_mean, accelxy_mean ,gyrox_mean, gyroy_mean, gyroz_mean,...
           accelz_std, accelxy_std, gyrox_std, gyroy_std, gyroz_std,...
          accelz_rms, accelxy_rms, gyrox_rms, gyroy_rms, gyroz_rms,...
        accelz_minmax, accelxy_minmax, gyrox_minmax, gyroy_minmax, gyroz_minmax,... 
          accelz_speceng, accelxy_speceng,gyrox_speceng, gyroy_speceng,gyroz_speceng,...
          accelz_ent, accelxy_ent, gyrox_ent, gyroy_ent, gyroz_ent,SMA...
          accelxyz_corr, gyroxy_corr, gyroxz_corr, gyroyz_corr, tilt_angle];
    end


    function entropy = getEntropy(fourier_data)
        power_spectrum = ((sqrt(abs(fourier_data).*abs(fourier_data))*2)/length(fourier_data));
        power_spectrum = power_spectrum(1:length(fourier_data)/2);
        
        norm_ps = power_spectrum(:);
        norm_ps = norm_ps /sum(norm_ps + 1e-12); 
        
        entropy = -sum(norm_ps.*log2(norm_ps+1e-12))/log2(length(norm_ps));
    end
end