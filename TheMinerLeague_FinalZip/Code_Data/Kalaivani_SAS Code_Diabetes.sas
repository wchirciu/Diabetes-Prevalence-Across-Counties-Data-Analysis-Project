title "Diabetes Prevalence Dataset";
* Read from file;
data diabetes;
infile "C:\Users\KCHANDR1\Downloads\Diabetes_Final.csv" firstobs=2 delimiter="," missover;
input Indicator : $60. State : $60. FIPS_code $ County : $50. Diagnosed_Percent Unemp_Rate Income  less_HighSch_Pct HighSch_only College_Deg Bach_Deg_Pct Obes_Per Leisure_Inact Med_Age;
label Indicator ="Indicator" State="State" FIPS_code="FIPS_code" Diagnosed_Percent="Diagnosed Diabetes Est. Percent" Unemp_Rate="Unemployment Rate" Income="Household Median Income" less_HighSch_Pct="Percent of adults with less than a high school diploma" HighSch_only="Percent of adults with a high school diploma only" College_Deg="Percent of adults completing some college or associate's degree"Bach_Deg_Pct="Percent of adults with a bachelor's degree or higher" Obes_Per="Obesity Prev Percent" Leisure_Inact="Leisure Time Physical Inactivity Prev Perc" Med_Age="Median Age";
run;

proc print;
run;

* -----[Explore the distribution]-----;
* Create histogram and normal probability plot diabetes;
title "Explore the Distribution for Diabetes";
proc univariate data=diabetes normal; 
var Diagnosed_Percent;
histogram/normal (mu=est sigma=est);
probplot/normal(mu=est sigma=est);
run;

* -----[ CORRELATION ]-----;
* Explore the pair-wise associations between diagnose percent and individual independent variable;
* Generate scatterplot matrix - ;
proc sgscatter;
title "Scatterplot Matrix for Diabetes ($)";
matrix Diagnosed_Percent Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Bach_Deg_Pct Obes_Per Leisure_Inact Med_Age;
run;
proc sgscatter; 
title "Scatterplot Matrix for Diabetes ($)";
plot Diagnosed_Percent *(Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Bach_Deg_Pct Obes_Per Leisure_Inact Med_Age);
run;

* to compute correlation matrix;
proc corr;
var Diagnosed_Percent Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Bach_Deg_Pct Obes_Per Leisure_Inact Med_Age;
run;

*compute regression analysis to predict Diabetes percentage from the other depedent variables;
proc reg data=diabetes;
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Bach_Deg_Pct Obes_Per Leisure_Inact Med_Age/stb;
run;

*Regression analysis after removing the bach degree variable;
proc reg data=diabetes;
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/stb;
run;
*To check for multicollinearity;
Title "Compute the variance inflation factor";
proc reg data=diabetes;
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/vif;
run;

*to check for the outliers in the full model;
Title" model with outliers";
proc reg data=diabetes;
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/r influence;
run;

*Full model after removing the putliers and influential points;
data Diabetesnew;
set Diabetes;
if _n_ in (6,32,43,44,53,60,66,69,71,72,73,74,77,82,84,85,86,88,90,91,93,94,95,110,122,191,198,201,226,236,239,256,284,379) then delete;
if _n_ in (412,416,442,504,517,530,539,576,889,917,920,921,924,925,928,965,972,974,980,1022,1037) then delete;
if _n_ in (1046,1057,1062,1066,1068,1084,1086,1099,1129,1140,1164,1199,1210,1328,1365,1410,1427,1431,1459,1468,1475,1614) then delete;
if _n_ in (1619,1634,1671,1687,1691,1735,1739,1755,1777,1807,1810,1998,2007,2030,2031,2078,2115,2199,2208,2213,2241,2274) then delete;
if _n_ in (2315,2320,2331,2347,2359,2362,2368,2373,2380,2419,2425,2449,2514,2551,2568,2603,2605,2606,2628,2671,2682,2692) then delete;
if _n_ in (2694,2709,2715,2734,2743,2760,2765,2773,2774,2789,2824,2881,2961,2976,2978,2994,3021,3084,3119) then delete;
run;

*Regression analysis for the model without outliers;
proc reg data=diabetesnew;
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age;
run;


