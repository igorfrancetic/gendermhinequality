/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Paper: Gender-related self-reported mental health inequalities in primary care in England: Cross-sectional 
// analysis using the GP Patient Survey (Watkinson R, Linfield A, Tielemans J, Francetic I, Munford L)
// Analysis by: Watkinson, Francetic, Munford
// Version: 16/11/2023
// Do-file title: Analysis
////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
This do-file produced all descriptive statistics and analyses, generating the figures and tables in the paper.
It will first run the preparation do-file (bookmark 2). To generate outputs it uses the following Stata packages:
- asdocx (https://asdocx.com/)
- esttab (available from SSC)
- table1 (available from SSC)
- heatplot (available from SSC)
- cleanplots (available from SSC)
- eclplot (available from SSC)
- transform_margins (https://www.stata.com/users/jpitblado/transform_margins/transform_margins.hlp)

************************************************
**# Installing/Updating SSC packages
************************************************
ssc install estout, replace
ssc install table1, replace
ssc install heatplot, replace
ssc install cleanplots, replace
ssc install eclplot, replace
net install transform_margins.pkg, replace from(http://www.stata.com/users/jpitblado/)
*/

************************************************
**# Setting folders
************************************************
clear all
set more off, permanently

// set your root directory
global root "X:\your_root_directory"

// set globals for sub folders
global datain "$root\Raw_data"
global dataout "$root\Processed_data"
global output "$root\Output"

************************************************
**# Launch preparation do-file saved in the same folder as the analysis do-file
************************************************
do  "`c(pwd)'\20231116_revision2_preparation.do"
clear all
use "$dataout\GPPS_final_2021_2022.dta", clear

******************************************************
**# Descriptives
// 	Launches the do-file generating descriptives
******************************************************
do  "`c(pwd)'\20231116_revision2_descriptives.do"

log using $output/review2, replace
******************************************************
**# Regression analysis - MH condition outcome
******************************************************
// Analysis
// Outcome 1: MH condition
// Overall
******************************************************

local model 1

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional)post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\mhcond_summary.dta", replace // save as summary because 1st model, after append
restore

******************************************************
// Analysis
// Outcome 1: MH condition
// Add health vars (LTCs)
******************************************************

local model 2

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 1: MH condition
// Add health + socioeconomic vars (IMD, doing, rural)
******************************************************

local model 3

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

// This generates the CIs not via Delta-method and puts the result in a matrix with all coefficients to be used for plotting later 
matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Sensitivity
// Outcome 1: MH condition
// Overall - using complete data for all mediators
******************************************************

local model 4

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if complete_med_1==1 ///
	, vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender	

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)
 
matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Sensitivity
// Outcome 1: MH condition
// adding health and socioeconomic - 
// using complete data for all mediators
******************************************************

local model 5

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural ///
	[pweight=wt_new] ///
	if complete_med_1==1 ///
	, vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender	

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 1: MH condition
// Overall - under 35
******************************************************

local model 6

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp<=2 ///
	, vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 1: MH condition
// Overall - 35-64
******************************************************

local model 7

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp>2 & agegp<6 ///
	, vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender	

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 1: MH condition
// Overall - 65+
******************************************************

local model 8

// regression
logistic mhcond i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp>=6 ///
	, vce(robust)	
estimates store m_`model'

esttab m_`model' using $output\mhcond_OR_model`model'.rtf, replace ///
	eform ///
	b(2) ci(2) nostar ///
	varwidth(30) nogaps  ///
	label nonumbers	title("model_`model'")

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender	

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhcond_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 1 // for outcome 1
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhcond_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhcond_summary.dta", replace
restore


******************************************************
// Export table of regressions (as odds ratios)
******************************************************

esttab m_1 m_2 m_3 m_4 m_5 m_6 m_7 m_8 using "$output\mhcond_OR_summary.rtf", ///
	eform b(2) ci(2) label nonumbers nostar ///
	title(1 "Main" 2 "Add health" 3 "Add health and socioeconomic" ///
	4 "Sensitivity" 5 "Sensitivity plus mediators" 6 "Age - under 35" ///
	7 "Age - 35-64" 8 "Age - 65+") ///
	replace
	
******************************************************	
**# Plots
******************************************************
// Tidy up summary file with predicted probabilities
// Then export for table
// And plot
******************************************************	

preserve
// open
clear all
use "$output\mhcond_summary.dta", clear

label define genderlab 1 "Female" 2 "Male" 3 "Non-binary" ///
	4 "Prefer to self-describe" 5 "Prefer not to say"
label values gender genderlab
label var gender "Gender"

label define translab 1 "Cisgender" 2 "Transgender" 3 "Prefer not to say"
label values trans translab
label var trans "Cis/trans identity"

label define outcomelab 1 "A mental health condition" 2 "MH needs not met"
label values outcome varlab	
label var outcome "Outcome"

label define modellab 1 "Main" 2 "Add health" 3 "Add health and socioeconomic" ///
	4 "Sensitivity" 5 "Sensitivity plus mediators" 6 "Age - under 35" ///
	7 "Age - 35-64" 8 "Age - 65+", replace
label values model modellab

save "$output\mhcond_summary.dta", replace
	
// plot - loop through models
// use 0-60 scale for most models
set scheme cleanplots, perm
graph set window fontface "Arial"
foreach model in 1 2 3 4 5 {
	eclplot b lb ub trans if outcome==1 & model==`model', ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)60)) ylabel(0(10)60) ytick(0(5)60) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(col(1) subtitle("Gender", size(medlarge)) size(medlarge))
	graph save "$output\mhcond_predp_model`model'.gph", replace
	graph export "$output\mhcond_predp_model`model'.svg", replace
	graph export "$output\mhcond_predp_model`model'.png", replace	
}	
// 0-80 scale for age-split
set scheme cleanplots, perm
graph set window fontface "Arial"
foreach model in 6 7 8 {
	eclplot b lb ub trans if outcome==1 & model==`model', ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)80)) ylabel(0(10)80) ytick(0(5)80) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(col(1) subtitle("Gender", size(medlarge)) size(medlarge))
	graph save "$output\mhcond_predp_model`model'.gph", replace
	graph export "$output\mhcond_predp_model`model'.svg", replace
	graph export "$output\mhcond_predp_model`model'.png", replace	
}	

// Create Figure 2 in the paper
// use 0-60 scale for most models
set scheme cleanplots, perm
graph set window fontface "Arial"
	eclplot b lb ub trans if outcome==1 & model==1, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)60)) ylabel(0(10)60) ytick(0(5)60) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)",  size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: A}) plotregion(margin(zero))
	graph save "$output\Fig2A.gph", replace
	graph export "$output\Fig2A.svg", replace
	graph export "$output\Fig2A.png", replace

	
	eclplot b lb ub trans if outcome==1 & model==2, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)60)) ylabel(0(10)60) ytick(0(5)60) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge) color(white)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: B}) plotregion(margin(zero))
		graph save "$output\Fig2B.gph", replace
		graph export "$output\Fig2B.svg", replace
		graph export "$output\Fig2B.png", replace
		
	eclplot b lb ub trans if outcome==1 & model==3, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)60)) ylabel(0(10)60) ytick(0(5)60) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
				ytitle("Predicted probability" ///
			"(rescaled as %)", color(white) size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: C}) plotregion(margin(zero))
		graph save "$output\Fig2C.gph", replace
		graph export "$output\Fig2C.svg", replace
		graph export "$output\Fig2C.png", replace
		
	eclplot b lb ub trans if outcome==1 & model==3, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)60)) ylabel(0(10)60) ytick(0(5)60) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("") ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8))  ///
		legend(col(1) subtitle("Gender", size(medlarge)) size(medlarge) pos(6)) title({bf: C}) plotregion(margin(zero))
		graph save "$output\Fig2_legend.gph", replace
		graph export "$output\Fig2_legend.svg", replace
		graph export "$output\Fig2_legend.png", replace

