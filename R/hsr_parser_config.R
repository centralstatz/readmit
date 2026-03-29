#' Create an HSR parser configuration
#'
#' @param artifacts Optional artifact-level overrides.
#' @param components Optional component-level overrides.
#'
#' @description
#' Creates a parser configuration object that controls how local HSR source
#' bundles are interpreted. The package provides built-in defaults for file
#' inclusion, artifact role hints, embedded component markers, and basic column
#' aliases, while allowing users to override selected assumptions when their
#' files differ.
#'
#' @return A `readmit_hsr_spec` object.
#' @export
#'
#' @examples
#' spec <- hsr_parser_config()
#' spec$artifacts$role_hints$payment_summary <- c("payment", "summary_table")
#' spec
hsr_parser_config <- function(artifacts = NULL, components = NULL) {
  spec <- structure(
    list(
      meta = list(
        version = 1L,
        name = "default_csv"
      ),
      artifacts = list(
        include_pattern = "\\.csv$",
        role_hints = list(
          payment_summary = c("payment"),
          cohort_summary = c("cohort"),
          dual_stays = c("dual"),
          discharges = c("discharge"),
          coefficients = c("coeff")
        )
      ),
      components = list(
        payment_summary = list(
          column_aliases = list(
            metric = c("metric", "name"),
            value = c("value", "amount")
          )
        ),
        cohort_summary = list(
          cohort_column = c("cohort", "measure"),
          column_aliases = list(
            cohort = c("cohort", "measure")
          )
        ),
        dual_stays = list(
          id_column = c("ID Number", "ID.Number", "ID", "id"),
          column_aliases = list(
            `ID Number` = c("ID Number", "ID.Number", "ID", "id")
          )
        ),
        discharges = list(
          cohort_column = c("cohort", "measure"),
          id_column = c("ID Number", "ID.Number", "ID", "id"),
          column_aliases = list(
            cohort = c("cohort", "measure"),
            `ID Number` = c("ID Number", "ID.Number", "ID", "id")
          )
        ),
        coefficients = list(
          cohort_column = c("cohort", "measure"),
          term_column = c("term", "factor", "Factor"),
          value_column = c("value", "weight", "Value"),
          layout = list(
            embedded_component_column = ".component"
          ),
          column_aliases = list(
            cohort = c("cohort", "measure"),
            term = c("term", "factor", "Factor"),
            value = c("value", "weight", "Value")
          )
        )
      )
    ),
    class = "readmit_hsr_spec"
  )

  if (!is.null(artifacts)) {
    spec$artifacts <- utils::modifyList(spec$artifacts, artifacts)
  }
  if (!is.null(components)) {
    spec$components <- utils::modifyList(spec$components, components)
  }

  validate_hsr_parser_config(spec)
}

is_hsr_parser_config <- function(x) {
  inherits(x, "readmit_hsr_spec")
}

validate_hsr_parser_config <- function(x) {
  if (!is_hsr_parser_config(x)) {
    stop("`spec` must inherit from class 'readmit_hsr_spec'.")
  }

  required_fields <- c("meta", "artifacts", "components")
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0) {
    stop(
      "HSR parser config is missing required fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  if (!is.character(x$artifacts$include_pattern) || length(x$artifacts$include_pattern) != 1) {
    stop("`spec$artifacts$include_pattern` must be a scalar character string.")
  }
  if (!is.list(x$artifacts$role_hints)) {
    stop("`spec$artifacts$role_hints` must be a list.")
  }

  required_components <- hsr_get_component_names()
  missing_components <- setdiff(required_components, names(x$components))
  if (length(missing_components) > 0) {
    stop(
      "HSR parser config is missing component definitions: ",
      paste(missing_components, collapse = ", ")
    )
  }

  invisible(x)
}

hsr_component_config <- function(spec, component) {
  validate_hsr_parser_config(spec)

  if (!component %in% names(spec$components)) {
    stop("Unknown HSR component in parser config: ", component)
  }

  spec$components[[component]]
}

hsr_find_column <- function(data, candidates) {
  candidates <- candidates[candidates %in% names(data)]

  if (length(candidates) < 1) {
    return(NA_character_)
  }

  candidates[[1]]
}

hsr_apply_alias_map <- function(data, aliases) {
  if (length(aliases) < 1) {
    return(data)
  }

  for (canonical in names(aliases)) {
    if (canonical %in% names(data)) {
      next
    }

    alias <- hsr_find_column(data, aliases[[canonical]])
    if (!is.na(alias)) {
      names(data)[names(data) == alias] <- canonical
    }
  }

  data
}