*to select the train and test obseravtions;
title"test and train sets for diabetes";
proc surveyselect data=diabetes out=NewDiab seed= 5000 samprate=0.75 outall;
run;
proc print;
run;

*to create the new variable for test and train set;
data NewDiab;
set NewDiab;
if selected then new_y=Diagnosed_Percent;
run;
Proc print data=NewDiab;
run;

*Models;
title "Model Selection";
proc reg data=NewDiab;
*MODEL 1;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/selection=forward;
*MODEL 2;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/selection=stepwise;
run;

*to check for the influential points in model 1;
title"Outliers and influential points for train set";
proc reg data=NewDiab;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/r influence vif stb;
run;

*to remove the outliers and influential points;
data NewDiab_new;
set NewDiab;
if _n_ in (6,27,32,43,44,46,53,60,66,68,72,74,77,82,85,87,88,90,91,93,94,95,101,110,165,191,198,200,201,205,212,228,236,239,255,256,258,271,272) then delete;
if _n_ in (284,289,290,297,327,328,379,405,412,456,467,480,504,517,530,576,733,826,889,917,920,924,925,928,965,972,974,980,1022,1037,1057,1062) then delete;
if _n_ in (1068,1084,1086,1099,1129,1140,1164,1319,1365,1410,1427,1431,1468,1475,1614,1619,1634,1671,1735,1739,1810,1998,2007,2030,2031,2078,2115) then delete;
if _n_ in (2199,2208,2241,2274,2315,2320,2331,2359,2362,2368,2373,2380,2425,2449,2514,2551,2568,2603,2671,2682,2694,2715,2734,2743,2760,2765,2773,2774) then delete;
if _n_ in (2789,2976,2978,3021,3084,3119) then delete;
run;

* Fitted Model - Goodness of Fit with standardized coefficentts ;
* stb - standardized parameter estimates;
title "Final Model";
proc reg data=NewDiab_new;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/stb;
run;

* -------------- Check model assumptions - Resiiduals and Probability Plots;
title "Residual and Probability Plots for Diagonose percent";
proc reg;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age;
* Residual Plots;
plot student.*predicted.;
plot npp.*student.;
plot student.*(Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age);
run;

 
/* get predicted values for the missing new_y in test set*/
title "Validation - Test Set";
proc reg data=NewDiab;
* MODEL1;
model new_y=Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age;
*out=outm1 defines dataset containing Model1 predicted values for test set;
output out=outm1(where=(new_y=.)) p=yhat;
run;

proc print data=outm1;
run;


/* summarize the results of the cross-validations for model-1*/
title "Difference between Observed and Predicted in Test Set";
data outm1_sum;
set outm1;
d=Diagnosed_Percent-yhat; *d is the difference between observed and predicted values in test set;
absd=abs(d);
run;
/* computes predictive statistics: root mean square error (rmse) 
and mean absolute error (mae)*/
proc summary data=outm1_sum;
var d absd;
output out=outm1_stats std(d)=rmse mean(absd)=mae;
run;
proc print data=outm1_stats;
title 'Validation  statistics for Model';
run;
*computes correlation of observed and predicted values in test set;
proc corr data=outm1;
var Diagnosed_Percent yhat;
run;



/**************************************************
K-FOLD CROSS VALIDATION
**************************************************/

* Compute 5-fold crossvalidation;
/* Apply 5-fold cross validation with backward model selection 
using prediction res#idual sum of squares as criterion for removing variables
(step=cv)*/
title "5-fold crossvalidation";
proc glmselect data=Diabetes
	plots=(asePlot Criteria);
model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/
	selection=backward(stop=cv)cvMethod=split(5) cvDetails=all;
run;
/* apply 5-fold crossvalidation with stepwise selection 
and 25% of data removed for testing; */
title "5-fold crossvalidation + 25% testing set";
proc glmselect data=Diabetes
	plots=(asePlot Criteria);
	*partition defines a test set (25% of data) to validate model on new data;
	partition fraction(test=0.25);
	* selection=stepwise uses stepwise selection method;
	* stop=cv: minimizes prediction residual sum of squares for variable selection;
	model Diagnosed_Percent = Unemp_Rate Income less_HighSch_Pct HighSch_only College_Deg Obes_Per Leisure_Inact Med_Age/
		selection=stepwise(stop=cv) cvMethod=split(5) cvDetails=all;
run;
