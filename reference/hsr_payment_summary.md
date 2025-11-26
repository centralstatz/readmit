# Extract payment summary information from a Hospital-Specific Report (HSR)

Parses the Table 1 payment summary from the HSR, including (but not
limited to) the payment penalty, peer group the hospital was compared
against, and dual proportion that determines peer group assignment.

***Note**: CMS changed the format of Hospital-Specific Reports (HSRs)
for FY2026 (see
[here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The
current HSR functions support formats through FY2025.*

## Usage

``` r
hsr_payment_summary(file)

hsr_count_dual_stays(file)

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

- `hsr_payment_summary()` returns a
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  containing the full Table 1 parsed from the report.

- Additional convenience functions extract specific columns from this
  table, and always return a numeric value.

## Examples

``` r
# Access a report
my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")

# Full payment summary table
payment_summary <- hsr_payment_summary(my_report)
payment_summary
#> # A tibble: 1 × 7
#>   Number of Dually Eligible Stays…¹ Total Number of Stay…² `Dual Proportion [c]`
#>                               <dbl>                  <dbl>                 <dbl>
#> 1                               186                    856                 0.217
#> # ℹ abbreviated names: ¹​`Number of Dually Eligible Stays (Numerator) [a]`,
#> #   ²​`Total Number of Stays(Denominator) [b]`
#> # ℹ 4 more variables: `Peer Group Assignment [d]` <dbl>,
#> #   `Neutrality Modifier [e]` <dbl>, `Payment Reduction Percentage [f]` <dbl>,
#> #   `Payment Adjustment Factor [g]` <dbl>


# Extract individual components (from file)
hsr_payment_penalty(my_report)
#> [1] 7e-04

# Or existing extract
hsr_payment_penalty(payment_summary)
#> [1] 7e-04
```
