* ##################
* Infosys project
* Feb 06 2026 
* Project level analysis
* clean do file 
* ####################



clear all 

* gl work "/Users/wangjin/Desktop/Infosys"
gl work "/Users/wangjin/Desktop/Infosys_drive"
* gl work "/Volumes/Extreme_SSD/Infosys_drive"

gl data "$work/data_batch_Sep2025"
gl output "$work/output"

cd $data 


* Create a string for today's date (YYYY-MM-DD format)
local today : display %tdCY-N-D daily("`c(current_date)'","DMY")
* Define a base output folder (adjust path!)
local base "$output"
* Build today's directory path
local outdir "`base'/`today'"
* Create the directory if it does not exist
capture mkdir "`outdir'"


cd $work/data_batch_Dec2025

	* ------------------------------
	* read in new quarterly month from Sreeram (Dec 17th)
	* ------------------------------
	
	import delimited using "quarterly_team_manager_fte.csv", clear 

		
	*------------------------------------------------------------
	* Labels year quarter variable for plotting later 
	* data contains 2022q1 to 2026q4 ????
	*------------------------------------------------------------
	cap drop tq
	gen int tq = yq(fiscal_year, quarter)
	format tq %tq 
	tab tq
		
	* collapse (mean) team_size_fte manager_fte, by(master_project_code tq)
	
	save "$data/quarterly_team_manager_fte_Dec2025.dta", replace 
	
		* ------------------------------
		* read the quarterly data from Sreeram and save into STATA format 
		* data contains 2022q1 to 2025 q4
		* ------------------------------
		
		* edu cat 
		import delimited using "Employee_Education_by_Master_Project_Quarter.csv", clear
		
		cap drop tq
		gen int tq = yq(fiscal_year, quarter)
		format tq %tq 
		tab tq 
	
		keep master_project_code education_category percentage tq
		
		ren education_category edu_cat
		ren percentage perc
		
		
		gen str32 edu_key = lower(trim(edu_cat))
		replace edu_key = "none" if inlist(edu_key, "-", "", ".")
		
		* Replace unsafe characters with underscores / words
		replace edu_key = subinstr(edu_key, " ", "_", .)
		replace edu_key = subinstr(edu_key, "/", "_", .)
		replace edu_key = subinstr(edu_key, "&", "and", .)
		replace edu_key = subinstr(edu_key, "(", "", .)
		replace edu_key = subinstr(edu_key, ")", "", .)
		replace edu_key = subinstr(edu_key, ".", "", .)
		replace edu_key = subinstr(edu_key, "-", "_", .)
		replace edu_key = subinstr(edu_key, ":", "_", .)
		replace edu_key = subinstr(edu_key, ",", "_", .)

		* Collapse repeated underscores
		while strpos(edu_key, "__") {
			replace edu_key = subinstr(edu_key, "__", "_", .)
		}

		* Ensure it starts with a letter (Stata requirement for varnames)
		replace edu_key = "edu_" + edu_key if !regexm(edu_key, "^[a-z]")
		
		drop edu_cat

		* If there are duplicate rows per (project, tq, edu_key), resolve before reshape:
		* (uncomment one of the following if reshape complains with r(451))
		* duplicates report master_project_code tq edu_key
		* collapse (mean) perc, by(master_project_code tq edu_key)  // or (sum)

		* ---- Reshape ----
		reshape wide perc, i(master_project_code tq) j(edu_key) string
						
		save "$data/project_quarter_education_cat_Dec2025.dta", replace 

		
		* role cat 
	
		import delimited using "Employee_Roles_by_Master_Project_Quarter.csv", clear
		
		cap drop tq
		gen int tq = yq(fiscal_year, quarter)
		format tq %tq 
		tab tq 
	
		keep master_project_code role_category percentage tq
				
		ren role_category role_cat
		ren percentage perc
			
	
		gen str32 role_key = lower(trim(role_cat))
		replace role_key = "none" if inlist(role_key, "-", "", ".")
		
		* Replace unsafe characters with underscores / words
		replace role_key = subinstr(role_key, " ", "_", .)
		replace role_key = subinstr(role_key, "/", "_", .)
		replace role_key = subinstr(role_key, "&", "and", .)
		replace role_key = subinstr(role_key, "(", "", .)
		replace role_key = subinstr(role_key, ")", "", .)
		replace role_key = subinstr(role_key, ".", "", .)
		replace role_key = subinstr(role_key, "-", "_", .)
		replace role_key = subinstr(role_key, ":", "_", .)
		replace role_key = subinstr(role_key, ",", "_", .)

		* Collapse repeated underscores
		while strpos(role_key, "__") {
			replace role_key = subinstr(role_key, "__", "_", .)
		}

		* Ensure it starts with a letter (Stata requirement for varnames)
		replace role_key = "role_" + role_key if !regexm(role_key, "^[a-z]")

		drop role_cat

		* ---- Reshape ----
		reshape wide perc, i(master_project_code tq) j(role_key) string
						
		save "$data/project_quarter_role_cat_Dec2025.dta", replace 
	
	
		* tenure cat 
		* data contains 2022q1 to 2025 q4
	
		import delimited using "Employee_Tenure_by_Master_Project_Quarter.csv", clear
		
		cap drop tq
		gen int tq = yq(fiscal_year, quarter)
		format tq %tq 
	
		keep master_project_code tenure_category percentage tq employee_count
				
		ren tenure_category ten_cat
		ren percentage perc
			
			
		gen str32 ten_key = lower(trim(ten_cat))
		replace ten_key = "none" if inlist(ten_key, "-", "", ".")
		
		* Example variable: ten_key
		replace ten_key = trim(ten_key)

		* Replace triple or multiple underscores
		while strpos(ten_key, "__") {
			replace ten_key = subinstr(ten_key, "__", "_", .)
		}

		* Replace the "<" and ">" symbols with text equivalents
		replace ten_key = subinstr(ten_key, "<", "", .)

		gen ten_id = .
		replace ten_id = 1 if ten_key == "0 - 3"
		replace ten_id = 2 if ten_key == "3 - 6"
		replace ten_id = 3 if ten_key == "6 - 9"
		replace ten_id = 4 if ten_key == "9 - 12"
		replace ten_id = 5 if ten_key == "12 - 15"
		replace ten_id = 6 if ten_key == ">15"
		replace ten_id = 7 if ten_key == "unknown"

		tab ten_id, sum(perc)
		table (tq) if ten_id == 7 , statistic(median perc)
		table (tq) if ten_id == 7 , statistic(mean perc)
		
		drop ten_cat ten_key
		
		* ---- Reshape ----
		reshape wide perc employee_count, i(master_project_code tq) j(ten_id) 
		
		egen perc_ten = rsum(perc1 perc2 perc3 perc4 perc5 perc6 perc7)
						
		save "$data/project_quarter_tenure_cat_Dec2025.dta", replace 
		
	
		* merging all thre variables 
			
		u "$data/project_quarter_tenure_cat_Dec2025.dta", clear 
		
		merge 1:1 master_project_code tq using "$data/project_quarter_role_cat_Dec2025"
	
		cap drop _m 
		
		merge 1:1 master_project_code tq using "$data/project_quarter_education_cat_Dec2025"
	
		cap drop _m 
		
		save "$data/project_quarter_org_cat_Dec2025.dta", replace
	
	

	/*
	cd $data

	* ------------------------------
	* read the monthly data from Yarong and aggregate into quarterly level 
	* ------------------------------
	
	import delimited using "final_output.csv", clear 
	
	*------------------------------------------------------------
	* (2) identify quarters and aggregate the adoption timing to quarterly level  
	*------------------------------------------------------------
	gen quarter = 1 if month >=1 & month<=3
	replace quarter = 2 if month >=4 & month<=6
	replace quarter = 3 if month >=7 & month<=9
	replace quarter = 4 if month >=10 & month<=12
		
	*------------------------------------------------------------
	* (3) Labels year quarter variable for plotting later 
	*------------------------------------------------------------
	cap drop tq
	gen int tq = yq(year, quarter)
	format tq %tq 
		
	gen num_mgmt = role_count if role_type == "Manager"
	gen num_eng = role_count if role_type == "Engineer"
	gen num_Dom = role_count if role_type == "Domain"
	gen num_Oper = role_count if role_type == "Operations"
	
	local vars "num_mgmt num_eng num_Dom num_Oper"
	foreach x in `vars'{
		egen `x'_f = min(`x'), by(master_project_code year month)
		replace `x'_f = 0 if `x'_f ==.
	}
	
	gen t1 = tenure_count if emp_tenure == "0 - <3"
	gen t2 = tenure_count if emp_tenure == "3 - <6"
	gen t3 = tenure_count if emp_tenure == "6 - <9"
	gen t4 = tenure_count if emp_tenure == "9 - <12"
	gen t5 = tenure_count if emp_tenure == "12 - <15"
	gen t6 = tenure_count if emp_tenure == ">15"
	
	local vars "t1 t2 t3 t4 t5 t6"
	foreach x in `vars'{
		egen `x'_f = min(`x'), by(master_project_code year month)
		replace `x'_f = 0 if `x'_f ==.
	}		
		
	collapse (sum) total_hours (mean) *_f, by(master_project_code tq)
	
	save "quarterly_team_vars.dta", replace 
	
	*/
		

