function [cond_variance_garch] = estimation_GARCH_new(namefile)

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

ret=data.ret;
ret1=ret-ones(size(ret,1),1)*mean(ret);

% Testing the existence of conditional heteroscedasticity
[h,pValue,stat,cValue]=archtest(ret1);

% Estimating the GARCH(1,1) 
Mdl=garch('GARCHLags',1,'ARCHLags',1,'distribution','Gaussian');
[EstMdl,EstParamCov,logL] = estimate(Mdl,ret1); 

%-------------------------------------------------

% Goodness of fit 
numParams = sum(any(EstParamCov));
T=length(ret1);
[aic,bic] = aicbic(logL,numParams,T);

%-------------------------------------------------
[cond_variance_garch] = infer(EstMdl,ret1);
subplot(2,2,1); plot(ret);

title('Plot of FTSE 100 Returns');
ylabel('Returns in %');
legend('hide');
grid('off');

Innovations=ret1;
subplot(2,2,2); plot(Innovations);
title('Innovations');
legend('hide');
grid('off');
xlim([1 4840]);

subplot(2,2,3); plot(cond_variance_garch);
title('Conditional Variance');
legend('hide');
grid('off');
xlim([1 4840]);

sd_residuals=ret1./cond_variance_garch.^0.5;

subplot(2,2,4); plot(sd_residuals);
title('Standardized Residuals');
legend('hide');
grid('off');
xlim([1 4840]);

%-------------------------------------------------

% Now we are going to implement the test of Engle and NG (1993)
v2=sd_residuals.^2;
v2=v2(2:size(sd_residuals,1),1);
%Here we lag the Innovations
innovationsL = lagmatrix(Innovations,1);
innovationsL=innovationsL(2:size(Innovations,1),1);

%Here we build the dummy
d=zeros(size(innovationsL,1),1);
for i=1:size(innovationsL,1)
if (innovationsL(i,1)<0)
    d(i,1)=1;
end
end

%Now we do the regression of the test
%We have to build a matrix with the observations of the regressors
X=[ones(size(innovationsL,1),1) d d.*innovationsL innovationsL.*(1-d)];

[b,bint,r,rint,stats]=regress(v2,X)

test=size(v2,1).*stats(1,1);
pvalue = 1-chi2cdf(test,3);

C='We reject the null hypothesis';
if pvalue<0.05
    disp(C);
end

%-------------------------------------------------
% Estimating the GJR(1,1)
Mdl = gjr('GARCHLags', 1, 'ARCHLags', 1, 'LeverageLags', 1, 'distribution', 't');
[EstMdl, EstParamCov, logL] = estimate(Mdl,ret1); 

%-------------------------------------------------
% Goodness of fit 
numParams = sum(any(EstParamCov));
T=length(ret1);
[aic,bic] = aicbic(logL,numParams,T);
%-------------------------------------

[cond_variance_gjr] = infer(EstMdl,ret1);
subplot(2,2,1); plot(ret1);

title('Plot of FTSE 100 Returns');
ylabel('Returns in %');
legend('hide');
grid('off');
xlim([1 4840]);

Innovations=ret1;
subplot(2,2,2); plot(Innovations);
title('Innovations');
legend('hide');
grid('off');
xlim([1 4840]);

subplot(2,2,3); plot(cond_variance_gjr);
title('Conditional Variance');
legend('hide');
grid('off');
xlim([1 4840]);

%construct the series os standardized residuals
sd_residuals=ret1./cond_variance_gjr.^0.5;

subplot(2,2,4); plot(sd_residuals);
title('Standardized Residuals');
legend('hide');
grid('off');
xlim([1 4840]);
hold off
%-------------------------------------------------
x=cond_variance_garch; %this is the conditional variance of the GARCH model
y=cond_variance_gjr; %this is the conditional variance of the GJR model
n=size(x,1);
ax=1:1:n;
subplot(2,2,1); plot(ax,x,ax,y);
title('Plot of the Conditional Variances-GARCH--GJR'); 
hleg1 = legend('GARCH','GJR');
xlim([1 4840]);
z1=1:60;
z2=1:60;
subplot(2,2,2); scatter(x,y);
hold on;
line(z1,z2,'Color','r','LineWidth',4);
xlabel('GARCH')
ylabel('GJR')
title('Scatter Plot of the Conditional Variances-GARCH--GJR');

%NIC graph 
A = 0.0171041 + 0 * var(ret1)
cond_var = [0];
eps = linspace(-3,3,602)
for i=-3:0.01:3
    if i > 0
        temp = A + 0.898633 * i^2;
        cond_var = cat(1, cond_var, temp);
    else
        temp = A + (0.898633 + 0.168561)* i^2;
        cond_var = cat(1, cond_var, temp);
    end
end   
plot(eps, cond_var)
 






