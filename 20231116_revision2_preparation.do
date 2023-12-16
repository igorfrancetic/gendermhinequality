/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Paper: Gender-related self-reported mental health inequalities in primary care in England: Cross-sectional 
// analysis using the GP Patient Survey (Watkinson R, Linfield A, Tielemans J, Francetic I, Munford L)
// Analysis by: Watkinson, Francetic, Munford
// Do-file version: 16/11/2023
// Do-file title: Preparation
////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
This do-file includes cleaning of raw data, defining and labelling key variables to prepare the final dataset
used for the analysis. The dofile is called by the main "Analysis" dataset but can also be launched independently.
The do-file is set to read/write on the following folders, which should exist in the root folder you work in:
- Reading raw data from "Raw_data"
- Save processed data in "Processed_data"
- Export outputs to "Outputs"
*/

************************************************
**# Setting folders
************************************************
clear all
set more off

// set your root directory
global root "X:\your_root_directory"

// set globals for sub folders
global datain "$root\Raw_data"
global dataout "$root\Processed_data\revision_analysis"
global output "$root\Output"

************************************************
**# Cleaning - assembling file
************************************************

// open 2022 file
use "$datain\GPPS_raw_2022.dta", clear
gen year = 2022

// append 2021 file
append using "$datain\GPPS_raw_2021.dta"
// 1,569,343 obs

replace year = 2021 if year==.

// keep only relevant variables
keep q83 q107 q84 q86a q86b q86e q87 q89 q107 q84 q28 ///
	q31* q112 q113 q49 q48_merged q50 q57 ///
	q56 q8 q9 ///
	practice_name practice_code practice_pop_size ///
	practice_ru11ind practice_ru11des patient_imd_decile la_id_ons ///
	wt_new year mode
drop q31_17 // this is "don't have any LTCs" but only need the indicators	

************************************************
**# Cleaning - main outcomes
************************************************

// core outcomes

// main labels
label define ynlab 0 "Yes" 1 "No" 9 "Missing", replace
label define nylab 0 "No" 1 "Yes" 9 "Missing", replace

// Sensitivity analysis for MH needs met - new variable

tab q87, mi
gen sens_mhneeds = .
replace sens_mhneeds = 0 if q87<=2 & q87!=.
replace sens_mhneeds = 0 if q87>3 & q87!=. // the change is just this line
replace sens_mhneeds = 1 if q87==3
tab q87 sens_mhneeds, mi
label values sens_mhneeds ynlab
label var sens_mhneeds "Mental health needs met (sensitivity)"
tab sens_mhneeds, mi // now 9% missing

// MH needs met

tab q87, mi
gen mhneeds = .
replace mhneeds = 0 if q87<=2 & q87!=.
replace mhneeds = 1 if q87==3
tab q87 mhneeds, mi
label values mhneeds ynlab
label var mhneeds "Mental health needs met"
drop q87

// MH

tab q31_14, mi
rename q31_14 mhcond
label values mhcond nylab
label var mhcond "Mental health condition"	



**# Cleaning - main exposures

*** Revision change is that mode is now included
*** (no changes made to coding tho - used as is)

***************************************************

// core exposures 

// Gender

tab q112, mi
rename q112 gender
label define genderlab 1 "Female" 2 "Male" 3 "Non-binary" ///
	4 "Prefer to self-describe" 5 "Prefer not to say", replace
label values gender genderlab
label variable gender "Gender"

// Cis/trans

tab q113, mi
rename q113 trans
label define translab 1 "Cisgender" 2 "Transgender" 3 "Prefer not to say"
label values trans translab
label variable trans "Cis/trans identity"

// Age

tab q48_merged, mi
rename q48_merged agegp

rename agegp origage
gen agegp =.
replace agegp=1 if origage==2
replace agegp=2 if origage==3
replace agegp=3 if origage==4
replace agegp=4 if origage==5
replace agegp=5 if origage==6
replace agegp=6 if origage==7
replace agegp=7 if origage==8
replace agegp=7 if origage==9

