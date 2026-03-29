hsr_parse_legacy_excel <- function(path, ...) {
  sheets <- readxl::excel_sheets(path)
  cohort_names <- c("AMI", "COPD", "HF", "PN", "CABG", "HK")

  parsed <- structure(
    list(
      meta = list(
        source = path,
        format = "legacy_excel",
        fiscal_year = hsr_parse_legacy_fiscal_year(path),
        parsed_at = Sys.time()
      ),
      sections = list(
        payment_summary = hsr_parse_legacy_payment_summary(path),
        cohort_summary = hsr_parse_legacy_cohort_summary(path),
        dual_stays = hsr_parse_legacy_dual_stays(path)
      ),
      cohorts = stats::setNames(
        lapply(
          cohort_names,
          function(cohort) {
            list(
              discharges = hsr_parse_legacy_discharges(path, cohort),
              coefficients = hsr_parse_legacy_coefficients(path, cohort),
              extras = list()
            )
          }
        ),
        cohort_names
      ),
      raw = list(
        sheet_names = sheets,
        sections = list(
          payment_summary = list(sheet = hsr_find_legacy_sheet(sheets, "Payment Adjustment")),
          cohort_summary = list(sheet = hsr_find_legacy_sheet(sheets, "Hospital Results")),
          dual_stays = list(sheet = hsr_find_legacy_sheet(sheets, "Dual Stays")),
          cohorts = stats::setNames(
            lapply(
              cohort_names,
              function(cohort) {
                list(sheet = hsr_find_legacy_sheet(sheets, paste0("\\s", cohort, "\\s")))
              }
            ),
            cohort_names
          )
        )
      ),
      issues = character()
    ),
    class = "readmit_hsr"
  )

  parsed
}

hsr_parse_legacy_payment_summary <- function(path) {
  hsr_payment_summary(path)
}

hsr_parse_legacy_cohort_summary <- function(path) {
  hsr_cohort_summary(path)
}

hsr_parse_legacy_dual_stays <- function(path) {
  hsr_dual_stays(path)
}

hsr_parse_legacy_discharges <- function(path, cohort) {
  hsr_discharges_legacy(
    file = path,
    cohort = cohort,
    discharge_phi = TRUE,
    risk_factors = TRUE,
    eligible_only = FALSE
  )
}

hsr_parse_legacy_coefficients <- function(path, cohort) {
  hsr_coefficients_legacy(path, cohort)
}

hsr_parse_legacy_fiscal_year <- function(path) {
  matches <- stringr::str_match(basename(path), "FY([0-9]{4})")[, 2]

  if (is.na(matches)) {
    return(NA_integer_)
  }

  as.integer(matches)
}

hsr_find_legacy_sheet <- function(sheets, pattern) {
  match <- stringr::str_subset(sheets, pattern = pattern)

  if (length(match) < 1) {
    return(NA_character_)
  }

  match[[1]]
}