graph use $output/Fig2_legend.gph, play($output/legendonly)
graph save $output/legend.gph, replace
		
graph combine $output/Fig2A.gph $output/Fig2B.gph $output/Fig2C.gph $output/legend.gph , /// 
cols(4) ///
ycommon ///
graphregion(margin(l=0 r=0)) ///
scale(1) xsize(100) ysize(40) ///
saving($output/Fig2.gph, replace)
graph export $output/Fig2.svg, replace
graph export $output/Fig2.pdf, replace
graph export $output/Fig2.tif, replace

// export to CSV ready to make tables
gen prob = round(b, 0.01)
gen ll = round(lb, 0.01)
gen ul = round(ub, 0.01)
drop b lb ub
export delim using "$output\mhcond_summary.csv", replace
restore

******************************************************
**# Associations with potential mediators
******************************************************
// Supplementary
// Assoications between potential mediators and 
// outcome
******************************************************

// regression
logistic mhcond b5.imd_q i.doing i.rural q31* ///
	[pweight=wt_new] , vce(robust)	
estimates store mediators

esttab mediators using "$output\mhcond_OR_mediators.rtf", ///
	eform b(2) ci(2) label nonumbers nostar ///
	replace

// Table of potential mediators for outcome 1 sample - by outcome
table1 if mhcond!=., by(mhcond) vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat ///
	) ///
	onecol saving ("$output\baseline_outcome1_mediators_bymhcond.xlsx", replace) 	
	
