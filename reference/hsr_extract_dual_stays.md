# Extract dually-eligible discharges from a Hospital-Specific Report (HSR)

Parses the discharge-level records from the HSR of patients who were
dually-eligible for Medicare and Medicaid benefits (see details).

## Usage

``` r
hsr_extract_dual_stays(file)
```

## Arguments

- file:

  File path to a report

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)

## Details

In the [Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp),
hospitals' readmission rates are compared against a peer group of "like"
hospitals, which determines whether or not they will get penalized
financially.

The peer group allocation done by [CMS](https://www.cms.gov/) is
determined by creating hospital groupings based on the share of Medicare
beneficiaries who were also eligible for Medicaid benefits, a marker of
socioeconomic status in the hospital population.
`hsr_extract_dual_stays()` extracts the list of discharges accounting
for the numerator of this ratio.

## Examples

``` r
my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
hsr_extract_dual_stays(my_report)
#> # A tibble: 186 × 6
#>    `ID Number` MBI         `Beneficiary DOB` `Admission Date` `Discharge Date`
#>          <int> <chr>       <chr>             <chr>            <chr>           
#>  1           1 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  2           2 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  3           3 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  4           4 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  5           5 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  6           6 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  7           7 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  8           8 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#>  9           9 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#> 10          10 9AA9AA9AA99 99/99/9999        99/99/9999       99/99/9999      
#> # ℹ 176 more rows
#> # ℹ 1 more variable: `Claim Type` <chr>
```
