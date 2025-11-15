#' Extract discharge-level data from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#' @param cohort Cohort to extract the discharges for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#' @param discharge_phi Should discharge PHI be included? Defaults to `TRUE` (see details).
#' @param risk_factors Should readmission risk factors be included? Defaults to `FALSE` (see details).
#' @param eligible_only Should only eligible discharges be included? Defaults to `FALSE` (see details).
#'
#' @description
#' Parses out the discharge-level data for a specific program cohort that contributed to penalty program in the reporting fiscal year (FY).
#'
#' @details
#' The first set of columns in the discharge level data (typically through column R) contain the protected health information (PHI)
#' associated with the discharges, such as medical record identifiers, admission/discharge/readmission dates, index diagnoses, etc. which
#' can be used to identify the specific patients contributing (and not contributing) to the CMS penalty calculation for the cohort.
#'
#' The risk factors contain the discharge-level clinical information used for individual risk adjustment by
#' CMS to estimate individual level readmission rates. These can be useful to explore to understand risk factor
#' distributions and prevalence, especially in combination with [hsr_coefficients()] which indicates the
#' risk factors most heavily-weighted in the readmission risk calculation.
#'
#' The HSR contains discharges that were not necessarily included/eligible to be counted in the
#' [Hospital Readmissions Reduction Program (HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp).
#' Setting `eligible_only = TRUE` will filter the returned result to only those that are eligible, and thus should match the denominator
#' displayed in [hsr_cohort_summary()].
#'
#' @return A [tibble::tibble()]
#'
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # All discharges
#' hsr_discharges(my_report, "HF")
#'
#'
#' # Discharges eligible for HRRP
#' hsr_discharges(my_report, "HF", eligible_only = TRUE)
#'
#'
#' # Only show risk factors for eligible discharges
#' hsr_discharges(
#'    file = my_report,
#'    cohort = "HF",
#'    discharge_phi = FALSE,
#'    risk_factors = TRUE,
#'    eligible_only = TRUE
#' )
#'
#' # Row count matches denominator for HF
#' hsr_cohort_summary(my_report)
hsr_discharges <-
  function(
    file,
    cohort,
    discharge_phi = TRUE,
    risk_factors = FALSE,
    eligible_only = FALSE
  ) {
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

    # Import file (with extra rows we don't want)
    temp_discharges <-
      readxl::read_xlsx(
        path = file,
        sheet = stringr::str_subset(
          sheets,
          pattern = paste0("\\s", cohort, "\\s")
        ),
        skip = 6,
        na = c("--", "N/A")
      ) |>

      # Always remove model intercept columns
      dplyr::select(-dplyr::matches("_EFFECT$"))

    # Identify rows to keep
    discharges <-
      temp_discharges |>

      # Parse extraneous values to missing
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of("ID Number"),
          \(.id) {
            dplyr::case_when(
              stringr::str_detect(.id, "[^0-9]") ~ NA_character_,
              TRUE ~ .id
            ) |>
              as.integer()
          }
        )
      ) |>

      # Filter out "missing" ID's
      dplyr::filter(!is.na(.data$`ID Number`))

    # Check for eligible only inclusion
    if (eligible_only) {
      discharges <-
        discharges |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::matches("Cohort Inclusion"),
            \(.inc) .inc == "0"
          )
        )
    }

    ## Identify columns to keep

    # Get initial possible column set
    candidates <-
      temp_discharges[1, ] |>

      # Send down the rows
      tidyr::pivot_longer(
        cols = dplyr::everything(),
        names_to = "Column",
        values_to = "Value",
        values_transform = list(Value = as.character)
      )

    # Sequentially apply filters
    if (!discharge_phi) {
      candidates <- candidates |> dplyr::filter(!is.na(.data$Value))
    }
    if (!risk_factors) {
      candidates <- candidates |> dplyr::filter(is.na(.data$Value))
    }

    # Make final selection
    discharges |>
      dplyr::select(
        dplyr::any_of(
          c(
            "ID Number",
            candidates$Column
          )
        )
      )
  }
