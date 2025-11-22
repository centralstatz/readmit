#' Find relevant dates from the Hospital Readmissions Reduction Program (HRRP)
#'
#' @param ref A `Date` object
#' @param period The program period to extract dates for. One of `c("payment", "performance", "review")`.
#' @param discharge Should the `ref` date be taken as a _discharge_ date? Defaults to `TRUE`. If `FALSE`, it's taken to be a penalty/program date.
#'
#' @description
#' Identifies key dates (see [hrrp_keydates]) from the [Hospital Readmissions Reduction Program (HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp)
#' that are associated with an input reference date, such as performance and payment periods.
#'
#' @return A [tibble::tibble]
#'
#' @seealso [hrrp_keydates]
#'
#' @export
#'
#' @examples
#' my_date <- as.Date("2022-01-01")
#'
#' # What are the payment periods for this discharge?
#' hrrp_get_dates(my_date, period = "payment", discharge = TRUE)
#'
#' # What performance periods is this discharge included in?
#' hrrp_get_dates(my_date, period = "performance", discharge = TRUE)
#'
#' # What is the payment period overlapping this date?
#' hrrp_get_dates(my_date, period = "payment", discharge = FALSE)
#'
#' # What is the performance period whose penalty period overlaps this date?
#' hrrp_get_dates(my_date, period = "performance", discharge = FALSE)
#'
#' # What is the performance period for current penalty enforcement?
#' hrrp_get_dates(Sys.Date(), period = "performance", discharge = FALSE)
hrrp_get_dates <-
  function(
    ref,
    period = c("payment", "performance"),
    discharge = TRUE
  ) {
    # Check arguments
    if (rlang::is_missing(ref)) {
      stop("Specify one or more reference dates")
    }
    period <- rlang::arg_match(
      period,
      values = period
    )

    # Determine reference/lookup tables
    if (period == "payment") {
      # Return result from payment table
      ref_table <- hrrp_payment_periods
      lookup_table <- ref_table

      # If ref date is a discharge date, lookup based on performance
      if (discharge) {
        lookup_table <- hrrp_performance_periods
      }
    } else if (period == "performance") {
      # Return result based on performance table
      ref_table <- hrrp_performance_periods
      lookup_table <- ref_table

      # If ref date is not a discharge date, lookup based on penalty
      if (!discharge) {
        lookup_table <- hrrp_payment_periods
      }
    }

    # Determine lookup table

    # Find the matching program years
    program_years <-
      lookup_table |>

      # Keep included date range
      dplyr::filter(
        ref >= StartDate,
        ref <= EndDate
      ) |>

      # Pull out program year
      dplyr::pull("ProgramYear")

    # Get reference rows for desired years
    ref_table |>

      # Filter to previously-found years
      dplyr::filter(ProgramYear %in% program_years)

    # 4 possibilities to return a date (range)
    # 1. If period is payment
    # a. If type = discharge; return the dates where payments would occur for that discharge
    # b. If type = program; return the dates corresponding to the current payment period that overlaps that date
    # 2. If period is performance
    # a. If type = discharge; return dates that correspond to the performance period capturing that discharge date
    # b. If type = program; return the performance period for the program year in the entered reference date
  }
