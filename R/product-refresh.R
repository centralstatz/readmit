# Check the three known product shapes before writing project-owned files.
rrp_validate_products <- function(products) {
  expected <- list(
    current_risk = c("selected_run_id", "as_of_time", "episode_id",
                     "discharge_time", "followup_window_end", "disposition",
                     "probability"),
    trajectory = c("selected_run_id", "run_id", "as_of_time", "created_at",
                   "episode_id", "probability"),
    scope = c("selected_run_id", "project_id", "as_of_time", "created_at",
              "episodes_assessed", "eligible_count", "accepted_count",
              "provider_failure_count", "ineligible_count",
              "window_closed_count", "known_readmission_count",
              "known_death_count")
  )
  invalid <- function() stop("Analytical products are invalid and were not written.",
                             call. = FALSE)
  if (!is.list(products) || !identical(names(products), names(expected)) ||
      !all(vapply(names(expected), function(name) {
        is.data.frame(products[[name]]) &&
          identical(names(products[[name]]), expected[[name]])
      }, logical(1L)))) invalid()

  current <- products$current_risk
  trajectory <- products$trajectory
  scope <- products$scope
  valid_id <- function(value) {
    is.character(value) && !anyNA(value) && all(nzchar(trimws(value)))
  }
  valid_time <- function(value) {
    inherits(value, "POSIXct") && identical(attr(value, "tzone"), "UTC") &&
      all(is.finite(as.numeric(value)))
  }
  valid_risk <- function(value) {
    is.double(value) && !anyNA(value) &&
      all(is.finite(value) & value >= 0 & value <= 1)
  }
  if (nrow(scope) != 1L ||
      !valid_id(scope$selected_run_id) || !valid_id(scope$project_id) ||
      !valid_time(scope$as_of_time) || !valid_time(scope$created_at) ||
      !all(vapply(scope[5:12], function(value) {
        is.integer(value) && !anyNA(value) && all(value >= 0L)
      }, logical(1L)))) invalid()
  counts <- scope[1L, 5:12]
  if (counts$eligible_count !=
        counts$accepted_count + counts$provider_failure_count ||
      counts$ineligible_count !=
        counts$window_closed_count + counts$known_readmission_count +
          counts$known_death_count ||
      counts$episodes_assessed !=
        counts$eligible_count + counts$ineligible_count) invalid()

  for (value in list(current, trajectory)) {
    if (!valid_id(value$selected_run_id) ||
        !all(value$selected_run_id == scope$selected_run_id[[1L]]) ||
        !valid_id(value$episode_id) || !valid_time(value$as_of_time)) {
      invalid()
    }
  }
  if (!valid_time(current$discharge_time) ||
      !valid_time(current$followup_window_end) ||
      !all(current$as_of_time == scope$as_of_time[[1L]]) ||
      anyDuplicated(current$episode_id) ||
      !is.character(current$disposition) ||
      !all(current$disposition %in% c("accepted", "provider_failure")) ||
      !is.double(current$probability) ||
      !valid_risk(current$probability[current$disposition == "accepted"]) ||
      !all(is.na(current$probability[
        current$disposition == "provider_failure"])) ||
      nrow(current) != counts$eligible_count ||
      sum(current$disposition == "accepted") != counts$accepted_count ||
      sum(current$disposition == "provider_failure") !=
        counts$provider_failure_count) invalid()
  if (!valid_id(trajectory$run_id) ||
      !valid_time(trajectory$created_at) ||
      !valid_risk(trajectory$probability) ||
      !all(trajectory$episode_id %in% current$episode_id) ||
      !all(trajectory$as_of_time <= scope$as_of_time[[1L]])) invalid()
  invisible(TRUE)
}

# Convert UTC POSIXct columns explicitly; leave numeric and missing risk intact.
rrp_product_csv_data <- function(data) {
  for (field in names(data)[vapply(data, inherits, logical(1L), "POSIXct")]) {
    data[[field]] <- format(data[[field]], "%Y-%m-%dT%H:%M:%OS6Z",
                            tz = "UTC", usetz = FALSE)
  }
  data
}

#' Refresh an RRP project's analytical product CSVs
#'
#' Derive the current clinically eligible risk pool, observed accepted-risk
#' trajectories, and operational scope from retained assessment history. The
#' selected completed run has the greatest analytical `as_of_time`; execution
#' `created_at` and then `run_id` break ties. A later-executed historical
#' backfill does not replace a newer analytical snapshot.
#'
#' @param path Path to an existing RRP project with initialized analytical state
#'   and at least one completed assessment run.
#' @return Invisibly, a list with `selected_run_id`, UTC `as_of_time`, and named
#'   character `files` containing the three generated CSV paths.
#' @details Files are written under `state/products/` as
#'   `current-remaining-risk.csv`, `remaining-risk-trajectory.csv`, and
#'   `operational-scope-summary.csv`. The current-risk file includes clinically
#'   eligible provider-failure episodes with a missing probability, never zero
#'   or an earlier estimate. Refresh reads history only: it does not run the
#'   source mapper or provider, add a run, change retained history, or edit the
#'   project-owned app. All files are staged and checked before replacement.
#'   Replacement of the three files is not fully atomic if a filesystem error
#'   occurs during the final replacement sequence.
#' @export
rrp_refresh_products <- function(path) {
  products <- rrp_calculate_products(path)
  rrp_validate_products(products)
  project <- rrp_inspection_project(path)
  state <- file.path(project$root, "state")
  filenames <- c(
    current_risk = "current-remaining-risk.csv",
    trajectory = "remaining-risk-trajectory.csv",
    scope = "operational-scope-summary.csv"
  )
  types <- list(
    current_risk = c(rep("character", 6L), "numeric"),
    trajectory = c(rep("character", 5L), "numeric"),
    scope = c(rep("character", 4L), rep("integer", 8L))
  )
  stage <- tempfile("products-stage-", tmpdir = state)
  if (!dir.create(stage)) {
    stop("Could not create a product staging directory.", call. = FALSE)
  }
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)

  for (name in names(filenames)) {
    staged <- file.path(stage, filenames[[name]])
    data <- rrp_product_csv_data(products[[name]])
    utils::write.csv(data, staged, row.names = FALSE, na = "",
                     fileEncoding = "UTF-8")
    if (!file.exists(staged)) {
      stop("A staged analytical product could not be verified.",
           call. = FALSE)
    }
    read_back <- utils::read.csv(
      staged, check.names = FALSE, stringsAsFactors = FALSE,
      colClasses = types[[name]], na.strings = "", fileEncoding = "UTF-8"
    )
    if (!identical(names(read_back), names(products[[name]])) ||
        nrow(read_back) != nrow(products[[name]])) {
      stop("A staged analytical product could not be verified.",
           call. = FALSE)
    }
  }

  destination <- file.path(state, "products")
  if (file.exists(destination) && !dir.exists(destination)) {
    stop("state/products exists but is not a directory.", call. = FALSE)
  }
  if (!dir.exists(destination) && !dir.create(destination)) {
    stop("Could not create state/products for analytical outputs.",
         call. = FALSE)
  }
  files <- file.path(destination, unname(filenames))
  names(files) <- names(filenames)
  for (name in names(filenames)) {
    if (!isTRUE(file.copy(file.path(stage, filenames[[name]]), files[[name]],
                          overwrite = TRUE))) {
      stop(sprintf("Could not replace analytical product %s.",
                   filenames[[name]]), call. = FALSE)
    }
  }
  invisible(list(
    selected_run_id = products$scope$selected_run_id[[1L]],
    as_of_time = products$scope$as_of_time[1L],
    files = files
  ))
}
