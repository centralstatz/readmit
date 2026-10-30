inspection_test_time <- function(value) as.POSIXct(value, tz = "UTC")

inspection_test_project <- function() {
  project <- tempfile("rrp-inspection-")
  rrp_project_init(project, "inspection-test")
  episodes <- data.frame(
    episode_id = paste0("episode-", 1:7),
    patient_id = paste0("patient-", 1:7),
    index_encounter_id = paste0("encounter-", 1:7),
    admission_time = rep(inspection_test_time("2026-01-01 01:00:00.125"), 7),
    discharge_time = rep(inspection_test_time("2026-01-02 01:00:00.125"), 7)
  )
  episodes$admission_time[7] <- inspection_test_time("2025-11-30")
  episodes$discharge_time[7] <- inspection_test_time("2025-12-01")
  events <- data.frame(
    terminal_event_id = c("event-readmission", "event-death"),
    episode_id = c("episode-5", "episode-6"),
    event_type = c("readmission", "death"),
    occurred_at = rep(inspection_test_time("2026-01-05 08:00:00.5"), 2),
    available_at = rep(inspection_test_time("2026-01-06 09:00:00.25"), 2)
  )
  saveRDS(list(discharge_episode = episodes, terminal_event = events),
          file.path(project, "canonical.rds"))
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  readRDS(file.path(project_root, 'canonical.rds'))",
    "}"
  ), file.path(project, "R", "produce-canonical.R"))
  writeLines(c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  if (request$episode_id == 'episode-2')",
    "    return(list(failure = 'Predictor unavailable'))",
    "  if (request$episode_id == 'episode-3')",
    "    return(list(probability = NA_real_))",
    "  if (request$episode_id == 'episode-4') stop('Model failed')",
    "  list(probability = 0.25)",
    "}"
  ), file.path(project, "R", "calculate-risk.R"))
  project
}

test_that("status works before state and empty inspection stays typed", {
  project <- inspection_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)

  before <- rrp_project_status(project)
  expect_identical(names(before), c("project_id", "state_initialized",
                                    "run_count", "latest_run_id",
                                    "latest_as_of_time"))
  expect_identical(before$project_id, "inspection-test")
  expect_identical(before$state_initialized, FALSE)
  expect_identical(before$run_count, 0L)
  expect_identical(before$latest_run_id, NA_character_)
  expect_s3_class(before$latest_as_of_time, "POSIXct")
  expect_identical(attr(before$latest_as_of_time, "tzone"), "UTC")
  expect_true(is.na(before$latest_as_of_time))
  expect_false(dir.exists(file.path(project, "state")))
  expect_error(rrp_inspect_history(project), "rrp_state_init")
  expect_false(dir.exists(file.path(project, "state")))

  rrp_state_init(project)
  ready <- rrp_project_status(project)
  expect_identical(ready$state_initialized, TRUE)
  expect_identical(ready$run_count, 0L)
  expect_identical(ready$latest_run_id, NA_character_)
  expect_s3_class(ready$latest_as_of_time, "POSIXct")
  expect_true(is.na(ready$latest_as_of_time))

  empty <- rrp_inspect_history(project)
  filtered <- rrp_inspect_history(project, run_id = "unknown",
                                   episode_id = "episode-1")
  expect_s3_class(empty, "data.frame")
  expect_identical(nrow(empty), 0L)
  expect_identical(names(empty), c(
    "run_id", "episode_id", "patient_id", "index_encounter_id",
    "admission_time", "discharge_time", "followup_window_end",
    "disposition", "probability", "failure_kind", "failure_reason",
    "terminal_event_id", "terminal_event_type", "terminal_occurred_at",
    "terminal_available_at", "project_id", "as_of_time", "created_at",
    "source_mapping_script", "risk_provider_script"
  ))
  expect_identical(names(filtered), names(empty))
  expect_identical(vapply(filtered, typeof, character(1)),
                   vapply(empty, typeof, character(1)))
  expect_type(empty$run_id, "character")
  expect_type(empty$probability, "double")
  expect_type(empty$failure_kind, "character")
  for (field in c("as_of_time", "created_at", "admission_time",
                  "discharge_time", "followup_window_end",
                  "terminal_occurred_at", "terminal_available_at")) {
    expect_s3_class(empty[[field]], "POSIXct")
    expect_identical(attr(empty[[field]], "tzone"), "UTC")
  }
})

