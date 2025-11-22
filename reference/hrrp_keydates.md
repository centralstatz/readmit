# Key dates from the Hospital Readmissions Reduction Program (HRRP)

A collection of datasets giving important dates involved in the
[Hospital Readmissions Reduction Program
(HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp),
including performance periods, payment periods, review and correction
periods, claims snapshot dates, and cohort inclusion status for program
years since 2019. The data is manually abstracted from
[QualityNet](https://qualitynet.cms.gov/inpatient/hrrp/resources#tab1)
and was most recently updated on 11/21/2025.

All tables contain the `ProgramYear`, which is the HRRP program (or
federal fiscal year) in question. Tables with date ranges contain a
`StartDate` and `EndDate` contain the beginning and end dates of the
respective interval. Other tables contain individual dates or indicators
for cohort inclusion (see descriptions).

## Usage

``` r
hrrp_keydates

hrrp_performance_periods

hrrp_payment_periods

hrrp_review_periods

hrrp_snapshot_dates

hrrp_cohort_inclusion
```

## Format

### `hrrp_performance_periods`

Start and end dates for discharges evaluated for readmissions. Note some
program years have multiple performance intervals and are represented on
separate rows of this table.

### `hrrp_payment_periods`

Start and end dates for when payment penalties are applied by CMS to
hospital reimbursement.

### `hrrp_review_periods`

Start and end dates for the review and correction period where hospitals
could review discharge-level data and downstream calculations of penalty
amounts.

### `hrrp_snapshot_dates`

The *as of* date for when claims data were extracted by CMS for
evaluation in the program. *Note some discrepancies exist in CMS
documentation for these dates (e.g., FY2026) when comparing anticipated
versus actual snapshot date. The latter was used in this case.*

### `hrrp_cohort_inclusion`

Indicators of whether each cohort was included in the program for the
given year. `1` = included, `0` = excluded.

- AMI:

  Acute Myocardial Infarction

- COPD:

  Chronic Obstructive Pulmonary Disease

- HF:

  Heart Failure

- PN:

  Pneumonia

- CABG:

  Coronary Artery Bypass Graft

- HK:

  Total Hip/Knee Replacement

### `hrrp_keydates`

A combined table that joins all of the above individual tables into a
single common table with altered column names.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 11
rows and 3 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 9
rows and 3 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 3 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 9
rows and 2 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 9
rows and 7 columns.

## Source

<https://qualitynet.cms.gov/inpatient/hrrp/resources#tab1>
