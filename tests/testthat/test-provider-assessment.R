provider_test_time <- function(value) as.POSIXct(value, tz = "UTC")

provider_test_eligibility <- function() {
  episodes <- data.frame(
    episode_id = paste0("episode-", 1:6),
    patient_id = c("patient-1", "patient-1", paste0("patient-", 2:5)),
    index_encounter_id = paste0("encounter-", 1:6),
    admission_time = provider_test_time(rep("2026-01-01", 6)),
    discharge_time = provider_test_time(c(rep("2026-01-02", 5),
                                          "2025-12-01"))
  )
  events <- data.frame(
    terminal_event_id = c("event-readmission", "event-death"),
    episode_id = c("episode-4", "episode-5"),
    event_type = c("readmission", "death"),
    occurred_at = provider_test_time(rep("2026-01-05", 2)),
    available_at = provider_test_time(rep("2026-01-06", 2))
  )
  as_of_time <- provider_test_time("2026-01-10")
  list(
    episodes = readmit:::rrp_evaluate_eligibility(
      list(discharge_episode = episodes, terminal_event = events), as_of_time
    ),
    as_of_time = as_of_time
  )
}

test_that("requests carry exactly one eligible episode and its remaining horizon", {
  fixture <- provider_test_eligibility()
  requests <- list()
  roots <- character()
  provider <- function(project_root, request) {
    roots <<- c(roots, project_root)
    requests[[length(requests) + 1L]] <<- request
    list(probability = switch(request$episode_id,
                              "episode-1" = 0, "episode-2" = 0.24,
                              "episode-3" = 1))
  }

  result <- readmit:::rrp_assess_eligible_episodes(
    fixture$episodes, fixture$as_of_time, "/example-project", provider
  )

  expect_length(requests, 3L)
  expect_identical(roots, rep("/example-project", 3))
  expect_identical(vapply(requests, `[[`, character(1), "episode_id"),
                   paste0("episode-", 1:3))
  expect_identical(names(requests[[1L]]), c(
    "episode_id", "patient_id", "index_encounter_id", "admission_time",
    "discharge_time", "as_of_time", "followup_window_end",
    "remaining_seconds"
  ))
  expect_identical(requests[[1L]]$patient_id, "patient-1")
  expect_identical(requests[[2L]]$patient_id, "patient-1")
  expect_identical(requests[[1L]]$index_encounter_id, "encounter-1")
  expect_identical(requests[[1L]]$admission_time,
                   fixture$episodes$admission_time[1L])
  expect_identical(requests[[1L]]$discharge_time,
                   fixture$episodes$discharge_time[1L])
  expect_identical(requests[[1L]]$as_of_time, fixture$as_of_time)
  expect_identical(requests[[1L]]$followup_window_end,
                   fixture$episodes$followup_window_end[1L])
  expect_equal(requests[[1L]]$remaining_seconds,
               as.numeric(difftime(requests[[1L]]$followup_window_end,
                                   fixture$as_of_time, units = "secs")))
  expect_gt(requests[[1L]]$remaining_seconds, 0)
  expect_s3_class(requests[[1L]]$as_of_time, "POSIXct")
  expect_identical(attr(requests[[1L]]$as_of_time, "tzone"), "UTC")
  expect_identical(attr(requests[[1L]]$followup_window_end, "tzone"), "UTC")
  expect_identical(result$disposition[1:3], rep("accepted", 3))
  expect_identical(result$probability[1:3], c(0, 0.24, 1))
  expect_true(all(is.na(result$failure_kind[1:3])))
  expect_true(all(is.na(result$failure_reason[1:3])))
  expect_identical(result$episode_id, fixture$episodes$episode_id)
  expect_identical(result$terminal_event_id,
                   fixture$episodes$terminal_event_id)
})