label define agelab 1 "16-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" ///
	6 "65-74" 7 "75+", replace
label values agegp agelab
label variable agegp "Age group"

tab agegp origage, mi
drop origage

// year needs to be binary indicator (currently numeric)

rename year origyear
gen year =.
replace year = 1 if origyear==2021
replace year = 2 if origyear==2022
label define yearlab 1 "2021" 2 "2022"
label values year yearlab
tab year origyear
drop origyear

// check mode variables
tab mode, mi
// no missing data
// binary variable: scanned vs online
// 38.71% online, 61.29% scanned
// variable labeled as "collection mode"
tab mode, nolab
// coded as 1 and 3, this is fine for now, leave as is


*** No revision changes made in any of these data cleaning sections
*** All as previsouly up to save of dataset

**# Cleaning - potential mediators
************************************************
// Potential mediators
************************************************

**# Cleaning - socioeconomic variables
************************************************
// socioeconomic

// make 3 categories
// major urban conerbation, urban other, rural
encode practice_ru11des, gen(enc_rural)
tab enc_rural, mi
tab enc_rural, nolab
generate rural = .
replace rural =1 if enc_rural==9
replace rural =2 if enc_rural==10
replace rural =2 if enc_rural==8
replace rural =2 if enc_rural==7
replace rural =3 if enc_rural<=6 & enc_rural != .
label define urbanlab 1 "Major urban conurbation" 2 "Urban other" 3 "Rural" ///
	9 "Missing", replace
label values rural urbanlab
tab rural practice_ru11des
label var rural "Urban/rural area"
drop practice_ru11des
drop practice_ru11ind
drop enc_rural

// employment / doing at the moment
tab q50, mi
tab q50, nolab
gen doing=.
replace doing=1 if q50==1
replace doing=1 if q50==2
replace doing=2 if q50==3
replace doing=3 if q50==4
replace doing=3 if q50==5
replace doing=4 if q50==6
replace doing=5 if q50==7
replace doing=5 if q50==8
label define doinglab 1 "Paid employment" 2 "Full-time education" ///
	3 "Unemployed, long-term sick, or disabled" 4 "Fully retired" ///
	5 "Looking after home/family, or doing something else" 9 "Missing", replace
label values doing doinglab
label var doing "Currently doing"
tab doing q50, mi
drop q50	

// add IMD quintiles (have decile)
gen imd_q = .
replace imd_q = 1 if patient_imd_decile==1
replace imd_q = 1 if patient_imd_decile==2
replace imd_q = 2 if patient_imd_decile==3
replace imd_q = 2 if patient_imd_decile==4
replace imd_q = 3 if patient_imd_decile==5
replace imd_q = 3 if patient_imd_decile==6
replace imd_q = 4 if patient_imd_decile==7
replace imd_q = 4 if patient_imd_decile==8
replace imd_q = 5 if patient_imd_decile==9
replace imd_q = 5 if patient_imd_decile==10

label variable imd_q "IMD quintile"
label define imdlab 1 "Q1 (most deprived)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (least deprived)" 9 "Missing", replace
label values imd_q imdlab
tab imd_q, mi
tab imd_q patient_imd_decile
label var imd_q "Deprivation quintile"
drop patient_imd_decile


**# Cleaning - appointment variables
***************************************************

// appointment

// sorting out last appointment variables
// q83 = when was last appt
tab q83, mi
tab q83, nolab
rename q83 lastapp_when
label variable lastapp_when "When last appointment occurred"
tab lastapp_when
label define whenlab 1 "<3 months" 2 "3-6 months" 3 "6-12 months" ///
	4 "12+ months" 5 "None at this practice" 9 "Missing", replace
label values lastapp_when whenlab	
tab lastapp_when

// q107 = what type was last appt
tab q107, mi
tab q107, nolab
rename q107 lastapp_type
label variable lastapp_type "Last appointment type"
tab lastapp_type
label define typelab 1 "Telephone" 2 "At GP practice" ///
	3 "At other GP location" 4 "Online" 5 "Home visit" 9 "Missing", replace
