#' Get path to an example Hospital-Specific Report (HSR)
#'
#' @param path Name of file. If NULL, the example file will be listed.
#'
#' @description Provides the location of the example HSR that comes with the package for users to access with package functions. This file is for FY 2025 program year downloaded on 11/8/2025 from https://qualitynet.cms.gov/inpatient/hrrp/reports.
#'
#' @export
#'
#' @examples
#' hsr_example()
#' hsr_example("999999_HRRP_Readmissions_HSR.xlsx")
hsr_example <- function(path = NULL) {
  if (is.null(path)) {
    dir(system.file("extdata", package = "readmit"))
  } else {
    system.file("extdata", path, package = "readmit", mustWork = TRUE)
  }
}
