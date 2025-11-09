# Extract payment summary information a Hospital-Specific Report (HSR)

Parses Table 1 of the Hospital-Specific Report, either altogether in a
single output or each component individually.

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

  File path to a report

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html)
containing the columns `Measure` and `Value` for the metric and value,
respectively.

## Examples

``` r
my_report <- hsr_mock_reports("FY2021_HRRP_MockHSR.xlsx")
hsr_extract_payment_summary(my_report)
#> # A tibble: 6 × 2
#>   Measure                                           Value
#>   <chr>                                             <dbl>
#> 1 Number of Dual Eligible Stays (Numerator) [a]  2932    
#> 2 Total Number of Stays(Denominator) [b]        27178    
#> 3 Dual Proportion [c]                               0.108
#> 4 Peer Group Assignment [d]                         1    
#> 5 Neutrality Modifier [e]                           0.961
#> 6 Payment Adjustment Factor [f]                     1.000
```
