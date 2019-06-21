function [parameters parameters1]=Assignment_2()



filex = 'MRO.xlsx';
filey = '^IBEX.xlsx';
filez = 'GOLD.xlsx';

%filex is the MRO data file
%filey is the ^IBEX data file
%filez is the GOLD  data file 
%load the data file
datax = readtable(filex);
datay = readtable(filey);
dataz = readtable(filez);

%remove the AdjClose column
datax = removevars(datax, {'AdjClose'});
datay = removevars(datay, {'AdjClose'});
dataz = removevars(dataz, {'AdjClose'});

%Remove any NANs from the Returns column 
datax = datax(~any(ismissing(datax),2),:);
datay = datay(~any(ismissing(datay),2),:);
dataz = dataz(~any(ismissing(dataz),2),:);

%Convert the tables to timetables
datax = table2timetable(datax);
datay = table2timetable(datay);
dataz = table2timetable(dataz);

%Part 2 Plotting the data against time 
sync = synchronize(datax,datay,dataz);
sync.Properties.VariableNames = {'MRO' 'IBEX' 'GOLD'};
stackedplot(sync, 'Title', 'Plot of Synchronized Returns', 'DisplayLabels', {'Returns % MOR', 'Returns % ^IBEX', 'Returns % GOLD'});

plot(sync.Date,sync.Variables);
legend(sync.Properties.VariableNames,'Interpreter','none');
xlabel('Date');
ylabel('Returns in %');
title('Plot of ^IBEX, MOR & GOLD Returns');


%Part 3 Estimate DCC-GARCH Model for daily returns - total data set
x_resized = datax(end-4183:end,:)
y_resized = datay(end-4183:end,:)

%filter the data such we have a mean zero data.
%For MRO data
x_mean = mean(x_resized.Returns);
res_x = x_resized.Returns - x_mean.*ones(length(x_resized.Returns),1);

%For ^IBEX data
y_mean=mean(y_resized.Returns);
res_y =y_resized.Returns - y_mean.*ones(length(y_resized.Returns),1);

%For GOLD data
z_mean=mean(dataz.Returns);
res_z=dataz.Returns-z_mean.*ones(length(dataz.Returns),1);

% creating the data
data=[res_x  res_y res_z];

% Now we estimate a DCC model
M=1 ; %Order of symmetric innovations in DCC model
L=0;  %Order of asymmetric innovations in ADCC model
N=1;  %Order of lagged correlation in DCC model
P=1;  %[OPTIONAL] Positive, scalar integer representing the number of symmetric innovations in the
%                    univariate volatility models.  Can also be a K by 1 vector containing the lag length
%                    for each series. Default is 1.
O=1; %         - [OPTIONAL] Non-negative, scalar integer representing the number of asymmetric innovations in the
%                    univariate volatility models.  Can also be a K by 1 vector containing the lag length
%                    for each series. Default is 0.
Q=1; %         - [OPTIONAL] Non-negative, scalar integer representing the number of conditional covariance lags in
%                    the univariate volatility models.  Can also be a K by 1 vector containing the lag length
%                    for each series. Default is 1.

GJRTYPE=2;      %- [OPTIONAL] Either 1 (TARCH/AVGARCH) or 2 (GJR-GARCH/GARCH/ARCH). Can also be a K by 1 vector
%                    containing the model type for each for each series. Default is 2.

[parameters, loglikelihood, Ht, Qt]=dcc(data,[],M,L,N,P,O,Q,GJRTYPE);


% getting the correlations --- I dont actually think we need this part 
% for i=1:length(res_x)
%     corr_dcc(i,1)=Ht1(2,1,i)./(sqrt(Ht1(1,1,i)).*sqrt(Ht1(2,2,i)));
% end
% plot(corr_dcc);
% title('Estimated Correlations: Nasdaq versus S&P 500- DCC Model');

%Part 5 Fitting a DCC-GARCH model with reduced data - only first 2000 observations
[parameters_red, loglikelihood1_red, Ht1_red, Qt1_red]=dcc(data(1:2000,:),[],M,L,N,P,O,Q,GJRTYPE);



