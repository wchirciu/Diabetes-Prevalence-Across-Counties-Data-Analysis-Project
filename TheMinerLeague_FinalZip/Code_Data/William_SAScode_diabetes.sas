*Importing data from csv;
data diabetes;
infile 'S:/423/423Project/Diabetes_Final.csv' delimiter = ',' missover firstobs = 2;
input Indicator $ State $ FIPS_code County $ Diabetes_Est_Prevalence Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age;
Age_Obesity = Median_Age * Obesity_Prevalence;
Age_Inactivity =  Median_Age * Physical_Inactivity_Prevalence;
Unemployment_Age = Unemployment_Rate * Median_Age;
Unemployment_Obesity = Unemployment_Rate * Obesity_Prevalence;
Unemployment_Inactivity = Unemployment_Rate * Physical_Inactivity_Prevalence;
run;

*Dropping all columns not needed for regression modeling;
data diabetes;
set diabetes;
drop Indicator;
drop State;
drop FIPS_code;
drop County;
run;
proc print;
title 'Diabetes Prevalence Data';
run;

*Scatterplots;
proc sgscatter;
title 'Scatter Matrix';
matrix Diabetes_Est_Prevalence Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age;
run;

proc univariate;
title 'Diabetes_Est_Prevalence Distribution';
histogram;
var Diabetes_Est_Prevalence;
run;

proc univariate;
title 'Unemployment Rate Distribution';
histogram;
var Unemployment_Rate;
run;

proc univariate;
title 'Median_Income Distribution';
histogram;
var Median_Income;
run;

proc univariate;
title 'Adults_No_HighSchool_Diploma Distribution';
histogram;
var Adults_No_HighSchool_Diploma;
run;

proc univariate;
title 'Adults_HighSchool_Diploma_Only Distribution';
histogram;
var Adults_HighSchool_Diploma_Only;
run;

proc univariate;
title 'Adults_Associates_Degree Distribution';
histogram;
var Adults_Associates_Degree;
run;

proc univariate;
title 'Adults_Bachelors_Or_Higher Distribution';
histogram;
var Adults_Bachelors_Or_Higher;
run;

proc univariate;
title 'Obesity_Prevalence Distribution';
histogram;
var Obesity_Prevalence;
run;

proc univariate;
title 'Physical_Inactivity_Prevalence Distribution';
histogram;
var Physical_Inactivity_Prevalence;
run;

proc univariate;
title 'Median_Age Distribution';
histogram;
var Median_Age;
run;

*Correlation Matrix;
proc corr;
title 'Correlation Matrix';
var Diabetes_Est_Prevalence Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Age_Obesity Age_Inactivity Unemployment_Age Unemployment_Obesity
Unemployment_Inactivity;
run;

*Fit full model and check VIFs/Tols;
proc reg;
title 'Regression Analysis Full Model w/ Interaction Terms';
model Diabetes_Est_Prevalence = Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Age_Obesity Age_Inactivity Unemployment_Age Unemployment_Obesity
Unemployment_Inactivity/vif tol;
run;

*Fit full model and check VIFs/Tols without insignificant vars;
proc reg;
title 'Regression Analysis Full Model w/ Interaction Terms';
model Diabetes_Est_Prevalence = Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age Unemployment_Obesity/vif tol;
run;

*Need to center Unemployment_Rate and interaction variables;
data diabetes;
set diabetes;
Unemployment_Rate_c = 6.24562 - Unemployment_Rate;
Unemployment_Age_c = Unemployment_Rate_c * Median_Age;
Unemployment_Obesity_c =  Unemployment_Rate_c * Obesity_Prevalence;
run;
proc print;
title 'Centered Diabetes Prevalence Data';
run;

*Check for outliers/influential points;
proc reg;
title 'Regression Analysis Full Model w/ Interaction Terms';
model Diabetes_Est_Prevalence = Unemployment_Rate_c Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c /influence r;
run;

