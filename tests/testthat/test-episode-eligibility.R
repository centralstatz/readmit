eligibility_time <- function(value) as.POSIXct(value, tz = "UTC")

eligibility_canonical <- function() {
  list(
    discharge_episode = data.frame(
      episode_id = "episode-1",
      patient_id = "patient-1",
      index_encounter_id = "encounter-1",
      admission_time = eligibility_time("2026-01-01 00:00:00"),
      discharge_time = eligibility_time("2026-01-02 00:00:00")
    ),
    terminal_event = data.frame(
      terminal_event_id = character(),
      episode_id = character(),
      event_type = character(),
      occurred_at = eligibility_time(character()),
      available_at = eligibility_time(character())
    )
  )
}

eligibility_events <- function(id, episode, type, occurred, available) {
  data.frame(
    terminal_event_id = id,
    episode_id = episode,
    event_type = type,
    occurred_at = eligibility_time(occurred),
    available_at = eligibility_time(available)
  )
}

test_that("follow-up uses 30 elapsed days and a strict assessment endpoint", {
  canonical <- eligibility_canonical()
  discharge <- eligibility_time("2026-03-08 07:30:00")
  canonical$discharge_episode$discharge_time <- discharge
  canonical$discharge_episode$admission_time <- discharge - 86400
  endpoint <- discharge + 30 * 24 * 60 * 60
  evaluate <- function(time) readmit:::rrp_evaluate_eligibility(canonical, time)

  at_discharge <- evaluate(discharge)
  expect_identical(at_discharge$disposition, "eligible")
  expect_identical(at_discharge$followup_window_end, endpoint)
  expect_equal(as.numeric(difftime(endpoint, discharge, units = "secs")),
               30 * 24 * 60 * 60)
  expect_identical(evaluate(discharge + 15 * 86400)$disposition, "eligible")
  expect_identical(evaluate(endpoint - 1)$disposition, "eligible")
  expect_identical(evaluate(endpoint)$disposition, "window_closed")
  expect_identical(evaluate(endpoint + 1)$disposition, "window_closed")
  expect_identical(evaluate(discharge - 1)$disposition,
                   "not_yet_discharged")
  expect_true(all(is.na(at_discharge[c(
    "terminal_event_id", "terminal_event_type", "terminal_occurred_at",
    "terminal_available_at"
  )])))
  expect_s3_class(at_discharge$terminal_occurred_at, "POSIXct")
  expect_identical(attr(at_discharge$terminal_occurred_at, "tzone"), "UTC")
})

test_that("analytical time follows the existing finite UTC instant rule", {
  canonical <- eligibility_canonical()
  evaluate <- function(time) readmit:::rrp_evaluate_eligibility(canonical, time)

  expect_error(evaluate(as.Date("2026-01-03")), "finite UTC POSIXct")
  expect_error(evaluate(eligibility_time(c("2026-01-03", "2026-01-04"))),
               "one finite UTC POSIXct")
  expect_error(evaluate(eligibility_time(NA_character_)),
               "finite UTC POSIXct")
  expect_error(evaluate(as.POSIXct("2026-01-03", tz = "America/Chicago")),
               "finite UTC POSIXct")
})

test_that("only events occurred and available by the requested time are known", {
  canonical <- eligibility_canonical()
  episodes <- canonical$discharge_episode
  episodes$episode_id <- "episode-2"
  episodes$patient_id <- "patient-1"
  episodes$index_encounter_id <- "encounter-2"
  canonical$discharge_episode <- rbind(canonical$discharge_episode, episodes)
  canonical$terminal_event <- eligibility_events(
    c("readmission-late", "death-late", "future-event"),
    c("episode-1", "episode-2", "episode-2"),
    c("readmission", "death", "readmission"),
    c("2026-01-04", "2026-01-04", "2026-01-11"),
    c("2026-01-08", "2026-01-08", "2026-01-03")
  )

  day_5 <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-05")
  )
  day_9 <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-09")
  )

  expect_identical(day_5$disposition, c("eligible", "eligible"))
  expect_true(all(is.na(day_5$terminal_event_id)))
  expect_identical(day_9$disposition,
                   c("known_readmission", "known_death"))
  expect_identical(day_9$terminal_event_id,
                   c("readmission-late", "death-late"))
  expect_identical(day_9$terminal_occurred_at,
                   eligibility_time(c("2026-01-04", "2026-01-04")))
  expect_identical(day_9$terminal_available_at,
                   eligibility_time(c("2026-01-08", "2026-01-08")))
  expect_identical(day_5$episode_id, day_9$episode_id)
})

