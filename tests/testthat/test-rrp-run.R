run_test_time <- function(value) as.POSIXct(value, tz = "UTC")

run_test_canonical <- function() {
  episodes <- data.frame(
    episode_id = paste0("episode-", 1:8),
    patient_id = c("patient-1", "patient-1", paste0("patient-", 2:7)),
    index_encounter_id = paste0("encounter-", 1:8),
    admission_time = rep(run_test_time("2026-01-01 01:00:00.125"), 8),
    discharge_time = c(rep(run_test_time("2026-01-02 01:00:00.125"), 7),
                       run_test_time("2026-01-02 01:00:00.125"))
  )
  episodes$discharge_time[7] <- run_test_time("2025-12-01 01:00:00.125")
  episodes$admission_time[7] <- run_test_time("2025-11-30 01:00:00.125")
  events <- data.frame(
    terminal_event_id = c("event-readmission", "event-death", "event-delayed"),
    episode_id = c("episode-5", "episode-6", "episode-8"),
    event_type = c("readmission", "death", "readmission"),
    occurred_at = rep(run_test_time("2026-01-05 08:00:00.5"), 3),
    available_at = c(rep(run_test_time("2026-01-06 09:00:00.25"), 2),
                     run_test_time("2026-01-12 09:00:00.25"))
  )
  list(discharge_episode = episodes, terminal_event = events)
}

run_test_project <- function() {
  project <- tempfile("rrp-run-")
  rrp_project_init(project, "run-test")
  saveRDS(run_test_canonical(), file.path(project, "canonical.rds"))
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  log <- file.path(project_root, 'source-times.rds')",
    "  times <- if (file.exists(log)) readRDS(log) else list()",
    "  times[[length(times) + 1L]] <- as_of_time",
    "  saveRDS(times, log)",
    "  readRDS(file.path(project_root, 'canonical.rds'))",
    "}"
  ), file.path(project, "R", "produce-canonical.R"))
  writeLines(c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  log <- file.path(project_root, 'provider-requests.rds')",
    "  requests <- if (file.exists(log)) readRDS(log) else list()",
    "  requests[[length(requests) + 1L]] <- request",
    "  saveRDS(requests, log)",
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

test_that("integrated runs retain outcomes and time-specific event knowledge", {
  project <- run_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  file.rename(file.path(project, "R", "produce-canonical.R"),
              file.path(project, "R", "clinical-map.R"))
  file.rename(file.path(project, "R", "calculate-risk.R"),
              file.path(project, "R", "risk-model.R"))
  writeLines(c("Source-Mapping-Script: R/clinical-map.R",
               "Risk-Provider-Script: R/risk-model.R"),
             file.path(project, "rrp-authoring.dcf"))
  expect_true(rrp_project_validate(project))
  rrp_state_init(project)
  earlier <- run_test_time("2026-01-10 12:00:00.125")
  later <- run_test_time("2026-01-13 12:00:00.125")

  first <- rrp_run(project, earlier)
  expect_identical(names(first), c("run_id", "as_of_time",
                                   "episodes_processed", "accepted",
                                   "provider_failures", "ineligible"))
  expect_identical(first$as_of_time, earlier)
  expect_identical(unname(first[c("episodes_processed", "accepted",
                                  "provider_failures", "ineligible")]),
                   list(8L, 2L, 3L, 3L))
  expect_identical(first$episodes_processed,
                   first$accepted + first$provider_failures + first$ineligible)
  runs <- readmit:::rrp_read_runs(project)
  expect_identical(runs$run_id, first$run_id)
  expect_identical(runs$project_id, "run-test")
  expect_identical(runs$source_mapping_script, "R/clinical-map.R")
  expect_identical(runs$risk_provider_script, "R/risk-model.R")
  expect_identical(as.numeric(runs$as_of_time), as.numeric(earlier))
  expect_identical(attr(runs$created_at, "tzone"), "UTC")
  stored <- readmit:::rrp_read_assessments(project, first$run_id)
  expect_identical(nrow(stored), 8L)
  expect_identical(stored$episode_id, paste0("episode-", 1:8))
  expect_identical(stored$disposition, c(
    "accepted", rep("provider_failure", 3), "known_readmission",
    "known_death", "window_closed", "accepted"
  ))
  expect_identical(stored$probability[c(1, 8)], c(0.25, 0.25))
  expect_identical(stored$failure_kind[2:4],
                   c("reported", "unusable_result", "error"))
  expect_match(stored$failure_reason[2], "Predictor unavailable")
  expect_match(stored$failure_reason[4], "Model failed")
  expect_identical(stored$terminal_event_id[5:6],
                   c("event-readmission", "event-death"))
  expect_identical(stored$terminal_event_type[5:6],
                   c("readmission", "death"))
  expect_true(is.na(stored$terminal_event_id[8]))
  expect_true(all(is.na(stored$probability[2:7])))
  expect_true(all(is.na(stored$failure_kind[c(1, 5:8)])))
  expect_false(dir.exists(file.path(project, "state", "products")))

  requests <- readRDS(file.path(project, "provider-requests.rds"))
  expect_identical(vapply(requests, `[[`, character(1), "episode_id"),
                   paste0("episode-", c(1:4, 8)))
  expect_true(all(vapply(requests, function(request) {
    identical(request$as_of_time, earlier)
  }, logical(1))))
  expect_identical(readRDS(file.path(project, "source-times.rds"))[[1L]],
                   earlier)

  second <- rrp_run(project, later)
  third <- rrp_run(project, earlier)
  expect_length(unique(c(first$run_id, second$run_id, third$run_id)), 3L)
  expect_identical(unname(second[c("episodes_processed", "accepted",
                                   "provider_failures", "ineligible")]),
                   list(8L, 1L, 3L, 4L))
  expect_identical(unname(third[c("episodes_processed", "accepted",
                                  "provider_failures", "ineligible")]),
                   list(8L, 2L, 3L, 3L))
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 3L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 24L)
  first_delayed <- readmit:::rrp_read_assessments(
    project, first$run_id, "episode-8"
  )
  second_delayed <- readmit:::rrp_read_assessments(
    project, second$run_id, "episode-8"
  )
  expect_identical(first_delayed$disposition, "accepted")
  expect_true(is.na(first_delayed$terminal_event_id))
  expect_identical(second_delayed$disposition, "known_readmission")
  expect_identical(second_delayed$terminal_event_id, "event-delayed")
  expect_identical(as.numeric(second_delayed$terminal_occurred_at),
                   as.numeric(run_test_time("2026-01-05 08:00:00.5")))
  expect_identical(as.numeric(second_delayed$terminal_available_at),
                   as.numeric(run_test_time("2026-01-12 09:00:00.25")))
  expect_identical(vapply(readRDS(file.path(project, "source-times.rds")),
                          as.numeric, numeric(1)),
                   as.numeric(c(earlier, later, earlier)))
  requests <- readRDS(file.path(project, "provider-requests.rds"))
  expect_identical(length(requests), 14L)
  expect_true(all(vapply(requests[6:9], function(request) {
    identical(request$as_of_time, later)
  }, logical(1))))
})

