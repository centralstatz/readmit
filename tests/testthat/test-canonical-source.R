canonical_test_time <- function(value) as.POSIXct(value, tz = "UTC")

canonical_test_data <- function() {
  list(
    discharge_episode = data.frame(
      episode_id = c("episode-1", "episode-2"),
      patient_id = c("patient-1", "patient-1"),
      index_encounter_id = c("encounter-1", "encounter-2"),
      admission_time = canonical_test_time(c(
        "2026-01-01 00:00:00", "2026-01-03 00:00:00"
      )),
      discharge_time = canonical_test_time(c(
        "2026-01-02 00:00:00", "2026-01-04 00:00:00"
      ))
    ),
    terminal_event = data.frame(
      terminal_event_id = c("event-1", "event-2"),
      episode_id = c("episode-1", "episode-1"),
      event_type = c("readmission", "death"),
      occurred_at = canonical_test_time(c(
        "2026-01-05 00:00:00", "2026-01-06 00:00:00"
      )),
      available_at = canonical_test_time(c(
        "2026-01-12 00:00:00", "2026-01-07 00:00:00"
      ))
    )
  )
}

canonical_test_project <- function() {
  project <- tempfile("rrp-canonical-")
  rrp_project_init(project, "canonical-test")
  writeLines(
    paste0(
      "rrp_produce_canonical <- function(project_root, as_of_time) ",
      "readRDS(file.path(project_root, 'canonical.rds'))"
    ),
    file.path(project, "R", "produce-canonical.R")
  )
  project
}

test_that("canonical source accepts project facts without interpreting time", {
  project <- canonical_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  canonical <- canonical_test_data()
  canonical$discharge_episode$project_note <- c("kept", "kept")
  saveRDS(canonical, file.path(project, "canonical.rds"))
  as_of_time <- canonical_test_time("2026-01-10 00:00:00")

  result <- readmit:::rrp_produce_project_canonical(project, as_of_time)

  expect_identical(result, canonical)
  expect_false("followup_window_end" %in% names(result$discharge_episode))
  expect_true(result$terminal_event$occurred_at[1] < as_of_time)
  expect_true(result$terminal_event$available_at[1] > as_of_time)
  expect_false(dir.exists(file.path(project, "state")))
  template <- system.file("project-template", package = "readmit")
  expect_identical(
    unname(tools::md5sum(file.path(project, "R/calculate-risk.R"))),
    unname(tools::md5sum(file.path(template, "R/calculate-risk.R")))
  )
})

test_that("typed empty canonical tables are accepted", {
  project <- canonical_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  as_of_time <- canonical_test_time("2026-01-10 00:00:00")
  canonical <- canonical_test_data()
  canonical$terminal_event <- canonical$terminal_event[FALSE, , drop = FALSE]
  saveRDS(canonical, file.path(project, "canonical.rds"))
  expect_identical(readmit:::rrp_produce_project_canonical(project, as_of_time),
                   canonical)

  canonical$discharge_episode <- canonical$discharge_episode[FALSE, ,
                                                             drop = FALSE]
  saveRDS(canonical, file.path(project, "canonical.rds"))
  expect_identical(readmit:::rrp_produce_project_canonical(project, as_of_time),
                   canonical)
})

test_that("canonical structural errors identify unusable facts", {
  project <- canonical_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  as_of_time <- canonical_test_time("2026-01-10 00:00:00")
  valid <- canonical_test_data()
  check_invalid <- function(value, message) {
    saveRDS(value, file.path(project, "canonical.rds"))
    expect_error(readmit:::rrp_produce_project_canonical(project, as_of_time),
                 message)
  }

  value <- valid
  value$terminal_event <- NULL
  check_invalid(value, "named list")
  value <- valid
  value$discharge_episode$patient_id <- NULL
  check_invalid(value, "discharge_episode.*required columns")
  value <- valid
  value$discharge_episode$episode_id <- 1:2
  check_invalid(value, "discharge_episode\\$episode_id")
  value <- valid
  value$terminal_event$available_at <- as.character(value$terminal_event$available_at)
  check_invalid(value, "terminal_event\\$available_at")
  value <- valid
  value$discharge_episode$patient_id[1] <- NA_character_
  check_invalid(value, "discharge_episode\\$patient_id")
  value <- valid
  value$terminal_event$occurred_at[1] <- canonical_test_time(NA_character_)
  check_invalid(value, "terminal_event\\$occurred_at")
  value <- valid
  value$terminal_event$occurred_at[1] <- as.POSIXct(Inf, origin = "1970-01-01",
                                                  tz = "UTC")
  check_invalid(value, "terminal_event\\$occurred_at")
  value <- valid
  value$discharge_episode$episode_id[2] <- "episode-1"
  check_invalid(value, "episode_id must be unique")
  value <- valid
  value$terminal_event$terminal_event_id[2] <- "event-1"
  check_invalid(value, "terminal_event_id must be unique")
  value <- valid
  value$terminal_event$event_type[1] <- "transfer"
  check_invalid(value, "event_type must be readmission or death")
  value <- valid
  value$terminal_event$episode_id[1] <- "unknown"
  check_invalid(value, "must reference a discharge episode")
  value <- valid
  value$discharge_episode$episode_id[1] <- "   "
  check_invalid(value, "discharge_episode\\$episode_id")
  value <- valid
  attr(value$terminal_event$available_at, "tzone") <- "America/Chicago"
  check_invalid(value, "finite UTC POSIXct")

  saveRDS(valid, file.path(project, "canonical.rds"))
  expect_error(readmit:::rrp_produce_project_canonical(project, as.Date("2026-01-10")),
               "as_of_time")
  expect_error(readmit:::rrp_produce_project_canonical(
    project, canonical_test_time(c("2026-01-10", "2026-01-11"))),
    "as_of_time")
})

test_that("source mapper can use a project-owned supporting script", {
  project <- canonical_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  canonical <- canonical_test_data()
  saveRDS(canonical, file.path(project, "canonical.rds"))
  writeLines(
    "canonical_from_file <- function(root) readRDS(file.path(root, 'canonical.rds'))",
    file.path(project, "R", "support.R")
  )
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  source(file.path(project_root, 'R', 'support.R'), local = TRUE)",
    "  canonical_from_file(project_root)",
    "}"
  ), file.path(project, "R", "produce-canonical.R"))

  expect_identical(
    readmit:::rrp_produce_project_canonical(
      project, canonical_test_time("2026-01-10 00:00:00")
    ),
    canonical
  )
})

test_that("source-mapper errors are reported without empty substitution", {
  project <- canonical_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  stop('source offline')",
    "}"
  ), file.path(project, "R", "produce-canonical.R"))

  expect_error(
    readmit:::rrp_produce_project_canonical(
      project, canonical_test_time("2026-01-10 00:00:00")
    ),
    "Canonical source production failed: source offline"
  )
})
