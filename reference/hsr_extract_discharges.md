# Extract discharge-level data from a Hospital-Specific Report (HSR)

Parses out the discharge-level data for a specific program cohort that
contributed to penalty program in the reporting fiscal year (FY).

## Usage

``` r
hsr_extract_discharges(
  file,
  cohort,
  discharge_phi = TRUE,
  risk_factors = FALSE,
  eligible_only = FALSE
)
```

## Arguments

- file:

  File path to a report

- cohort:

  Cohort to extract the discharges for. One of
  `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`

- discharge_phi:

  Should discharge PHI be included? Defaults to `TRUE` (see details).

- risk_factors:

  Should readmission risk factors be included? Defaults to `FALSE` (see
  details).

- eligible_only:

  Should only eligible discharges be included? Defaults to `FALSE` (see
  details).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)

## Details

The first set of columns in the discharge level data (typically through
column R) contain the protected health information (PHI) associated with
the discharges, such as medical record identifiers,
admission/discharge/readmission dates, index diagnoses, etc. which can
be used to identify the specific patients contributing (and not
contributing) to the CMS penalty calculation for the cohort.

The risk factors contain the discharge-level clinical information used
for individual risk adjustment by CMS to estimate individual level
readmission rates. These can be useful to explore to understand risk
factor distributions and prevalence, especially in combination with
[`hsr_extract_coefficients()`](https://centralstatz.github.io/readmit/reference/hsr_extract_coefficients.md)
which indicates the risk factors most heavily-weighted in the
readmission risk calculation.

The HSR contains discharges that were not necessarily included/eligible
to be counted in the [Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp).
Setting `eligible_only = TRUE` will filter the returned result to only
those that are eligible, and thus should match the denominator displayed
in
[`hsr_extract_cohort_summary()`](https://centralstatz.github.io/readmit/reference/hsr_extract_cohort_summary.md).

## Examples

``` r
# Access a report
my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")

# All discharges
hsr_extract_discharges(my_report, "HF")
#> # A tibble: 30 × 17
#>    `ID Number` MBI         `Medical Record Number` `Beneficiary DOB`
#>          <int> <chr>       <chr>                   <chr>            
#>  1           1 9AA9AA9AA99 99999A                  99/99/9999       
#>  2           2 9AA9AA9AA99 99999A                  99/99/9999       
#>  3           3 9AA9AA9AA99 99999A                  99/99/9999       
#>  4           4 9AA9AA9AA99 99999A                  99/99/9999       
#>  5           5 9AA9AA9AA99 99999A                  99/99/9999       
#>  6           6 9AA9AA9AA99 99999A                  99/99/9999       
#>  7           7 9AA9AA9AA99 99999A                  99/99/9999       
#>  8           8 9AA9AA9AA99 99999A                  99/99/9999       
#>  9           9 9AA9AA9AA99 99999A                  99/99/9999       
#> 10          10 9AA9AA9AA99 99999A                  99/99/9999       
#> # ℹ 20 more rows
#> # ℹ 13 more variables: `Admission Date of Index Stay` <chr>,
#> #   `Discharge Date of Index Stay` <chr>,
#> #   `Cohort Inclusion/Exclusion Indicator` <chr>, `Index Stay (Yes/No)` <chr>,
#> #   `Principal Discharge Diagnosis of Index Stay` <chr>,
#> #   `Discharge Destination` <chr>,
#> #   `Unplanned \r\nReadmission within \r\n30 Days (Yes/No) [a]` <chr>, …


# Discharges eligible for HRRP
hsr_extract_discharges(my_report, "HF", eligible_only = TRUE)
#> # A tibble: 25 × 17
#>    `ID Number` MBI         `Medical Record Number` `Beneficiary DOB`
#>          <int> <chr>       <chr>                   <chr>            
#>  1           1 9AA9AA9AA99 99999A                  99/99/9999       
#>  2           2 9AA9AA9AA99 99999A                  99/99/9999       
#>  3           3 9AA9AA9AA99 99999A                  99/99/9999       
#>  4           4 9AA9AA9AA99 99999A                  99/99/9999       
#>  5           5 9AA9AA9AA99 99999A                  99/99/9999       
#>  6           6 9AA9AA9AA99 99999A                  99/99/9999       
#>  7           7 9AA9AA9AA99 99999A                  99/99/9999       
#>  8           8 9AA9AA9AA99 99999A                  99/99/9999       
#>  9           9 9AA9AA9AA99 99999A                  99/99/9999       
#> 10          10 9AA9AA9AA99 99999A                  99/99/9999       
#> # ℹ 15 more rows
#> # ℹ 13 more variables: `Admission Date of Index Stay` <chr>,
#> #   `Discharge Date of Index Stay` <chr>,
#> #   `Cohort Inclusion/Exclusion Indicator` <chr>, `Index Stay (Yes/No)` <chr>,
#> #   `Principal Discharge Diagnosis of Index Stay` <chr>,
#> #   `Discharge Destination` <chr>,
#> #   `Unplanned \r\nReadmission within \r\n30 Days (Yes/No) [a]` <chr>, …


# Only show risk factors for eligible discharges
hsr_extract_discharges(
   file = my_report,
   cohort = "HF",
   discharge_phi = FALSE,
   risk_factors = TRUE,
   eligible_only = TRUE
)
#> # A tibble: 25 × 39
#>    `ID Number` `Years Over 65 (continuous)`  Male History of Coronary Artery B…¹
#>          <int>                        <dbl> <dbl>                          <dbl>
#>  1           1                            8     1                              0
#>  2           2                           25     1                              1
#>  3           3                            9     0                              0
#>  4           4                            9     0                              0
#>  5           5                           30     0                              0
#>  6           6                           13     0                              0
#>  7           7                           12     1                              1
#>  8           8                            7     1                              1
#>  9           9                           25     1                              0
#> 10          10                           22     0                              0
#> # ℹ 15 more rows
#> # ℹ abbreviated name: ¹​`History of Coronary Artery Bypass Graft (CABG) Surgery`
#> # ℹ 35 more variables: `History of COVID-19` <dbl>,
#> #   `Metastatic Cancer and Acute Leukemia` <dbl>, Cancer <dbl>,
#> #   `Diabetes Mellitus (DM) or DM Complications` <dbl>,
#> #   `Protein-Calorie Malnutrition` <dbl>,
#> #   `Other Significant Endocrine and Metabolic Disorders; Disorders of Fluid/Electrolyte/\r\nAcid-base Balance` <dbl>, …

# Row count matches denominator for HF
hsr_extract_cohort_summary(my_report)
#> # A tibble: 6 × 10
#>   `Measure [a]` `Number of Eligible Discharges [b]` Number of Readmissions Amo…¹
#>   <chr>                                       <dbl>                        <dbl>
#> 1 AMI                                             2                            0
#> 2 COPD                                           18                            3
#> 3 HF                                             25                            2
#> 4 Pneumonia                                      32                            5
#> 5 CABG                                           NA                           NA
#> 6 THA/TKA                                        45                            0
#> # ℹ abbreviated name: ¹​`Number of Readmissions Among Eligible Discharges [c]`
#> # ℹ 7 more variables: `Predicted Readmission Rate [d]` <dbl>,
#> #   `Expected Readmission Rate [e]` <dbl>,
#> #   `Excess Readmission Ratio (ERR) [f]` <dbl>,
#> #   `Peer Group Median ERR [g]` <dbl>, `Penalty Indicator (Yes/No) [h]` <chr>,
#> #   `Ratio of DRG Payments Per Measure to Total Payments [i]` <dbl>,
#> #   `National Observed Readmission Rate [j]` <dbl>
```
