#' Extract cohort summary information from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report.
#'
#' @description
#' Parses the Table 2 cohort summary from the HSR, including (but not limited to) the discharge/readmission volumes,
#' predicted/expected readmission rates, peer group medians, and DRG ratios.
#'
#' _**Note**: CMS changed the format of Hospital-Specific Reports (HSRs) for FY2026 (see [here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The current HSR functions support formats through FY2025._
#'
#' @return A [tibble::tibble()] containing the full Table 2 parsed from the report.
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Extract the cohort summary as a dataset
#' hsr_cohort_summary(my_report)
hsr_cohort_summary <-
  function(file) {
    # Check arguments
    if (rlang::is_missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }

    # Sheet names extracted from the report
    sheets <- readxl::excel_sheets(file)

    # Import file
    readxl::read_xlsx(
      path = file,
      sheet = stringr::str_subset(
        sheets,
        pattern = paste0("Hospital Results")
      ),
      skip = 4,
      n_max = 6,
      na = c("--", "NQ")
    )
  }
