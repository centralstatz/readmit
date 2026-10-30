# Calculate the three Stage 4 products from one read-only history view.
# This remains internal until the separate refresh operation is added.
rrp_calculate_products <- function(path) {
  project <- rrp_inspection_project(path)
  connection <- rrp_history_connect(project$root, read_only = TRUE)
  on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)

  history <- DBI::dbWithTransaction(connection, {
    list(
      runs = DBI::dbGetQuery(connection, paste(
        "SELECT run_id, project_id, as_of_time, created_at FROM runs"
      )),
      assessments = DBI::dbGetQuery(connection, paste(
        "SELECT run_id, episode_id, discharge_time, followup_window_end,",
        "disposition, probability FROM assessments"
      ))
    )
  })
  runs <- history$runs
  assessments <- history$assessments
  if (!nrow(runs)) {
    stop("Project history has no completed runs; run an assessment first.",
         call. = FALSE)
  }

  ordering <- order(runs$as_of_time, runs$created_at, runs$run_id)
  selected <- runs[ordering[nrow(runs)], , drop = FALSE]
  selected_id <- selected$run_id[[1L]]
  selected_assessments <- assessments[assessments$run_id == selected_id,
                                      , drop = FALSE]
  eligible <- selected_assessments[
    selected_assessments$disposition %in% c("accepted", "provider_failure"),
    , drop = FALSE
  ]
  current_risk <- data.frame(
    selected_run_id = rep(selected_id, nrow(eligible)),
    as_of_time = selected$as_of_time[rep(1L, nrow(eligible))],
    episode_id = eligible$episode_id,
    discharge_time = eligible$discharge_time,
    followup_window_end = eligible$followup_window_end,
    disposition = eligible$disposition,
    probability = eligible$probability
  )
  current_risk <- current_risk[order(current_risk$episode_id), , drop = FALSE]
  rownames(current_risk) <- NULL

  observations <- assessments[
    assessments$disposition == "accepted" &
      assessments$episode_id %in% eligible$episode_id,
    , drop = FALSE
  ]
  source_runs <- match(observations$run_id, runs$run_id)
  observations <- observations[
    runs$as_of_time[source_runs] <= selected$as_of_time[[1L]], , drop = FALSE
  ]
  source_runs <- match(observations$run_id, runs$run_id)
  trajectory <- data.frame(
    selected_run_id = rep(selected_id, nrow(observations)),
    run_id = observations$run_id,
    as_of_time = runs$as_of_time[source_runs],
    created_at = runs$created_at[source_runs],
    episode_id = observations$episode_id,
    probability = observations$probability
  )
  trajectory <- trajectory[order(trajectory$episode_id, trajectory$as_of_time,
                                 trajectory$created_at, trajectory$run_id),
                           , drop = FALSE]
  rownames(trajectory) <- NULL

  dispositions <- selected_assessments$disposition
  count <- function(value) as.integer(sum(dispositions == value))
  accepted <- count("accepted")
  failures <- count("provider_failure")
  closed <- count("window_closed")
  readmissions <- count("known_readmission")
  deaths <- count("known_death")
  scope <- data.frame(
    selected_run_id = selected_id,
    project_id = selected$project_id[[1L]],
    as_of_time = selected$as_of_time[1L],
    created_at = selected$created_at[1L],
    episodes_assessed = as.integer(nrow(selected_assessments)),
    eligible_count = accepted + failures,
    accepted_count = accepted,
    provider_failure_count = failures,
    ineligible_count = closed + readmissions + deaths,
    window_closed_count = closed,
    known_readmission_count = readmissions,
    known_death_count = deaths
  )
  if (nrow(current_risk) != scope$eligible_count[[1L]] ||
      scope$episodes_assessed[[1L]] !=
        scope$eligible_count[[1L]] + scope$ineligible_count[[1L]]) {
    stop("Retained assessment dispositions cannot be reconciled.",
         call. = FALSE)
  }

  list(current_risk = current_risk, trajectory = trajectory, scope = scope)
}
