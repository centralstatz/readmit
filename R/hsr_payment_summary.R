#' Extract payment summary information a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#'
#' @description Parses Table 1 of the Hospital-Specific Report, either altogether in a single output or each component individually.
#'
#' @return A \code{\link[tibble]{tibble}} containing the columns \code{Measure} and \code{Value} for the metric and value, respectively.
#' @export
#'
#' @examples
#' my_report <- hsr_mock_reports("FY2021_HRRP_MockHSR.xlsx")
#' hsr_extract_payment_summary(my_report)
hsr_extract_payment_summary <-
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
        pattern = paste0("Payment Adjustment")
      ),
      skip = 4,
      n_max = 1,
      na = "--"
    ) |>

      # Convert all columns to numeric (pre-parse if needed)
      dplyr::mutate(
        dplyr::across(
          dplyr::where(is.character),
          \(x) as.numeric(stringr::str_remove(x, "[%]")) / 100
        ),
        dplyr::across(
          dplyr::everything(),
          as.numeric
        )
      ) |>

      # Send down the rows
      tidyr::pivot_longer(
        cols = dplyr::everything(),
        names_to = "Measure",
        values_to = "Value"
      )
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_count_dual_eligible_stays <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Dual Eligible Stays"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_count_total_stays <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Number of Stays"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_dual_proportion <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Dual Proportion"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_peer_group <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Peer Group"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_neutrality_modifier <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Neutrality Modifier"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_payment_adjustment_factor <-
  function(file) {
    file |>

      # Get the payment summary
      hsr_extract_payment_summary() |>

      # Filter to number of dually-eligible stays
      dplyr::filter(stringr::str_detect(
        Measure,
        pattern = "Adjustment Factor"
      )) |>

      # Pull the value
      dplyr::pull("Value")
  }

#' @export
#' @rdname hsr_extract_payment_summary
hsr_payment_penalty <- function(file) {
  # Use existing extraction (not all reports have the percentage)
  1 - hsr_payment_adjustment_factor(file)
}