test_that("earliest known event, readmission tie, and event ID resolve ties", {
  canonical <- eligibility_canonical()
  canonical$terminal_event <- eligibility_events(
    c("readmission-z", "death-a", "readmission-a", "later-death"),
    rep("episode-1", 4),
    c("readmission", "death", "readmission", "death"),
    c("2026-01-06", "2026-01-06", "2026-01-06", "2026-01-08"),
    rep("2026-01-09", 4)
  )

  selected <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-10")
  )
  expect_identical(selected$disposition, "known_readmission")
  expect_identical(selected$terminal_event_id, "readmission-a")
  expect_identical(selected$terminal_event_type, "readmission")

  canonical$terminal_event$occurred_at[2] <- eligibility_time("2026-01-05")
  earliest <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-10")
  )
  expect_identical(earliest$disposition, "known_death")
  expect_identical(earliest$terminal_event_id, "death-a")
})

test_that("closed window takes precedence and leaves event context missing", {
  canonical <- eligibility_canonical()
  canonical$terminal_event <- eligibility_events(
    "event-1", "episode-1", "readmission", "2026-01-05", "2026-01-05"
  )
  endpoint <- canonical$discharge_episode$discharge_time + 30 * 86400

  result <- readmit:::rrp_evaluate_eligibility(canonical, endpoint)

  expect_identical(result$disposition, "window_closed")
  expect_true(is.na(result$terminal_event_id))
  expect_true(is.na(result$terminal_occurred_at))
  expect_identical(attr(result$terminal_available_at, "tzone"), "UTC")
})

test_that("episode order, associations, and typed empty output are stable", {
  canonical <- eligibility_canonical()
  second <- canonical$discharge_episode
  second$episode_id <- "episode-2"
  second$index_encounter_id <- "encounter-2"
  third <- second
  third$episode_id <- "episode-3"
  third$patient_id <- "patient-2"
  third$index_encounter_id <- "encounter-3"
  canonical$discharge_episode <- rbind(third, canonical$discharge_episode, second)
  canonical$terminal_event <- eligibility_events(
    c("event-2", "event-1"), c("episode-2", "episode-1"),
    c("death", "readmission"), c("2026-01-05", "2026-01-04"),
    c("2026-01-05", "2026-01-04")
  )

  result <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-06")
  )
  expect_identical(result$episode_id,
                   c("episode-3", "episode-1", "episode-2"))
  expect_identical(result$patient_id,
                   c("patient-2", "patient-1", "patient-1"))
  expect_identical(result$index_encounter_id,
                   c("encounter-3", "encounter-1", "encounter-2"))
  expect_identical(result$disposition,
                   c("eligible", "known_readmission", "known_death"))
  expect_identical(result$terminal_event_id,
                   c(NA_character_, "event-1", "event-2"))
  expect_identical(result$admission_time,
                   canonical$discharge_episode$admission_time)
  expect_identical(result$discharge_time,
                   canonical$discharge_episode$discharge_time)
  expect_identical(nrow(result), nrow(canonical$discharge_episode))

  canonical$discharge_episode <- canonical$discharge_episode[FALSE, ,
                                                             drop = FALSE]
  canonical$terminal_event <- canonical$terminal_event[FALSE, , drop = FALSE]
  empty <- readmit:::rrp_evaluate_eligibility(
    canonical, eligibility_time("2026-01-06")
  )
  expect_identical(nrow(empty), 0L)
  expect_type(empty$disposition, "character")
  expect_s3_class(empty$followup_window_end, "POSIXct")
  expect_s3_class(empty$terminal_occurred_at, "POSIXct")
  expect_identical(attr(empty$terminal_occurred_at, "tzone"), "UTC")
})