test_that("status and inspection expose completed history without analytical execution", {
  project <- inspection_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  rrp_state_init(project)
  later <- inspection_test_time("2026-01-13 12:00:00.125")
  earlier <- inspection_test_time("2026-01-10 12:00:00.125")
  first <- rrp_run(project, later)
  Sys.sleep(0.02)
  second <- rrp_run(project, earlier)

  status <- rrp_project_status(project)
  expect_identical(status$project_id, "inspection-test")
  expect_identical(status$state_initialized, TRUE)
  expect_identical(status$run_count, 2L)
  expect_identical(status$latest_run_id, second$run_id)
  expect_identical(as.numeric(status$latest_as_of_time), as.numeric(earlier))
  expect_identical(attr(status$latest_as_of_time, "tzone"), "UTC")
  expect_gt(as.numeric(later), as.numeric(earlier))

  all_rows <- rrp_inspect_history(project)
  expect_identical(nrow(all_rows), 14L)
  expect_identical(all_rows$run_id[1:7], rep(first$run_id, 7))
  expect_identical(all_rows$run_id[8:14], rep(second$run_id, 7))
  expect_identical(all_rows$episode_id[1:7], paste0("episode-", 1:7))
  expect_identical(all_rows$episode_id[8:14], paste0("episode-", 1:7))
  expect_identical(all_rows, rrp_inspect_history(project))
  expect_true(all(all_rows$project_id == "inspection-test"))
  expect_identical(as.numeric(all_rows$as_of_time[1:7]),
                   rep(as.numeric(later), 7))
  expect_identical(as.numeric(all_rows$as_of_time[8:14]),
                   rep(as.numeric(earlier), 7))
  expect_identical(attr(all_rows$as_of_time, "tzone"), "UTC")
  first_rows <- rrp_inspect_history(project, run_id = first$run_id)
  expect_identical(first_rows$disposition, c(
    "accepted", "provider_failure", "provider_failure",
    "provider_failure", "known_readmission", "known_death", "window_closed"
  ))
  expect_identical(first_rows$probability[1], 0.25)
  expect_true(all(is.na(first_rows$probability[2:7])))
  expect_identical(first_rows$failure_kind[2:4],
                   c("reported", "unusable_result", "error"))
  expect_match(first_rows$failure_reason[2], "Predictor unavailable")
  expect_match(first_rows$failure_reason[4], "Model failed")
  expect_identical(first_rows$terminal_event_id[5:6],
                   c("event-readmission", "event-death"))
  expect_identical(first_rows$terminal_event_type[5:6],
                   c("readmission", "death"))
  expect_identical(as.numeric(first_rows$terminal_occurred_at[5:6]),
                   rep(as.numeric(inspection_test_time(
                     "2026-01-05 08:00:00.5")), 2))
  expect_identical(as.numeric(first_rows$terminal_available_at[5:6]),
                   rep(as.numeric(inspection_test_time(
                     "2026-01-06 09:00:00.25")), 2))
  expect_true(all(is.na(first_rows$terminal_event_id[c(1:4, 7)])))

  expect_identical(nrow(rrp_inspect_history(project,
                                           episode_id = "episode-1")), 2L)
  expect_identical(nrow(rrp_inspect_history(project, first$run_id,
                                           "episode-1")), 1L)
  expect_identical(nrow(rrp_inspect_history(project, first$run_id,
                                           "episode-2")), 1L)
  expect_identical(nrow(rrp_inspect_history(project,
                                           episode_id = "unknown")), 0L)
  for (result in list(
    rrp_inspect_history(project, run_id = "unknown"),
    rrp_inspect_history(project, run_id = first$run_id,
                        episode_id = "unknown"),
    rrp_inspect_history(project, run_id = "unknown",
                        episode_id = "episode-1")
  )) {
    expect_identical(nrow(result), 0L)
    expect_identical(names(result), names(all_rows))
    expect_identical(vapply(result, typeof, character(1)),
                     vapply(all_rows, typeof, character(1)))
  }

  # Sourcing either edited script now throws. Reads still succeed unchanged.
  writeLines("stop('source script was sourced')",
             file.path(project, "R", "produce-canonical.R"))
  writeLines("stop('provider script was sourced')",
             file.path(project, "R", "calculate-risk.R"))
  expect_identical(rrp_project_status(project), status)
  expect_identical(rrp_inspect_history(project), all_rows)
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 2L)
  expect_false(dir.exists(file.path(project, "state", "products")))

  # Read-only connections closed; after restoring scripts, a new run still works.
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time)",
    "  readRDS(file.path(project_root, 'canonical.rds'))"
  ), file.path(project, "R", "produce-canonical.R"))
  writeLines("rrp_calculate_risk <- function(project_root, request) list(probability = 0.25)",
             file.path(project, "R", "calculate-risk.R"))
  third <- rrp_run(project, earlier)
  expect_identical(nrow(rrp_inspect_history(project)), 21L)
  expect_identical(rrp_project_status(project)$latest_run_id, third$run_id)
})

