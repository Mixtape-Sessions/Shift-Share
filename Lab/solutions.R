## Example solutions for SSIV Lab
## Written by Peter Hull & Kyle Butts
## 5/16/2022 (v1)

devtools::install_github("kylebutts/ssaggregate")
library(tidyverse) # Data Cleaning
library(fixest) # Regressions
library(here) # Relative file paths
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


# Basic SSIV and balance 
df |> 
  feols(
    y ~ post | 0 | x ~ z, weights = ~weight, cluster = ~state
  )

df |> 
  feols(
    y_lag ~ post | 0 | x ~ z, weights = ~weight, cluster = ~state
  )




# Add sum of shares control
df <- adh_shares |> 
  group_by(location, year) |> 
  summarize(sum_share = sum(ind_share)) |> 
  left_join(df, by=c("location", "year"))

summary(df$sum_share)

# SSIV with Sum of Shares 
df |> 
  feols(
    y ~ post + sum_share | 0 | x ~ z, weights = ~weight, cluster = ~state
  )

# Balance Test with Sum of Shares 
df |> 
  feols(
    y_lag ~ post + sum_share | 0 | x ~ z, weights = ~weight, cluster = ~state
  )




# Interact sum of shares with year

# SSIV with Sum of Shares x Year
df |> 
  feols(
    y ~ post + i(post, sum_share) | 0 | x ~ z, weights = ~weight, cluster = ~state
  )

# Balance Test with Sum of Shares x Year
df |> 
  feols(
    y_lag ~ post + i(post, sum_share) | 0 | x ~ z, weights = ~weight, cluster = ~state
  )

# Check why sum of shares matters
adh_shocks |> 
  feols(shock ~ i(year), cluster = ~industry)



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

ssagg_df |> 
  feols(y ~ 1 | year | x ~ shock, weights = ~s_n, cluster = ~industry)

ssagg_df |> 
  feols(y_lag ~ 1 | year | x ~ shock, weights = ~s_n, cluster = ~industry)