test_that("zero-episode source creates one empty completed run", {
  project <- run_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  canonical <- run_test_canonical()
  canonical$discharge_episode <- canonical$discharge_episode[FALSE, , drop = FALSE]
  canonical$terminal_event <- canonical$terminal_event[FALSE, , drop = FALSE]
  saveRDS(canonical, file.path(project, "canonical.rds"))
  rrp_state_init(project)
  time <- run_test_time("2026-01-10 12:00:00.125")

  summary <- rrp_run(project, time)

  expect_identical(summary$as_of_time, time)
  expect_identical(unname(summary[c("episodes_processed", "accepted",
                                    "provider_failures", "ineligible")]),
                   list(0L, 0L, 0L, 0L))
  expect_identical(nrow(readmit:::rrp_read_runs(project, summary$run_id)), 1L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 0L)
  expect_false(file.exists(file.path(project, "provider-requests.rds")))
})

test_that("invalid prerequisites and source failures leave no completed run", {
  project <- run_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  time <- run_test_time("2026-01-10 12:00:00.125")
  expect_error(rrp_run(project, time), "rrp_state_init")
  expect_false(dir.exists(file.path(project, "state")))
  expect_false(file.exists(file.path(project, "source-times.rds")))
  expect_false(file.exists(file.path(project, "provider-requests.rds")))
  rrp_state_init(project)

  expect_error(rrp_run(project, as.Date("2026-01-10")), "UTC POSIXct")
  expect_error(rrp_run(project, as.POSIXct(NA, tz = "UTC")), "finite")
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 0L)

  writeLines("rrp_produce_canonical <- function(project_root, as_of_time) stop('Source unavailable')",
             file.path(project, "R", "produce-canonical.R"))
  expect_error(rrp_run(project, time), "Canonical source production failed")
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 0L)

  writeLines("rrp_produce_canonical <- function(project_root, as_of_time) readRDS(file.path(project_root, 'canonical.rds'))",
             file.path(project, "R", "produce-canonical.R"))
  saveRDS(list(discharge_episode = data.frame()),
          file.path(project, "canonical.rds"))
  expect_error(rrp_run(project, time), "Canonical source")
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 0L)

  invalid <- run_test_project()
  on.exit(unlink(invalid, recursive = TRUE), add = TRUE)
  unlink(file.path(invalid, "rrp-authoring.dcf"))
  expect_error(rrp_run(invalid, time), "configuration file is missing")
  expect_false(dir.exists(file.path(invalid, "state")))
})

test_that("fatal persistence failure rolls back and preserves earlier runs", {
  project <- run_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  rrp_state_init(project)
  time <- run_test_time("2026-01-10 12:00:00.125")
  prior <- rrp_run(project, time)
  canonical <- run_test_canonical()
  canonical$discharge_episode$discharge_time[1] <-
    run_test_time("2026-01-11 01:00:00.125")
  saveRDS(canonical, file.path(project, "canonical.rds"))

  expect_error(rrp_run(project, time))
  expect_identical(readmit:::rrp_read_runs(project)$run_id, prior$run_id)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 8L)

  saveRDS(run_test_canonical(), file.path(project, "canonical.rds"))
  next_run <- rrp_run(project, time)
  expect_false(identical(next_run$run_id, prior$run_id))
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 2L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 16L)
})
