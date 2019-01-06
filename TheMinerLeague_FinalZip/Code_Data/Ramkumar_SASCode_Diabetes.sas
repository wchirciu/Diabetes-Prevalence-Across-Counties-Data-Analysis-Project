
title "Diabetes Prevalence Dataset";
* -----[IMPORT FILE]-----;
proc import datafile="Diabetes_Final.csv"
     out=import(rename=(VAR2=State VAR4=County VAR5=Diag_Pct VAR6=Unemp_Rate VAR7=Income VAR8=lt_HighSchool VAR9=only_HighSchool VAR10=Col_Degree VAR11=Bach_Degree VAR12=Obesity VAR13=Ph_Inactivity VAR14=Age) drop= VAR1 VAR3)
     dbms=csv
     replace;
     getnames=no;
	 DATAROW=2;
	 guessingrows=500; 
run;
* -----[SET REGIONS]-----;
Data diab;
set import;
if State in ("New England","Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont","New Jersey", "New York", "Pennsylvania") then
	region = "Northeast" ;
else
	if State in ("Illinois", "Indiana", "Michigan", "Ohio", "Wisconsin","Iowa", "Kansas", "Minnesota", "Missouri", "Nebraska", "North Dakota", "South Dakota") then
		region = "Midwest" ;
	else
		if State in ("Delaware", "Florida", "Georgia", "Maryland", "North Carolina", "South Carolina", "Virginia", "District of Columbia", "West Virginia","Alabama","Kentucky", "Mississippi", "Tennessee","Arkansas", "Louisiana", "Oklahoma", "Texas") then
			region = "South" ;
		else
			if State in ("Arizona", "Colorado", "Idaho", "Montana", "Nevada", "New Mexico", "Utah", "Wyoming","Alaska", "California", "Hawaii", "Oregon", "Washington") then
				region = "West" ;

d_Northeast=(region = "Northeast");
d_Midwest=(region = "Midwest");
d_South=(region = "South");
*d_West=(region = "West");
run;
quit;

proc print;
run;


* -----[Explore the distribution]-----;
title "Explore the Distribution for Diagnosis percentage";
proc univariate data=diab normal;
var Diag_Pct;
histogram/normal (mu=est sigma=est);
probplot/normal(mu=est sigma=est);
run;


* -----[ CORRELATION ]-----;
* Generate scatterplot matrix - ;
proc sgscatter;
title "Scatterplot Diagnosis Percentage";
plot Diag_Pct *(Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Bach_Degree Obesity Ph_Inactivity Age);
run;

* -----[ MULTICOLLINEARITY ]-----;
*Check for multicollinearity;
title "Correlation check";
proc corr;
var Diag_Pct Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Bach_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South;
run;

*Variance Inflation check for multicollinearity;
title "Variance Inflation";
proc reg data=diab;
model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Bach_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South  /vif tol;
run; 

*Variance Inflation check for multicollinearity;
title "Variance Inflation without Bach_Degree";
proc reg data=diab;
model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South  /vif tol;
run; 

* -----[ LINEAR REGRESSION ]-----;
*Fit linear regression model;
title "Linear regression";
proc reg data=diab;
model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South  /stb;
run; 


* -----[ INFLUENTIAL POINTS & OUTLIERS ]-----;
*Check for outliers;
title "Linear regression influence points";
proc reg data=diab;
model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South /r influence tol;
run; 

* remove influential observations;
* writing the new dataset after the deletion into diab_new;
data diab_new;
set diab;
if _n_ in (6,27,32,34,43,44,46,53,60,66,68,69,71,72,73,74,77,82,84,85,86,87,88,90,91,93,94,95,96,101,102,110,122,192,196,198,223,226,228,239,249,255,256,257,258,259,272,284,339,405,412,416,442,456,475,504,517,530,539,547,554,555,696,703,725,733,739,765,889,917,920,921,928,965,974) then delete;
if _n_ in (1015,1062,1066,1068,1129,1142,1164,1210,1226,1274,1410,1427,1450,1468,1475,1598,1614,1619,1634,1639,1739,1750,1755,1797,1810,1811,1835,1851,1858,1867,1870) then delete;
if _n_ in (2028,2031,2040,2052,2078,2079,2080,2083,2114,2123,2189,2206,2208,2213,2227,2235,2241,2267,2274,2303,2320,2331,2359,2363,2368,2380,2425,2419,2449,2514,2551,2568,2603,2605,2671,2682,2693,2709,2715,2734,2760,2765,2773,2774,2778,2789,2824,2881,2976) then delete;
if _n_ in (3084,3119) then delete;
run;

*Full model without outliers;
title "Linear regression full model";
proc reg data=diab_new;
model Diag_Pct=Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/vif stb;
run;

