#' Resolve an HSR source bundle
#'
#' @param x Path to a local HSR source bundle.
#' @param spec A parser configuration created by `hsr_parser_config()`.
#' @param ... Reserved for future source-resolution options.
#'
#' @description
#' Resolves a local source bundle for Hospital-Specific Report (HSR) parsing.
#' The returned object inventories source artifacts but does not parse them into
#' conceptual components.
#'
#' @return A `readmit_hsr_source` object.
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
#' hsr_resolve_source(bundle_path, spec = hsr_parser_config())
hsr_resolve_source <- function(x, spec = hsr_parser_config(), ...) {
  if (rlang::is_missing(x)) {
    stop("Specify a local HSR source bundle path.")
  }

  hsr_resolve_local(x, spec = spec, ...)
}

#' Check whether an object is an HSR source bundle
#'
#' @param x An object to test.
#'
#' @return `TRUE` if `x` inherits from class `\"readmit_hsr_source\"`,
#'   otherwise `FALSE`.
#' @export
is_hsr_source <- function(x) {
  inherits(x, "readmit_hsr_source")
}

#' @export
print.readmit_hsr_source <- function(x, ...) {
  validate_hsr_source(x)

  cat("<readmit_hsr_source>\n")
  cat("  Path:", x$location$path, "\n")
  cat("  Artifacts:", nrow(x$artifacts), "\n")
  cat("  Issues:", length(x$issues), "\n")

  if (nrow(x$artifacts) > 0) {
    hint_counts <- sort(table(x$artifacts$role_hint), decreasing = TRUE)
    cat(
      "  Role hints:",
      paste(paste0(names(hint_counts), "=", as.integer(hint_counts)), collapse = ", "),
      "\n"
    )
  }

  invisible(x)
}

hsr_resolve_local <- function(path, spec = hsr_parser_config(), ...) {
  spec <- validate_hsr_parser_config(spec)
  path <- normalizePath(path, mustWork = TRUE)

  if (!dir.exists(path)) {
    stop("`path` must point to a local directory.")
  }

  artifact_paths <- list.files(
    path = path,
    pattern = spec$artifacts$include_pattern,
    recursive = TRUE,
    full.names = TRUE
  )

  artifacts <- tibble::tibble(
    artifact_id = paste0("artifact_", seq_along(artifact_paths)),
    path = artifact_paths,
    format = rep("csv", length(artifact_paths)),
    role_hint = vapply(artifact_paths, hsr_guess_artifact_role, character(1), spec = spec),
    name = basename(artifact_paths)
  )

  source <- structure(
    list(
      meta = list(
        source_type = "local",
        subtype = "csv_bundle",
        resolved_at = Sys.time(),
        spec_name = spec$meta$name
      ),
      location = list(path = path),
      artifacts = artifacts,
      issues = character()
    ),
    class = "readmit_hsr_source"
  )

  validate_hsr_source(source)
}

validate_hsr_source <- function(x) {
  if (!is_hsr_source(x)) {
    stop("`x` must inherit from class 'readmit_hsr_source'.")
  }

  required_fields <- c("meta", "location", "artifacts", "issues")
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0) {
    stop(
      "HSR source bundle is missing required fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  if (!is.list(x$location) || !is.character(x$location$path) || length(x$location$path) != 1) {
    stop("`location$path` must be a scalar character path.")
  }
  if (!dir.exists(x$location$path)) {
    stop("`location$path` must exist.")
  }

  if (!inherits(x$artifacts, "data.frame")) {
    stop("`artifacts` must be a data frame.")
  }

  required_cols <- c("artifact_id", "path", "format", "role_hint", "name")
  missing_cols <- setdiff(required_cols, names(x$artifacts))
  if (length(missing_cols) > 0) {
    stop(
      "`artifacts` is missing required columns: ",
      paste(missing_cols, collapse = ", ")
    )
  }

  if (nrow(x$artifacts) > 0) {
    if (!all(vapply(x$artifacts$path, is.character, logical(1)))) {
      stop("`artifacts$path` entries must be character.")
    }
    if (anyNA(x$artifacts$artifact_id) || anyDuplicated(x$artifacts$artifact_id)) {
      stop("`artifacts$artifact_id` values must be unique and non-missing.")
    }
    if (!all(file.exists(x$artifacts$path))) {
      stop("All `artifacts$path` values must exist.")
    }
  }

  if (!is.character(x$issues)) {
    stop("`issues` must be a character vector.")
  }

  invisible(x)
}

hsr_guess_artifact_role <- function(path, spec) {
  spec <- validate_hsr_parser_config(spec)
  name <- tolower(basename(path))

  for (component in names(spec$artifacts$role_hints)) {
    hints <- spec$artifacts$role_hints[[component]]

    if (any(vapply(
      hints,
      function(hint) stringr::str_detect(name, stringr::fixed(tolower(hint))),
      logical(1)
    ))) {
      return(component)
    }
  }

  "unknown"
}