label values lastapp_type typelab
tab lastapp_type

// q84 = who was last app with
tab q84, mi
tab q84, nolab
rename q84 lastapp_who
label variable lastapp_who "Who last appt was with"
tab lastapp_who
label define wholab 1 "GP" 2 "Nurse" 3 "Pharmacist" 4 "MH professional" ///
	5 "Other HCP" 6 "Don't know" 9 "Missing", replace
label values lastapp_who wholab	
tab lastapp_who		

// continuity

// continuity - preferred GP
tab q8, mi
tab q8, nolab
gen cont_pref=.
replace cont_pref=0 if q8==1
replace cont_pref=0 if q8==3
replace cont_pref=0 if q8==4
replace cont_pref=1 if q8==2
label values cont_pref ynlab
label variable cont_pref "Has preferred GP"
tab cont_pref q8, mi
drop q8

// continuity - able to see
tab q9, mi
tab q9, nolab
gen cont_happens=.
replace cont_happens=1 if q9==1
replace cont_happens=1 if q9==2
replace cont_happens=2 if q9==3
replace cont_happens=2 if q9==4
replace cont_happens=3 if q9==5
replace cont_happens=3 if q9==. & cont_pref==1
label define haplab 1 "Always/a lot of the time" 2 "Sometimes / never" ///
	3 "Haven't tried / not relevant" 9 "Missing", replace
label values cont_happen haplab	
label variable cont_happen "Able to see preferred GP"
tab cont_happen q9, mi
drop q9



**# Cleaning - health (ltc) variables
***********************************************

// health

rename q31_1 q31_alzheimers
tab q31_alzheimers, missing
label var q31_alzheimers "Alzheimer's disease / dementia"
label values q31_alzheimers nylab
tab q31_alzheimers

rename q31_3 q31_arthritis
tab q31_arthritis, missing
label var q31_arthritis "Arthritis / back/joints problems"
label values q31_arthritis nylab
tab q31_arthritis

rename q31_21 q31_autism
tab q31_autism, missing
label var q31_autism "Autism / autism spectrum condition"
label val q31_autism nylab
tab q31_autism

rename q31_5 q31_blindness
tab q31_blindness, missing
label var q31_blindness "Blindness / partial sight"
label values q31_blindness nylab
tab q31_blindness

rename q31_4 q31_breathing
tab q31_breathing, missing
label var q31_breathing "Breathing condition"
label val q31_breathing nylab
tab q31_breathing

rename q31_6 q31_cancer
tab q31_cancer, missing
label var q31_cancer "Cancer (last 5 yrs)"
label values q31_cancer nylab
tab q31_cancer

rename q31_7 q31_deafness
tab q31_deafness, missing
label var q31_deafness "Deafness / hearing loss"
label val q31_deafness nylab
tab q31_deafness

rename q31_8 q31_diabetes
tab q31_diabetes, missing
label var q31_diabetes "Diabetes"
label val q31_diabetes nylab
tab q31_diabetes

rename q31_2 q31_heart
tab q31_heart, missing
label var q31_heart "Heart condition"
label val q31_heart nylab
tab q31_heart

rename q31_10 q31_hbp
tab q31_hbp, missing
label var q31_hbp "High blood pressure"
label val q31_hbp nylab
tab q31_hbp

rename q31_11 q31_kidney
tab q31_kidney, missing
label var q31_kidney "Kidney or liver disease"
label val q31_kidney nylab
tab q31_kidney

rename q31_19 q31_learning
tab q31_learning, missing
label var q31_learning "Learning disability"
label val q31_learning nylab
tab q31_learning

rename q31_15 q31_neurological
tab q31_neurological, missing
label var q31_neurological "Neurological condition"
label val q31_neurological nylab
tab q31_neurological

rename q31_20 q31_stroke
tab q31_stroke, missing
label var q31_stroke "Stroke"
label val q31_stroke nylab
tab q31_stroke