/*
*------------------------------------------------------------
* import the data and identify the adoption timing at the daily and monthly level
* retired - just need to run it once 
*------------------------------------------------------------

* 12 employees without ID with GenAI usage information 
* Is this about copliot only or all GenAI tools? Coploit 

import excel using "Masked_GHCP_FirstUse.xlsx", firstrow clear 

ren MaskedEmpNo emp_masked_id
duplicates drop emp_masked_id, force 

drop if emp_masked_id =="-"

merge 1:m emp_masked_id using "employee_allocations.dta"

keep if _m==3

keep emp_masked_id FirstUseDate alloc_from_date alloc_to_date master_project_code alloc_percent

export delimited "Mickeymouse_copliot_cleaned.csv", replace 


import delimited using "Mickeymouse_copliot_cleaned.csv", ///
    varnames(1) stringcols(_all) case(preserve) clear

*------------------------------------------------------------
* (1) Standardize date variables to Stata daily dates
*     - Handles "YYYY-MM-DD" and "MM/DD/YYYY"
*------------------------------------------------------------
foreach v in alloc_from_date alloc_to_date FirstUseDate{
    capture confirm numeric variable `v'
    if _rc {
        gen double `v'_d = cond(strpos(`v', "-"), daily(`v', "YMD"), daily(`v', "MDY"))
    }
    else {
        gen double `v'_d = `v'
    }
    format `v'_d %tdNN/DD/CCYY
}

rename alloc_from_date_d alloc_from_d
rename alloc_to_date_d   alloc_to_d
rename FirstUseDate_d  first_used

*------------------------------------------------------------
* (2) Expand each allocation spell to monthly rows
*------------------------------------------------------------
gen int startm = mofd(alloc_from_d)
gen int endm   = mofd(alloc_to_d)
format startm endm %tm

*  Number of months in the spell (inclusive)
gen int nmonths = endm - startm + 1

* Expand the dataset so each row = one employee–project–month
expand nmonths

*  Sequence within each original allocation spell to add to startm
bysort emp_masked_id master_project_code alloc_from_d alloc_to_d: gen int _seq = _n - 1

*  Monthly time index for each expanded row
gen int ym = startm + _seq
drop _seq nmonths
format ym %tm

* Year / month columns for readability
gen int  year  = yofd(dofm(ym))
gen byte month = month(dofm(ym))

*------------------------------------------------------------
* (3) Ensure alloc_percent is numeric
*------------------------------------------------------------
capture confirm numeric variable alloc_percent
if _rc {
    destring alloc_percent, replace ignore("% ,")
}

*------------------------------------------------------------
* (4) Collapse to one row per employee–project–month
*     - Sum alloc_percent if multiple rows hit the same month
*     - Keep the same FirstUsageDate (first nonmissing)
*------------------------------------------------------------

collapse (sum) alloc_percent (firstnm) first_used=first_used, ///
    by(emp_masked_id master_project_code ym year month)

format first_used %tdNN/DD/CCYY

replace alloc_percent = min(alloc_percent, 100)

*------------------------------------------------------------
* (5) Create a panel id and declare panel structure at monthly frequency
*------------------------------------------------------------
egen panel_id = group(emp_masked_id master_project_code), label
xtset panel_id ym, monthly

*------------------------------------------------------------
* (6) Tidy column order and sort
*------------------------------------------------------------
order emp_masked_id master_project_code year month ym alloc_percent first_used panel_id
sort emp_masked_id master_project_code ym

/*------------------------------------------------------------
* (7)  Flag the month of first use
*------------------------------------------------------------
gen byte firstuse_in_this_month = (mofd(first_used) == ym)
*/

