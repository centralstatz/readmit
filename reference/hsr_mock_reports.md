# Get path to mock Hospital-Specific Reports (HSR)

Provides the location of mock HSRs downloaded from QualityNet that come
with the package that users can import. These files are a representation
of what a hospital's real report looks like when received from CMS. They
contain mock data for sensitive fields (discharge level data, etc.), but
real data for national level results (e.g., model coefficients). Thus,
it gives user ability to practice/explore package functions and
translate them to their own hospital reports. Files include fiscal years
(FY) 2019-2025 and were downloaded on 11/8/2025 from
https://qualitynet.cms.gov/inpatient/hrrp/reports. File names were
changed for better identifiability.

## Usage

``` r
hsr_mock_reports(path = NULL)
```

## Arguments

- path:

  Name of file. If NULL, all files will be listed.

## Examples

``` r
hsr_mock_reports()
#> [1] "FY2019_HRRP_MockHSR.xlsx" "FY2020_HRRP_MockHSR.xlsx"
#> [3] "FY2021_HRRP_MockHSR.xlsx" "FY2022_HRRP_MockHSR.xlsx"
#> [5] "FY2023_HRRP_MockHSR.xlsx" "FY2024_HRRP_MockHSR.xlsx"
#> [7] "FY2025_HRRP_MockHSR.xlsx"
hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#> [1] "/home/runner/work/_temp/Library/readmit/extdata/FY2025_HRRP_MockHSR.xlsx"
```