rename q31_16 q31_other
tab q31_other, missing
label var q31_other "Other long-term condition"
label val q31_other nylab
tab q31_other



**# Cleaning - HCP interaction variables
***********************************************

// HCP interactions

// HCP - time
	
tab q86a, mi
gen time = .
replace time = 0 if q86a<=3 & q86a!=.
replace time = 1 if q86a==4
replace time = 1 if q86a==5
tab q86a time, mi
label define gblab 0 "Good (or neutral)" 1 "Poor" 9 "Missing", replace
label values time gblab
label var time "Given enough time at appointment"
drop q86a

// listen

tab q86b, mi
gen listening = .
replace listening = 0 if q86b<=3 & q86b!=.
replace listening = 1 if q86b==4
replace listening = 1 if q86b==5
tab q86b listen, mi
label values listen gblab
label var listen "Felt listened to at appointment"
drop q86b

// care and concern

tab q86e, mi
gen careandconcern = .
replace careandconcern = 0 if q86e<=3 & q86e!=.
replace careandconcern = 1 if q86e==4
replace careandconcern = 1 if q86e==5
tab q86e care, mi
label values care gblab
label var care "Treated with care and concern at appointment"
drop q86e

// confidence and trust

tab q89, mi
gen confandtrust = .
replace confandtrust = 0 if q89<=2 & q89!=.
replace confandtrust = 1 if q89==3
tab q89 confandtrust, mi
label define ynlab 0 "Yes (or neutral)" 1 "No" 9 "Missing", replace
label values conf ynlab
label var conf "Had confidence and trust in HCP at appointment"
drop q89

*******************************************
** Sorting missing data
*******************************************

// generate complete data indicators
ds, has(type numeric)
gen complete_med_1=. // for 1st set of mediators
gen complete_med_2=. // for full set of mediators

replace complete_med_1=1 if ///
imd_q!=. & doing!=. & rural!=. & ///  
q31_arthritis!=. & q31_diabetes!=. & q31_neurol!=. & q31_blindn!=. & ///
	q31_hbp!=. & q31_other!=. & q31_autism!=. & q31_heart!=. & q31_stroke!=. & ///
	q31_alzhei!=. & q31_deafness!=. & q31_cancer!=. & q31_learning!=. & ///
	q31_breath!=. & q31_kidney!=.

tab complete_med_1, mi	// 87.01% (1,322,951)
	
replace complete_med_2=1 if ///
imd_q!=. & doing!=. & rural!=. & ///  
q31_arthritis!=. & q31_diabetes!=. & q31_neurol!=. & q31_blindn!=. & ///
	q31_hbp!=. & q31_other!=. & q31_autism!=. & q31_heart!=. & q31_stroke!=. & ///
	q31_alzhei!=. & q31_deafness!=. & q31_cancer!=. & q31_learning!=. & ///
	q31_breath!=. & q31_kidney!=. & ///          
cont_happens!=. & cont_pref!=. & ///
lastapp_when!=. & lastapp_type!=. & lastapp_who!=. & ///
time!=. & listening!=. & careandcon!=. & confandtrust!=.

tab complete_med_2, mi // 69.74% (1,060,306)

// change missing to 9 for all so no automatically excluded in regressions
// (but not for outcome vars - keep as true missing)
recode imd_q doing rural q31_* cont_* lastapp* time listen care conf (.=9)

**** Updated all the value labels to include 9 as "Missing"

// remainder of missing data flow chart
count if mhcond!=. // 1,365,598
tab complete_med_1 if mhcond!=., mi // 42,647 (3.12%)
count if mhcond!=. & complete_med_1==1 // 1,322,951 (84.3% of starting total)

count if mhneeds!=. // 624,388
tab complete_med_2 if mhneeds!=., mi // 153,588 (24.60%)
count if mhneeds!=. & complete_med_2==1 // 470,800 (30.0% of starting total)


// compress and save file
compress
save "$dataout\GPPS_final_2021_2022.dta", replace