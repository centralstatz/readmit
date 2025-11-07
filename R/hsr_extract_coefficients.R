#' Extract model coefficients from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#' @param cohort Cohort to extract the coefficients for. One of \code{c("AMI", "COPD", "HF", "PN", "CABG", "HK")}
#'
#' @description Parses out the regression coefficients from the logistic regression model used by CMS to estimate discharge-level readmission risk, including the hospital-level and hospital average intercept terms.
#'
#' @return A \code{\link[tibble]{tibble}} containing the columns \code{Factor} and \code{Value} for the model term and coefficient value, respectively (on the linear-predictor scale).
#' @export
#'
#' @examples
#' \dontrun{
#' my_report <- "Readmissions_HSR.xlsx"
#' hsr_extract_coefficients(my_report, "AMI")
#' }
hsr_extract_coefficients <-
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
      dplyr::filter(!is.na(Value))
  }
