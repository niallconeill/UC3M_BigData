function [s_mean, s_sd, s_k, s_sk] = sample_properties(namefile)

data = readtable(namefile);

% pre-process the data, show returns
n_rows = height(data);
ret = [0];
for i = 2:n_rows
temp = 100 * (log(data.price(i)) - log(data.price(i-1)));
ret = cat(1, ret, temp);
end
data.ret = ret;

data = table2timetable(data);

subplot(3,2,1); stackedplot(data, 'Title', 'Plot of Prices and FTSE 100 Returns', 'Fontsize', 16, 'DisplayLabels', {'Price', 'Returns in %'});

ret = data.ret;
s_mean = mean(ret);
s_sd = sqrt(var(ret));
s_k = kurtosis(ret);
s_sk = skewness(ret);

% next we obtain the squared observations
ret2 = (ret).^2;
subplot(3,2,2); plot(ret2);
title('Plot of Squared Returns');
xlim([1 4840]);
legend('hide');
grid('off');

% now compute autocorrelation function of returns
subplot(3,2,3); autocorr(ret, 50);
title('ACF of Returns');


% and squared returns
subplot(3,2,4); autocorr(ret2,50);
title('ACF of Squared Returns');

% finally, calculate the cross-correlation between squared returns and past returns
subplot(3,2,5); crosscorr(ret2, ret, 50);
title('CCF Between Squared Returns and Past Returns');
