#' Extract payment summary information from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report. For convenience functions, this can also be the pre-parsed table from `hsr_extract_payment_summary()` (to minimize file I/O).
#'
#' @description
#' Parses the Table 1 payment summary from the HSR, including (but not limited to) the payment penalty,
#' peer group the hospital was compared against, and dual proportion that determines peer group assignment.
#'
#' _**Note**: CMS changed the format of Hospital-Specific Reports (HSRs) for FY2026 (see [here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The current HSR functions support formats through FY2025._
#'
#' @return
#' * `hsr_payment_summary()` returns a [tibble::tibble()] containing the full Table 1 parsed from the report.
#' * Additional convenience functions extract specific columns from this table, and always return a numeric value.
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Full payment summary table
#' payment_summary <- hsr_payment_summary(my_report)
#' payment_summary
#'
#'
#' # Extract individual components (from file)
#' hsr_payment_penalty(my_report)
#'
#' # Or existing extract
#' hsr_payment_penalty(payment_summary)
hsr_payment_summary <-
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
      )
  }

#' @export
#' @rdname hsr_payment_summary
hsr_count_dual_stays <-
  function(file) {
    hsr_get_payment_summary_column(file, "Dual Eligible Stays")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_count_total_stays <-
  function(file) {
    hsr_get_payment_summary_column(file, "Number of Stays")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_dual_proportion <-
  function(file) {
    hsr_get_payment_summary_column(file, "Dual Proportion")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_peer_group <-
  function(file) {
    hsr_get_payment_summary_column(file, "Peer Group")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_neutrality_modifier <-
  function(file) {
    hsr_get_payment_summary_column(file, "Neutrality Modifier")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_payment_adjustment_factor <-
  function(file) {
    hsr_get_payment_summary_column(file, "Adjustment Factor")
  }

#' @export
#' @rdname hsr_payment_summary
hsr_payment_penalty <- function(file) {
  # Use existing extraction (not all reports have the percentage)
  1 - hsr_payment_adjustment_factor(file)
}

# Helper function to retrieve the table
hsr_get_payment_summary_table <-
  function(file) {
    # If it's a string, then import the file; otherwise it's already the table
    if (is.character(file)) {
      file <- hsr_payment_summary(file)
    }

    file
  }

# Helper function to extract the individual column value from the table
hsr_get_payment_summary_column <-
  function(file, col) {
    file |>

      # Get the payment summary
      hsr_get_payment_summary_table() |>

      # Select dual-eligible stays
      dplyr::select(dplyr::matches(col)) |>

      # Pull the value
      dplyr::pull(1)
  }
