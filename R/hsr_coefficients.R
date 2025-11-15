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
hsr_coefficients <-
  function(file, cohort) {
    # Check arguments
    if (rlang::is_missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }
    cohort <- rlang::arg_match(
      cohort,
      values = c("AMI", "COPD", "HF", "PN", "CABG", "HK")
    )

    # Sheet names extracted from the report
    sheets <- readxl::excel_sheets(file)

    # Import file
    readxl::read_xlsx(
      path = file,
      sheet = stringr::str_subset(
        sheets,
        pattern = paste0("\\s", cohort, "\\s")
      ),
      skip = 6,
      n_max = 1,
      na = "--"
    ) |>

      # Convert all columns to numeric
      dplyr::mutate(
        dplyr::across(
          dplyr::everything(),
          as.numeric
        )
      ) |>

      # Send down the rows
      tidyr::pivot_longer(
        cols = dplyr::everything(),
        names_to = "Factor",
        values_to = "Value"
      ) |>

      # Remove non-coefficient columns
      dplyr::filter(!is.na(.data$Value))
  }