******************************************************
// Supplementary
// Variation in potential mediators by gender
// And by cis/trans identity
******************************************************

// Table of potnetial mediators for outcome 1 sample
table1 if mhcond!=., by(gender) vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat ///
	) ///
	onecol saving ("$output\baseline_outcome1_mediators_bygender.xlsx", replace) 
	
// Table of potnetial mediators for outcome 1 sample
table1 if mhcond!=., by(trans) vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat ///
	) ///
	onecol saving ("$output\baseline_outcome1_mediators_bycistrans.xlsx", replace) 	
	

*******************************************************
**# Regression analysis - MH needs not met outcome
******************************************************
// Analysis
// Outcome 2: MH needs
// Overall
******************************************************

// drop stored estimates
estimates clear

local model 1

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)
 
matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\mhneeds_summary.dta", replace // save as summary because 1st model, after append
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// Add health vars (LTCs)
******************************************************

local model 2

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)
 
matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// Add health + socioeconomic vars (IMD, doing, rural)
******************************************************

local model 3

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// Add health + socioeconomic vars (IMD, doing, rural)
// + last appointment vars
******************************************************

local model 4

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural i.lastapp_when i.lastapp_who b2.lastapp_type ///
	i.cont_pref i.cont_happens ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// Add health + socioeconomic vars (IMD, doing, rural)
// + last appointment vars
// + HCP interaction vars
******************************************************

local model 5

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural i.lastapp_when i.lastapp_who b2.lastapp_type ///
	i.cont_pref i.cont_happens i.time i.listen i.care i.conf ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// just HCP interaction vars alone
******************************************************

local model 6

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	i.time i.listen i.care i.conf ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Sensitivity
// Outcome 2: MH needs
// Overall - using complete data for all mediators
// (outcome 2 set)
******************************************************

local model 7

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if complete_med_2==1 ///
	, vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix 
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Sensitivity
// Outcome 1: MH condition
// adding health and socioeconomic - 
// using complete data for all mediators
******************************************************

local model 8

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_* ///
	b5.imd_q i.doing i.rural i.lastapp_when i.lastapp_who b2.lastapp_type ///
	i.cont_pref i.cont_happens i.time i.listen i.care i.conf ///
	[pweight=wt_new] ///
	if complete_med_2==1 ///
	, vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 2: MH needs
// Overall - under 35
******************************************************

local model 9

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp<=2 ///
	, vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 2: MH needs
// Overall - 35-64
******************************************************

local model 10

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp>2 & agegp<6 ///
	, vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Age split
// Outcome 2: MH needs
// Overall - 65+
******************************************************

local model 11

// regression
logistic mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new] ///
	if agegp>=6 ///
	, vce(robust)	
estimates store m_`model'

// test for overall significance of interactions
test 2.trans#1.gender 2.trans#3.gender 2.trans#4.gender 2.trans#5.gender 3.trans#1.gender 3.trans#3.gender 3.trans#4.gender 3.trans#5.gender

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace) 

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Analysis
// Outcome 2: MH needs
// BUT WITH DIFFERENT CODING OF INCLUSION
// people who said not relevant coded as needs met
// outcome variable = "sens_mhneeds"
******************************************************

local model 12

// regression
logistic sens_mhneeds i.trans##b2.gender b6.agegp i.year i.mode ///
	[pweight=wt_new], vce(robust)	
estimates store m_`model'

