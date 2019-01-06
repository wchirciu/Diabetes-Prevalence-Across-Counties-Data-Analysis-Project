*import diabetes dataset;
proc import datafile="Max_Diabetes_Final.csv" out=Diabetes replace;
delimiter=',';
getnames=yes;
run;

proc print;
run;

*create interaction terms where it makes sense;
data diabetes;
set diabetes;
unemp_income = Unemployment_Rate*Household_Median_Income;
obesity_inactivity = Obesity_Prev_Percent*Leisure_Time_Physical_Inactivity;
age_income = Median_Age*Household_Median_Income;
unemp_age = Unemployment_Rate*Median_Age;
obesity_income=Obesity_Prev_Percent*Household_Median_Income;
obesity_age=Obesity_Prev_Percent*Median_Age;
inactivity_age=Leisure_Time_Physical_Inactivity*Median_Age;
inactivity_income=Leisure_Time_Physical_Inactivity*Household_Median_Income;
HSOnly_unemp=Perc_Adults_HSOnly*Unemployment_Rate;
run;

proc print;
run;
*Variables below;
*Diagnosed_Diabetes_Est__Percent Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege Perc_Adults_BAorHigher 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age unemp_income obesity_inactivity age_income unemp_age
obesity_income obesity_age inactivity_age inactivity_income HSOnly_unemp;

*examine distributions of y variable diabetes prevalance;
proc univariate normal;
var Diagnosed_Diabetes_Est__Percent;
histogram / normal (mu=est sigma=est);
run;

*scatterplots of dependent with predictors as matrix was hard to see;
PROC GPLOT data=Diabetes;
PLOT Diagnosed_Diabetes_Est__Percent*(Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege Perc_Adults_BAorHigher 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age);
run;


*check for multicolinearity;
proc corr;
var Diagnosed_Diabetes_Est__Percent Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege Perc_Adults_BAorHigher 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age unemp_income obesity_inactivity age_income unemp_age
obesity_income obesity_age inactivity_age inactivity_income HSOnly_unemp;
run;

*check vif;
proc reg;
model Diagnosed_Diabetes_Est__Percent=Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege Perc_Adults_BAorHigher 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age unemp_income obesity_inactivity age_income unemp_age
obesity_income obesity_age inactivity_age inactivity_income HSOnly_unemp/vif;
run;

*drop insignificant vars and run again;
proc reg;
model Diagnosed_Diabetes_Est__Percent=Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age obesity_inactivity unemp_age obesity_income/vif;
run;

*run corr table with vars above;
proc corr;
var Diagnosed_Diabetes_Est__Percent Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age obesity_inactivity unemp_age obesity_income;
run;


*center vars in interaction terms;
data Diabetes_centered;
set Diabetes;
Unemp_rate_c = 6.24562-Unemployment_Rate;
income_c = 49533-Household_Median_Income;
obesity_c = 31.47509-Obesity_Prev_Percent;
inactivity_c = 26.82440-Leisure_Time_Physical_Inactivity;
age_c = 40.71911-Median_Age;
obesity_inactivity_c = obesity_c*inactivity_c;
unemp_age_c = Unemp_rate_c*age_c;
obesity_income_c = obesity_c*income_c;
run;

proc print data=Diabetes_centered;
run;

*re-run model with centered vars;
proc reg data=Diabetes_centered;
model Diagnosed_Diabetes_Est__Percent = Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c/vif stb;
run;

*run model without interaction terms to see if rsquared improved;
proc reg data=Diabetes;
model Diagnosed_Diabetes_Est__Percent = Unemployment_Rate Household_Median_Income Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege 
Obesity_Prev_Percent Leisure_Time_Physical_Inactivity Median_Age/vif stb;
run;

*interaction terms did improve rsquare and adj rsquare;


*scatterplots of dependent with predictors as matrix was hard to see;
PROC GPLOT data=Diabetes_centered;
PLOT Diagnosed_Diabetes_Est__Percent*(Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c);
run;


*examine vif, studentized residuals, probability plot, influential points, standardized coefficients on prelim model;
proc reg data=Diabetes_centered;
model Diagnosed_Diabetes_Est__Percent = Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c/vif stb influence r;
plot student.*predicted.;
plot student.*(Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c);
plot npp.*student.;
run;

*cross-validation/fit final model;
proc glmselect data=Diabetes_centered;
model Diagnosed_Diabetes_Est__Percent = Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c/selection=backward(stop=cv) cvMethod=split(5) cvDetails=all;
run;

*Final model for prediction;
PROC reg data = Diabetes_Centered;
model Diagnosed_Diabetes_Est__Percent = Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c;
run;

*create two predictions data line for final model;
data pred;
input Unemp_rate_c income_c Perc_Adults_LessThanHS Perc_Adults_HSOnly 
Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c;
datalines;
1 -10000 10 50 40 20 12 2 240 2 -200000
-5 10000 20 60 20 -10 -12 -5 120 25 -100000
;
*merge datasets;
data prediction;
set pred Diabetes_centered;
run;
proc print;
run;

*predict diabetes prevalance with predictor values;
proc reg data=prediction;
model Diagnosed_Diabetes_Est__Percent = Unemp_rate_c income_c Perc_Adults_LessThanHS 
Perc_Adults_HSOnly Perc_Adults_AssociateSomeCollege obesity_c inactivity_c age_c
obesity_inactivity_c unemp_age_c obesity_income_c/p clm cli;
run;
