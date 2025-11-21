#' Key dates from the Hospital Readmissions Reduction Program (HRRP)
#'
#' @description
#'
#' A collection of datasets giving important dates involved in the [Hospital Readmissions Reduction Program (HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp),
#' including performance periods, payment periods, review and correction periods, claims snapshot dates, and cohort inclusion
#' status for program years since 2019. The data is manually abstracted from [QualityNet](https://qualitynet.cms.gov/inpatient/hrrp/resources#tab1) and
#' was most recently updated on 11/21/2025.
#'
#' All tables contain the `ProgramYear`, which is the HRRP program (or federal fiscal year) in question.
#' Tables with date ranges contain a `StartDate` and `EndDate` contain the beginning and end dates of the
#' respective interval. Other tables contain individual dates or indicators for cohort inclusion (see descriptions).
#'
#' @format ## `hrrp_performance_periods`
#' Start and end dates for discharges evaluated for readmissions. Note some program years
#' have multiple performance intervals and are represented on separate rows of this table.
#'
#' @format ## `hrrp_payment_periods`
#' Start and end dates for when payment penalties are applied by CMS to hospital reimbursement.
#'
#' @format ## `hrrp_review_periods`
#' Start and end dates for the review and correction period where hospitals could review discharge-level data
#' and downstream calculations of penalty amounts.
#'
#' @format ## `hrrp_snapshot_dates`
#' The _as of_ date for when claims data were extracted by CMS for evaluation in the program. _Note some discrepancies
#' exist in CMS documentation for these dates (e.g., FY2026) when comparing anticipated versus actual snapshot date. The
#' latter was used in this case._
#'
#' @format ## `hrrp_cohort_inclusion`
#' Indicators of whether each cohort was included in the program for the given year. `1` = included, `0` = excluded.
#' \describe{
#'   \item{AMI}{Acute Myocardial Infarction}
#'   \item{COPD}{Chronic Obstructive Pulmonary Disease}
#'   \item{HF}{Heart Failure}
#'   \item{PN}{Pneumonia}
#'   \item{CABG}{Coronary Artery Bypass Graft}
#'   \item{HK}{Total Hip/Knee Replacement}
#' }
#'
#' @format ## `hrrp_keydates`
#' A combined table that joins all of the above individual tables into a single common table with altered column names.
#'
#' @source <https://qualitynet.cms.gov/inpatient/hrrp/resources#tab1>
"hrrp_keydates"

#' @rdname hrrp_keydates
"hrrp_performance_periods"

#' @rdname hrrp_keydates
"hrrp_payment_periods"

#' @rdname hrrp_keydates
"hrrp_review_periods"

#' @rdname hrrp_keydates
"hrrp_snapshot_dates"

#' @rdname hrrp_keydates
"hrrp_cohort_inclusion"
