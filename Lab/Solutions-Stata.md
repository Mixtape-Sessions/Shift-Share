
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

``` stata
/*****************************************/
/*    Example Solution for SSIV Lab      */
/* Written by Peter Hull, 5/16/2022 (v1) */
/*****************************************/

* ssc install ssaggregate, replace
* clear all

/* Construct z */
use adh_shares, clear
merge m:1 industry year using adh_shocks, nogen 
gen z = ind_share * shock
collapse (sum) z, by(location year)
quietly tempfile IV
quietly save `IV', replace
use adh_noIV, clear
merge 1:1 location year using `IV', nogen
```

        Result                           # of obs.
        -----------------------------------------
        not matched                             0
        matched                           573,268  
        -----------------------------------------

        Result                           # of obs.
        -----------------------------------------
        not matched                             0
        matched                             1,444  
        -----------------------------------------

``` stata
/* Basic SSIV regression */
ivreg2 y (x=z) post [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  2,    47) =    75.24
                                                          Prob > F      =   0.0000
    Total (centered) SS     =  4396.587068                Centered R2   =   0.0664
    Total (uncentered) SS   =   12720.4953                Uncentered R2 =   0.6773
    Residual SS             =  4104.857494                Root MSE      =    1.686

    ------------------------------------------------------------------------------
                 |               Robust
               y |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |  -.7460301   .0680391   -10.96   0.000    -.8793842   -.6126759
            post |   .4444447   .3237889     1.37   0.170    -.1901699    1.079059
           _cons |  -1.217818   .1385799    -8.79   0.000     -1.48943   -.9462069
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             16.908
                                                       Chi-sq(1) P-val =    0.0000
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):             1147.000
                             (Kleibergen-Paap rk Wald F statistic):         97.539
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post
    Excluded instruments: z
    ------------------------------------------------------------------------------

``` stata
/* Basic balance test */
ivreg2 y_lag (x=z) post [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  2,    47) =     6.17
                                                          Prob > F      =   0.0042
    Total (centered) SS     =   5965.12058                Centered R2   =  -0.0095
    Total (uncentered) SS   =  11733.73695                Uncentered R2 =   0.4868
    Residual SS             =  6021.864871                Root MSE      =    2.042

    ------------------------------------------------------------------------------
                 |               Robust
           y_lag |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |  -.1306289   .1094679    -1.19   0.233     -.345182    .0839242
            post |   .2497804   .1641307     1.52   0.128    -.0719099    .5714706
           _cons |  -1.877539   .2665396    -7.04   0.000    -2.399947   -1.355131
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             16.908
                                                       Chi-sq(1) P-val =    0.0000
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):             1147.000
                             (Kleibergen-Paap rk Wald F statistic):         97.539
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post
    Excluded instruments: z
    ------------------------------------------------------------------------------

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

