product_test_time <- function(value) as.POSIXct(value, tz = "UTC")

product_test_project <- function() {
  project <- tempfile("rrp-products-")
  rrp_project_init(project, "product-test")
  rrp_state_init(project)
  project
}

product_test_write <- function(project, run_id, as_of_time, created_at,
                               outcomes = character(), probabilities = numeric()) {
  ids <- if (length(outcomes)) names(outcomes) else character()
  n <- length(outcomes)
  discharge <- rep(product_test_time("2026-01-01 00:00:00.125"), n)
  discharge[outcomes == "window_closed"] <-
    product_test_time("2025-11-01 00:00:00.125")
  probability <- rep(NA_real_, n)
  accepted <- outcomes == "accepted"
  probability[accepted] <- unname(probabilities[ids[accepted]])
  failure_kind <- rep(NA_character_, n)
  failure_reason <- rep(NA_character_, n)
  failure_kind[outcomes == "provider_failure"] <- "reported"
  failure_reason[outcomes == "provider_failure"] <- "No estimate"
  terminal_id <- rep(NA_character_, n)
  terminal_type <- rep(NA_character_, n)
  known <- outcomes %in% c("known_readmission", "known_death")
  terminal_id[known] <- paste0("event-", ids[known])
  terminal_type[outcomes == "known_readmission"] <- "readmission"
  terminal_type[outcomes == "known_death"] <- "death"
  terminal_time <- as.POSIXct(rep(NA_real_, n),
                              origin = "1970-01-01", tz = "UTC")
  terminal_time[known] <- product_test_time("2026-01-05 00:00:00.5")
  assessments <- data.frame(
    episode_id = ids,
    patient_id = ids,
    index_encounter_id = ids,
    admission_time = discharge - 3600,
    discharge_time = discharge,
    followup_window_end = discharge + 30 * 24 * 60 * 60,
    disposition = unname(outcomes),
    probability = probability,
    failure_kind = failure_kind,
    failure_reason = failure_reason,
    terminal_event_id = terminal_id,
    terminal_event_type = terminal_type,
    terminal_occurred_at = terminal_time,
    terminal_available_at = terminal_time
  )
  readmit:::rrp_write_history(project, list(
    run_id = run_id, project_id = "product-test",
    as_of_time = product_test_time(as_of_time),
    created_at = product_test_time(created_at),
    source_mapping_script = "R/produce-canonical.R",
    risk_provider_script = "R/calculate-risk.R"
  ), assessments)
}

test_that("no run differs from a selected completed zero-episode run", {
  project <- product_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  expect_error(readmit:::rrp_calculate_products(project),
               "no completed runs")
  product_test_write(project, "empty-run", "2026-01-20 00:00:00.125",
                     "2026-01-21 00:00:00.125")
  products <- readmit:::rrp_calculate_products(project)
  expect_identical(names(products), c("current_risk", "trajectory", "scope"))
  expect_identical(names(products$current_risk), c(
    "selected_run_id", "as_of_time", "episode_id", "discharge_time",
    "followup_window_end", "disposition", "probability"
  ))
  expect_identical(names(products$trajectory), c(
    "selected_run_id", "run_id", "as_of_time", "created_at",
    "episode_id", "probability"
  ))
  expect_identical(names(products$scope), c(
    "selected_run_id", "project_id", "as_of_time", "created_at",
    "episodes_assessed", "eligible_count", "accepted_count",
    "provider_failure_count", "ineligible_count", "window_closed_count",
    "known_readmission_count", "known_death_count"
  ))
  expect_identical(nrow(products$current_risk), 0L)
  expect_identical(nrow(products$trajectory), 0L)
  expect_identical(nrow(products$scope), 1L)
  expect_identical(products$scope$selected_run_id, "empty-run")
  expect_identical(unname(unlist(products$scope[5:12])), rep(0L, 8L))
  for (frame in products) {
    for (field in intersect(names(frame), c("as_of_time", "created_at",
                                            "discharge_time",
                                            "followup_window_end"))) {
      expect_s3_class(frame[[field]], "POSIXct")
      expect_identical(attr(frame[[field]], "tzone"), "UTC")
    }
  }
  expect_type(products$current_risk$probability, "double")
  expect_type(products$trajectory$probability, "double")
  expect_true(all(vapply(products$scope[5:12], is.integer, logical(1))))
  expect_false(dir.exists(file.path(project, "state", "products")))
})

