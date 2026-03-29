#' Extract risk model coefficients from a Hospital-Specific Report (HSR)
#'
#' @param file A parsed HSR bundle or a local source bundle path.
#' @param cohort Cohort to extract the coefficients for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#'
#' @description
#' Extracts the regression coefficients from the parsed HSR `coefficients`
#' component for a given cohort.
#'
#' @return A [tibble::tibble()] containing the columns:
#' * `Factor`: The model term name (as listed in the file)
#' * `Value`: The model coefficient value (on the linear predictor scale)
#'
#' @export
#'
#' @examples
#' bundle_path <- file.path(tempdir(), "hsr_bundle")
#' dir.create(bundle_path, recursive = TRUE)
#' utils::write.csv(
#'   data.frame(
#'     cohort = c("HF", "HF"),
#'     term = c("AGE", "HOSP_EFFECT"),
#'     value = c(0.25, -0.10)
#'   ),
#'   file.path(bundle_path, "coefficients.csv"),
#'   row.names = FALSE
#' )
#' hsr_coefficients(bundle_path, "HF")
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

    hsr_require_component(file, "coefficients") |>
      hsr_require_fields("coefficients", c("cohort", "term", "value")) |>
      hsr_filter_component_cohort("coefficients", cohort) |>
      dplyr::transmute(
        Factor = .data$term,
        Value = as.numeric(.data$value)
      ) |>
      dplyr::filter(!is.na(.data$Value))
  }

hsr_coefficients_legacy <-
  function(file, cohort) {
    sheets <- readxl::excel_sheets(file)

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
      dplyr::rename_with(
        \(x) stringr::str_remove_all(x, "[[:cntrl:]]")
      ) |>
      dplyr::mutate(
        dplyr::across(
          dplyr::everything(),
          as.numeric
        )
      ) |>
      tidyr::pivot_longer(
        cols = dplyr::everything(),
        names_to = "Factor",
        values_to = "Value"
      ) |>
      dplyr::filter(!is.na(.data$Value))
  }