*------------------------------------------------------------
* Quick checks on duplicates and ranges
*------------------------------------------------------------
duplicates report emp_masked_id master_project_code ym

*------------------------------------------------------------
* generate month of first use 
*------------------------------------------------------------
gen byte post_firstuse = (ym >= mofd(first_used)) if !missing(first_used)


save "Mickeymouse_copliot_montly_panel.dta", replace 
*/


*------------------------------------------------------------
* clean and aggregate data into project quarterly level 
*------------------------------------------------------------

cd $data

u "Mickeymouse_copliot_montly_panel.dta", clear 


*------------------------------------------------------------
* (1) keep data in range 
*------------------------------------------------------------

* keep if ym >= ym(2022,1) & ym < ym(2025,9)

*------------------------------------------------------------
* (2) identify quarters and aggregate the adoption timing to quarterly level 
	* aggregate to financial quarter to be consistent with the team files 
*------------------------------------------------------------


* Create a month variable if you haven't already from your ym variable
gen mth = month(dofm(ym))
gen yr  = year(dofm(ym))

* Define Fiscal Quarters
gen quarter = .
replace quarter = 1 if mth >= 4 & mth <= 6   // April - June
replace quarter = 2 if mth >= 7 & mth <= 9   // July - September
replace quarter = 3 if mth >= 10 & mth <= 12 // October - December
replace quarter = 4 if mth >= 1  & mth <= 3  // January - March

* Define Fiscal Year (If Jan-Mar 2024 is FY 2024, then April-Dec 2023 is also FY 2024)
gen fiscal_year = yr
replace fiscal_year = yr + 1 if mth >= 4

ren year year_cal 
gen year = fiscal_year 
		
		

/*
* calendar quarter 
gen quarter = 1 if month >=1 & month<=3
replace quarter = 2 if month >=4 & month<=6
replace quarter = 3 if month >=7 & month<=9
replace quarter = 4 if month >=10 & month<=12
*/


	*------------------------------------------------------------
	* Collapse monthly rows to one row per employee–project–year-quarter
	*------------------------------------------------------------

	bysort master_project_code year quarter emp_masked_id: egen byte used_yq = max(post_firstuse)

	*------------------------------------------------------------
	* summarize allocation within the year for weighting later
	*------------------------------------------------------------

	bysort master_project_code year quarter emp_masked_id: egen double alloc_mean = mean(alloc_percent)

	*------------------------------------------------------------
	*  Keep a single record per employee–project–year=quarter
	*------------------------------------------------------------

	bysort master_project_code year quarter emp_masked_id: keep if _n == 1

	*------------------------------------------------------------
	* Unweighted share: % of employees with usage in that project–year
	*------------------------------------------------------------

	bysort master_project_code year quarter: egen int emp_cnt  = total(1)
	bysort master_project_code year quarter: egen int used_cnt = total(used_yq)
	gen double pct_copilot_users = 100 * used_cnt / emp_cnt
	label var pct_copilot_users "% employees with Copilot usage (unweighted)"


	bysort master_project_code year quarter: egen double total_alloc = total(alloc_mean)
	gen double w = cond(total_alloc > 0, alloc_mean / total_alloc, .)
	bysort master_project_code year quarter: egen double w_used = total(w * used_yq)
	gen double pct_copilot_users_w = 100 * w_used
	label var pct_copilot_users_w "Alloc-weighted % employees with Copilot usage (optional)"
	
