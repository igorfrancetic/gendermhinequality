/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Paper: Gender-related self-reported mental health inequalities in primary care in England: Cross-sectional 
// analysis using the GP Patient Survey (Watkinson R, Linfield A, Tielemans J, Francetic I, Munford L)
// Analysis by: Watkinson, Francetic, Munford
// Version: 16/11/2023
// Do-file title: Descriptive statistics
////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
This do-file produced all descriptive statistics reported in figures and tables in the paper. 
It is called by the main do-file running all analyses (20231116_revision2_analysis.do).

To generate outputs it uses the following Stata packages:
- asdocx (https://asdocx.com/)
- esttab (available from SSC)
- table1 (available from SSC)
- heatplot (available from SSC)
- cleanplots (available from SSC)

************************************************
**# Installing/Updating SSC packages
************************************************
ssc install estout, replace
ssc install table1, replace
ssc install heatplot, replace
ssc install cleanplots, replace
*/

******************************************************
**# Descriptive - baseline tables
******************************************************
// Descriptive stats
// Baseline tables
******************************************************

/* 
Create indicators for 3 big groups to generate descriptives:
i.	 Characteristics of respondents with no missing on main exposures
ii.	 Characteristics of sample with no missing for outcome 1 (subset of i.)
iii. Characteristics of sample with no missing for outcome 2 (subset of i.)
*/

gen sample1=1 if gender!=. & trans!=. & agegp!=.
qui: reg mhcond i.trans##b2.gender b6.agegp i.year i.mode [pweight=wt_new]
gen sample2=1 if e(sample)
qui: reg mhneeds i.trans##b2.gender b6.agegp i.year i.mode i.q31_*[pweight=wt_new], vce(robust)	
gen sample3=1 if e(sample)

forvalues i=1/3 {

// Table 1 - demographics and main outcomes
table1 if sample`i'==1, vars( ///
	gender cat \ trans cat \ agegp cat \ year cat \ mode cat \ mhcond cat \ mhneeds cat ) ///
	onecol saving ("$output\baseline_main`i'.xlsx", replace)

// use proportion to get weighted proportions as additional information for table 1
prop gender [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop trans [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop agegp [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop year [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop mode [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop mhcond [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
prop mhneeds [pweight=wt_new] if sample`i'==1, percent cformat(%4.1f)
tab mhcond if sample`i'==1, miss
tab mhneeds if sample`i'==1, miss
	
// Table of potential mediators for outcome 1 sample
table1 if sample`i'==1, vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat ///
	) ///
	onecol saving ("$output\baseline_outcome1_mediators`i'.xlsx", replace) 

// Table of potential mediators for outcome 2 sample
table1 if sample`i'==1, vars( ///
	imd_q cat \ doing cat \ rural cat \ ///
	q31_al cat \ q31_arth cat \ ///
	q31_aut cat \ q31_blind cat \ q31_breath cat \ q31_cancer cat \ ///
	q31_deaf cat \ q31_diab cat \ q31_heart cat \ q31_hbp cat \ ///
	q31_kid cat \ q31_learn cat \ q31_neuro cat \ q31_stroke cat \ q31_o cat \ ///
	lastapp_when cat \ lastapp_who cat \ lastapp_type cat \ ///
	cont_pref cat \ cont_happen cat \ ///
	time cat \ listen cat \ care cat \ conf cat ) ///
	onecol saving ("$output\baseline_outcome2_mediators`i'.xlsx", replace) 
}


// set survey design so weighted counts and percentages and chisq test
svyset, clear
svyset [pweight=wt_new]

// use asdoc with svy and tab to export weighted table, include missing

// First: by gender, for MH cond sample
asdocx svy: tab gender i.trans i.agegp i.year i.mode i.mhcond ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\gendersplit_desc_mhcondsample.docx"") replace
	   
// 2nd: by trans, for MH cond sample
asdocx svy: tab trans i.gender i.agegp i.year i.mode i.mhcond ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\transsplit_desc_mhcondsample.docx") replace	
	
// 3rd: by gender, for MH needs sample
asdocx svy: tab gender i.trans i.agegp i.year i.mode i.mhneeds ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	i.lastapp_when i.lastapp_who i.lastapp_type ///
	i.cont_pref i.cont_happen ///
	i.time i.listen i.care i.conf ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\gendersplit_desc_mhneedssample.docx") replace

// 4th: by trans, for MH needs sample
asdocx svy: tab trans i.gender i.agegp i.year i.mode i.mhneeds ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	i.lastapp_when i.lastapp_who i.lastapp_type ///
	i.cont_pref i.cont_happen ///
	i.time i.listen i.care i.conf ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\transsplit_desc_mhneedssample.docx") replace	

	
// 5th: by MH cond, for MH cond sample
asdocx svy: tab mhcond i.gender i.trans i.agegp i.year i.mode ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\mhcondsplit_desc_mhcondsample.docx") replace		
	
// 6th: by mh needs, for MH needs sample
asdocx svy: tab mhneeds i.gender i.trans i.agegp i.year i.mode ///
	i.imd_q i.doing i.rural  ///
	i.q31_al i.q31_arth i.q31_aut i.q31_blind i.q31_breath i.q31_cancer ///
	i.q31_deaf i.q31_diab i.q31_heart i.q31_hbp i.q31_kid i.q31_learn ///
	i.q31_neuro i.q31_stroke i.q31_o ///
	i.lastapp_when i.lastapp_who i.lastapp_type ///
	i.cont_pref i.cont_happen ///
	i.time i.listen i.care i.conf ///
	if sample1==1, ///
	missing factor(N %) col dec(1) ///
	template(table1) table_layout(autofit) ///
	save("$output\mhneedssplit_desc_mhneedssample.docx") replace	

******************************************************
**# Descriptive - proportions gender / cis/trans / age
******************************************************
// Descriptive stats
// Proportions by gender / cis/trans / age
******************************************************	

// Check observation numbers for age splits
gen id = _n 
svyset id [pweight=wt_new]

tab agegp	
tab agegp, nolab // 1,2 - 3,4,5 - 6,7
	
tab gender trans if mhcond!=. & agegp<=2
tab gender trans if mhcond!=. & agegp>2 & agegp<=5
tab gender trans if mhcond!=. & agegp>5

tab gender trans if mhneeds!=. & agegp<=2	
tab gender trans if mhneeds!=. & agegp>2 & agegp<=5	
tab gender trans if mhneeds!=. & agegp>5					

// make grouped variable with labels
egen gxt = group(gender trans), label
tab gxt

// Create plot for sample1
preserve
keep if sample1==1
// proportions
// under 35s
proportion gxt if agegp<=2 ///
	[pweight=wt_new]
				
// results to matrix
matrix results = r(table)
matrix r1 = 100*results'
matrix define s1 = J(15,1,1)
matrix group = (1\2\3\4\5\6\7\8\9\10\11\12\13\14\15)
matrix summary1 = (s1, group, r1)

// proportions
// 35 to 64
proportion gxt if agegp>2 & agegp<=5 ///
	[pweight=wt_new]

matrix results2 = r(table)
matrix r2 = 100*results2'
matrix define s2 = J(15,1,2)
matrix summary2 = (s2, group, r2)
		
// proportions
// 65+
proportion gxt if agegp>5 ///
	[pweight=wt_new]
		
matrix results3 = r(table)
matrix r3 = 100*results3'				
matrix define s3 = J(15,1,3)
matrix summary3 = (s3, group, r3)

//combine				
matrix summary = (summary1 \ summary2 \ summary3)
matrix list summary	
	
// export
esttab matrix(summary, fmt(%4.3f)) using "$output\gender_trans_agecat.csv", ///
	onecell nogap compress plain replace
// import to dataset
import delimited using "$output\gender_trans_agecat.csv", ///
	clear rowrange(2:) colrange(1:) varnames(2)
save "$output\gender_trans_agecat.dta", replace 

// tidy up and label etc
rename c1 agecat
rename v3 gxt
keep agecat gxt b ll ul

gen gender=.
replace gender =1 if gxt <=3
replace gender =2 if gxt >3 & gxt <=6
replace gender =3 if gxt >6 & gxt <=9
replace gender =4 if gxt >9 & gxt <=12
replace gender =5 if gxt >12

label define genderlab 1 "Female" 2 "Male" 3 "Non-binary" ///
	4 "Prefer to self-describe" 5 "Prefer not to say"
label values gender genderlab
	
gen gender2 = 6 - gender
label define genderlab2 5 "Female" 4 "Male" 3 "Non-binary" ///
		2 "Prefer to self-describe" 1 "Prefer not to say"	
label values gender2 genderlab2	
label variable gender "Gender"

gen trans=.
replace trans=1 if gxt==1 | gxt==4 | gxt==7 | gxt==10 | gxt==13
replace trans=2 if gxt==2 | gxt==5 | gxt==8 | gxt==11 | gxt==14
replace trans=3 if gxt==3 | gxt==6 | gxt==9 | gxt==12 | gxt==15

label define translab 1 "Cisgender" 2 "Transgender" 3 "Prefer not to say"
label values trans translab
	
label define agelab 1 "16-34" 2 "35-64" 3 "65+"
label values agecat agelab
label variable agecat "Age group"

label variable b "%"

save "$output\gender_trans_agecat.dta", replace
	
// plot
set scheme cleanplots, perm
graph set window fontface "Arial"
		
// heat maps	
// <35
heatplot b i.gender2 i.trans if agecat==1, discrete(1) ///
	color(viridis, rev  intensity(0.7)) ///
	values(format(%4.2f) size(medium)) ///
	ylabel(, nogrid labsize(medium)) ///
	xlabel(, angle(45) nogrid labsize(medium)) ///
	ytitle("Gender", size(medium)) ///
	xtitle("Cis/trans identity", size(medium)) ///
	ysize(2) xsize(2.2) ///
	cuts(0(0.02)0.8)  ///
	ramp(space(12) length(60)  label(0(0.2)0.8) right) ///	
	p(lcolor(white) lwidth(*0.05))

graph save "$output\gender_trans_u35.gph", replace
graph export "$output\gender_trans_u35.png", replace	
graph export "$output\Fig1A.svg", replace	
	
	
// 35-64
heatplot b i.gender2 i.trans if agecat==2, discrete(1) ///
	color(viridis, rev intensity(0.7)) ///
	values(format(%4.2f) size(medium)) ///
	ylabel(, nogrid labsize(medium)) ///
	xlabel(, angle(45) nogrid labsize(medium)) ///
	ytitle("Gender", size(medium)) ///
	xtitle("Cis/trans identity", size(medium)) ///
	ysize(2) xsize(2.2) ///
	cuts(0(0.02)0.8)  ///
	ramp(space(12) length(60)  label(0(0.02)0.8) right) ///	
	p(lcolor(white) lwidth(*0.05)) 
	
graph save "$output\gender_trans_35-64.gph", replace
graph export "$output\gender_trans_35-64.png", replace
graph export "$output\Fig1B.svg", replace	

// 65+
heatplot b i.gender2 i.trans if agecat==3, discrete(1) ///
	color(viridis, rev intensity(0.7)) ///
	values(format(%4.2f) size(medium)) ///
	ylabel(, nogrid labsize(medium)) ///
	xlabel(, angle(45) nogrid labsize(medium)) ///
	ytitle("Gender", size(medium)) ///
	xtitle("Cis/trans identity", size(medium)) ///
	ysize(2) xsize(2.2) ///
	cuts(0(0.02)0.8)  ///
	ramp(space(12) length(60)  label(0(0.02)0.8) right) ///
	p(lcolor(white) lwidth(*0.05)) 

graph save "$output\gender_trans_65plus.gph", replace
graph export "$output\gender_trans_65plus.png", replace	
graph export "$output\Fig1C.svg", replace	
	

// for legend	
heatplot b i.gender2 i.trans if agecat==1 & trans!=1, discrete(1) ///
	color(viridis, rev intensity(0.7)) ///
	values(format(%4.2f) size(medium)) ///
	ylabel(, nogrid labsize(medium)) ///
	xlabel(, angle(45) nogrid labsize(medium)) ///
	ytitle("Gender", size(medium)) ///
	xtitle("Cis/trans identity", size(medium)) ///
	ysize(2) xsize(2.2) ///
	cuts(0(0.02)0.8)  ///
	ramp(space(12) length(60)  label(0(0.2)0.8) right) ///	
	p(lcolor(white) lwidth(*0.05)) 

graph save "$output\gender_trans_scale.gph", replace
graph export "$output\gender_trans_scale.png", replace
graph export "$output\Fig1_legend.svg", replace
restore