* -----[ SPLIT TRAIN & TEST DATASET ]-----;
title "Split dataset into train and test";
proc surveyselect data=diab_new out=xv_all seed=646789
samprate=0.60 outall;
run;
* print out training/test datasets identified by variable "selected";
title "Train Set";
proc print data=xv_all;
run;
*create new variable new_y ;
data xv_all;
set xv_all;
if selected then new_y=Diag_Pct;
run;
proc print data=xv_all;
run;

* -----[ TRAINING DATASET MODEL SELECTION ]-----;
title "Model selection - Train dataset";
proc reg data=xv_all;
*Model 1;
model new_y=Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/selection=backward slentry=0.05 slstay=0.05;

*Model 2;
model new_y=Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/selection=stepwise slentry=0.05 slstay=0.05;

run;

*-----[ SELECTED MODELS ]-----;
*Selected models from model selection methods;
title "Linear regression on selected models - Test";
proc reg data=xv_all;
*Model 1;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/ stb;
*Model 2;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South/ stb;
run;


*-----[ TRAIN MODEL 1 RESIDUALS ]-----;
title "Train Model1 residuals";
proc reg data= xv_all;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/stb;
* Residual plot: residuals vs predicted values;
plot student.*(Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South predicted.);
* Normal probability plot or QQ plot;
plot npp.*student.;
run;

*-----[ TRAIN MODEL 2 RESIDUALS ]-----;
title "Train Model2 residuals";
proc reg data= xv_all;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South/stb;
* Residual plot: residuals vs predicted values;
plot student.*(Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South predicted.);
* Normal probability plot or QQ plot;
plot npp.*student.;
run;

*-----[ FINAL MODEL 1 TEST ]-----;
/* get predicted values for the missing new_y in test set fore model 1*/
title "Validation Model1 - Test Set";
proc reg data=xv_all;
* MODEL1;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South;
output out=outm1(where=(new_y=.)) p=yhat;
run;

proc print data=outm1;
run;

*-----[ FINAL MODEL 2 TEST ]-----;
/* get predicted values for the missing new_y in test set for model 2*/
title "Validation Model2 - Test Set";
proc reg data=xv_all;
* MODEL2;
model new_y=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South;
output out=outm2(where=(new_y=.)) p=yhat;
run;

proc print data=outm2;
run;

*-----[ FINAL MODEL 1 PREDICTED VS OBSERVED ]-----;
/* summarize the results of the cross-validations for model-1*/
title "Difference between Observed and Predicted in Test Set for Model1";
data outm1_sum;
set outm1;
d=Diag_Pct-yhat; 
absd=abs(d);
run;
/* rmse & mae)*/
proc summary data=outm1_sum;
var d absd;
output out=outm1_stats std(d)=rmse mean(absd)=mae ;
run;
proc print data=outm1_stats;
title 'Validation  statistics for Model1';
run;
*correlation;
proc corr data=outm1;
var Diag_Pct yhat;
run;

*-----[ FINAL MODEL 2 PREDICTED VS OBSERVED ]-----;
/* summarize the results of the cross-validations for model-2*/
title "Difference between Observed and Predicted in Test Set for Model2";
data outm2_sum;
set outm2;
d=Diag_Pct-yhat; 
absd=abs(d);
run;
/* rmse & mae)*/
proc summary data=outm2_sum;
var d absd;
output out=outm2_stats std(d)=rmse mean(absd)=mae ;
run;
proc print data=outm2_stats;
title 'Validation  statistics for Model2';
run;
*computes correlation ;
proc corr data=outm2;
var Diag_Pct yhat;
run;

*-----[ FINAL MODEL SELECTED ]-----;
*Final model selected from validation;
title "Final Model";
proc reg data= xv_all;
model Diag_Pct=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South/stb;
* Residual plot: residuals vs predicted values;
plot student.*(Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South predicted.);
* Normal probability plot or QQ plot;
plot npp.*student.;
run;

/*-----[ FINAL MODEL SELECTED ]-----;
*Final model selected from validation;
title "Final Model";
proc reg data= diab;
model Diag_Pct=Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South/stb;
* Residual plot: residuals vs predicted values;
plot student.*(Unemp_Rate Income Col_Degree Obesity Ph_Inactivity Age d_South predicted.);
* Normal probability plot or QQ plot;
plot npp.*student.;
run;*/


/**************************************************
K-FOLD CROSS VALIDATION
**************************************************/
title "5-fold crossvalidation";
proc glmselect data=diab
	plots=(asePlot Criteria);
model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/
	selection=backward(stop=cv)cvMethod=split(5) cvDetails=all;
run;
/* apply 5-fold crossvalidation with stepwise selection 
and 40% of data removed for testing; */
title "5-fold crossvalidation + 40% testing set";
proc glmselect data=diab
	plots=(asePlot Criteria);

	partition fraction(test=0.40);

	model Diag_Pct = Unemp_Rate Income lt_HighSchool only_HighSchool Col_Degree Obesity Ph_Inactivity Age d_Northeast d_Midwest d_South/
		selection=stepwise(stop=cv) cvMethod=split(5) cvDetails=all;
run;