*------------------------------------------------------------
* (3) Keep one row per project–year with tidy columns
*------------------------------------------------------------

bysort master_project_code year quarter: keep if _n == 1

keep master_project_code year quarter ym used_yq emp_cnt used_cnt pct_copilot_users pct_copilot_users_w 
sort master_project_code year quarter

*------------------------------------------------------------
* (4) Labels for counts
*------------------------------------------------------------

label var emp_cnt  "Employees on project–year"
label var used_cnt "Employees with Copilot usage on project–year-month"

*------------------------------------------------------------
* (5) Labels year quarter variable for plotting later 
*------------------------------------------------------------
		
		* we have the data up to 2027 (with few observations); stable sample in between 2021q1 to 2026q2

cap drop tq
gen int tq = yq(year, quarter)
format tq %tq 
tab tq

egen used_yq_fixed = max(used_yq), by(master_project_code)
tab tq if used_yq_fixed==1 & used_yq==0

*------------------------------------------------------------
* (6) Save quarterly data  
*------------------------------------------------------------		
* save "Mickeymouse_copliot_project_quarter_panel_byfiscalyear.dta", replace

save "Mickeymouse_copliot_project_quarter_panel_byfiscalyear_Jan2026.dta", replace 


*------------------------------------------------------------
* (67) Plotting the adoption by year quarter for validation  
*------------------------------------------------------------
preserve 
collapse (mean) used_yq emp_cnt used_cnt pct_copilot_users pct_copilot_users_w, by(tq)
	

sort tq
twoway ///
	(connected used_yq tq, lpattern(dash) lcolor(blue) ///
	legend(label(1 "Copilot Usage"))), ///
	xtitle("Year & Quarter") ///
	ytitle("Percentage of Copliot Users") ///
	title("Copliot Usage Over Time") ///
	legend(position(best) ring(1)) ///
	graphregion(color(white))	
			
graph export "`outdir'/Copliot_Users_Project_Quarter_telemetry_Jan2026.png", replace 	
restore 



/*------------------------------------------------------------
* validation 
* why such a high percentage of project-quarter level observations are not matching with the finanical table 
*------------------------------------------------------------
u "Mickeymouse_copliot_project_quarter_panel.dta", clear
keep master_project_code

duplicates drop master_project_code, force 

save "Mickeymouse_unique_projects.dta", replace 

u "$work/data_4y/ v_projects_quarterly.dta", clear

keep master_project_code

duplicates drop master_project_code, force 

save "v_project_q_unique_projects.dta", replace 

merge 1:1  master_project_code using "Mickeymouse_unique_projects.dta"

* about 24 projects are not covered in the data 
keep if _m==2 

drop _m 
save "missing_in_financial_table_quarterly.dta", replace 

export delimited "missing_in_financial_table_quarterly.csv", replace 

u "Mickeymouse_copliot_project_quarter_panel.dta", clear
keep master_project_code year quarter

duplicates drop master_project_code year quarter, force 

save "Mickeymouse_unique_projects_quarter.dta", replace 

u "$work/data_4y/ v_projects_quarterly.dta", clear

gen year = fiscal_year

keep master_project_code year quarter

duplicates drop master_project_code year quarter, force 

save "v_project_q_unique_projects_quarter.dta", replace 

merge 1:1 master_project_code year quarter using "Mickeymouse_copliot_project_quarter_panel.dta"
tab year quarter if _m==2

ren _m merge_1

merge m:1 master_project_code using "missing_in_financial_table_quarterly.dta"

drop if _m ==3
tab year quarter if merge_1==2

preserve 
keep if merge_1==2
keep master_project_code quarter year ym tq
save "missing_in_financial_table_quarterly_records_v2.dta", replace 

export delimited "missing_in_financial_table_quarterly_records_v2.csv", replace 
restore 

tab year quarter if merge_1==1
*/



*------------------------------------------------------------

*------------------------------------------------------------
* (1) merge with the quarterly telemetric data for high tech account 
* many data point in the Mickeymouse_copliot telemetry data can NOT be merged with the Mickeymouse copilot data - Why?
* currently merged by fiscal year quarter but can change 
*------------------------------------------------------------


*------------------------------------------------------------
* Import quarterly financail data   
* financial quarter only available to 2025Q4
*------------------------------------------------------------	
u "$work/data_4y/ v_projects_quarterly.dta", clear

tab customer_name