``` stata
/* Add sum of shares control */
preserve
use adh_shares, clear
collapse (sum) sum_share=ind_share, by(location year)
tempfile sum_shares
save `sum_shares', replace
restore
merge 1:1 location year using `sum_shares', nogen
summ sum_share
```

    (note: file /var/folders/m3/fzql5frx44nbt7v3j41h6l440000gn/T//S_23416.000002 not found)
    file /var/folders/m3/fzql5frx44nbt7v3j41h6l440000gn/T//S_23416.000002 saved

        Result                           # of obs.
        -----------------------------------------
        not matched                             0
        matched                             1,444  
        -----------------------------------------

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
       sum_share |      1,444    .2448133    .1418183          0   .7033063

``` stata
/* SSIV with Sum of Shares */
ivreg2 y (x=z) post sum_share [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  3,    47) =    72.28
                                                          Prob > F      =   0.0000
    Total (centered) SS     =  4396.587068                Centered R2   =   0.2671
    Total (uncentered) SS   =   12720.4953                Uncentered R2 =   0.7467
    Residual SS             =  3222.202106                Root MSE      =    1.494

    ------------------------------------------------------------------------------
                 |               Robust
               y |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |   -.464863   .0923312    -5.03   0.000    -.6458289   -.2838972
            post |  -.4181931   .3911119    -1.07   0.285    -1.184758    .3483721
       sum_share |  -5.804483   1.801034    -3.22   0.001    -9.334444   -2.274521
           _cons |   .0953533   .4024273     0.24   0.813    -.6933896    .8840963
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             15.093
                                                       Chi-sq(1) P-val =    0.0001
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              646.088
                             (Kleibergen-Paap rk Wald F statistic):         52.612
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post sum_share
    Excluded instruments: z
    ------------------------------------------------------------------------------

``` stata
/* Balance test with Sum of Shares */
ivreg2 y_lag (x=z) post sum_share [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  3,    47) =     3.73
                                                          Prob > F      =   0.0173
    Total (centered) SS     =   5965.12058                Centered R2   =   0.0597
    Total (uncentered) SS   =  11733.73695                Uncentered R2 =   0.5220
    Residual SS             =  5609.078366                Root MSE      =    1.971

    ------------------------------------------------------------------------------
                 |               Robust
           y_lag |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |   .1428534   .1110188     1.29   0.198    -.0747395    .3604463
            post |  -.5892802    .251948    -2.34   0.019    -1.083089   -.0954712
       sum_share |  -5.645837   1.710474    -3.30   0.001    -8.998304   -2.293371
           _cons |   -.600258   .4602922    -1.30   0.192    -1.502414    .3018981
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             15.093
                                                       Chi-sq(1) P-val =    0.0001
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              646.088
                             (Kleibergen-Paap rk Wald F statistic):         52.612
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post sum_share
    Excluded instruments: z
    ------------------------------------------------------------------------------

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

``` stata
/* Interact sum of shares with year */
gen post_sum_share=post*sum_share
```

\`\`\`\`\`\`

``` stata
ivreg2 y (x=z) post sum_share post_sum_share [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  4,    47) =    66.42
                                                          Prob > F      =   0.0000
    Total (centered) SS     =  4396.587068                Centered R2   =   0.3481
    Total (uncentered) SS   =   12720.4953                Uncentered R2 =   0.7747
    Residual SS             =  2866.338032                Root MSE      =    1.409

    --------------------------------------------------------------------------------
                   |               Robust
                 y |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    ---------------+----------------------------------------------------------------
                 x |  -.3138509   .0965684    -3.25   0.001    -.5031216   -.1245803
              post |   .9280979   .3410626     2.72   0.007     .2596275    1.596568
         sum_share |   -4.08933   1.784564    -2.29   0.022     -7.58701   -.5916493
    post_sum_share |  -7.025949   1.883592    -3.73   0.000    -10.71772   -3.334177
             _cons |  -.5596031   .3801593    -1.47   0.141    -1.304702    .1854955
    --------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             13.433
                                                       Chi-sq(1) P-val =    0.0002
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              513.936
                             (Kleibergen-Paap rk Wald F statistic):         40.980
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post sum_share post_sum_share
    Excluded instruments: z
    ------------------------------------------------------------------------------

``` stata
ivreg2 y_lag (x=z) post sum_share post_sum_share [aw=weight], cluster(state) 
```

    (sum of wgt is     2.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on state

    Number of clusters (state) =        48                Number of obs =     1444
                                                          F(  4,    47) =     9.64
                                                          Prob > F      =   0.0000
    Total (centered) SS     =   5965.12058                Centered R2   =   0.0636
    Total (uncentered) SS   =  11733.73695                Uncentered R2 =   0.5239
    Residual SS             =  5586.028167                Root MSE      =    1.967

    --------------------------------------------------------------------------------
                   |               Robust
             y_lag |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    ---------------+----------------------------------------------------------------
                 x |   .0548532   .1353977     0.41   0.685    -.2105213    .3202277
              post |  -1.373812    .260005    -5.28   0.000    -1.883413   -.8642119
         sum_share |  -6.645319   1.522569    -4.36   0.000    -9.629498   -3.661139
    post_sum_share |   4.094273   1.678152     2.44   0.015     .8051558     7.38339
             _cons |  -.2185914   .3992032    -0.55   0.584    -1.001015    .5638324
    --------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             13.433
                                                       Chi-sq(1) P-val =    0.0002
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              513.936
                             (Kleibergen-Paap rk Wald F statistic):         40.980
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: post sum_share post_sum_share
    Excluded instruments: z
    ------------------------------------------------------------------------------

``` stata
/* Check why sum of shares matters */
preserve
use adh_shocks, clear
reg shock year, cluster(industry)
restore
```

    Linear regression                               Number of obs     =        794
                                                    F(1, 396)         =      52.51
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.0476
                                                    Root MSE          =     28.051

                                 (Std. Err. adjusted for 397 clusters in industry)
    ------------------------------------------------------------------------------
                 |               Robust
           shock |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
            year |   1.252134   .1727881     7.25   0.000     .9124373    1.591831
           _cons |  -2486.937   343.7704    -7.23   0.000     -3162.78   -1811.094
    ------------------------------------------------------------------------------

*Comments:*

Interacting the sum-of-shares control with year isolates the within-year
variation in shocks. To see this take the year fixed effects as the
industry-level “q_n” discussed in class and note that to leverage this
control we need to control for sum_n (s_lnt*q_n) = sum_nt
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

``` stata
/* Get exposure-robust SEs with ssaggregate */
ssaggregate y x y_lag [aw=weight], ///
    n(industry) l(location) t(year) ///
    s(ind_share) sfilename(adh_shares) ///
    controls("post sum_share post_sum_share") 
merge 1:1 industry year using adh_shocks, nogen 
```

        Result                           # of obs.
        -----------------------------------------
        not matched                             0
        matched                               794  
        -----------------------------------------

``` stata
ivreg2 y (x=shock) i.year [aw=s_n], cluster(industry)
```

    (sum of wgt is     1.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on industry

    Number of clusters (industry) =    397                Number of obs =      794
                                                          F(  2,   396) =     4.73
                                                          Prob > F      =   0.0093
    Total (centered) SS     =  224.9468962                Centered R2   =   0.0399
    Total (uncentered) SS   =  224.9468962                Uncentered R2 =   0.0399
    Residual SS             =  215.9683306                Root MSE      =    .5215

    ------------------------------------------------------------------------------
                 |               Robust
               y |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |  -.3138509   .1019619    -3.08   0.002    -.5136925   -.1140093
                 |
            year |
           2000  |  -7.59e-09   .0572135    -0.00   1.000    -.1121364    .1121364
                 |
           _cons |   3.32e-09   .0494265     0.00   1.000    -.0968742    .0968742
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             10.947
                                                       Chi-sq(1) P-val =    0.0009
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              154.847
                             (Kleibergen-Paap rk Wald F statistic):         33.136
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: 2000.year
    Excluded instruments: shock
    ------------------------------------------------------------------------------

``` stata
ivreg2 y_lag (x=shock) i.year [aw=s_n], cluster(industry)
```

    (sum of wgt is     1.0000e+00)

    IV (2SLS) estimation
    --------------------

    Estimates efficient for homoskedasticity only
    Statistics robust to heteroskedasticity and clustering on industry

    Number of clusters (industry) =    397                Number of obs =      794
                                                          F(  2,   396) =     0.05
                                                          Prob > F      =   0.9503
    Total (centered) SS     =  406.4453938                Centered R2   =   0.0043
    Total (uncentered) SS   =  406.4453938                Uncentered R2 =   0.0043
    Residual SS             =  404.6782172                Root MSE      =    .7139

    ------------------------------------------------------------------------------
                 |               Robust
           y_lag |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
               x |   .0548532   .1742726     0.31   0.753    -.2867148    .3964211
                 |
            year |
           2000  |  -9.19e-09   .0228729    -0.00   1.000    -.0448301      .04483
                 |
           _cons |   6.82e-09   .0742794     0.00   1.000     -.145585     .145585
    ------------------------------------------------------------------------------
    Underidentification test (Kleibergen-Paap rk LM statistic):             10.947
                                                       Chi-sq(1) P-val =    0.0009
    ------------------------------------------------------------------------------
    Weak identification test (Cragg-Donald Wald F statistic):              154.847
                             (Kleibergen-Paap rk Wald F statistic):         33.136
    Stock-Yogo weak ID test critical values: 10% maximal IV size             16.38
                                             15% maximal IV size              8.96
                                             20% maximal IV size              6.66
                                             25% maximal IV size              5.53
    Source: Stock-Yogo (2005).  Reproduced by permission.
    NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
    ------------------------------------------------------------------------------
    Hansen J statistic (overidentification test of all instruments):         0.000
                                                     (equation exactly identified)
    ------------------------------------------------------------------------------
    Instrumented:         x
    Included instruments: 2000.year
    Excluded instruments: shock
    ------------------------------------------------------------------------------