*Remove Heavy Outliers/Influential Points;
data diabetes;
set diabetes;
if _n_ = 60 then delete;
if _n_ = 77 then delete;
if _n_ = 88 then delete;
if _n_ = 1057 then delete;
if _n_ = 2331 then delete;
if _n_ = 2419 then delete;
run;

*Split into train/test dataset;
proc surveyselect data=diabetes out=diabetes_split seed= 807231000
samprate=0.80 OUTALL;
title 'Train/Test Split';
run;

data diabetes_split;
set diabetes_split;
if selected then diabetes_pred = Diabetes_Est_Prevalence;
run;
proc print;
title 'Diabetes Prevalence Split Dataset';
run;

*Model Selection;
proc reg;
title 'Adjusted RSquare Selection';
model diabetes_pred = Unemployment_Rate_c Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c /selection = adjrsq;
run;

*Fitting the model with predictors selected from adj r2 model selection and checking for outliers;
proc reg;
title 'Final Regression Model- outliers/infuential points';
model diabetes_pred = Unemployment_Rate_c Median_Income Adults_HighSchool_Diploma_Only Adults_Associates_Degree 
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c/influence r stb;
plot student.*predicted.;
plot npp.*student.;
run;

*Fitting the model with predictors selected from adj r2 model selection;
proc reg;
title 'Final Regression Model';
model diabetes_pred = Unemployment_Rate_c Median_Income Adults_HighSchool_Diploma_Only Adults_Associates_Degree 
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c/stb;
plot student.*predicted.;
plot npp.*student.;
run;

proc reg;
title "Validation - Test Set";
model diabetes_pred = Unemployment_Rate_c Median_Income Adults_HighSchool_Diploma_Only Adults_Associates_Degree 
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c;
output out=outm(where=(diabetes_pred=.)) p=yhat; 
run;

*Calculates distance between predicted and observed values for diabetes prevalence;
title "Difference between Observed and Predicted in Test Set";
data outm_sum;
set outm;
d=Diabetes_Est_Prevalence-yhat;
absd=abs(d);
run;

*Predictive Statistics;
proc summary data=outm_sum;
title 'Predictive Statistics';
var d absd;
output out=outm_stats std(d)=rmse mean(absd)=mae;
run;
proc print data=outm_stats;
title 'Validation statistics for model';
run;
*Correlation matrix to determine test-set R-square;
proc corr data=outm;
title 'Test Set R-Square';
var Diabetes_Est_Prevalence yhat;
run;

*Computing 2 predictions;
data pred;
input Diabetes_Est_Prevalence Unemployment_Rate Median_Income 
Adults_No_HighSchool_Diploma Adults_HighSchool_Diploma_Only Adults_Associates_Degree Adults_Bachelors_Or_Higher
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age diabetes_pred;
Unemployment_Age = Unemployment_Rate * Median_Age;
Unemployment_Obesity = Unemployment_Rate * Obesity_Prevalence;
Unemployment_Rate_c = 6.24562 - Unemployment_Rate;
Unemployment_Age_c = Unemployment_Rate_c * Median_Age;
Unemployment_Obesity_c =  Unemployment_Rate_c * Obesity_Prevalence;
datalines;
. 6.0 55192 15.786 39.91 30.014 25.336 32.5 27.3 39.1 .
. 5.7 53467 17.989 35.76 28.650 23.548 30.6 29.6 37.8 .
;

*Making predictons;
data predict;
set pred diabetes_split;
proc print;
title 'Dataset with predictions appended';
run;

proc reg;
title 'Making predictions on new counties';
model diabetes_pred = Unemployment_Rate_c Median_Income Adults_HighSchool_Diploma_Only Adults_Associates_Degree 
Obesity_Prevalence Physical_Inactivity_Prevalence Median_Age Unemployment_Age_c Unemployment_Obesity_c/p clm cli alpha=0.05;
run;
