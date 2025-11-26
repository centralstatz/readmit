#' Extract dually-eligible discharges from a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#'
#' @description
#' Parses the discharge-level records from the HSR of patients who were
#' dually-eligible for Medicare and Medicaid benefits (see details).
#'
#' _**Note**: CMS changed the format of Hospital-Specific Reports (HSRs) for FY2026 (see [here](https://qualitynet.cms.gov/inpatient/hrrp/reports#tab2)). The current HSR functions support formats through FY2025._
#'
#' @details
#' In the [Hospital Readmissions Reduction Program (HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp),
#' hospitals' readmission rates are compared against a peer group of "like" hospitals, which determines whether or not they will
#' get penalized financially.
#'
#' The peer group allocation done by [CMS](https://www.cms.gov/) is determined by creating hospital groupings based
#' on the share of Medicare beneficiaries who were also eligible for Medicaid benefits, a marker of socioeconomic status
#' in the hospital population. `hsr_dual_stays()` extracts the list of discharges accounting for the numerator of this ratio.
#'
#' @return A [tibble::tibble()]
#'
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Extract dually-eligible stays as a dataset
#' hsr_dual_stays(my_report)
hsr_dual_stays <-
  function(file) {
    # Check arguments
    if (rlang::is_missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }

    # Sheet names extracted from the report
    sheets <- readxl::excel_sheets(file)

    # Import file (with extra rows we don't want)
    readxl::read_xlsx(
      path = file,
      sheet = stringr::str_subset(
        sheets,
        pattern = paste0("Dual Stays")
      ),
      skip = 5,
      na = c("--", "N/A")
    ) |>

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
  }