*-----------------------------------------------------------
* is it correct to change from fiscal year to calendar year (what is infosys's fiscal year starting from?)
*------------------------------------------------------------


/*
* --- 1) Parse the custom fiscal month code ---
ren quarter fiscal_quarter

* --- 2) Convert to calendar month and year ---
* Map fiscal: Jul=1,...,Dec=6, Jan=7,...,Jun=12  --> calendar: Jan=1,...,Dec=12
gen int  cal_year  = cond(fiscal_quarter <= 2, fiscal_year, fiscal_year - 1)

gen byte cal_quarter = mod(fiscal_quarter + 1, 4) + 1

label var cal_year    "Calendar year"
label var cal_quarter "Calendar quarter (mapped from fiscal)"

* Quarterly date for the calendar quarter
gen tq_cal = yq(cal_year, cal_quarter)
format tq_cal %tq
label var tq_cal "Calendar quarter date"


* --- 4) sanity checks & labels ---
assert inrange(fiscal_quarter, 1, 4) 

gen year    = cal_year
gen quarter = cal_quarter   // avoid overwriting original 'quarter'
*/
*------------------------------------------------------------

gen year = fiscal_year
cap drop tq
gen int tq = yq(year, quarter)
format tq %tq 

*------------------------------------------------------------
* (1) merge with the quarterly telemetric data for high tech account 
* many data point in the Mickeymouse_copliot telemetry data can NOT be merged with the Mickeymouse copilot data - Why? Based on discussion with Sreeram, those are projects without employee activities (pass-through?) 
* currently merged by fiscal year quarter but can change 
*------------------------------------------------------------
merge 1:1 master_project_code tq using "Mickeymouse_copliot_project_quarter_panel_byfiscalyear.dta"

*------------------------------------------------------------
* validation 
* some non high tech account projects are in the telemetric data? Probably because of the employees got assigned to multiple accounts?
*------------------------------------------------------------
tab customer_name if _m==3
* tab ym if _m==3
tab tq if _m ==3

keep if _m==3

*------------------------------------------------------------
* keep high tech only for now 
*------------------------------------------------------------
keep if customer_name =="Hi-Tech"

*------------------------------------------------------------
* replace first adoption timing to 0 for control groups (those that are NOT in the telemetric data)
*------------------------------------------------------------

* drop if tq >= 263 | tq<=247

drop if _m == 2 

tab used_yq

gen cp = used_yq
replace cp = 0 if cp ==.
tab cp 
tab tq, sum(cp)

ren _m merge_copilot


*------------------------------------------------------------
* merge the quarterly data from Sreeram 
*------------------------------------------------------------
merge 1:1 master_project_code tq using "quarterly_team_manager_fte_Dec2025.dta"

ren _m merge_fte
tab merge_copilot merge_fte
*------------------------------------------------------------
* merge the quarterly data from Yarong  
*------------------------------------------------------------
merge 1:1 master_project_code tq using "quarterly_team_vars.dta"
tab merge_copilot _m

ren _m merge_team_vars


drop if tq >= 263 | tq<=247


/*
*------------------------------------------------------------
* Dec 8 2015 
* analysis to identify the non-matches between fte and new org data for Sreeram
*------------------------------------------------------------

preserve 

count if merge_fte==3 &  merge_team_vars==3

keep if (merge_fte==3 &  merge_team_vars==1) |  (merge_fte==2 &  merge_team_vars==3)

keep master_project_code tq merge_fte merge_team_vars
save "non_matched_sample.dta", replace 

/*
tab master_project_code if merge_fte==3 & merge_team_vars !=3

master_proj |
   ect_code |      Freq.     Percent        Cum.
------------+-----------------------------------
   MCRMBAPM |          1        0.28        0.28  2024q2
   MD15SPZ1 |          1        0.28        0.57  2022q3
   MS365STP |          1        0.28        0.85  2023q2
   MS3CPZ51 |          1        0.28        1.13  2024q2
   MS3PCHZ2 |          1        0.28        1.42  2024q2

*/


		u "quarterly_team_manager_fte.dta", clear
		tab tq if master_project_code == "MCRMBAPM"


		u "project_quarter_role_cat.dta", clear 
		
		tab tq if master_project_code == "MCRMBAPM"
		tab tq if master_project_code == "MD15SPZ1"
        tab tq if master_project_code == "MS365STP"
        tab tq if master_project_code == "MS3CPZ51"
        tab tq if master_project_code == "MS3PCHZ2"
		
	
restore 
*------------------------------------------------------------
*------------------------------------------------------------
*/


*------------------------------------------------------------
* merge the quarterly data by Wang - slidely larger sample here 
*------------------------------------------------------------
merge 1:1 master_project_code tq using "project_quarter_fte_layers.dta"

ren _m merge_layer


*------------------------------------------------------------
* merge the quarterly data by Sreeram - tenure, education, and role 
*------------------------------------------------------------

* merge 1:1 master_project_code tq using "project_quarter_org_cat.dta"

merge 1:1 master_project_code tq using "project_quarter_org_cat_Dec2025.dta"


ren _m merge_org

tab merge_org merge_fte


*------------------------------------------------------------
* plot out the avearge by year quarter for the matched sample; and by contract type 
* the fall during late 2024 could be due to the exit of high usage projects?
*------------------------------------------------------------

* Create a string for today's date (YYYY-MM-DD format)
local today : display %tdCY-N-D daily("`c(current_date)'","DMY")
* Define a base output folder (adjust path!)
local base "$output"
* Build today's directory path
local outdir "`base'/`today'"
* Create the directory if it does not exist
capture mkdir "`outdir'"


preserve 
collapse (mean) used_yq cp pct_copilot_users_w, by(tq)

sort tq
twoway ///
	(connected cp tq, lpattern(dash) lcolor(blue) ///
	legend(label(1 "Copilot Usage"))), ///
	xtitle("Year & Month") ///
	ytitle("Average projects with Copilot Usage") ///
	title("Copliot Usage Over Time") ///
	legend(position(best) ring(1)) ///
	graphregion(color(white))	
			
graph export "`outdir'/copliot_trend_dum_matched.png", replace 	
restore 

* by contract type 

preserve 
collapse (mean) used_yq cp pct_copilot_users_w, by(contract_type tq)
		
twoway (connected cp tq if contract_type=="FP",  msymbol(Oh) mcolor(navy) lcolor(navy) lpattern(solid)) (connected cp tq if contract_type=="OTM", msymbol(Oh) mcolor(maroon) lcolor(maroon) lpattern(dash)) (connected cp tq if contract_type=="TM", msymbol(Oh) mcolor(black) lcolor(black) lpattern(dash)), legend(order(1 "FP" 2 "OTM" 3 "TM") pos(11) ring(0)) title("Average of Copliot Exposure by Contract Type") xtitle("Year & Month") ytitle("Average Copliot Usage") xline(2023, lcolor(black) lpattern(dash) lwidth(medthick))
graph export "`outdir'/copliot_trend_dum_bycontracts_quarterly.png", replace 			
restore 		
		


preserve 
collapse (mean) total_revenue operating_margin total_operating_cost, by(tq)

sort tq
twoway ///
	(connected total_revenue tq, lpattern(dash) lcolor(blue) ///
	legend(label(1 "Revenue"))), ///
	xtitle("Year & Month") ///
	ytitle("Revenue") ///
	title("Copliot Usage Over Time") ///
	legend(position(best) ring(1)) ///
	graphregion(color(white))	
			
graph export "`outdir'/reve_dum_matched.png", replace 

twoway ///
	(connected total_operating_cost tq, lpattern(dash) lcolor(blue) ///
	legend(label(1 "Operating Cost"))), ///
	xtitle("Year & Month") ///
	ytitle("Operating Cost") ///
	title("Copliot Usage Over Time") ///
	legend(position(best) ring(1)) ///
	graphregion(color(white))	
			
graph export "`outdir'/cost_dum_matched.png", replace 


twoway ///
	(connected operating_margin tq, lpattern(dash) lcolor(blue) ///
	legend(label(1 "Operating Margin"))), ///
	xtitle("Year & Month") ///
	ytitle("Operating Margin") ///
	title("Copliot Usage Over Time") ///
	legend(position(best) ring(1)) ///
	graphregion(color(white))	
			
graph export "`outdir'/margin_dum_matched.png", replace 
restore 


* ===========================
* Analysis based on adoption timing 
* Event study  
* ===========================
		
tab cp tq if merge_layer==3
				
gen treat = tq if cp == 1
egen treat_min = min(treat), by(master_project_code)
order treat_min
tab treat_min	
		
* control time window  
cap drop treat_time
gen treat_time = tq - treat_min 
tab treat_time		
replace treat_time = 0 if treat_time == .
		
* leads
forval x = 1/10 {  // drop the first lead
	cap drop F_`x'
	gen F_`x' = treat_time == -`x'
}

* lags
forval x = 0/10 {
	cap drop L_`x'
	gen L_`x' = treat_time ==  `x'
	}

gen logrev = log(1+ total_revenue)	
gen logcost = log(1+total_operating_cost)
gen logmargin = log(1+operating_margin)
gen logbilled = log(1+total_billed_months)


gen treated = (cp==1)
egen treated_fixed = max(treated), by(master_project_code)

* why we don't have any projects that started before 2023 Q2 in the telemetric data from high-tech account for adopters 

tab tq if treated ==0 & treated_fixed==1	
	
	* -------------
	* adding Sreeram's quartely data as controls & outcomes
	* -------------
	
	gen logteam_size_fte = log(1+team_size_fte)
	gen logmgmt = log(1+manager_fte)
	sum logteam_size_fte logmgmt,d	

	* -------------
	* adding Yarong's quartely data as controls & outcomes
	* -------------	
	
	
	gen logteam_size = log(1+total_hours)
	gen logmgmt_v2 = log(1+num_mgmt_f)
	sum logteam_size logmgmt_v2,d		

	* ============================
	* explore a balanced sample ?
	* ============================
	
	* reghdfe logrev F_5 F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 L_5 logteam_size_fte if (treat_time >=-5 & treat_time<=4), ab(master_project_code year quarter) cluster(master_project_code)
	
	reghdfe logrev F_5 F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 L_5, ab(master_project_code year quarter) cluster(master_project_code)
	
	tab tq if e(sample)==1
	
	tab tq cp 
	
	cap drop seq
	egen seq= seq(), by(master_project_code)
	cap drop max 
	egen max = max(seq), by(master_project_code)
	
	tab max
	
	sort master_project_code tq

	* Identify consecutive observations for the same firm
	gen tag = (master_project_code != master_project_code[_n-1]) | (tq != tq[_n-1] + 1)
	gen group = sum(tag)

	* Count how many consecutive periods per group
	bysort master_project_code group: gen n_consec = _N

	* Flag projects with any spell of at least 6 consecutive years
	bysort master_project_code: egen max_consec = max(n_consec)
	
	/*
	gen logteam_size_fte = log(1+team_size_fte)
	gen logmgmt = log(1+manager_fte)
	sum logteam_size_fte logmgmt,d		
	*/
	
	cap gen logteam_size = log(1+total_hours)
	cap gen logmgmt_v2 = log(1+num_mgmt_f)
	sum logteam_size logmgmt_v2,d		

	cap gen mnmg_rt = manager_fte/team_size_fte
	cap gen rev_prod = total_revenue/team_size_fte
			
	local vars "total_hours num_mgmt_f num_eng_f num_Dom_f employee_count1 employee_count2 employee_count3 employee_count4 employee_count5 employee_count6 employee_count7"		
	foreach x in `vars'{
		cap drop log`x'
		gen log`x' = log(1+ `x')
	}
	
		
	* ================================	
	* Within estimator along  
	* =================================		
	

