# Compute discharge-level readmission risks in a Hospital-Specific Report (HSR)

Computes the *predicted* and *expected* readmission risks for each
eligible discharge in the specified cohort.

## Usage

``` r
hsr_readmission_risks(file, cohort)
```

## Arguments

- file:

  File path to a report

- cohort:

  Cohort to compute readmission risks for. One of
  `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the following columns:

- `ID Number`: The unique discharge identifier (see
  [`hsr_discharges()`](https://centralstatz.github.io/readmit/reference/hsr_discharges.md))

- `Predicted`: The predicted readmission risk for the discharge

- `Expected`: The expected readmission risk for the discharge

## Details

The [readmission
measure](https://qualitynet.cms.gov/inpatient/measures/readmission) is
what [CMS](https://www.cms.gov/) uses to grade performance in the
[Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp).

Individual discharges are assigned an adjusted readmission risk (based
on clinical history), which then get aggregated into a hospital-level
score and compared to peer groups for penalty determination.
Specifically, a random-intercept logistic regression model is built for
each cohort ([see
methodology](https://qualitynet.cms.gov/inpatient/measures/readmission/methodology))
which serves as the basis for two (2) readmission risks assigned to each
discharge:

- *Predicted*: Adjusted for patient-specific clinical factors plus the
  *hospital-specific* effect (random intercept term)

- *Expected*: Adjusted for patient-specific clinical factors plus the
  *hospital-average* effect

These quantities are then aggregated across all discharges and their
ratio is taken to form the *Excess Readmission Ratio (ERR)*, which is
then used as the cohort-specific comparison metric. Thus, it is a
comparative measure of how likely patients are to be readmitted at
*your* hospital versus the *average* hospital, given your hospital's
clinical characteristics.

## Examples

``` r
# Access a report
my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")

# Compute readmission risks for HF discharges
hf_risks <- hsr_readmission_risks(my_report, "HF")
hf_risks
#> # A tibble: 25 × 3
#>    `ID Number` Predicted Expected
#>          <int>     <dbl>    <dbl>
#>  1           1    0.258    0.264 
#>  2           2    0.186    0.192 
#>  3           3    0.184    0.189 
#>  4           4    0.188    0.193 
#>  5           5    0.0857   0.0885
#>  6           6    0.133    0.138 
#>  7           7    0.110    0.113 
#>  8           8    0.183    0.188 
#>  9           9    0.163    0.168 
#> 10          10    0.179    0.184 
#> # ℹ 15 more rows

# Compute the ERR from scratch
hf_risks |>
 dplyr::summarize(
   Discharges = dplyr::n(),
   Predicted = mean(Predicted),
   Expected = mean(Expected),
   ERR = Predicted / Expected
 )
#> # A tibble: 1 × 4
#>   Discharges Predicted Expected   ERR
#>        <int>     <dbl>    <dbl> <dbl>
#> 1         25     0.159    0.164 0.971


# Check that this matches the report table
hsr_cohort_summary(my_report) |>
 dplyr::select(
  dplyr::matches(
     paste0(
       "^Measure|",
       "^Number of Eligible Discharges|",
       "^Predicted|",
       "^Expected|",
       "^Excess"
     )
   )
 )
#> # A tibble: 6 × 5
#>   `Measure [a]` `Number of Eligible Discharges [b]` Predicted Readmission Rate…¹
#>   <chr>                                       <dbl>                        <dbl>
#> 1 AMI                                             2                       0.181 
#> 2 COPD                                           18                       0.165 
#> 3 HF                                             25                       0.159 
#> 4 Pneumonia                                      32                       0.142 
#> 5 CABG                                           NA                      NA     
#> 6 THA/TKA                                        45                       0.0350
#> # ℹ abbreviated name: ¹​`Predicted Readmission Rate [d]`
#> # ℹ 2 more variables: `Expected Readmission Rate [e]` <dbl>,
#> #   `Excess Readmission Ratio (ERR) [f]` <dbl>
```
