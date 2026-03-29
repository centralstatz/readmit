hsr_as_bundle <- function(x, ...) {
  if (is_hsr_bundle(x)) {
    return(validate_hsr_bundle(x))
  }

  if (is.character(x) && length(x) == 1 && dir.exists(x)) {
    return(hsr_parse(x, ...))
  }

  stop("`x` must be a parsed HSR bundle or a local source bundle path.")
}

hsr_get_component <- function(x, component) {
  x <- hsr_as_bundle(x)

  if (!component %in% hsr_get_component_names()) {
    stop("Unknown HSR component: ", component)
  }

  x$components[[component]]
}

hsr_require_component <- function(x, component) {
  data <- hsr_get_component(x, component)

  if (nrow(data) < 1) {
    stop(
      "HSR component `", component,
      "` is missing or unpopulated in this parsed bundle."
    )
  }

  data
}

hsr_require_fields <- function(data, component, fields) {
  missing_fields <- setdiff(fields, names(data))

  if (length(missing_fields) > 0) {
    stop(
      "HSR component `", component,
      "` is missing required fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  data
}

hsr_filter_component_cohort <- function(data, component, cohort) {
  data <- hsr_require_fields(data, component, "cohort")

  data |>
    dplyr::filter(.data$cohort == cohort)
}

hsr_component_inclusion_fields <- function(data) {
  names(data)[stringr::str_detect(names(data), "Cohort Inclusion")]
}

hsr_risk_factor_fields <- function(data) {
  setdiff(
    names(data),
    c("cohort", "ID Number", hsr_component_inclusion_fields(data))
  )
}

hsr_get_component_names <- function() {
  c(
    "discharges",
    "coefficients",
    "payment_summary",
    "cohort_summary",
    "dual_stays"
  )
}