* Create a string for today's date (YYYY-MM-DD format)
local today : display %tdCY-N-D daily("`c(current_date)'","DMY")
* Define a base output folder (adjust path!)
local base "$output"
* Build today's directory path
local outdir "`base'/`today'"
* Create the directory if it does not exist
capture mkdir "`outdir'"	

eststo clear 
local vars "logrev logcost logmargin logbilled total_revenue total_operating_cost operating_margin total_billed_months logmgmt_v2 logmgmt mnmg_rt manager_fte team_size_fte rev_prod avg_layers num_mgmt_f num_eng_f num_Dom_f num_Oper_f total_hours "

foreach x in `vars'{
	reghdfe `x' F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte if (treat_time >=-4 & treat_time<=4) & max_consec>=5, ab(master_project_code year quarter) cluster(master_project_code)	
	eststo `x'_wt, addscalars(NNN e(N) adjR2 e(r2_a))
	coefplot (`x'_wt, label(a. within projects)), vertical drop(_cons logteam_size_fte) yline(0) levels(90) rename(F_4 = "T-4" F_3 = "T-3" F_2 = "T-2" L_0 = "T" L_1 = "T+1" L_2 = "T+2" L_3 = "T+3" L_4 = "T+4") byopts(yrescale col(1)) xlabel(,labsize(small)) ylabel(,labsize(vsmall)) title(`x', size(vsmall)) xline(3.5, lpattern(dash)) cismooth(intensity(0 30)) xtitle("Time to Adoption", size(small)) ytitle("Effect on Outcome", size(small)) subtitle(, size(small) margin(small) justification(left) color(white) bcolor(black) bmargin(top_bottom)) 
	graph export "`outdir'/Figure_`x'_tw4_withsize_re_balanced_v2_within.png", replace	
	}			

