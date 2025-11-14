# Retrieve file location of mock Hospital-Specific Reports (HSR)

Provides the location of mock HSRs downloaded from QualityNet that come
with the package that users can import. These files are a representation
of what a hospital's real report looks like when received from CMS. They
contain mock data for sensitive fields (discharge level data, etc.), but
real data for national level results (e.g., model coefficients). Thus,
it gives user ability to practice/explore package functions and
translate them to their own hospital reports. Files include fiscal years
(FY) 2019-2025 and were downloaded on 11/8/2025 from
<https://qualitynet.cms.gov/inpatient/hrrp/reports>. File names were
changed for better identifiability.

## Usage

``` r
hsr_mock_reports(path = NULL)
```

## Arguments

- path:

  Name of file. If NULL, all files will be listed.

## Details

This function was adapted from
[`readxl::readxl_example()`](https://readxl.tidyverse.org/reference/readxl_example.html).

## Examples

``` r
# Show all available mock reports
hsr_mock_reports()
#> [1] "FY2019_HRRP_MockHSR.xlsx" "FY2020_HRRP_MockHSR.xlsx"
#> [3] "FY2021_HRRP_MockHSR.xlsx" "FY2022_HRRP_MockHSR.xlsx"
#> [5] "FY2023_HRRP_MockHSR.xlsx" "FY2024_HRRP_MockHSR.xlsx"
#> [7] "FY2025_HRRP_MockHSR.xlsx"

# Show path to a single report
hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#> [1] "/home/runner/work/_temp/Library/readmit/extdata/FY2025_HRRP_MockHSR.xlsx"

# Use mock report for testing package functions
hsr_extract_payment_summary(hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx"))
#> # A tibble: 1 × 7
#>   Number of Dually Eligible Stays…¹ Total Number of Stay…² `Dual Proportion [c]`
#>                               <dbl>                  <dbl>                 <dbl>
#> 1                               186                    856                 0.217
#> # ℹ abbreviated names: ¹​`Number of Dually Eligible Stays (Numerator) [a]`,
#> #   ²​`Total Number of Stays(Denominator) [b]`
#> # ℹ 4 more variables: `Peer Group Assignment [d]` <dbl>,
#> #   `Neutrality Modifier [e]` <dbl>, `Payment Reduction Percentage [f]` <dbl>,
#> #   `Payment Adjustment Factor [g]` <dbl>
```
