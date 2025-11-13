# Extract risk model coefficients from a Hospital-Specific Report (HSR)

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

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the columns:

- `Factor`: The model term name (as listed in the file)

- `Value`: The model coefficient value (on the linear predictor scale)

## Examples

``` r
my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
hsr_extract_coefficients(my_report, "HF")
#> # A tibble: 40 × 2
#>    Factor                                                                  Value
#>    <chr>                                                                   <dbl>
#>  1 "Years Over 65 (continuous)"                                         -0.00589
#>  2 "Male"                                                               -0.0359 
#>  3 "History of Coronary Artery Bypass Graft (CABG) Surgery"              0.0199 
#>  4 "History of COVID-19"                                                -0.00239
#>  5 "Metastatic Cancer and Acute Leukemia"                                0.149  
#>  6 "Cancer"                                                              0.0126 
#>  7 "Diabetes Mellitus (DM) or DM Complications"                          0.0968 
#>  8 "Protein-Calorie Malnutrition"                                        0.0856 
#>  9 "Other Significant Endocrine and Metabolic Disorders; Disorders of …  0.163  
#> 10 "Liver or Biliary Disease"                                            0.0865 
#> # ℹ 30 more rows
```
