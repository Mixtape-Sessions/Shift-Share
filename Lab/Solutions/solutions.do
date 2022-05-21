/*****************************************/
/*    Example Solution for SSIV Lab      */
/* Written by Peter Hull, 5/16/2022 (v1) */
/*****************************************/

ssc install ssaggregate, replace
clear all

/* Construct z */
use adh_shares, clear
merge m:1 industry year using adh_shocks, nogen 
gen z = ind_share * shock
collapse (sum) z, by(location year)
tempfile IV
save `IV', replace
use adh_noIV, clear
merge 1:1 location year using `IV', nogen

/* Basic SSIV and balance */
ivreg2 y (x=z) post [aw=weight], cluster(state) 
ivreg2 y_lag (x=z) post [aw=weight], cluster(state) 

/* Add sum of shares control */
preserve
use adh_shares, clear
collapse (sum) sum_share=ind_share, by(location year)
tempfile sum_shares
save `sum_shares', replace
restore
merge 1:1 location year using `sum_shares', nogen
summ sum_share
ivreg2 y (x=z) post sum_share [aw=weight], cluster(state) 
ivreg2 y_lag (x=z) post sum_share [aw=weight], cluster(state) 

/* Interact sum of shares with year */
gen post_sum_share=post*sum_share
ivreg2 y (x=z) post sum_share post_sum_share [aw=weight], cluster(state) 
ivreg2 y_lag (x=z) post sum_share post_sum_share [aw=weight], cluster(state) 

/* Check why sum of shares matters */
preserve
use adh_shocks, clear
reg shock year, cluster(industry)
restore

/* Get exposure-robust SEs with ssaggregate */
ssaggregate y x y_lag [aw=weight], ///
	n(industry) l(location) t(year) ///
	s(ind_share) sfilename(adh_shares) ///
	controls("post sum_share post_sum_share") 
merge 1:1 industry year using adh_shocks, nogen 
ivreg2 y (x=shock) i.year [aw=s_n], cluster(industry)
ivreg2 y_lag (x=shock) i.year [aw=s_n], cluster(industry)
