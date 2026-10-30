history_test_time <- function(value) as.POSIXct(value, tz = "UTC")

history_test_project <- function() {
  project <- tempfile("rrp-history-")
  rrp_project_init(project, "history-test")
  project
}

history_test_run <- function(as_of_time = history_test_time(
                               "2026-01-10 12:00:00.125")) {
  list(
    project_id = "history-test", as_of_time = as_of_time,
    created_at = history_test_time("2026-01-10 12:00:01.375"),
    source_mapping_script = "R/produce-canonical.R",
    risk_provider_script = "R/calculate-risk.R"
  )
}

history_test_assessments <- function() {
  discharge <- history_test_time("2026-01-02 01:00:00.125")
  episodes <- data.frame(
    episode_id = paste0("episode-", 1:7),
    patient_id = c("patient-1", "patient-1", paste0("patient-", 2:6)),
    index_encounter_id = paste0("encounter-", 1:7),
    admission_time = rep(history_test_time("2026-01-01 01:00:00.125"), 7),
    discharge_time = c(rep(discharge, 6),
                       history_test_time("2025-12-01 01:00:00.125"))
  )
  events <- data.frame(
    terminal_event_id = c("event-readmission", "event-death"),
    episode_id = c("episode-5", "episode-6"),
    event_type = c("readmission", "death"),
    occurred_at = rep(history_test_time("2026-01-05 08:00:00.5"), 2),
    available_at = rep(history_test_time("2026-01-06 09:00:00.25"), 2)
  )
  eligibility <- readmit:::rrp_evaluate_eligibility(
    list(discharge_episode = episodes, terminal_event = events),
    history_test_run()$as_of_time
  )
  provider <- function(project_root, request) {
    switch(request$episode_id,
           "episode-1" = list(probability = 0.25),
           "episode-2" = list(failure = "Predictor unavailable"),
           "episode-3" = list(probability = NA_real_),
           "episode-4" = stop("Model failed"))
  }
  readmit:::rrp_assess_eligible_episodes(
    eligibility, history_test_run()$as_of_time, "/example-project", provider
  )
}

test_that("state initialization requires a valid fresh project and stays separate", {
  project <- history_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  result <- rrp_state_init(project)
  expect_identical(result, normalizePath(project, winslash = "/"))
  expect_true(file.exists(file.path(project, "state", "history.duckdb")))
  expect_false(dir.exists(file.path(project, "state", "products")))
  expect_setequal(list.files(file.path(project, "state")), "history.duckdb")

  connection <- readmit:::rrp_history_connect(project, read_only = TRUE)
  expect_setequal(DBI::dbListTables(connection), c("runs", "assessments"))
  DBI::dbDisconnect(connection, shutdown = TRUE)
  expect_error(rrp_state_init(project), "state already exists")
  expect_true(file.exists(file.path(project, "state", "history.duckdb")))

  invalid <- history_test_project()
  on.exit(unlink(invalid, recursive = TRUE), add = TRUE)
  unlink(file.path(invalid, "rrp-authoring.dcf"))
  expect_error(rrp_state_init(invalid), "configuration file is missing")
  expect_false(dir.exists(file.path(invalid, "state")))

  partial <- history_test_project()
  on.exit(unlink(partial, recursive = TRUE), add = TRUE)
  dir.create(file.path(partial, "state"))
  writeLines("owner data", file.path(partial, "state", "notes.txt"))
  expect_error(rrp_state_init(partial), "state already exists")
  expect_identical(readLines(file.path(partial, "state", "notes.txt")),
                   "owner data")
})

test_that("new history reads as typed empty data and missing state is not created", {
  project <- history_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  expect_error(readmit:::rrp_read_runs(project), "not initialized")
  expect_false(dir.exists(file.path(project, "state")))
  rrp_state_init(project)

  runs <- readmit:::rrp_read_runs(project)
  assessments <- readmit:::rrp_read_assessments(project)
  expect_identical(nrow(runs), 0L)
  expect_identical(nrow(assessments), 0L)
  expect_identical(names(runs), c("run_id", "project_id", "as_of_time",
                                  "created_at", "source_mapping_script",
                                  "risk_provider_script"))
  expect_true(all(c("run_id", "episode_id", "probability", "failure_kind",
                    "terminal_occurred_at", "as_of_time") %in%
                  names(assessments)))
  expect_s3_class(runs$as_of_time, "POSIXct")
  expect_s3_class(runs$created_at, "POSIXct")
  expect_s3_class(assessments$terminal_occurred_at, "POSIXct")
  expect_type(assessments$probability, "double")
  expect_type(assessments$failure_kind, "character")
  expect_identical(attr(assessments$terminal_occurred_at, "tzone"), "UTC")
})

