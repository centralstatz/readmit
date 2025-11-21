#' Extract risk model coefficients from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#' @param cohort Cohort to extract the coefficients for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#'
#' @description
#' Parses out the regression coefficients from the logistic regression model
#' used by CMS to estimate discharge-level readmission risk,
#' including the hospital-level and hospital average intercept terms.
#'
#' @return A [tibble::tibble()] containing the columns:
#' * `Factor`: The model term name (as listed in the file)
#' * `Value`: The model coefficient value (on the linear predictor scale)
#'
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Show coefficients for heart failure model
#' hsr_coefficients(my_report, "HF")
hrrp_timeline <-
  function(
    period,
    type,
    ref_date = Sys.Date(),
    format = "%Y",
    range = FALSE,
    range_func = max
  ) {
    # Extract period
    period <- rlang::arg_match(
      period,
      values = c("payment", "performance")
    )

    # Extract type
    type <- rlang::arg_match(
      type,
      values = c("discharge", "program")
    )

    if (period == "payment") {
      if (type == "discharge") {} else if (type == "program") {}
    } else if (period == "performance") {
      if (type == "discharge") {} else if (type == "program") {}
    }

    # 4 possibilities to return a date (range)
    # 1. If period is payment
    # a. If type = discharge; return the dates where payments would occur for that discharge
    # b. If type = program; return the dates corresponding to the current payment period that overlaps that date
    # 2. If period is performance
    # a. If type = discharge; return dates that correspond to the performance period capturing that discharge date
    # b. If type = program; return the performance period for the program year in the entered reference date
  }
