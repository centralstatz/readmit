# Extract payment summary information from a Hospital-Specific Report (HSR)

Parses the Table 1 payment summary from the HSR, including (but not
limited to) the payment penalty, peer group the hospital was compared
against, and dual proportion that determines peer group assignment.

## Usage

``` r
hsr_extract_payment_summary(file)

hsr_count_dual_eligible_stays(file)

hsr_count_total_stays(file)

hsr_dual_proportion(file)

hsr_peer_group(file)

hsr_neutrality_modifier(file)

hsr_payment_adjustment_factor(file)

hsr_payment_penalty(file)
```

## Arguments

- file:

  File path to a report. For convenience functions, this can also be the
  pre-parsed table from `hsr_extract_payment_summary()` (to minimize
  file I/O).

## Value

- `hsr_extract_payment_summary()` returns a
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  containing the full Table 1 parsed from the report.

- Additional convenience functions extract specific columns from this
  table, and always return a numeric value.

## Examples

``` r
my_report <- hsr_mock_reports("FY2021_HRRP_MockHSR.xlsx")
payment_summary <- hsr_extract_payment_summary(my_report)
payment_summary
#> # A tibble: 1 × 6
#>   Number of Dual Eligible Stays (…¹ Total Number of Stay…² `Dual Proportion [c]`
#>                               <dbl>                  <dbl>                 <dbl>
#> 1                              2932                  27178                 0.108
#> # ℹ abbreviated names: ¹​`Number of Dual Eligible Stays (Numerator) [a]`,
#> #   ²​`Total Number of Stays(Denominator) [b]`
#> # ℹ 3 more variables: `Peer Group Assignment [d]` <dbl>,
#> #   `Neutrality Modifier [e]` <dbl>, `Payment Adjustment Factor [f]` <dbl>

hsr_payment_penalty(my_report)
#> [1] 2e-04
hsr_payment_penalty(payment_summary)
#> [1] 2e-04
```
