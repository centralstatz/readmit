# Extract model coefficients from a Hospital-Specific Report (HSR)

Parses out the regression coefficients from the logistic regression
model used by CMS to estimate discharge-level readmission risk,
including the hospital-level and hospital average intercept terms.

## Usage

``` r
hsr_extract_coefficients(file, cohort)
```

## Arguments

- file:

  File path to a report

- cohort:

  Cohort to extract the coefficients for. One of
  `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html)
containing the columns `Factor` and `Value` for the model term and
coefficient value, respectively (on the linear-predictor scale).

## Examples

``` r
my_report <- hsr_mock_reports("FY2021_HRRP_MockHSR.xlsx")
hsr_extract_coefficients(my_report, "AMI")
#> # A tibble: 33 × 2
#>    Factor                                                                Value
#>    <chr>                                                                 <dbl>
#>  1 "Age Minus 65"                                                      0.00998
#>  2 "Male"                                                             -0.0937 
#>  3 "Anterior Myocardial Infarction \r\n"                               0.272  
#>  4 "Non-Anterior Location of Myocardial Infarction"                    0.0160 
#>  5 "History of Coronary Artery Bypass Graft (CABG) Surgery"            0.00330
#>  6 "History of Percutaneous Transluminal Coronary Angioplasty (PTCA)" -0.0108 
#>  7 "Severe Infection; Other Infectious Diseases"                       0.0181 
#>  8 "Metastatic Cancer and Acute Leukemia"                              0.247  
#>  9 "Cancer"                                                            0.0309 
#> 10 "Diabetes Mellitus (DM) or DM Complications"                        0.181  
#> # ℹ 23 more rows
```
