# Read project identity without sourcing either analytical script.
rrp_inspection_project <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path)) || !dir.exists(path)) {
    stop("`path` must be an existing project directory.", call. = FALSE)
  }
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  project <- rrp_read_project_dcf(root, "rrp-project.dcf", "Project-ID")
  list(root = root, project_id = project[["Project-ID"]])
}

# Distinguish an absent state directory from an existing incomplete state.
rrp_inspection_has_state <- function(root) {
  state <- file.path(root, "state")
  if (!file.exists(state)) return(FALSE)
  database <- file.path(state, "history.duckdb")
  if (!dir.exists(state) || !file.exists(database) || dir.exists(database)) {
    stop("Project analytical state exists but state/history.duckdb is missing or invalid.",
         call. = FALSE)
  }
  TRUE
}

#' Summarize an RRP project's retained history
#'
#' Read project identity and completed-run status without sourcing the
#' project's analytical scripts, executing an assessment, or changing state.
#' This also works before analytical state has been initialized.
#'
#' @param path Path to an existing RRP project directory.
#' @return An ordinary named list containing character `project_id`, logical
#'   `state_initialized`, integer `run_count`, character `latest_run_id`, and
#'   UTC `POSIXct` `latest_as_of_time`. The latest fields are typed missing
#'   values when there are no runs.
#' @details The latest run is the most recently recorded completed run by
#'   `created_at`, not the largest analytical `as_of_time`. Ties in recorded
#'   creation time are broken by `run_id`. Reads use a read-only connection and
#'   do not initialize state.
#' @examples
#' project <- tempfile("rrp-status-")
#' rrp_project_init(project, "example-rrp")
#' rrp_project_status(project)
#' unlink(project, recursive = TRUE)
#' @export
rrp_project_status <- function(path) {
  if (missing(path)) {
    stop("`path` must be an existing project directory.", call. = FALSE)
  }
  project <- rrp_inspection_project(path)
  initialized <- rrp_inspection_has_state(project$root)
  runs <- if (initialized) {
    tryCatch(rrp_read_runs(project$root), error = function(error) {
      stop(sprintf("Could not read initialized project history: %s",
                   conditionMessage(error)), call. = FALSE)
    })
  } else {
    NULL
  }
  count <- if (is.null(runs)) 0L else as.integer(nrow(runs))
  latest_time <- as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC")
  list(
    project_id = project$project_id,
    state_initialized = initialized,
    run_count = count,
    latest_run_id = if (count) runs$run_id[[count]] else NA_character_,
    latest_as_of_time = if (count) runs$as_of_time[count] else latest_time
  )
}

#' Inspect completed RRP assessments
#'
#' Read retained assessment rows and their run context without sourcing or
#' invoking project-authored analytical functions. Both optional filters use
#' exact identifier matching and may be combined.
#'
#' @param path Path to an existing RRP project with initialized state.
#' @param run_id Optional single nonblank run ID to select.
#' @param episode_id Optional single nonblank episode ID to select.
#' @return An ordinary data frame containing stored assessment identity,
#'   times, disposition, probability, failure detail, selected terminal-event
#'   context, and associated run metadata. Empty results retain the same
#'   columns and types, including UTC `POSIXct` timestamps.
#' @details Initialize state with [rrp_state_init()] before inspecting history.
#'   Rows are ordered by run creation time, run ID, and episode ID. Reads use a
#'   read-only connection and never create state or modify history. A completed
#'   run with zero episodes contributes no assessment row.
#' @examples
#' project <- tempfile("rrp-inspect-")
#' rrp_project_init(project, "example-rrp")
#' rrp_state_init(project)
#' rrp_inspect_history(project)
#' unlink(project, recursive = TRUE)
#' @export
rrp_inspect_history <- function(path, run_id = NULL, episode_id = NULL) {
  if (missing(path)) {
    stop("`path` must be an existing project directory.", call. = FALSE)
  }
  project <- rrp_inspection_project(path)
  for (field in c("run_id", "episode_id")) {
    value <- if (field == "run_id") run_id else episode_id
    if (!is.null(value) &&
        (!is.character(value) || length(value) != 1L || is.na(value) ||
         !nzchar(trimws(value)))) {
      stop(sprintf("`%s` must be one nonblank character identifier.", field),
           call. = FALSE)
    }
  }
  if (!rrp_inspection_has_state(project$root)) {
    stop("Project history is not initialized; call rrp_state_init(path) first.",
         call. = FALSE)
  }
  tryCatch(
    rrp_read_assessments(project$root, run_id = run_id,
                         episode_id = episode_id),
    error = function(error) {
      stop(sprintf("Could not read initialized project history: %s",
                   conditionMessage(error)), call. = FALSE)
    }
  )
}