test_that("current pool includes failures and trajectories retain accepted history", {
  project <- product_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  product_test_write(project, "run-old", "2026-01-10 00:00:00.125",
                     "2026-01-10 01:00:00.125",
                     c(a = "accepted", b = "accepted", c = "accepted",
                       d = "accepted", e = "accepted", h = "accepted"),
                     c(a = 0.24, b = 0.28, c = 0.4, d = 0.5, e = 0.6,
                       h = 0.7))
  latest <- c(a = "provider_failure", b = "accepted",
              c = "known_readmission", d = "known_death",
              e = "window_closed", f = "provider_failure", g = "accepted")
  product_test_write(project, "run-zzzz", "2026-01-20 00:00:00.125",
                     "2026-01-20 01:00:00.125", latest,
                     c(b = 0.20, g = 0.29))
  product_test_write(project, "run-a", "2026-01-20 00:00:00.125",
                     "2026-01-21 01:00:00.125", latest,
                     c(b = 0.21, g = 0.30))
  product_test_write(project, "run-z", "2026-01-20 00:00:00.125",
                     "2026-01-21 01:00:00.125", latest,
                     c(b = 0.22, g = 0.31))
  # Executed last, but analytically earlier; h is absent from the current run.
  product_test_write(project, "run-backfill", "2026-01-15 00:00:00.125",
                     "2026-01-30 01:00:00.125",
                     c(a = "accepted", b = "accepted", h = "accepted"),
                     c(a = 0.23, b = 0.25, h = 0.35))

  before_runs <- readmit:::rrp_read_runs(project)
  before_assessments <- readmit:::rrp_read_assessments(project)
  writeLines("stop('Source script was sourced')",
             file.path(project, "R", "produce-canonical.R"))
  writeLines("stop('Provider script was sourced')",
             file.path(project, "R", "calculate-risk.R"))
  products <- readmit:::rrp_calculate_products(project)
  expect_identical(products$scope$selected_run_id, "run-z")
  expect_identical(products$scope$project_id, "product-test")
  expect_identical(products$current_risk$episode_id, c("a", "b", "f", "g"))
  expect_identical(products$current_risk$disposition,
                   c("provider_failure", "accepted", "provider_failure",
                     "accepted"))
  expect_true(all(is.na(products$current_risk$probability[c(1, 3)])))
  expect_identical(products$current_risk$probability[c(2, 4)], c(0.22, 0.31))
  expect_identical(unique(products$current_risk$selected_run_id), "run-z")
  expect_true(all(products$current_risk$as_of_time ==
                  product_test_time("2026-01-20 00:00:00.125")))
  expect_identical(unname(unlist(products$scope[5:12])),
                   c(7L, 4L, 2L, 2L, 3L, 1L, 1L, 1L))
  expect_identical(nrow(products$current_risk), products$scope$eligible_count)

  trajectory <- products$trajectory
  expect_identical(unique(trajectory$selected_run_id), "run-z")
  expect_setequal(unique(trajectory$episode_id), c("a", "b", "g"))
  expect_false(any(trajectory$episode_id %in% c("c", "d", "e", "f", "h")))
  expect_identical(trajectory$run_id[trajectory$episode_id == "a"],
                   c("run-old", "run-backfill"))
  expect_identical(trajectory$probability[trajectory$episode_id == "a"],
                   c(0.24, 0.23))
  expect_identical(trajectory$run_id[trajectory$episode_id == "b"],
                   c("run-old", "run-backfill", "run-zzzz", "run-a", "run-z"))
  expect_identical(trajectory$probability[trajectory$episode_id == "b"],
                   c(0.28, 0.25, 0.20, 0.21, 0.22))
  expect_identical(trajectory$run_id[trajectory$episode_id == "g"],
                   c("run-zzzz", "run-a", "run-z"))
  expect_identical(attr(trajectory$created_at, "tzone"), "UTC")
  expect_identical(attr(trajectory$as_of_time, "tzone"), "UTC")
  expect_identical(readmit:::rrp_read_runs(project), before_runs)
  expect_identical(readmit:::rrp_read_assessments(project),
                   before_assessments)
  expect_false(dir.exists(file.path(project, "state", "products")))
})

test_that("a later partial or ineligible snapshot replaces earlier membership", {
  project <- product_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  product_test_write(project, "wide", "2026-01-10 00:00:00.125",
                     "2026-01-10 01:00:00.125",
                     c(a = "accepted", b = "accepted"),
                     c(a = 0.24, b = 0.32))
  product_test_write(project, "partial", "2026-01-21 00:00:00.125",
                     "2026-01-21 01:00:00.125",
                     c(a = "provider_failure"))
  partial <- readmit:::rrp_calculate_products(project)
  expect_identical(partial$current_risk$episode_id, "a")
  expect_identical(partial$current_risk$disposition, "provider_failure")
  expect_true(is.na(partial$current_risk$probability))
  expect_identical(partial$trajectory$episode_id, "a")
  expect_identical(partial$trajectory$probability, 0.24)
  expect_identical(partial$scope$episodes_assessed, 1L)
  expect_identical(partial$scope$eligible_count, 1L)
  expect_identical(partial$scope$provider_failure_count, 1L)

  product_test_write(project, "ineligible", "2026-01-22 00:00:00.125",
                     "2026-01-22 01:00:00.125",
                     c(a = "known_readmission", b = "known_death",
                       c = "window_closed"))
  excluded <- readmit:::rrp_calculate_products(project)
  expect_identical(excluded$scope$selected_run_id, "ineligible")
  expect_identical(nrow(excluded$current_risk), 0L)
  expect_identical(nrow(excluded$trajectory), 0L)
  expect_identical(excluded$scope$episodes_assessed, 3L)
  expect_identical(excluded$scope$eligible_count, 0L)
  expect_identical(excluded$scope$ineligible_count, 3L)
})
