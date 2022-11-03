
# Mixtape SSIV Workshop: Coding Lab

This lab will walk through some basic SSIV analyses using data from
[Autor, Dorn, and
Hanson](https://github.com/Mixtape-Sessions/Shift-Share/blob/main/Readings/Autor_Dorn_Hanson_2013)
(ADH, 2013). As discussed in lecture, ADH use a shift-share instrument
aggregating Chinese import shocks across 397 manufacturing instruments
with exposure weights calculated as the economy-wide share of (baseline)
industry employment. We will use three cleaned datasets from their
setup:

-   `adh_shocks.dta`: an industry-by-year dataset of the shocks

-   `adh_shares.dta`: a location-by-industry-by-year dataset of the
    shares

-   `adh_noIV.dta`: a location-by-year dataset of the main outcome
    (manufacturing employment growth, `y`), treatment (local growth of
    China import exposure, `x`), and other useful variables – excluding
    the ADH instrument

## Exercises:

1.  Construct the ADH (location-by-year) instrument by appropriately
    combining the data on shocks and shares. Merge this into the
    `adh_noIV` dataset, and estimate an IV regression of the outcome
    onto the treatment which controls for year (i.e. the `post`
    variable) and weights by baseline total employment (the `weight`
    variable), clustering by `state`. Then estimate the exact same IV
    regression replacing the outcome `y` with the lagged outcome
    `y_lag`, capturing growth in manufacturing employment that took
    place before the ADH “China Shock” quasi-experiment. How does the
    latter IV regression help build support for the former IV
    regression?

``` r
## Example solutions for SSIV Lab
## Written by Peter Hull & Kyle Butts
## 5/16/2022 (v1)

devtools::install_github("kylebutts/ssaggregate")
```

    Skipping install of 'ssaggregate' from a github remote, the SHA1 (4d4c50cc) has not changed since last install.
      Use `force = TRUE` to force installation

``` r
library(tidyverse) # Data Cleaning
```

    ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──

    ✔ ggplot2 3.3.5     ✔ purrr   0.3.4
    ✔ tibble  3.1.7     ✔ dplyr   1.0.8
    ✔ tidyr   1.2.0     ✔ stringr 1.4.0
    ✔ readr   2.1.2     ✔ forcats 0.5.1

    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ dplyr::filter() masks stats::filter()
    ✖ dplyr::lag()    masks stats::lag()

``` r
library(fixest) # Regressions
library(here) # Relative file paths
```

    here() starts at /Users/kylebutts/Documents/Mixtape-Sessions/Shift-Share

``` r
library(haven) # Reading .dta
library(ssaggregate)

# Construct z
adh_shares <- haven::read_dta(here("Lab/adh_shares.dta"))
adh_shocks <- haven::read_dta(here("Lab/adh_shocks.dta"))
df <- haven::read_dta(here("Lab/adh_noIV.dta"))

df <- adh_shares |> 
  # Merge shares with shocks
  left_join(adh_shocks, by=c("industry", "year")) |> 
  # Create \sum (shock * share)
  mutate(z = ind_share * shock) |> 
  group_by(location, year) |> 
  summarize(z = sum(z)) |> 
  # Merge with no IV dataset
  left_join(df, by = c("location", "year"))
```

    `summarise()` has grouped output by 'location'. You can override using the
    `.groups` argument.

``` r
# Basic SSIV and balance 
df |> 
  feols(
    y ~ post | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                 Estimate Std. Error   t value   Pr(>|t|)    
    (Intercept) -1.217818   0.140144  -8.68979 2.4286e-11 ***
    fit_x       -0.746030   0.068807 -10.84239 2.2079e-14 ***
    post         0.444445   0.327442   1.35732 1.8116e-01    
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.062748   Adj. R2: 0.065058
    F-test (1st stage), x: stat = 1,146.1, p < 2.2e-16, on 1 and 1,441 DoF.
               Wu-Hausman: stat =   152.6, p < 2.2e-16, on 1 and 1,440 DoF.

``` r
df |> 
  feols(
    y_lag ~ post | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y_lag, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y_lag
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                 Estimate Std. Error  t value   Pr(>|t|)    
    (Intercept) -1.877539   0.269547 -6.96553 9.2190e-09 ***
    fit_x       -0.130629   0.110703 -1.17999 2.4394e-01    
    post         0.249780   0.165983  1.50486 1.3905e-01    
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.076   Adj. R2: -0.010914
    F-test (1st stage), x: stat = 1,146.1, p < 2.2e-16 , on 1 and 1,441 DoF.
               Wu-Hausman: stat =    11.2, p = 8.305e-4, on 1 and 1,440 DoF.

*Comments:*

The lag outcome IV estimate is much smaller than the main IV estimate
(-0.131 vs -0.746) and statistically insignificant. This tells us that
regions which would get a large “china shock” in the post period are not
on differential outcome trends in the pre period, building support for
the validity of the instrument. To do this comparison properly we should
use exposure-robust standard errors, i.e. by the ssaggregate command
used below. But as you’ll see below the standard errors are not too
different this way.

2.  Construct the “sum-of-shares” control from the `adh_shares` dataset
    and add this control to both of the previous IV regressions. How
    does the main IV estimate change? Why, intuitively, is this control
    important to include?

``` r
# Add sum of shares control
df <- adh_shares |> 
  group_by(location, year) |> 
  summarize(sum_share = sum(ind_share)) |> 
  left_join(df, by=c("location", "year"))
```

    `summarise()` has grouped output by 'location'. You can override using the
    `.groups` argument.

``` r
summary(df$sum_share)
```

       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
     0.0000  0.1371  0.2366  0.2448  0.3408  0.7033 

``` r
# SSIV with Sum of Shares 
df |> 
  feols(
    y ~ post + sum_share | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                 Estimate Std. Error   t value   Pr(>|t|)    
    (Intercept)  0.095353   0.407109  0.234220 8.1583e-01    
    fit_x       -0.464863   0.093405 -4.976832 9.0973e-06 ***
    post        -0.418193   0.395662 -1.056945 2.9594e-01    
    sum_share   -5.804483   1.821988 -3.185797 2.5648e-03 ** 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.055594   Adj. R2: 0.265586
    F-test (1st stage), x: stat = 646.1, p < 2.2e-16  , on 1 and 1,440 DoF.
               Wu-Hausman: stat =  58.6, p = 3.557e-14, on 1 and 1,439 DoF.

``` r
# Balance Test with Sum of Shares 
df |> 
  feols(
    y_lag ~ post + sum_share | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y_lag, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y_lag
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                 Estimate Std. Error  t value Pr(>|t|)    
    (Intercept) -0.600258   0.465647 -1.28908 0.203678    
    fit_x        0.142853   0.112310  1.27195 0.209648    
    post        -0.589280   0.254879 -2.31200 0.025208 *  
    sum_share   -5.645837   1.730374 -3.26278 0.002059 ** 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.073349   Adj. R2: 0.057728
    F-test (1st stage), x: stat = 646.1     , p < 2.2e-16 , on 1 and 1,440 DoF.
               Wu-Hausman: stat =   0.138437, p = 0.709894, on 1 and 1,439 DoF.

*Comments:*

The sum-of-shares control should be included because ADH is a setting
with “incomplete shares” (i.e. the sum of shares I not constant across
location-years). Without this control the SSIV will be using both the
variation in shocks across industries and the average “size” of the
shock through the sum of shares (unless the shocks are mean-zero, which
you can see they are not).

3.  Interact the “sum-of-shares” control with year and add this control
    to both of the previous IV regressions. How do both IV estimates
    change? Can you see why, intuitively, the interaction control shifts
    the main IV estimate so much?

``` r
# SSIV with Sum of Shares x Year
df |> 
  feols(
    y ~ post + i(post, sum_share) | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                        Estimate Std. Error  t value   Pr(>|t|)    
    (Intercept)        -0.559603   0.384716 -1.45459 1.5243e-01    
    fit_x              -0.313851   0.097726 -3.21154 2.3839e-03 ** 
    post                0.928098   0.345151  2.68897 9.8865e-03 ** 
    post::0:sum_share  -4.089330   1.805953 -2.26436 2.8206e-02 *  
    post::1:sum_share -11.115279   2.266116 -4.90499 1.1591e-05 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.052434   Adj. R2: 0.346242
    F-test (1st stage), x: stat = 513.9, p < 2.2e-16 , on 1 and 1,439 DoF.
               Wu-Hausman: stat =  27.1, p = 2.184e-7, on 1 and 1,438 DoF.

``` r
# Balance Test with Sum of Shares x Year
df |> 
  feols(
    y_lag ~ post + i(post, sum_share) | 0 | x ~ z, weights = ~weight, cluster = ~state
  )
```

    TSLS estimation, Dep. Var.: y_lag, Endo.: x, Instr.: z
    Second stage: Dep. Var.: y_lag
    Observations: 1,444 
    Standard-errors: Clustered (state) 
                       Estimate Std. Error   t value   Pr(>|t|)    
    (Intercept)       -0.218591   0.403988 -0.541084 5.9101e-01    
    fit_x              0.054853   0.137021  0.400328 6.9073e-01    
    post              -1.373812   0.263121 -5.221211 3.9668e-06 ***
    post::0:sum_share -6.645319   1.540818 -4.312851 8.2052e-05 ***
    post::1:sum_share -2.551045   2.494568 -1.022640 3.1171e-01    
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.073198   Adj. R2: 0.060948
    F-test (1st stage), x: stat = 513.9    , p < 2.2e-16 , on 1 and 1,439 DoF.
               Wu-Hausman: stat =   1.42619, p = 0.232584, on 1 and 1,438 DoF.

``` r
# Check why sum of shares matters
adh_shocks |> 
  feols(shock ~ i(year), cluster = ~industry)
```

    OLS estimation, Dep. Var.: shock
    Observations: 794 
    Standard-errors: Clustered (industry) 
                Estimate Std. Error t value   Pr(>|t|)    
    (Intercept)  4.80993   0.596765 8.06000 9.1107e-15 ***
    year::2000  12.52134   1.727881 7.24664 2.2528e-12 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 28.0   Adj. R2: 0.046361

*Comments:* Interacting the sum-of-shares control with year isolates the
within-year variation in shocks. To see this take the year fixed effects
as the industry-level “q_n” discussed in class and note that to leverage
this control we need to control for sum_n (s_lnt*q_n) = sum_nt
(s_ln)*period_t in the location-year regression. You can see that the
shock mean is quite different across periods (in the post period the
average shock is significantly larger) such that isolating the
within-period variation makes a difference – without this control the
SSIV is using both within- and across-period shock variation, and the
economic conditions in the two periods are quite different (causing
OVB).

4.  Use the *ssaggregate* command to run both of the previous IV
    regressions at the shock level. You should control for year fixed
    effects in the shock-level IV regressions. The coefficients should
    be identical to the previous estimates, but the standard errors will
    be different. Comment on the change.

``` r
# Get exposure-robust SEs with ssaggregate 
ssagg <- ssaggregate(
  data = df,
  vars = ~ y + x + y_lag,
  controls = ~ post + i(post, sum_share),
  weights = "weight",
  n = "industry",
  l = "location",
  t = "year",
  s = "ind_share",
  shares = adh_shares
)

ssagg_df <- ssagg |> 
  left_join(adh_shocks, by = c("industry", "year"))
```

``` r
ssagg_df |> 
  feols(y ~ 1 | year | x ~ shock, weights = ~s_n, cluster = ~industry)
```

    TSLS estimation, Dep. Var.: y, Endo.: x, Instr.: shock
    Second stage: Dep. Var.: y
    Observations: 794 
    Fixed-effects: year: 2
    Standard-errors: Clustered (industry) 
           Estimate Std. Error  t value  Pr(>|t|)    
    fit_x -0.313851    0.10222 -3.07036 0.0022854 ** 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.018509     Adj. R2: 0.037487
                     Within R2: 0.039914
    F-test (1st stage), x: stat = 154.8     , p < 2.2e-16 , on 1 and 791 DoF.
               Wu-Hausman: stat =   0.035513, p = 0.850573, on 1 and 790 DoF.

``` r
ssagg_df |> 
  feols(y_lag ~ 1 | year | x ~ shock, weights = ~s_n, cluster = ~industry)
```

    TSLS estimation, Dep. Var.: y_lag, Endo.: x, Instr.: shock
    Second stage: Dep. Var.: y_lag
    Observations: 794 
    Fixed-effects: year: 2
    Standard-errors: Clustered (industry) 
          Estimate Std. Error  t value Pr(>|t|) 
    fit_x 0.054853   0.174713 0.313962  0.75372 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.025336     Adj. R2: 0.00183 
                     Within R2: 0.004348
    F-test (1st stage), x: stat = 154.8    , p < 2.2e-16 , on 1 and 791 DoF.
               Wu-Hausman: stat =   0.63358, p = 0.426284, on 1 and 790 DoF.