test_that("reported failures and thrown errors stay with their episodes", {
  fixture <- provider_test_eligibility()
  provider <- function(project_root, request) {
    if (request$episode_id == "episode-1") {
      return(list(failure = "Required predictor unavailable"))
    }
    if (request$episode_id == "episode-2") stop("Model input unavailable")
    list(probability = 0.6)
  }

  result <- readmit:::rrp_assess_eligible_episodes(
    fixture$episodes, fixture$as_of_time, "/example-project", provider
  )

  expect_identical(result$disposition[1:3],
                   c("provider_failure", "provider_failure", "accepted"))
  expect_identical(result$failure_kind[1:3],
                   c("reported", "error", NA_character_))
  expect_identical(result$failure_reason[1L],
                   "Required predictor unavailable")
  expect_match(result$failure_reason[2L], "Model input unavailable")
  expect_true(all(is.na(result$probability[1:2])))
  expect_identical(result$probability[3L], 0.6)
  expect_identical(result$disposition[4:6],
                   c("known_readmission", "known_death", "window_closed"))
  expect_true(all(is.na(result$probability[4:6])))
  expect_true(all(is.na(result$failure_kind[4:6])))
  expect_identical(result$terminal_event_id,
                   fixture$episodes$terminal_event_id)
  expect_identical(result$terminal_occurred_at,
                   fixture$episodes$terminal_occurred_at)
  expect_identical(result$terminal_available_at,
                   fixture$episodes$terminal_available_at)
})

test_that("unusable returns become failures and later episodes continue", {
  invalid <- list(
    null = NULL,
    bare_number = 0.2,
    empty_list = list(),
    missing_number = list(probability = NA_real_),
    not_a_number = list(probability = NaN),
    infinite = list(probability = Inf),
    below_zero = list(probability = -0.1),
    above_one = list(probability = 1.1),
    vector = list(probability = c(0.2, 0.3)),
    text_probability = list(probability = "0.2"),
    classed_probability = list(probability = structure(0.2, class = "estimate")),
    blank_failure = list(failure = "  "),
    missing_failure = list(failure = NA_character_),
    both_fields = list(probability = 0.2, failure = "uncertain"),
    classed_list = structure(list(probability = 0.2), class = "estimate"),
    data_frame = data.frame(probability = 0.2),
    unexpected_field = list(estimate = 0.2)
  )
  fixture <- provider_test_eligibility()
  for (case in names(invalid)) {
    calls <- 0L
    value <- invalid[[case]]
    provider <- function(project_root, request) {
      calls <<- calls + 1L
      if (calls == 1L) value else list(probability = 0.4)
    }
    result <- readmit:::rrp_assess_eligible_episodes(
      fixture$episodes, fixture$as_of_time, "/example-project", provider
    )
    expect_identical(calls, 3L, info = case)
    expect_identical(result$disposition[1L], "provider_failure", info = case)
    expect_identical(result$failure_kind[1L], "unusable_result", info = case)
    expect_true(nzchar(result$failure_reason[1L]), info = case)
    expect_true(is.na(result$probability[1L]), info = case)
    expect_identical(result$disposition[2:3], rep("accepted", 2), info = case)
  }
})

test_that("loaded project provider can read private data through project root", {
  fixture <- provider_test_eligibility()
  project <- tempfile("rrp-provider-")
  rrp_project_init(project, "provider-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  saveRDS(c("episode-1" = 0.15, "episode-2" = 0.35,
            "episode-3" = 0.55), file.path(project, "private-risk.rds"))
  writeLines(c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  private <- readRDS(file.path(project_root, 'private-risk.rds'))",
    "  list(probability = unname(private[[request$episode_id]]))",
    "}"
  ), file.path(project, "R", "calculate-risk.R"))
  loaded <- readmit:::rrp_load_project_authoring(project)

  result <- readmit:::rrp_assess_eligible_episodes(
    fixture$episodes, fixture$as_of_time, loaded$project_root,
    loaded$calculate_risk
  )

  expect_identical(result$probability[1:3], c(0.15, 0.35, 0.55))
  expect_identical(result$disposition[1:3], rep("accepted", 3))
  expect_false(dir.exists(file.path(project, "state")))
})

test_that("zero-row input remains typed and never invokes the provider", {
  fixture <- provider_test_eligibility()
  empty <- fixture$episodes[FALSE, , drop = FALSE]
  provider <- function(project_root, request) stop("must not run")

  result <- readmit:::rrp_assess_eligible_episodes(
    empty, fixture$as_of_time, "/example-project", provider
  )

  expect_identical(nrow(result), 0L)
  expect_identical(names(result), c(names(empty), "probability",
                                    "failure_kind", "failure_reason"))
  expect_type(result$probability, "double")
  expect_type(result$failure_kind, "character")
  expect_type(result$failure_reason, "character")
  expect_s3_class(result$terminal_occurred_at, "POSIXct")
})