// test pairwise contrasts in marginal effects based on delta-method
margins gender, at(trans=(1 2 3)) pwcompare(group) vce(unconditional) saving($output\mhneeds_compare_`model', replace)

// obtain linear predictions with confidence interval and store matrix
margins gender, at(trans=(1 2 3)) predict(xb) vce(unconditional) post // This obtains the linear prediction (non logit transformed)
transform_margins invlogit(@), matrix(C`model') // This generates CIs via endpoint transformation (not Delta-method) and stores a 3-col matrix (b,lb,ub)

matrix summary = J(15,7,.)
matrix colnames summary = outcome model trans gender b lb ub


local n = 1
foreach t in 1 2 3 {
              foreach g in 1 2 3 4 5 {
                             di `n'
                             matrix summary[`n',1] = 2 // for outcome 2
                             matrix summary[`n',2] = `model'
                             matrix summary[`n',3] = `t'
                             matrix summary[`n',4] = `g'
                             matrix summary[`n',5]= 100*C`model'[(`n'),1]
                             matrix summary[`n',6]= 100*C`model'[(`n'),2]
                             matrix summary[`n',7]= 100*C`model'[(`n'),3]
                             local n = `n'+1
                             }
}
matrix list summary

preserve
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\temp.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\temp.csv", ///
	clear rowrange(2:) colrange(2:) varnames(2)
save "$output\temp.dta", replace
use "$output\mhneeds_summary.dta", clear
append using "$output\temp.dta"
save "$output\mhneeds_summary.dta", replace
restore

******************************************************
// Export table of regressions (as odds ratios)
******************************************************

esttab m_1 m_2 m_3 m_4 m_5 m_6 m_7 m_8 m_9 m_10 m_11 m_12 ///
	using "$output/mhneeds_OR_summary.rtf", ///
	eform b(2) ci(2) label nonumbers nostar ///
	title(1 "Main" 2 "Add health" 3 "Add health and socioeconomic" ///
	4 "Add last appt" 5 "Add HCP interactions" 6 "HCP interactions only" ///
	7 "Sensitivity" 8 "Sensitivity plus mediators" 0 "Age - under 35" ///
	10 "Age - 35-64" 11 "Age - 65+" 12 "Weird code of needs") ///
	replace
	
log close	
	
********************************************************
**# Plots
******************************************************
// Tidy up summary file with predicted probabilities
// Then export for table
// And plot
******************************************************	

preserve
// open
clear all
use "$output\mhneeds_summary.dta", clear
label define genderlab 1 "Female" 2 "Male" 3 "Non-binary" ///
	4 "Prefer to self-describe" 5 "Prefer not to say"
label values gender genderlab
label var gender "Gender"

label define translab 1 "Cisgender" 2 "Transgender" 3 "Prefer not to say"
label values trans translab
label var trans "Cis/trans identity"

label define outcomelab 1 "A mental health condition" 2 "MH needs not met"
label values outcome varlab	
label var outcome "Outcome"

label define modellab 1 "Main" 2 "Add health" 3 "Add health and socioeconomic" ///
	4 "Add last appt" 5 "Add HCP interactions" 6 "HCP interactions only" ///
	7 "Sensitivity" 8 "Sensitivity plus mediators" 9 "Age - under 35" ///
	10 "Age - 35-64" 11 "Age - 65+" 12 "Weird code of needs", replace
label values model modellab

save "$output\mhneeds_summary.dta", replace	
restore

preserve
// open
clear all
use "$output\mhneeds_summary.dta", clear

// plot - loop through models
// use 0-60 scale for most models
set scheme cleanplots, perm
graph set window fontface "Arial"
foreach model in 1 2 3 4 5 6 7 8 12 {
	eclplot b lb ub trans if outcome==2 & model==`model', ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(col(1) subtitle("Gender", size(medlarge)) size(medlarge))
	graph save "$output\mhneeds_predp_model`model'.gph", replace
	graph export "$output\mhneeds_predp_model`model'.svg", replace	
	graph export "$output\mhneeds_predp_model`model'.png", replace	
}	
// 0-80 scale for age-split
set scheme cleanplots, perm
graph set window fontface "Arial"
foreach model in 9 10 11 {
	eclplot b lb ub trans if outcome==2 & model==`model', ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)80)) ylabel(0(10)80) ytick(0(5)80) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(col(1) subtitle("Gender", size(medlarge)) size(medlarge))
	graph save "$output\mhneeds_predp_model`model'.gph", replace
	graph export "$output\mhneeds_predp_model`model'.svg", replace	
	graph export "$output\mhneeds_predp_model`model'.png", replace	
}	

// Create Figure 3 in the paper
// use 0-60 scale for most models
set scheme cleanplots, perm
graph set window fontface "Arial"

	eclplot b lb ub trans if outcome==2 & model==1, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: A})
	graph save "$output\Fig3A.gph", replace
	
	eclplot b lb ub trans if outcome==2 & model==2, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge) color(white)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: B}) plotregion(margin(zero))
		graph save "$output\Fig3B.gph", replace
		
	eclplot b lb ub trans if outcome==2 & model==3, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
				ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge) color(white)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: C}) plotregion(margin(zero))
		graph save "$output\Fig3C.gph", replace

