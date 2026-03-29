#' Parse a Hospital-Specific Report (HSR)
#'
#' @param path File path to a report.
#' @param format Optional format override. Defaults to `NULL`, in which case
#'   [hsr_detect_format()] is used.
#' @param validate Should the parsed object be validated before returning?
#'   Defaults to `TRUE`.
#' @param ... Reserved for future parser-specific options.
#'
#' @description
#' Parses a Hospital-Specific Report (HSR) into a lightweight internal object
#' that can be reused by downstream helpers. Phase 1 support is limited to the
#' legacy Excel-based HSR format used through FY2025.
#'
#' The parsed object preserves current legacy section outputs as much as
#' possible, while also retaining raw parser metadata for debugging and future
#' format support.
#'
#' If `format` is left `NULL`, `hsr_detect_format()` is used to identify the
#' supported parser to apply.
#'
#' @return A `readmit_hsr` object.
#' @export
#'
#' @examples
#' report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#' parsed <- hsr_read(report)
#' parsed
hsr_read <- function(path, format = NULL, validate = TRUE, ...) {
  if (rlang::is_missing(path)) {
    stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
  }

  path <- normalizePath(path, mustWork = TRUE)

  if (is.null(format)) {
    format <- hsr_detect_format(path)
  }

  parser <- switch(
    format,
    legacy_excel = hsr_parse_legacy_excel,
    stop("Unsupported HSR format: ", format)
  )

  parsed <- parser(path, ...)

  if (isTRUE(validate)) {
    validate_hsr(parsed)
  }

  parsed
}

#' Detect the format of a Hospital-Specific Report (HSR)
#'
#' @param path File path to a report.
#'
#' @description
#' Detects the broad file format of a Hospital-Specific Report (HSR). Phase 1
#' only recognizes the legacy Excel-based format used through FY2025.
#'
#' @return A scalar character string describing the detected format.
#' @export
#'
#' @examples
#' report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#' hsr_detect_format(report)
hsr_detect_format <- function(path) {
  if (rlang::is_missing(path)) {
    stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
  }

  path <- normalizePath(path, mustWork = TRUE)

  ext <- tolower(tools::file_ext(path))
  if (!ext %in% c("xlsx", "xls")) {
    stop("Unsupported HSR file type: ", ext)
  }

  sheets <- readxl::excel_sheets(path)
  legacy_signals <- c("Payment Adjustment", "Hospital Results", "Dual Stays")

  if (all(vapply(
    legacy_signals,
    function(signal) any(stringr::str_detect(sheets, stringr::fixed(signal))),
    logical(1)
  ))) {
    return("legacy_excel")
  }

  stop("Unable to detect a supported HSR format for this file.")
}

#' Check whether an object is a parsed HSR
#'
#' @param x An object to test.
#'
#' @return `TRUE` if `x` inherits from class `\"readmit_hsr\"`, otherwise
#'   `FALSE`.
#' @export
#'
#' @examples
#' report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#' parsed <- hsr_read(report)
#' is_hsr(parsed)
#' is_hsr(report)
is_hsr <- function(x) {
  inherits(x, "readmit_hsr")
}

#' @export
print.readmit_hsr <- function(x, ...) {
  cohort_names <- names(x$cohorts)
  cohort_names <- cohort_names[nzchar(cohort_names)]

  cat("<readmit_hsr>\n")
  cat("  Source:", x$meta$source, "\n")
  cat("  Format:", x$meta$format, "\n")
  cat("  Sections:", paste(names(x$sections), collapse = ", "), "\n")
  cat("  Cohorts:", paste(cohort_names, collapse = ", "), "\n")
  invisible(x)
}

hsr_as_parsed <- function(x, ...) {
  if (is_hsr(x)) {
    validate_hsr(x)
    return(x)
  }

  if (is.character(x) && length(x) == 1) {
    return(hsr_read(x, ...))
  }

  stop("`x` must be a file path or a parsed HSR object.")
}

