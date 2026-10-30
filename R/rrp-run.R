#' Run an RRP assessment and retain its history
#'
#' Run the configured project source mapper at one analytical time, determine
#' which discharge episodes remain eligible for first readmission in the
#' remaining 30-day follow-up window, and call the project risk provider once
#' per eligible episode. Accepted estimates, provider failures, and ineligible
#' outcomes are retained together as one completed run.
#'
#' @param path Path to an existing RRP project with initialized analytical state.
#' @param as_of_time One finite UTC `POSIXct` analytical instant. This same time
#'   is used for source production, eligibility, provider requests, and history.
#' @return An ordinary list with `run_id`, `as_of_time`, `episodes_processed`,
#'   `accepted`, `provider_failures`, and `ineligible`. Counts are integers;
#'   the run ID belongs to a successfully committed run.
#' @details Call [rrp_state_init()] before the first run. The project owner must
#'   implement the configured `rrp_produce_canonical()` and
#'   `rrp_calculate_risk()` functions. A provider failure affects its episode,
#'   while a source or persistence failure stops the run without a partial
#'   completed record. Analytical products are generated separately.
#' @examples
#' \dontrun{
#' assessment_time <- as.POSIXct("2026-01-10 12:00:00", tz = "UTC")
#' rrp_run("my-rrp-project", assessment_time)
#' }
#' @export
rrp_run <- function(path, as_of_time) {
  if (missing(path)) {
    stop("`path` must be an existing project directory.", call. = FALSE)
  }
  if (missing(as_of_time) || length(as_of_time) != 1L) {
    stop("`as_of_time` must be one finite UTC POSIXct instant.", call. = FALSE)
  }
  rrp_check_utc_time(as_of_time, "as_of_time")
  project <- rrp_load_project_authoring(path)

  # Require state before invoking either project-authored analytical function.
  connection <- rrp_history_connect(project$project_root, read_only = TRUE)
  DBI::dbDisconnect(connection, shutdown = TRUE)

  canonical <- rrp_produce_project_canonical(
    project$project_root, as_of_time, project = project
  )
  eligibility <- rrp_evaluate_eligibility(canonical, as_of_time)
  assessments <- rrp_assess_eligible_episodes(
    eligibility, as_of_time, project$project_root, project$calculate_risk
  )

  run_id <- rrp_write_history(project$project_root, list(
    project_id = project$project_id,
    as_of_time = as_of_time,
    created_at = as.POSIXct(Sys.time(), tz = "UTC"),
    source_mapping_script = project$source_mapping_reference,
    risk_provider_script = project$risk_provider_reference
  ), assessments)
  dispositions <- assessments$disposition
  list(
    run_id = run_id,
    as_of_time = as_of_time,
    episodes_processed = as.integer(nrow(assessments)),
    accepted = as.integer(sum(dispositions == "accepted")),
    provider_failures = as.integer(sum(dispositions == "provider_failure")),
    ineligible = as.integer(sum(dispositions %in% c(
      "window_closed", "known_readmission", "known_death"
    )))
  )
}