set scheme cleanplots, perm
graph set window fontface "Arial"
	eclplot b lb ub trans if outcome==2 & model==4, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
		ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: D}) plotregion(margin(zero))
	graph save "$output\Fig3D.gph", replace
	
	eclplot b lb ub trans if outcome==2 & model==5, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
				ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge) color(white)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: E}) plotregion(margin(zero))
		graph save "$output\Fig3E.gph", replace
		
	eclplot b lb ub trans if outcome==2 & model==6, ///
		supby(gender, spaceby(0.1) offset(-0.2)) /// 
		xscale(range(0.75(0.5)3.25)) xlabel(1(1)3) ///
		yscale(range(0(20)40)) ylabel(0(10)40) ytick(0(5)40) ///
		xtitle("Cis/trans identity", size(medlarge)) ///
				ytitle("Predicted probability" ///
			"(rescaled as %)", size(medlarge) color(white)) ///
		xlabel(, angle(30) labsize(medlarge)) ylabel(, labsize(medlarge)) ///
		aspect(1.2) ///
		estopts1(lwidth(vthick) lcolor(dknavy) symbol(O) color(dknavy)) ///
		ciopts1(blcolor(dknavy)) ///
		estopts2(lwidth(vthick) lcolor(midblue) symbol(S) color(midblue)) ///
		ciopts2(blcolor(midblue)) ///	
		estopts3(lwidth(vthick) lcolor(emerald) symbol(T) color(emerald)) ///
		ciopts3(blcolor(emerald)) ///
		estopts4(lwidth(vthick) lcolor(brown) symbol(D) color(brown)) ///
		ciopts4(blcolor(brown)) ///
		estopts5(lwidth(vthick) lcolor(gs8) symbol(Oh) color(gs8)) ///
		ciopts5(blcolor(gs8)) ///
		legend(off) title({bf: F}) plotregion(margin(zero))
		graph save "$output\Fig3F.gph", replace
		
graph combine $output/Fig3A.gph $output/Fig3B.gph $output/Fig3C.gph ///
$output/Fig3D.gph $output/Fig3E.gph $output/Fig3F.gph $output/legend.gph ,  holes(4) /// 
cols(4) ///
ycommon ///
graphregion(margin(l=0 r=0 b=0 t=0)) ///
scale(0.7) xsize(100) ysize(60) ///
saving($output/Fig3.gph, replace)
graph export $output/Fig3.svg, replace
graph export $output/Fig3.pdf, replace
graph export $output/Fig3.tif, replace		
		
// export to CSV ready to make tables
sort outcome model trans gender
gen prob = round(b, 0.01)
gen ll = round(lb, 0.01)
gen ul = round(ub, 0.01)
drop b lb ub
export delim using "$output\mhneeds_summary.csv", replace
restore

******************************************************
**# Assoications with potential mediators
******************************************************
// Supplementary
// Assoications between potential mediators and 
// outcome
******************************************************

// regression
logistic mhneeds ///
	b5.imd_q i.doing i.rural i.q31_* i.lastapp_when i.lastapp_who b2.lastapp_type ///
	i.cont_pref i.cont_happens i.time i.listen i.care i.conf ///
	[pweight=wt_new] , vce(robust)	
estimates store mediators

esttab mediators using "$output\mhneeds_OR_mediators.rtf", ///
	eform b(2) ci(2) label nonumbers nostar ///
	replace

// Table of potential  mediators for outcome 1 sample - by outcome
table1 if mhneeds!=., by(mhneeds) test vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat \ ///
	lastapp_when cat \ lastapp_who cat \ lastapp_type cat \ ///
	cont_pref cat \ cont_happens cat \ time cat \ listen cat \ care cat \ conf cat) ///
	onecol saving ("$output\baseline_outcome2_mediators_bymhneeds.xlsx", replace) 	
	
