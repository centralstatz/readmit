#' Retrieve file location of mock Hospital-Specific Reports (HSR)
#'
#' @param path Name of file. If NULL, all files will be listed.
#'
#' @description
#' Provides the location of mock HSRs downloaded from QualityNet that come with the package that users can import.
#' These files are a representation of what a hospital's real report looks like when received from CMS.
#' They contain mock data for sensitive fields (discharge level data, etc.), but real data for national level results (e.g., model coefficients).
#' Thus, it gives user ability to practice/explore package functions and translate them to their own hospital reports.
#' Files include fiscal years (FY) 2019-2025 and were downloaded on 11/8/2025 from [https://qualitynet.cms.gov/inpatient/hrrp/reports](https://qualitynet.cms.gov/inpatient/hrrp/reports).
#' File names were changed for better identifiability.
#'
#' _**Note**: CMS changed the format of Hospital-Specific Reports (HSRs) for FY2026 (see [here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The current HSR functions support formats through FY2025._
#'
#' @return A character string or vector of strings
#'
#' @export
#'
#' @details
#' This function was adapted from [readxl::readxl_example()].
#'
#' @examples
#' # Show all available mock reports
#' hsr_mock_reports()
#'
#' # Show path to a single report
#' hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Use mock report for testing package functions
#' hsr_payment_summary(hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx"))
hsr_mock_reports <- function(path = NULL) {
  if (is.null(path)) {
    dir(system.file("extdata", package = "readmit"))
  } else {
    system.file("extdata", path, package = "readmit", mustWork = TRUE)
  }
}