eststo clear 
local vars "total_hours num_mgmt_f num_eng_f num_Dom_f employee_count1 employee_count2 employee_count3 employee_count4 employee_count5 employee_count6 employee_count7"

foreach x in `vars'{
	reghdfe `x' F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte if (treat_time >=-4 & treat_time<=4) & max_consec>=5, ab(master_project_code year quarter) cluster(master_project_code)	
	eststo `x'_wt, addscalars(NNN e(N) adjR2 e(r2_a))
	coefplot (`x'_wt, label(a. within projects)), vertical drop(_cons logteam_size_fte) yline(0) levels(90) rename(F_4 = "T-4" F_3 = "T-3" F_2 = "T-2" L_0 = "T" L_1 = "T+1" L_2 = "T+2" L_3 = "T+3" L_4 = "T+4") byopts(yrescale col(1)) xlabel(,labsize(small)) ylabel(,labsize(vsmall)) title(`x', size(vsmall)) xline(3.5, lpattern(dash)) cismooth(intensity(0 30)) xtitle("Time to Adoption", size(small)) ytitle("Effect on Outcome", size(small)) subtitle(, size(small) margin(small) justification(left) color(white) bcolor(black) bmargin(top_bottom)) 
	graph export "`outdir'/Figure_`x'_tw4_withsize_re_balanced_v2_within.png", replace	
	}	


eststo clear 
local vars "total_hours num_mgmt_f num_eng_f num_Dom_f employee_count1 employee_count2 employee_count3 employee_count4 employee_count5 employee_count6  employee_count7"

foreach x in `vars'{
	reghdfe log`x' F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte if (treat_time >=-4 & treat_time<=4) & max_consec>=5, ab(master_project_code year quarter) cluster(master_project_code)	
	eststo log`x'_wt, addscalars(NNN e(N) adjR2 e(r2_a))
	coefplot (log`x'_wt, label(a. within projects)), vertical drop(_cons logteam_size_fte) yline(0) levels(90) rename(F_4 = "T-4" F_3 = "T-3" F_2 = "T-2" L_0 = "T" L_1 = "T+1" L_2 = "T+2" L_3 = "T+3" L_4 = "T+4") byopts(yrescale col(1)) xlabel(,labsize(small)) ylabel(,labsize(vsmall)) title(`x', size(vsmall)) xline(3.5, lpattern(dash)) cismooth(intensity(0 30)) xtitle("Time to Adoption", size(small)) ytitle("Effect on Outcome", size(small)) subtitle(, size(small) margin(small) justification(left) color(white) bcolor(black) bmargin(top_bottom)) 
	graph export "`outdir'/Figure_log`x'_tw4_withsize_re_balanced_v2_within.png", replace	
	}			
	