******************************************************
// Supplementary
// Variation in potential mediators by gender
// And by cis/trans identity
******************************************************

// Table of potential mediators for outcome 1 sample
table1 if mhneeds!=., by(gender) vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat \ ///
	lastapp_when cat \ lastapp_who cat \ lastapp_type cat \ ///
	cont_pref cat \ cont_happens cat \ time cat \ listen cat \ care cat \ conf cat) ///
	onecol saving ("$output\baseline_outcome2_mediators_bygender.xlsx", replace) 
	
// Table of potential  mediators for outcome 1 sample
table1 if mhneeds!=., by(trans) vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat \ ///
	lastapp_when cat \ lastapp_who cat \ lastapp_type cat \ ///
	cont_pref cat \ cont_happens cat \ time cat \ listen cat \ care cat \ conf cat) ///
	onecol saving ("$output\baseline_outcome2_mediators_bycistrans.xlsx", replace) 
	
******************************************************
// Supplementary
// Pairwise tests for difference between coefficients
// C(15 2)=105 pairwise comparisons
******************************************************

clear all
use $output/mhcond_compare_1, clear 
keep  _pvalue _at1 _m1 _pw
label var _pw "Comparison"
rename (_pvalue) (_pvalue1)
forvalues i=2/8 {
merge 1:1 _pw using $output/mhcond_compare_`i', keepusing( _pvalue)
keep if _merge==3
drop _merge
rename (_pvalue) (_pvalue`i')
}

gen basecat=""
replace basecat="Cis, Female" if _pw>0&_pw<15
replace basecat="Cis, Male" if _pw>14&_pw<28
replace basecat="Cis, Non-binary" if _pw>27&_pw<40
replace basecat="Cis, Self-describe" if _pw>39&_pw<51
replace basecat="Cis, Prefer not to say" if _pw>50&_pw<61

replace basecat="Trans, Female" if _pw>60&_pw<71
replace basecat="Trans, Male" if _pw>69&_pw<78
replace basecat="Trans, Non-binary" if _pw>77&_pw<85
replace basecat="Trans, Self-describe" if _pw>84&_pw<91
replace basecat="Trans, Prefer not to say" if _pw>90&_pw<96

replace basecat="Prefer not to say, Female" if _pw>95&_pw<100
replace basecat="Prefer not to say, Male" if _pw>99&_pw<103
replace basecat="Prefer not to say, Non-binary" if _pw>102&_pw<105	
replace basecat="Prefer not to say, Self-describe" if _pw==105

drop _pw

order basecat _at1 _m1, first

export delim using "$output\mhcond_compare_all.csv", replace

clear all
use $output/mhneeds_compare_1, clear 
keep  _pvalue _at1 _m1 _pw
label var _pw "Comparison"
rename (_pvalue) (_pvalue1)
forvalues i=2/12 {
merge 1:1 _pw using $output/mhneeds_compare_`i', keepusing(_pvalue)
keep if _merge==3
drop _merge
rename (_pvalue) (_pvalue`i')
}

gen basecat=""
replace basecat="Cis, Female" if _pw>0&_pw<15
replace basecat="Cis, Male" if _pw>14&_pw<28
replace basecat="Cis, Non-binary" if _pw>27&_pw<40
replace basecat="Cis, Self-describe" if _pw>39&_pw<51
replace basecat="Cis, Prefer not to say" if _pw>50&_pw<61

replace basecat="Trans, Female" if _pw>60&_pw<71
replace basecat="Trans, Male" if _pw>69&_pw<78
replace basecat="Trans, Non-binary" if _pw>77&_pw<85
replace basecat="Trans, Self-describe" if _pw>84&_pw<91
replace basecat="Trans, Prefer not to say" if _pw>90&_pw<96

replace basecat="Prefer not to say, Female" if _pw>95&_pw<100
replace basecat="Prefer not to say, Male" if _pw>99&_pw<103
replace basecat="Prefer not to say, Non-binary" if _pw>102&_pw<105	
replace basecat="Prefer not to say, Self-describe" if _pw==105

drop _pw

order basecat _at1 _m1, first

export delim using "$output\mhneeds_compare_all.csv", replace