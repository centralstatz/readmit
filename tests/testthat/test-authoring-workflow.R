test_that("installed project supports the complete Stage 2 authoring workflow", {
  project <- tempfile("rrp-integration-")
  rrp_project_init(project, "integration-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)

  untouched <- withVisible(rrp_project_validate(project))
  expect_identical(untouched$value, TRUE)
  expect_false(untouched$visible)

  provider <- file.path(project, "R", "calculate-risk.R")
  installed_provider <- system.file("project-template", "R", "calculate-risk.R",
                                    package = "readmit")
  expect_identical(readLines(provider), readLines(installed_provider))

  writeLines(c(
    "canonical_fixture <- function(as_of_time) {",
    "  utc <- function(value) as.POSIXct(value, tz = 'UTC')",
    "  list(",
    "    discharge_episode = data.frame(",
    "      episode_id = c('episode-1', 'episode-2', 'episode-3'),",
    "      patient_id = c('patient-1', 'patient-2', 'patient-3'),",
    "      index_encounter_id = c('encounter-1', 'encounter-2', 'encounter-3'),",
    "      admission_time = utc(c('2026-01-01', '2026-01-02', '2026-01-03')),",
    "      discharge_time = utc(c('2026-01-02', '2026-01-03', '2026-01-04'))",
    "    ),",
    "    terminal_event = data.frame(",
    "      terminal_event_id = c('event-1', 'event-2', 'event-3'),",
    "      episode_id = c('episode-1', 'episode-2', 'episode-3'),",
    "      event_type = c('readmission', 'death', 'readmission'),",
    "      occurred_at = utc(c('2026-01-05', '2026-01-06', '2026-01-07')),",
    "      available_at = utc(c('2026-01-05', '2026-01-06', '2026-01-12'))",
    "    )",
    "  )",
    "}"
  ), file.path(project, "R", "canonical-fixture.R"))
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  source(file.path(project_root, 'R', 'canonical-fixture.R'), local = TRUE)",
    "  canonical_fixture(as_of_time)",
    "}"
  ), file.path(project, "R", "produce-canonical.R"))

  edited <- withVisible(rrp_project_validate(project))
  expect_identical(edited$value, TRUE)
  expect_false(edited$visible)
  loaded <- readmit:::rrp_load_project_authoring(project)
  expect_true(is.function(loaded$produce_canonical))
  expect_true(is.function(loaded$calculate_risk))
  expect_identical(loaded$risk_provider_script,
                   normalizePath(provider, winslash = "/"))

  as_of_time <- as.POSIXct("2026-01-10 00:00:00", tz = "UTC")
  canonical <- readmit:::rrp_produce_project_canonical(project, as_of_time)

  expect_identical(canonical$discharge_episode$episode_id,
                   c("episode-1", "episode-2", "episode-3"))
  expect_identical(canonical$terminal_event$terminal_event_id,
                   c("event-1", "event-2", "event-3"))
  expect_identical(canonical$terminal_event$event_type,
                   c("readmission", "death", "readmission"))
  expect_gt(canonical$terminal_event$available_at[3L], as_of_time)
  expect_lt(canonical$terminal_event$occurred_at[3L], as_of_time)
  expect_false("followup_window_end" %in%
                 names(canonical$discharge_episode))
  expect_identical(readLines(provider), readLines(installed_provider))
  expect_false(any(file.exists(file.path(project, c("source", "state")))))
})
