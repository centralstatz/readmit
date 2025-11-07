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
if (FALSE) { # \dontrun{
my_report <- "Readmissions_HSR.xlsx"
hsr_extract_coefficients(my_report, "AMI")
} # }
```
