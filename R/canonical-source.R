#' Project canonical source contract
#'
#' The project-authored `rrp_produce_canonical(project_root, as_of_time)`
#' function returns a named list with two data frames. `discharge_episode`
#' requires character `episode_id`, `patient_id`, and `index_encounter_id`,
#' plus UTC `POSIXct` `admission_time` and `discharge_time`.
#' `terminal_event` requires character `terminal_event_id`, `episode_id`, and
#' `event_type` (`"readmission"` or `"death"`), plus UTC `POSIXct`
#' `occurred_at` and `available_at`. Either table may have zero rows if it
#' retains its required typed columns. Identifiers must be nonmissing and
#' nonblank, and timestamps must be finite. Episode and terminal-event IDs
#' must be unique, and every terminal event must reference a supplied episode.
#' Additional columns are left unchanged but are not used by `readmit`.
#'
#' `as_of_time` is one finite UTC `POSIXct` instant. The project author supplies
#' episodes discharged by that time and truthful event occurrence and
#' availability times. An event may have occurred by `as_of_time` but become
#' available later; canonical validation does not filter it. The project owns
#' clinical source selection, mapping, and private predictors. `readmit` owns
#' the fixed 30-elapsed-day endpoint, which is derived from `discharge_time`
#' during later analytical execution and is not a canonical input column.
#'
#' @param project_root Path to the project that owns the source-mapping script.
#' @param as_of_time One finite UTC `POSIXct` analytical instant.
#' @param project Optional project authoring bindings already loaded for an
#'   integrated run. When omitted, they are loaded from `project_root`.
#' @return The validated canonical list, with its two data frames unchanged.
#' @keywords internal
rrp_produce_project_canonical <- function(project_root, as_of_time,
                                          project = NULL) {
  if (length(as_of_time) != 1L) {
    stop("`as_of_time` must be one finite UTC POSIXct instant.", call. = FALSE)
  }
  rrp_check_utc_time(as_of_time, "as_of_time")
  if (is.null(project)) project <- rrp_load_project_authoring(project_root)
  canonical <- tryCatch(
    project$produce_canonical(project$project_root, as_of_time),
    error = function(error) {
      stop(sprintf("Canonical source production failed: %s",
                   conditionMessage(error)), call. = FALSE)
    }
  )
  rrp_check_canonical_source(canonical)
  canonical
}

# Check timestamp representation without converting source-supplied values.
rrp_check_utc_time <- function(value, label) {
  if (!inherits(value, "POSIXct") ||
      !identical(attr(value, "tzone"), "UTC") ||
      any(!is.finite(as.numeric(value)))) {
    stop(sprintf("%s must contain finite UTC POSIXct timestamps.", label),
         call. = FALSE)
  }
  invisible(TRUE)
}

# Check required columns; additional project columns are not used by readmit.
rrp_check_canonical_table <- function(value, label, fields) {
  if (!is.data.frame(value)) {
    stop(sprintf("%s must be a data frame.", label), call. = FALSE)
  }
  if (anyDuplicated(names(value)) ||
      length(setdiff(fields, names(value))) > 0L) {
    stop(sprintf("%s is missing required columns or has duplicate names.",
                 label), call. = FALSE)
  }
  invisible(TRUE)
}

rrp_check_canonical_id <- function(value, label) {
  if (!is.character(value) || anyNA(value) ||
      any(!nzchar(trimws(value)))) {
    stop(sprintf("%s must contain nonempty character identifiers.", label),
         call. = FALSE)
  }
  invisible(TRUE)
}

# Check only facts needed to interpret the two canonical tables.
rrp_check_canonical_source <- function(canonical) {
  expected <- c("discharge_episode", "terminal_event")
  if (!is.list(canonical) || is.data.frame(canonical) ||
      is.null(names(canonical)) ||
      !identical(sort(names(canonical)), expected)) {
    stop("Canonical source must return a named list with discharge_episode and terminal_event.",
         call. = FALSE)
  }
  episodes <- canonical$discharge_episode
  events <- canonical$terminal_event
  rrp_check_canonical_table(
    episodes, "discharge_episode",
    c("episode_id", "patient_id", "index_encounter_id", "admission_time",
      "discharge_time")
  )
  rrp_check_canonical_table(
    events, "terminal_event",
    c("terminal_event_id", "episode_id", "event_type", "occurred_at",
      "available_at")
  )
  for (field in c("episode_id", "patient_id", "index_encounter_id")) {
    rrp_check_canonical_id(episodes[[field]], paste0("discharge_episode$", field))
  }
  for (field in c("terminal_event_id", "episode_id")) {
    rrp_check_canonical_id(events[[field]], paste0("terminal_event$", field))
  }
  if (anyDuplicated(episodes$episode_id)) {
    stop("discharge_episode$episode_id must be unique.", call. = FALSE)
  }
  if (anyDuplicated(events$terminal_event_id)) {
    stop("terminal_event$terminal_event_id must be unique.", call. = FALSE)
  }
  if (!is.character(events$event_type) || anyNA(events$event_type) ||
      any(!events$event_type %in% c("readmission", "death"))) {
    stop("terminal_event$event_type must be readmission or death.",
         call. = FALSE)
  }
  if (any(!events$episode_id %in% episodes$episode_id)) {
    stop("terminal_event$episode_id must reference a discharge episode.",
         call. = FALSE)
  }
  for (field in c("admission_time", "discharge_time")) {
    rrp_check_utc_time(episodes[[field]], paste0("discharge_episode$", field))
  }
  for (field in c("occurred_at", "available_at")) {
    rrp_check_utc_time(events[[field]], paste0("terminal_event$", field))
  }
  invisible(TRUE)
}