test_that("zero-episode runs appear in status without fabricated assessments", {
  project <- inspection_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  canonical <- readRDS(file.path(project, "canonical.rds"))
  canonical$discharge_episode <- canonical$discharge_episode[FALSE, , drop = FALSE]
  canonical$terminal_event <- canonical$terminal_event[FALSE, , drop = FALSE]
  saveRDS(canonical, file.path(project, "canonical.rds"))
  rrp_state_init(project)
  time <- inspection_test_time("2026-01-10 12:00:00.125")

  run <- rrp_run(project, time)
  status <- rrp_project_status(project)

  expect_identical(status$run_count, 1L)
  expect_identical(status$latest_run_id, run$run_id)
  expect_identical(as.numeric(status$latest_as_of_time), as.numeric(time))
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 1L)
  expect_identical(nrow(rrp_inspect_history(project)), 0L)
  expect_identical(nrow(rrp_inspect_history(project, run_id = run$run_id)), 0L)
})

test_that("invalid paths, filters, and existing state fail without creating data", {
  expect_error(rrp_project_status(), "path")
  expect_error(rrp_inspect_history(), "path")
  expect_error(rrp_project_status(tempfile("absent-")), "project directory")
  expect_error(rrp_inspect_history(tempfile("absent-")), "project directory")
  project <- inspection_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  for (value in list(NA_character_, "", "  ", c("a", "b"), 1L)) {
    expect_error(rrp_inspect_history(project, run_id = value), "run_id")
    expect_error(rrp_inspect_history(project, episode_id = value),
                 "episode_id")
  }
  expect_false(dir.exists(file.path(project, "state")))

  partial <- inspection_test_project()
  on.exit(unlink(partial, recursive = TRUE), add = TRUE)
  dir.create(file.path(partial, "state"))
  expect_error(rrp_project_status(partial), "history.duckdb")
  expect_error(rrp_inspect_history(partial), "history.duckdb")
  expect_false(file.exists(file.path(partial, "state", "history.duckdb")))

  corrupt <- inspection_test_project()
  on.exit(unlink(corrupt, recursive = TRUE), add = TRUE)
  dir.create(file.path(corrupt, "state"))
  writeLines("not a DuckDB database",
             file.path(corrupt, "state", "history.duckdb"))
  expect_error(rrp_project_status(corrupt), "Could not read initialized")
  expect_error(rrp_inspect_history(corrupt), "Could not read initialized")

  unlink(file.path(project, "rrp-project.dcf"))
  expect_error(rrp_project_status(project), "configuration file is missing")
  expect_error(rrp_inspect_history(project), "configuration file is missing")
})
