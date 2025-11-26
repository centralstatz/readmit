# Investigating a Hospital-Specific Report (HSR)

*Work in progress*

***Note**: CMS changed the format of Hospital-Specific Reports (HSRs)
for FY2026 (see
[here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The
current HSR functions support Excel-based formats through FY2025.*

As part of the [Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp),
the [Centers for Medicare & Medicaid Services
(CMS)](https://www.cms.gov/) provides a detailed, annual program summary
report (called the [Hospital-Specific Report
(HSR)](https://qualitynet.cms.gov/inpatient/hrrp/reports)) to hospitals
that includes details on the penalty calculation for the upcoming fiscal
year, such as discharge-level data, dually-eligible discharge lists,
cohort-level rollup, and the penalty amount. There is a defined [review
and correction period](https://centralstatz.github.io/readmit/articles/)
in which hospitals can use these reports to ensure the penalty being
enforced by CMS is accurate. It occurs approximately 1 month before the
new fiscal year, thus it is a time-critical event (see date ranges below
through the built-in package datasets):

``` r
# Extract date ranges
readmit::hrrp_keydates |>
  dplyr::select(
    ProgramYear,
    dplyr::matches("^(Payment|Review)")
  ) |>
  dplyr::distinct()
#> # A tibble: 9 × 5
#>   ProgramYear PaymentStartDate PaymentEndDate ReviewStartDate ReviewEndDate
#>         <dbl> <date>           <date>         <chr>           <chr>        
#> 1        2027 2026-10-01       2027-09-30     NA              NA           
#> 2        2026 2025-10-01       2026-09-30     2025-08-12      2025-09-10   
#> 3        2025 2024-10-01       2025-09-30     2024-08-12      2024-09-10   
#> 4        2024 2023-10-01       2024-09-30     2023-08-08      2023-09-07   
#> 5        2023 2022-10-01       2023-09-30     2022-08-08      2022-09-07   
#> 6        2022 2021-10-01       2022-09-30     2021-08-09      2021-09-08   
#> 7        2021 2020-10-01       2021-09-30     2020-08-10      2020-09-09   
#> 8        2020 2019-10-01       2020-09-30     2019-08-09      2019-09-09   
#> 9        2019 2018-10-01       2019-09-30     2018-08-06      2018-09-05
```

The report file itself is a large, multi-tab Microsoft Excel document
where the structured part of the data is ambiguously placed throughout,
thus we need tools to parse it out into a usable format. That is what
some functions `readmit` package are for. In this article, we go through
the tools that are available, what they do, and then provide some
strategies/approaches for how hospitals can use these tools to analyze
their own HSR’s to gain deeper insight into HRRP results and
readmissions more broadly.

## The Toolbox

First, we’ll start by taking a look at what relevant functions are
available to us, what they do, and how to use them. For our purposes,
these are all of the functions prefixed like `hsr_*`. We’ll do this
roughly in order of how the report is laid out, and how the HRRP results
roll up.

### 0. Mock Reports

As the developer of this package, I don’t have access to hospitals’
actual HSR’s, as they contain senstivie patient information (i.e.,
[PHI](https://centralstatz.github.io/readmit/articles/)) and thus are
not publicly available. So what we have to work with are *mock* reports
that [CMS
provides](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2) to the
public that are meant to mimick the exact format a hospital can expect
their report to be in. It just includes fake data.

- Provides a nice practice environment
- Issues with dates, we can fix to make them more “real”

### 1. Program Summary

- Show review periods, how they overlap with payment (the timing of it)
- Emphasize validation/correction period. These are some ways to help
  validate.

## Analysis Strategies

## Reconciling the penalty

- Start with first page, compute from there based on cohort page
- We can go a level deeper: how were those risks calculated? Compute
  readmission risks, reproduce Cohort quantities.

## Exploring risk distributions

- Model risk factors
- Risk factor prevalence
- Risk factor prevalence by model weight (scatterplot)

``` r
library(readmit)
hsr_mock_reports()
#> [1] "FY2019_HRRP_MockHSR.xlsx" "FY2020_HRRP_MockHSR.xlsx"
#> [3] "FY2021_HRRP_MockHSR.xlsx" "FY2022_HRRP_MockHSR.xlsx"
#> [5] "FY2023_HRRP_MockHSR.xlsx" "FY2024_HRRP_MockHSR.xlsx"
#> [7] "FY2025_HRRP_MockHSR.xlsx"
```
