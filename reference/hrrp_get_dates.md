# Find relevant dates from the Hospital Readmissions Reduction Program (HRRP)

Identifies key dates (see
[hrrp_keydates](https://centralstatz.github.io/readmit/reference/hrrp_keydates.md))
from the [Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp)
that are associated with an input reference date, such as performance
and payment periods.

## Usage

``` r
hrrp_get_dates(ref, period = c("payment", "performance"), discharge = TRUE)
```

## Arguments

- ref:

  A `Date` object

- period:

  The program period to extract dates for. One of
  `c("payment", "performance")`.

- discharge:

  Should the `ref` date be taken as a *discharge* date? Defaults to
  `TRUE`. If `FALSE`, it's taken to be a penalty/program date.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)

## See also

[hrrp_keydates](https://centralstatz.github.io/readmit/reference/hrrp_keydates.md)

## Examples

``` r
my_date <- as.Date("2022-01-01")

# What are the payment periods for this discharge?
hrrp_get_dates(my_date, period = "payment", discharge = TRUE)
#> # A tibble: 3 × 3
#>   ProgramYear StartDate  EndDate   
#>         <int> <date>     <date>    
#> 1        2026 2025-10-01 2026-09-30
#> 2        2025 2024-10-01 2025-09-30
#> 3        2024 2023-10-01 2024-09-30

# What performance periods is this discharge included in?
hrrp_get_dates(my_date, period = "performance", discharge = TRUE)
#> # A tibble: 4 × 3
#>   ProgramYear StartDate  EndDate   
#>         <dbl> <chr>      <chr>     
#> 1        2026 2021-07-01 2024-06-30
#> 2        2025 2020-07-01 2023-06-30
#> 3        2024 2019-07-01 2019-12-01
#> 4        2024 2020-07-01 2022-06-30

# What is the payment period overlapping this date?
hrrp_get_dates(my_date, period = "payment", discharge = FALSE)
#> # A tibble: 1 × 3
#>   ProgramYear StartDate  EndDate   
#>         <int> <date>     <date>    
#> 1        2022 2021-10-01 2022-09-30

# What is the performance period whose penalty period overlaps this date?
hrrp_get_dates(my_date, period = "performance", discharge = FALSE)
#> # A tibble: 1 × 3
#>   ProgramYear StartDate  EndDate   
#>         <dbl> <chr>      <chr>     
#> 1        2022 2017-07-01 2019-12-01

# What is the performance period for current penalty enforcement?
hrrp_get_dates(Sys.Date(), period = "performance", discharge = FALSE)
#> # A tibble: 1 × 3
#>   ProgramYear StartDate  EndDate   
#>         <dbl> <chr>      <chr>     
#> 1        2026 2021-07-01 2024-06-30
```