* Create a string for today's date (YYYY-MM-DD format)
local today : display %tdCY-N-D daily("`c(current_date)'","DMY")
* Define a base output folder (adjust path!)
local base "$output"
* Build today's directory path
local outdir "`base'/`today'"
* Create the directory if it does not exist
capture mkdir "`outdir'"		
*------------------------------------------
* 1) Run regressions + store estimates (1–6)
*------------------------------------------
eststo clear
local vars "employee_count1 employee_count2 employee_count3 employee_count4 employee_count5 employee_count6 employee_count7"

foreach x of local vars {
    reghdfe `x' F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte ///
        if (treat_time >= -4 & treat_time <= 4) & max_consec >= 5, ///
        ab(master_project_code year quarter) cluster(master_project_code)

    eststo `x'_wt, addscalars(NNN e(N) adjR2 e(r2_a))
}


*------------------------------------------
* 2) One plot: overlay the 6 series
*------------------------------------------
coefplot ///
    (employee_count1_wt, label("0-3")) ///
    (employee_count2_wt, label("3-6")) ///
    (employee_count3_wt, label("6-9")) ///
    (employee_count4_wt, label("9-12")) ///
    (employee_count5_wt, label("12-15")) ///
    (employee_count6_wt, label(">15")) ///
    (employee_count7_wt, label("Unknown")), ///	
    vertical ///
    drop(_cons logteam_size_fte) ///
    yline(0) ///
    levels(90) ///
    rename(F_4="T-4" F_3="T-3" F_2="T-2" L_0="T" L_1="T+1" L_2="T+2" L_3="T+3" L_4="T+4") ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(vsmall)) ///
    xline(3.5, lpattern(dash)) ///
    xtitle("Time to Adoption", size(small)) ///
    ytitle("Count of Employee", size(small)) ///
    title("Employee count by Tenure Category: event-time estimates", size(small)) ///
    legend(pos(6) ring(0) cols(3) size(vsmall)) ///
    cismooth(intensity(0 30))

graph export "`outdir'/Figure_employee_count_1to6_tw4_withsize_re_balanced_v2_within.png", replace

qui reghdfe logrev F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte if (treat_time >=-4 & treat_time<=4) & max_consec>=5, ab(master_project_code year quarter) cluster(master_project_code)

sum perc1 perc2 perc3 perc4 perc5 perc6 perc7 if e(sample)==1, d
sum employee_count1 employee_count2 employee_count3 employee_count4 employee_count5 employee_count6 employee_count7 if e(sample)==1, d



*------------------------------------------
* 3) One plot: as percentage 
*------------------------------------------

	
* Create a string for today's date (YYYY-MM-DD format)
local today : display %tdCY-N-D daily("`c(current_date)'","DMY")
* Define a base output folder (adjust path!)
local base "$output"
* Build today's directory path
local outdir "`base'/`today'"
* Create the directory if it does not exist
capture mkdir "`outdir'"		
*------------------------------------------
* 1) Run regressions + store estimates (1–6)
*------------------------------------------
eststo clear
local vars "perc1 perc2 perc3 perc4 perc5 perc6 perc7"

foreach x of local vars {
    reghdfe `x' F_4 F_3 F_2 L_0 L_1 L_2 L_3 L_4 logteam_size_fte ///
        if (treat_time >= -4 & treat_time <= 4) & max_consec >= 5, ///
        ab(master_project_code year quarter) cluster(master_project_code)

    eststo `x'_wt, addscalars(NNN e(N) adjR2 e(r2_a))
}


*------------------------------------------
* 2) One plot: overlay the 6 series
*------------------------------------------
coefplot ///
    (perc1_wt, label("0-3")) ///
    (perc2_wt, label("3-6")) ///
    (perc3_wt, label("6-9")) ///
    (perc4_wt, label("9-12")) ///
    (perc5_wt, label("12-15")) ///
    (perc6_wt, label(">15")) ///
    (perc7_wt, label("Unknown")), ///	
    vertical ///
    drop(_cons logteam_size_fte) ///
    yline(0) ///
    levels(90) ///
    rename(F_4="T-4" F_3="T-3" F_2="T-2" L_0="T" L_1="T+1" L_2="T+2" L_3="T+3" L_4="T+4") ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(vsmall)) ///
    xline(3.5, lpattern(dash)) ///
    xtitle("Time to Adoption", size(small)) ///
    ytitle("Percentage of FTE", size(small)) ///
    title("Percentage by Tenure Cateogry): event-time estimates", size(small)) ///
    legend(pos(6) ring(0) cols(3) size(vsmall)) ///
    cismooth(intensity(0 30))

graph export "`outdir'/Figure_Perc_employee_count_1to6_tw4_withsize_re_balanced_v2_within.png", replace