validate_hsr <- function(x) {
  if (!is_hsr(x)) {
    stop("`x` must inherit from class 'readmit_hsr'.")
  }

  required_top_level <- c("meta", "sections", "cohorts", "raw", "issues")
  missing_top_level <- setdiff(required_top_level, names(x))
  if (length(missing_top_level) > 0) {
    stop(
      "Parsed HSR is missing required top-level fields: ",
      paste(missing_top_level, collapse = ", ")
    )
  }

  required_meta <- c("source", "format")
  missing_meta <- setdiff(required_meta, names(x$meta))
  if (length(missing_meta) > 0) {
    stop(
      "Parsed HSR metadata is missing required fields: ",
      paste(missing_meta, collapse = ", ")
    )
  }

  required_sections <- c("payment_summary", "cohort_summary", "dual_stays")
  missing_sections <- setdiff(required_sections, names(x$sections))
  if (length(missing_sections) > 0) {
    stop(
      "Parsed HSR is missing required sections: ",
      paste(missing_sections, collapse = ", ")
    )
  }

  validate_hsr_payment_summary(x$sections$payment_summary)
  validate_hsr_cohort_summary(x$sections$cohort_summary)
  validate_hsr_dual_stays(x$sections$dual_stays)

  cohort_names <- c("AMI", "COPD", "HF", "PN", "CABG", "HK")
  if (!all(cohort_names %in% names(x$cohorts))) {
    stop("Parsed HSR must contain the standard HRRP cohort entries.")
  }

  for (cohort in cohort_names) {
    validate_hsr_cohort_entry(x$cohorts[[cohort]], cohort)
  }

  invisible(x)
}

validate_hsr_payment_summary <- function(x) {
  if (!inherits(x, "data.frame")) {
    stop("`sections$payment_summary` must be a data frame.")
  }

  required_patterns <- c(
    "Dually Eligible Stays",
    "Total Number of Stays",
    "Dual Proportion",
    "Peer Group Assignment",
    "Neutrality Modifier",
    "Payment Adjustment Factor"
  )

  missing_patterns <- required_patterns[!vapply(
    required_patterns,
    function(pattern) any(stringr::str_detect(names(x), stringr::fixed(pattern))),
    logical(1)
  )]

  if (length(missing_patterns) > 0) {
    stop(
      "`sections$payment_summary` is missing required columns matching: ",
      paste(missing_patterns, collapse = ", ")
    )
  }
}

validate_hsr_cohort_summary <- function(x) {
  if (!inherits(x, "data.frame")) {
    stop("`sections$cohort_summary` must be a data frame.")
  }

  if (!any(stringr::str_detect(names(x), "^Measure"))) {
    stop("`sections$cohort_summary` must contain a measure column.")
  }
}

validate_hsr_dual_stays <- function(x) {
  if (!inherits(x, "data.frame")) {
    stop("`sections$dual_stays` must be a data frame.")
  }

  if (!"ID Number" %in% names(x)) {
    stop("`sections$dual_stays` must contain 'ID Number'.")
  }
}

validate_hsr_cohort_entry <- function(x, cohort) {
  required_fields <- c("discharges", "coefficients", "extras")
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0) {
    stop(
      "Parsed HSR cohort entry '", cohort,
      "' is missing required fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  if (!inherits(x$discharges, "data.frame")) {
    stop("`cohorts[['", cohort, "']]$discharges` must be a data frame.")
  }
  if (!inherits(x$coefficients, "data.frame")) {
    stop("`cohorts[['", cohort, "']]$coefficients` must be a data frame.")
  }

  if (!"ID Number" %in% names(x$discharges)) {
    stop("`cohorts[['", cohort, "']]$discharges` must contain 'ID Number'.")
  }

  if (!all(c("Factor", "Value") %in% names(x$coefficients))) {
    stop(
      "`cohorts[['", cohort,
      "']]$coefficients` must contain 'Factor' and 'Value'."
    )
  }
}
