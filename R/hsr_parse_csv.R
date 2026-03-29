hsr_parse_csv_bundle <- function(source, spec = hsr_parser_config(), ...) {
  validate_hsr_source(source)
  spec <- validate_hsr_parser_config(spec)

  bundle <- structure(
    list(
      meta = list(
        bundle_type = "hsr",
        parser = "csv_bundle_v1",
        parsed_at = Sys.time(),
        spec_name = spec$meta$name
      ),
      source = source,
      components = list(
        discharges = tibble::tibble(),
        coefficients = tibble::tibble(),
        payment_summary = tibble::tibble(),
        cohort_summary = tibble::tibble(),
        dual_stays = tibble::tibble()
      ),
      lineage = tibble::tibble(
        artifact_id = character(),
        component = character(),
        output_id = character(),
        n_rows = integer()
      ),
      raw = list(
        artifact_outputs = list()
      ),
      issues = character()
    ),
    class = "readmit_hsr_bundle"
  )

  if (nrow(source$artifacts) == 0) {
    return(validate_hsr_bundle(bundle))
  }

  for (i in seq_len(nrow(source$artifacts))) {
    artifact <- source$artifacts[i, ]
    parsed_artifact <- hsr_parse_artifact(artifact, context = source, spec = spec, ...)
    bundle <- hsr_collect_component_output(bundle, parsed_artifact)
  }

  validate_hsr_bundle(bundle)
}

hsr_parse_artifact <- function(artifact, context, spec = hsr_parser_config(), ...) {
  spec <- validate_hsr_parser_config(spec)
  data <- readr::read_csv(
    file = artifact$path[[1]],
    show_col_types = FALSE
  )

  outputs <- list()
  embedded_component_col <- hsr_embedded_component_column(spec)

  if (embedded_component_col %in% names(data)) {
    component_values <- unique(stats::na.omit(data[[embedded_component_col]]))

    for (component in component_values) {
      component_data <- data |>
        dplyr::filter(.data[[embedded_component_col]] == component) |>
        dplyr::select(-dplyr::all_of(embedded_component_col))

      component_data <- hsr_apply_component_aliases(component_data, component, spec)

      outputs[[length(outputs) + 1]] <- list(
        component = component,
        data = component_data,
        metadata = list(
          artifact_id = artifact$artifact_id[[1]],
          role_hint = artifact$role_hint[[1]],
          name = artifact$name[[1]]
        )
      )
    }
  } else if (artifact$role_hint[[1]] %in% hsr_get_component_names()) {
    data <- hsr_apply_component_aliases(data, artifact$role_hint[[1]], spec)

    outputs[[1]] <- list(
      component = artifact$role_hint[[1]],
      data = data,
      metadata = list(
        artifact_id = artifact$artifact_id[[1]],
        role_hint = artifact$role_hint[[1]],
        name = artifact$name[[1]]
      )
    )
  }

  list(
    artifact = artifact,
    outputs = outputs,
    raw = list(data = data),
    issues = character()
  )
}

hsr_collect_component_output <- function(bundle, parsed_artifact) {
  artifact_id <- parsed_artifact$artifact$artifact_id[[1]]
  bundle$raw$artifact_outputs[[artifact_id]] <- parsed_artifact

  if (length(parsed_artifact$outputs) == 0) {
    return(bundle)
  }

  for (i in seq_along(parsed_artifact$outputs)) {
    output <- parsed_artifact$outputs[[i]]
    component <- output$component

    if (!component %in% hsr_get_component_names()) {
      bundle$issues <- c(
        bundle$issues,
        paste0("Unsupported component parsed from ", artifact_id, ": ", component)
      )
      next
    }

    bundle$components[[component]] <- dplyr::bind_rows(
      bundle$components[[component]],
      output$data
    )

    bundle$lineage <- dplyr::bind_rows(
      bundle$lineage,
      tibble::tibble(
        artifact_id = artifact_id,
        component = component,
        output_id = paste0(artifact_id, "_", i),
        n_rows = nrow(output$data)
      )
    )
  }

  bundle
}

hsr_embedded_component_column <- function(spec) {
  validate_hsr_parser_config(spec)

  component_cols <- vapply(
    spec$components,
    function(component_spec) {
      layout <- component_spec$layout

      if (is.null(layout) || is.null(layout$embedded_component_column)) {
        return(NA_character_)
      }

      layout$embedded_component_column
    },
    character(1)
  )

  component_cols <- unique(stats::na.omit(component_cols))

  if (length(component_cols) < 1) {
    return(".component")
  }

  component_cols[[1]]
}

hsr_apply_component_aliases <- function(data, component, spec) {
  component_spec <- hsr_component_config(spec, component)
  aliases <- component_spec$column_aliases

  hsr_apply_alias_map(data, aliases)
}
