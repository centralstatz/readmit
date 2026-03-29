#' Parse an HSR source bundle
#'
#' @param x A local HSR source bundle path or a `readmit_hsr_source` object.
#' @param spec A parser configuration created by `hsr_parser_config()`.
#' @param ... Reserved for future parser options.
#'
#' @description
#' Parses a local HSR source bundle into a lightweight conceptual bundle. The
#' parsed bundle tracks component outputs separately from source artifacts and
#' preserves artifact lineage and raw parser metadata.
#'
#' @return A `readmit_hsr_bundle` object.
#' @export
#'
#' @examples
#' bundle_path <- file.path(tempdir(), "hsr_bundle")
#' dir.create(bundle_path, recursive = TRUE)
#' utils::write.csv(
#'   data.frame(metric = "payment_adjustment_factor", value = 0.98),
#'   file.path(bundle_path, "payment_summary.csv"),
#'   row.names = FALSE
#' )
#' hsr_parse(bundle_path, spec = hsr_parser_config())
hsr_parse <- function(x, spec = hsr_parser_config(), ...) {
  spec <- validate_hsr_parser_config(spec)

  source <- if (is_hsr_source(x)) {
    validate_hsr_source(x)
  } else {
    hsr_resolve_source(x, spec = spec, ...)
  }

  hsr_parse_csv_bundle(source, spec = spec, ...)
}

#' Check whether an object is a parsed HSR bundle
#'
#' @param x An object to test.
#'
#' @return `TRUE` if `x` inherits from class `\"readmit_hsr_bundle\"`,
#'   otherwise `FALSE`.
#' @export
is_hsr_bundle <- function(x) {
  inherits(x, "readmit_hsr_bundle")
}

#' @export
print.readmit_hsr_bundle <- function(x, ...) {
  validate_hsr_bundle(x)

  non_empty <- vapply(x$components, nrow, integer(1))
  shown <- non_empty[non_empty > 0]

  cat("<readmit_hsr_bundle>\n")
  cat("  Source path:", x$source$location$path, "\n")
  cat("  Parser:", x$meta$parser, "\n")
  cat("  Source artifacts:", nrow(x$source$artifacts), "\n")
  cat(
    "  Non-empty components:",
    if (length(shown) > 0) {
      paste(paste0(names(shown), "=", shown), collapse = ", ")
    } else {
      "none"
    },
    "\n"
  )
  cat("  Lineage rows:", nrow(x$lineage), "\n")
  cat("  Issues:", length(x$issues), "\n")
  invisible(x)
}

validate_hsr_bundle <- function(x) {
  if (!is_hsr_bundle(x)) {
    stop("`x` must inherit from class 'readmit_hsr_bundle'.")
  }

  required_fields <- c("meta", "source", "components", "lineage", "raw", "issues")
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0) {
    stop(
      "Parsed HSR bundle is missing required fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  validate_hsr_source(x$source)

  if (!is.list(x$meta)) {
    stop("`meta` must be a list.")
  }
  if (!is.list(x$raw)) {
    stop("`raw` must be a list.")
  }
  if (!"artifact_outputs" %in% names(x$raw) || !is.list(x$raw$artifact_outputs)) {
    stop("`raw$artifact_outputs` must exist and be a list.")
  }
  if (!is.character(x$issues)) {
    stop("`issues` must be a character vector.")
  }

  required_components <- c(
    "discharges",
    "coefficients",
    "payment_summary",
    "cohort_summary",
    "dual_stays"
  )
  missing_components <- setdiff(required_components, names(x$components))
  if (length(missing_components) > 0) {
    stop(
      "Parsed HSR bundle is missing required components: ",
      paste(missing_components, collapse = ", ")
    )
  }

  invalid_components <- required_components[!vapply(
    x$components[required_components],
    inherits,
    logical(1),
    what = "data.frame"
  )]
  if (length(invalid_components) > 0) {
    stop(
      "Parsed HSR components must be data frames: ",
      paste(invalid_components, collapse = ", ")
    )
  }

  if (!inherits(x$lineage, "data.frame")) {
    stop("`lineage` must be a data frame.")
  }

  required_lineage_cols <- c("artifact_id", "component", "output_id", "n_rows")
  missing_lineage_cols <- setdiff(required_lineage_cols, names(x$lineage))
  if (length(missing_lineage_cols) > 0) {
    stop(
      "`lineage` is missing required columns: ",
      paste(missing_lineage_cols, collapse = ", ")
    )
  }

  if (nrow(x$lineage) > 0) {
    if (!all(x$lineage$artifact_id %in% x$source$artifacts$artifact_id)) {
      stop("`lineage$artifact_id` values must refer to known source artifacts.")
    }
    if (!all(x$lineage$component %in% names(x$components))) {
      stop("`lineage$component` values must refer to known components.")
    }
  }

  invisible(x)
}
