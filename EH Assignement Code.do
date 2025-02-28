
// Economic History Homework Assigned by Dr. Moritz Schularick
// Crisis Prediction and Crisis Cost
// By Eli Cheam Shapiro, Sciences Po M2 Fall Semester 2024-25
// Homework Instructions are in package


// Part 1: Crisis Prediction
clear all

cap cd "/Users/elishapiro/Documents/GitHub/Economic-History-Assignment-Sciences-Po/"

*Data is from JST Macrohistory, Dr. Moritz Schularick, and BVX Financial History Database
use JSTdatasetR6.dta, clear
merge 1:1 iso year using RecessionDummies.dta, keep(3) nogen
merge 1:1 country year using BVX_annual_regdata.dta, keep(3) nogen

* Set panel data 
xtset ifs year , yearly

* Generate regressors
gen lpop = log(pop)
gen lcpi = log(cpi)
gen lloans = log(tloans)
gen rprv = lloans - lcpi - lpop
gen drprv = d.rprv*100 

// Problem 1.1: Estimate a logit model with country fixed effects and with five lags of log changes in real credit

* Logit regression with country fixed effects for JST crises
logit crisisJST L.drprv L2.drprv L3.drprv L4.drprv L5.drprv i.ifs, cluster(ifs)

* Test for joint significance of five lags
test L.drprv L2.drprv L3.drprv L4.drprv L5.drprv

* Repeat for BVX crisis dates (replace 'BVX_crisis' with actual variable name)
logit PANIC L.drprv L2.drprv L3.drprv L4.drprv L5.drprv i.ifs, cluster(ifs)

* Test for joint significance for BVX crisis dates
test L.drprv L2.drprv L3.drprv L4.drprv L5.drprv

* Generate 5-year change in the ratio of credit over GDP (replace 'credit' and 'GDP' with actual variable names)
gen credit_GDP_change_5y = credit_to_gdp - L5.credit_to_gdp

* Logit regression using the 5-year change in credit/GDP ratio
logit crisisJST credit_GDP_change_5y i.ifs, cluster(ifs)

* Repeat for BVX crisis dates
logit PANIC credit_GDP_change_5y i.ifs, cluster(ifs)

// Problem 1.2: Model evaluation

* Split sample: Pre-1984 for estimation, post-1984 for prediction
gen pre1984 = year <= 1984

* Estimate the baseline logit model on pre-1984 data
logit crisisJST L.drprv L2.drprv L3.drprv L4.drprv L5.drprv i.ifs if pre1984, cluster(ifs)

* Get predicted probabilities for post-1984 observations
predict prob_baseline if year > 1984

* ROC curve for out-of-sample prediction
roctab crisisJST prob_baseline if year > 1984, graph

* Compare baseline model with a logit model using money as a predictor (replace 'money' with actual variable)
logit crisisJST money i.ifs if pre1984, cluster(ifs)
predict prob_money if year > 1984
roctab crisisJST prob_money if year > 1984, graph

* Compare baseline model with a logit model using public debt as a predictor (replace 'public_debt' with actual variable)
logit crisisJST debtgdp i.ifs if pre1984, cluster(ifs)
predict prob_debt if year > 1984
roctab crisisJST prob_debt if year > 1984, graph

* Plot all ROC curves together for comparison
roccomp crisisJST prob_baseline prob_money prob_debt if year > 1984, graph

// Part 2: Crisis Cost
// Eli Shapiro

clear all

cap cd "/Users/elishapiro/Documents/GitHub/Economic-History-Assignment-Sciences-Po/"

use JSTdatasetR6.dta

merge 1:1 iso year using RecessionDummies.dta, keep(3) nogen

replace N = 0 if missing(N)
replace F = 0 if missing(F)

xtset ifs year, yearly

gen y = log(rgdpbarro) * 100
sort ifs year

// Loop to generate response variables and estimate regressions
forval h = 1/5 {
    gen D_y_`h' = F`h'.y - L.y

    regress D_y_`h' N F i.ifs, robust

    scalar coef_normal_`h' = _b[N]
    scalar coef_financial_`h' = _b[F]
    
    // Confidence intervals
    scalar ci_low_normal_`h' = _b[N] - 1.96 * _se[N]
    scalar ci_high_normal_`h' = _b[N] + 1.96 * _se[N]
    
    scalar ci_low_financial_`h' = _b[F] - 1.96 * _se[F]
    scalar ci_high_financial_`h' = _b[F] + 1.96 * _se[F]
}

// Creating a dataset to store the IRF coefficients and confidence intervals
clear
input byte horizon float(coef_normal coef_financial ci_low_normal ci_high_normal ci_low_financial ci_high_financial)
1 . . . . . .
2 . . . . . .
3 . . . . . .
4 . . . . . .
5 . . . . . .
end

// Filling in values for coefficients and confidence intervals
forval h = 1/5 {
    replace coef_normal = coef_normal_`h' if horizon == `h'
    replace coef_financial = coef_financial_`h' if horizon == `h'
    
    replace ci_low_normal = ci_low_normal_`h' if horizon == `h'
    replace ci_high_normal = ci_high_normal_`h' if horizon == `h'
    
    replace ci_low_financial = ci_low_financial_`h' if horizon == `h'
    replace ci_high_financial = ci_high_financial_`h' if horizon == `h'
}

// Plotting the IRFs with opaque confidence interval shading (no bold borders)
twoway ///
    (rarea ci_low_normal ci_high_normal horizon, color(blue%30) lwidth(none) ///
        legend(label(3 "Normal Recession"))) ///
    (rarea ci_low_financial ci_high_financial horizon, color(red%30) lwidth(none) ///
        legend(label(4 "Financial Recession"))) ///
    (line coef_normal horizon, lcolor(blue) lwidth(medium) ///
        lpattern(solid) legend(label(1 "Normal Recession CI"))) ///
    (line coef_financial horizon, lcolor(red) lwidth(medium) ///
        lpattern(solid) legend(label(2 "Financial Recession CI"))) ///
    , title("Real GDP Per Capita (PPP) Responses from N and F Shocks") ///
      xlabel(1(1)5) ylabel(, grid angle(0)) ///
      ytitle("Percent Change in Real GDP per Capita") ///
      legend(position(11))

// The cumulative impulse response functions show the effects of a recession shock on real GDP per capita (as a percentage). The plot indicates that financial recessions are more costly than normal recessions. Financial recessions have a worse immediate effect and greater magnitude of accumulated loss than their normal recession counterparts. F has a 5-year horizon cumulative damage of 9.82 percent of real GDP per capita versus 7.12 percent for the latter.

//The reason for this is likely because financial crises involve systemic disruption to the financial system like banking crises, credit contractions, and asset price collpases, hindering the flow of credit and investment and stalling economic recovery. Additionally, financial Financial recessions are more costly because they often involve disruptions to the financial system, such as banking crises, credit contractions, and asset price collapses. These disruptions hinder the flow of credit and investment, which are critical for economic recovery. On the other hand, normal recessions do not usually involve the same systemic financial disruptions, allowing for a quicker and less severe recovery trajectory.
