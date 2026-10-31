# The project app reads only the three CSVs written by rrp_refresh_products().
rrp_app_read_csv <- function(path, columns, classes, time_columns) {
  if (!file.exists(path)) {
    return(list(status = "missing", data = NULL,
                message = paste(basename(path), "has not been generated.")))
  }
  data <- tryCatch(suppressWarnings(utils::read.csv(
    path, check.names = FALSE, stringsAsFactors = FALSE,
    colClasses = classes, na.strings = "", fileEncoding = "UTF-8"
  )), error = function(e) NULL)
  if (is.null(data) || !identical(names(data), columns)) {
    return(list(status = "invalid", data = NULL,
                message = paste(basename(path), "cannot be read or has incompatible columns.")))
  }
  for (field in time_columns) {
    value <- data[[field]]
    valid_text <- !is.na(value) & grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{6}Z$",
      value
    )
    parsed <- suppressWarnings(as.POSIXct(
      value, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"
    ))
    if (!all(valid_text) || anyNA(parsed)) {
      return(list(status = "invalid", data = NULL,
                  message = paste(basename(path), "has an invalid UTC timestamp.")))
    }
    data[[field]] <- parsed
  }
  list(status = "ok", data = data, message = NULL)
}

rrp_app_read_products <- function(project_root) {
  directory <- file.path(project_root, "state", "products")
  current <- rrp_app_read_csv(
    file.path(directory, "current-remaining-risk.csv"),
    c("selected_run_id", "as_of_time", "episode_id", "discharge_time",
      "followup_window_end", "disposition", "probability"),
    c(rep("character", 6L), "numeric"),
    c("as_of_time", "discharge_time", "followup_window_end")
  )
  trajectory <- rrp_app_read_csv(
    file.path(directory, "remaining-risk-trajectory.csv"),
    c("selected_run_id", "run_id", "as_of_time", "created_at",
      "episode_id", "probability"),
    c(rep("character", 5L), "numeric"), c("as_of_time", "created_at")
  )
  scope <- rrp_app_read_csv(
    file.path(directory, "operational-scope-summary.csv"),
    c("selected_run_id", "project_id", "as_of_time", "created_at",
      "episodes_assessed", "eligible_count", "accepted_count",
      "provider_failure_count", "ineligible_count", "window_closed_count",
      "known_readmission_count", "known_death_count"),
    c(rep("character", 4L), rep("integer", 8L)),
    c("as_of_time", "created_at")
  )
  invalid <- function(product, filename) {
    product$status <- "invalid"
    product$data <- NULL
    product$message <- paste(filename, "has incompatible product values.")
    product
  }
  valid_id <- function(value) is.character(value) && !anyNA(value) &&
    all(nzchar(trimws(value)))
  valid_risk <- function(value) is.numeric(value) && !anyNA(value) &&
    all(is.finite(value) & value >= 0 & value <= 1)

  if (current$status == "ok") {
    data <- current$data
    accepted <- data$disposition == "accepted"
    failed <- data$disposition == "provider_failure"
    if (!valid_id(data$selected_run_id) || !valid_id(data$episode_id) ||
        anyDuplicated(data$episode_id) ||
        !all(accepted | failed) ||
        !valid_risk(data$probability[accepted]) ||
        !all(is.na(data$probability[failed])) ||
        length(unique(data$selected_run_id)) > 1L ||
        length(unique(data$as_of_time)) > 1L) {
      current <- invalid(current, "current-remaining-risk.csv")
    }
  }
  if (trajectory$status == "ok") {
    data <- trajectory$data
    if (!valid_id(data$selected_run_id) || !valid_id(data$run_id) ||
        !valid_id(data$episode_id) || !valid_risk(data$probability) ||
        length(unique(data$selected_run_id)) > 1L) {
      trajectory <- invalid(trajectory, "remaining-risk-trajectory.csv")
    }
  }
  if (scope$status == "ok") {
    data <- scope$data
    if (nrow(data) != 1L || !valid_id(data$selected_run_id) ||
        !valid_id(data$project_id) ||
        !all(vapply(data[5:12], function(value) {
          is.integer(value) && !anyNA(value) && all(value >= 0L)
        }, logical(1L))) ||
        data$episodes_assessed != as.double(data$eligible_count) +
          data$ineligible_count ||
        data$eligible_count != as.double(data$accepted_count) +
          data$provider_failure_count ||
        data$ineligible_count != as.double(data$window_closed_count) +
          data$known_readmission_count + data$known_death_count) {
      scope <- invalid(scope, "operational-scope-summary.csv")
    }
  }

  # Current risk anchors its own view. Companion products must agree before
  # the app combines them with the selected pool.
  if (current$status == "ok" && nrow(current$data)) {
    selected_id <- current$data$selected_run_id[[1L]]
    selected_time <- current$data$as_of_time[[1L]]
  } else if (scope$status == "ok") {
    selected_id <- scope$data$selected_run_id[[1L]]
    selected_time <- scope$data$as_of_time[[1L]]
  } else {
    selected_id <- NULL
    selected_time <- NULL
  }
  mismatch <- function(product, filename) {
    product$status <- "mismatch"
    product$message <- paste(filename, "belongs to a different analytical snapshot.")
    product
  }
  if (!is.null(selected_id)) {
    if (scope$status == "ok" &&
        (scope$data$selected_run_id[[1L]] != selected_id ||
         scope$data$as_of_time[[1L]] != selected_time)) {
      scope <- mismatch(scope, "operational-scope-summary.csv")
    }
    if (trajectory$status == "ok" && nrow(trajectory$data) &&
        (any(trajectory$data$selected_run_id != selected_id) ||
         any(trajectory$data$as_of_time > selected_time) ||
         (current$status == "ok" &&
          any(!trajectory$data$episode_id %in% current$data$episode_id)))) {
      trajectory <- mismatch(trajectory, "remaining-risk-trajectory.csv")
    }
  }
  if (current$status == "ok" && scope$status == "ok" &&
      nrow(current$data) != scope$data$eligible_count[[1L]]) {
    scope <- mismatch(scope, "operational-scope-summary.csv")
  }
  list(current = current, trajectory = trajectory, scope = scope)
}