test_that("completed runs append and retain outcomes, UTC times, and nulls", {
  project <- history_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  rrp_state_init(project)
  input <- history_test_assessments()
  metadata <- history_test_run()
  first <- readmit:::rrp_write_history(project, metadata, input)
  second <- readmit:::rrp_write_history(project, metadata, input[1, , drop = FALSE])
  third <- readmit:::rrp_write_history(project, metadata, input[FALSE, , drop = FALSE])
  expect_length(unique(c(first, second, third)), 3L)

  runs <- readmit:::rrp_read_runs(project)
  stored <- readmit:::rrp_read_assessments(project, first)
  expect_identical(nrow(runs), 3L)
  expect_identical(nrow(stored), 7L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 8L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project, third)), 0L)
  expect_identical(nrow(readmit:::rrp_read_runs(project, first)), 1L)
  expect_identical(nrow(readmit:::rrp_read_assessments(
    project, first, "episode-5")), 1L)
  expect_identical(nrow(readmit:::rrp_read_assessments(
    project, episode_id = "episode-1")), 2L)
  expect_true(all(runs$as_of_time == metadata$as_of_time))
  expect_identical(as.numeric(runs$as_of_time),
                   rep(as.numeric(metadata$as_of_time), 3))
  expect_identical(as.numeric(runs$created_at),
                   rep(as.numeric(metadata$created_at), 3))
  expect_identical(attr(runs$as_of_time, "tzone"), "UTC")
  expect_identical(stored$disposition,
                   input$disposition[match(stored$episode_id, input$episode_id)])
  for (field in c("admission_time", "discharge_time",
                  "followup_window_end", "terminal_occurred_at",
                  "terminal_available_at")) {
    expect_s3_class(stored[[field]], "POSIXct")
    expect_identical(attr(stored[[field]], "tzone"), "UTC")
    expect_identical(as.numeric(stored[[field]]),
                     as.numeric(input[[field]][match(stored$episode_id,
                                                      input$episode_id)]))
  }
  expect_identical(stored$probability[stored$episode_id == "episode-1"], 0.25)
  expect_true(all(is.na(stored$failure_kind[stored$disposition == "accepted"])))
  expect_identical(stored$failure_kind[stored$episode_id %in%
                                              paste0("episode-", 2:4)],
                   c("reported", "unusable_result", "error"))
  expect_true(all(is.na(stored$probability[stored$disposition != "accepted"])))
  expect_identical(stored$terminal_event_id[stored$episode_id %in%
                                                paste0("episode-", 5:6)],
                   c("event-readmission", "event-death"))
  expect_true(all(is.na(stored$terminal_event_id[stored$episode_id %in%
                                                  paste0("episode-", c(1:4, 7))])))
  expect_true(all(is.na(stored$terminal_occurred_at[stored$episode_id ==
                                                         "episode-7"])))
  expect_identical(stored$source_mapping_script,
                   rep("R/produce-canonical.R", 7))

  expect_error(rrp_state_init(project), "state already exists")
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 3L)
})

test_that("failed inserts roll back all rows and leave earlier history usable", {
  project <- history_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  rrp_state_init(project)
  metadata <- history_test_run()
  input <- history_test_assessments()
  prior <- readmit:::rrp_write_history(project, metadata,
                                       input[1, , drop = FALSE])
  bad <- input[1:2, , drop = FALSE]
  bad$episode_id[2] <- bad$episode_id[1]
  expect_error(readmit:::rrp_write_history(project, metadata, bad))
  expect_identical(readmit:::rrp_read_runs(project)$run_id, prior)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 1L)

  duplicate <- metadata
  duplicate$run_id <- prior
  expect_error(readmit:::rrp_write_history(project, duplicate, input[1, ,
                                                                    drop = FALSE]))
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 1L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 1L)

  next_id <- readmit:::rrp_write_history(project, metadata,
                                         input[2, , drop = FALSE])
  expect_false(identical(next_id, prior))
  expect_identical(nrow(readmit:::rrp_read_runs(project)), 2L)
  expect_identical(nrow(readmit:::rrp_read_assessments(project)), 2L)

  # A new write-mode connection works after both successful and failed calls.
  connection <- readmit:::rrp_history_connect(project)
  expect_true(DBI::dbIsValid(connection))
  DBI::dbDisconnect(connection, shutdown = TRUE)
})
