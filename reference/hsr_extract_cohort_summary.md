# Extract cohort summary information from a Hospital-Specific Report (HSR)

Parses the Table 2 cohort summary from the HSR, including (but not
limited to) the discharge/readmission volumes, predicted/expected
readmission rates, peer group medians, and DRG ratios.

## Usage

``` r
hsr_extract_cohort_summary(file)
```

## Arguments

- file:

  File path to a report.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the full Table 2 parsed from the report.

## Examples

``` r
my_report <- hsr_mock_reports("FY2021_HRRP_MockHSR.xlsx")
cohort_summary <- hsr_extract_cohort_summary(my_report)
cohort_summary
#> # A tibble: 6 × 10
#>   `Measure [a]` `Number of Eligible Discharges [b]` Number of Readmissions Amo…¹
#>   <chr>                                       <dbl>                        <dbl>
#> 1 AMI                                            16                            2
#> 2 COPD                                           11                            4
#> 3 HF                                             27                            6
#> 4 Pneumonia                                      17                            2
#> 5 CABG                                           NA                           NA
#> 6 THA/TKA                                        12                            0
#> # ℹ abbreviated name: ¹​`Number of Readmissions Among Eligible Discharges [c]`
#> # ℹ 7 more variables: `Predicted Readmission Rate [d]` <dbl>,
#> #   `Expected Readmission Rate [e]` <dbl>,
#> #   `Excess Readmission Ratio (ERR) [f]` <dbl>,
#> #   `Peer Group Median ERR [g]` <dbl>, `Penalty Indicator (Yes/No) [h]` <chr>,
#> #   `Ratio of DRG Payments Per Measure to Total Payments [i]` <dbl>,
#> #   `National Observed Readmission Rate [j]` <dbl>
```
