# Exercise the public Stage 3 workflow as a user of an installed package.
# R CMD check runs this file against its installed build; it also runs directly
# with R_LIBS set to a separate temporary library containing a built package.
library(readmit)

stage3_time <- function(value) as.POSIXct(value, tz = "UTC")

stage3_expect_error <- function(expression, pattern) {
  error <- tryCatch({
    force(expression)
    NULL
  }, error = identity)
  stopifnot(inherits(error, "error"),
            grepl(pattern, conditionMessage(error), fixed = TRUE))
}

stage3_workflow <- function() {
  project <- tempfile("readmit-stage3-project-")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  root <- rrp_project_init(project, "stage3-acceptance")
  stopifnot(identical(root, normalizePath(project, winslash = "/")))

  discharge <- stage3_time("2026-01-02 01:00:00.125")
  episodes <- data.frame(
    episode_id = paste0("episode-", 1:7),
    patient_id = paste0("patient-", 1:7),
    index_encounter_id = paste0("encounter-", 1:7),
    admission_time = rep(stage3_time("2026-01-01 01:00:00.125"), 7),
    discharge_time = rep(discharge, 7)
  )
  episodes$admission_time[7] <- stage3_time("2025-11-30 01:00:00.125")
  episodes$discharge_time[7] <- stage3_time("2025-12-01 01:00:00.125")
  events <- data.frame(
    terminal_event_id = c("event-delayed", "event-death"),
    episode_id = c("episode-5", "episode-6"),
    event_type = c("readmission", "death"),
    occurred_at = rep(stage3_time("2026-01-05 08:00:00.5"), 2),
    available_at = c(stage3_time("2026-01-12 09:00:00.25"),
                     stage3_time("2026-01-06 09:00:00.25"))
  )
  canonical <- list(discharge_episode = episodes, terminal_event = events)
  saveRDS(canonical, file.path(project, "canonical.rds"))

  source_script <- file.path(project, "R", "produce-canonical.R")
  provider_script <- file.path(project, "R", "calculate-risk.R")
  source_lines <- c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  log <- file.path(project_root, 'source-times.rds')",
    "  times <- if (file.exists(log)) readRDS(log) else list()",
    "  times[[length(times) + 1L]] <- as_of_time",
    "  saveRDS(times, log)",
    "  readRDS(file.path(project_root, 'canonical.rds'))",
    "}"
  )
  provider_lines <- c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  log <- file.path(project_root, 'provider-requests.rds')",
    "  requests <- if (file.exists(log)) readRDS(log) else list()",
    "  requests[[length(requests) + 1L]] <- request",
    "  saveRDS(requests, log)",
    "  if (request$episode_id == 'episode-2')",
    "    return(list(failure = 'Predictor unavailable'))",
    "  if (request$episode_id == 'episode-3')",
    "    return(list(probability = NA_real_))",
    "  if (request$episode_id == 'episode-4') stop('Model input unavailable')",
    "  list(probability = 0.25)",
    "}"
  )
  writeLines(source_lines, source_script)
  writeLines(provider_lines, provider_script)

  stopifnot(isTRUE(rrp_project_validate(project)))
  before <- rrp_project_status(project)
  stopifnot(identical(before$project_id, "stage3-acceptance"),
            identical(before$state_initialized, FALSE),
            identical(before$run_count, 0L),
            !dir.exists(file.path(project, "state")))
  stage3_expect_error(
    rrp_run(project, stage3_time("2026-01-10 12:00:00.125")),
    "rrp_state_init"
  )
  stopifnot(!dir.exists(file.path(project, "state")))
  rrp_state_init(project)
  empty_status <- rrp_project_status(project)
  empty_history <- rrp_inspect_history(project)
  stopifnot(identical(empty_status$state_initialized, TRUE),
            identical(empty_status$run_count, 0L),
            is.data.frame(empty_history), nrow(empty_history) == 0L,
            inherits(empty_history$as_of_time, "POSIXct"))

  time_1 <- stage3_time("2026-01-10 12:00:00.125")
  time_2 <- stage3_time("2026-01-13 12:00:00.125")
  run_1 <- rrp_run(project, time_1)
  Sys.sleep(0.02)
  run_2 <- rrp_run(project, time_2)
  Sys.sleep(0.02)
  run_3 <- rrp_run(project, time_2)
  expected_counts <- list(
    c(7L, 2L, 3L, 2L),
    c(7L, 1L, 3L, 3L),
    c(7L, 1L, 3L, 3L)
  )
  for (i in seq_along(expected_counts)) {
    run <- list(run_1, run_2, run_3)[[i]]
    actual <- unlist(run[c("episodes_processed", "accepted",
                           "provider_failures", "ineligible")],
                     use.names = FALSE)
    stopifnot(identical(actual, expected_counts[[i]]),
              identical(run$episodes_processed,
                        run$accepted + run$provider_failures + run$ineligible),
              is.character(run$run_id), length(run$run_id) == 1L,
              nzchar(run$run_id),
              identical(run$as_of_time, if (i == 1L) time_1 else time_2))
  }
  ids <- c(run_1$run_id, run_2$run_id, run_3$run_id)
  stopifnot(length(unique(ids)) == 3L)

  source_times <- readRDS(file.path(project, "source-times.rds"))
  stopifnot(identical(vapply(source_times, as.numeric, numeric(1)),
                      as.numeric(c(time_1, time_2, time_2))))
  requests <- readRDS(file.path(project, "provider-requests.rds"))
  requested_ids <- vapply(requests, `[[`, character(1), "episode_id")
  stopifnot(identical(requested_ids, c(
    paste0("episode-", 1:5),
    paste0("episode-", 1:4),
    paste0("episode-", 1:4)
  )))
  request_fields <- c(
    "episode_id", "patient_id", "index_encounter_id", "admission_time",
    "discharge_time", "as_of_time", "followup_window_end",
    "remaining_seconds"
  )
  for (i in seq_along(requests)) {
    request <- requests[[i]]
    episode <- episodes[match(request$episode_id, episodes$episode_id), ]
    expected_time <- if (i <= 5L) time_1 else time_2
    stopifnot(
      identical(names(request), request_fields),
      identical(request$patient_id, episode$patient_id),
      identical(request$index_encounter_id, episode$index_encounter_id),
      identical(request$admission_time, episode$admission_time),
      identical(request$discharge_time, episode$discharge_time),
      identical(request$as_of_time, expected_time),
      identical(as.numeric(request$followup_window_end),
                as.numeric(episode$discharge_time + 30 * 24 * 60 * 60)),
      identical(request$remaining_seconds,
                as.numeric(difftime(request$followup_window_end,
                                    expected_time, units = "secs"))),
      request$remaining_seconds > 0
    )
  }

  status <- rrp_project_status(project)
  history <- rrp_inspect_history(project)
  early <- rrp_inspect_history(project, run_id = run_1$run_id)
  late <- rrp_inspect_history(project, run_id = run_2$run_id)
  repeat_late <- rrp_inspect_history(project, run_id = run_3$run_id)
  stopifnot(identical(status$run_count, 3L),
            identical(status$latest_run_id, run_3$run_id),
            identical(as.numeric(status$latest_as_of_time),
                      as.numeric(time_2)),
            nrow(history) == 21L, nrow(early) == 7L,
            nrow(late) == 7L, nrow(repeat_late) == 7L,
            identical(nrow(rrp_inspect_history(project,
                                               episode_id = "episode-5")), 3L),
            identical(nrow(rrp_inspect_history(project,
                                               run_id = run_1$run_id,
                                               episode_id = "episode-5")), 1L))
  stopifnot(identical(early$disposition, c(
    "accepted", "provider_failure", "provider_failure",
    "provider_failure", "accepted", "known_death", "window_closed"
  )), identical(late$disposition, c(
    "accepted", "provider_failure", "provider_failure",
    "provider_failure", "known_readmission", "known_death", "window_closed"
  )), identical(repeat_late$disposition, late$disposition))
  stopifnot(identical(early$probability[c(1, 5)], c(0.25, 0.25)),
            identical(late$probability[1], 0.25),
            all(is.na(early$probability[c(2:4, 6:7)])),
            identical(early$failure_kind[2:4],
                      c("reported", "unusable_result", "error")),
            grepl("Predictor unavailable", early$failure_reason[2],
                  fixed = TRUE),
            grepl("Model input unavailable", early$failure_reason[4],
                  fixed = TRUE),
            is.na(early$terminal_event_id[5]),
            identical(late$terminal_event_id[5], "event-delayed"),
            identical(late$terminal_event_type[5], "readmission"),
            identical(late$terminal_event_id[6], "event-death"),
            identical(late$terminal_event_type[6], "death"),
            all(is.na(late$probability[5:7])))
  stopifnot(identical(as.numeric(early$as_of_time),
                      rep(as.numeric(time_1), 7)),
            identical(as.numeric(late$as_of_time),
                      rep(as.numeric(time_2), 7)),
            identical(attr(history$as_of_time, "tzone"), "UTC"),
            identical(as.numeric(early$admission_time[1]),
                      as.numeric(episodes$admission_time[1])),
            identical(as.numeric(early$discharge_time[1]),
                      as.numeric(discharge)),
            identical(as.numeric(early$followup_window_end[1]),
                      as.numeric(discharge + 30 * 24 * 60 * 60)),
            identical(as.numeric(late$terminal_occurred_at[5]),
                      as.numeric(events$occurred_at[1])),
            identical(as.numeric(late$terminal_available_at[5]),
                      as.numeric(events$available_at[1])),
            is.na(early$terminal_occurred_at[5]),
            is.na(early$terminal_available_at[5]))

  # Source failures are run-fatal; provider failures above remained in runs.
  writeLines("rrp_produce_canonical <- function(project_root, as_of_time) stop('Source unavailable')",
             source_script)
  stage3_expect_error(rrp_run(project, time_1), "Canonical source production failed")
  stopifnot(identical(rrp_project_status(project)$run_count, 3L))
  writeLines(source_lines, source_script)
  saveRDS(list(discharge_episode = episodes), file.path(project, "canonical.rds"))
  stage3_expect_error(rrp_run(project, time_1), "Canonical source")
  stopifnot(identical(rrp_project_status(project)$run_count, 3L))
  saveRDS(canonical, file.path(project, "canonical.rds"))
  stopifnot(identical(rrp_inspect_history(project), history),
            !dir.exists(file.path(project, "state", "products")))

  # Fresh process: scripts now fail even when sourced, yet inspection succeeds.
  writeLines("stop('source script was sourced')", source_script)
  writeLines("stop('provider script was sourced')", provider_script)
  saveRDS(list(run_1 = run_1, run_3 = run_3, event = events[1, ]),
          file.path(project, "expected.rds"))
  child <- tempfile("readmit-stage3-fresh-", fileext = ".R")
  on.exit(unlink(child), add = TRUE)
  writeLines(c(
    "args <- commandArgs(trailingOnly = TRUE)",
    ".libPaths(c(args[[2L]], .libPaths()))",
    "library(readmit)",
    "project <- args[[1L]]",
    "expected <- readRDS(file.path(project, 'expected.rds'))",
    "status <- rrp_project_status(project)",
    "early <- rrp_inspect_history(project, run_id = expected$run_1$run_id)",
    "repeat_late <- rrp_inspect_history(project, run_id = expected$run_3$run_id)",
    "stopifnot(identical(status$run_count, 3L),",
    "          identical(status$latest_run_id, expected$run_3$run_id),",
    "          nrow(early) == 7L, nrow(repeat_late) == 7L,",
    "          identical(early$disposition[5], 'accepted'),",
    "          identical(early$probability[5], 0.25),",
    "          identical(repeat_late$disposition[5], 'known_readmission'),",
    "          identical(repeat_late$terminal_event_id[5], 'event-delayed'),",
    "          identical(as.numeric(repeat_late$terminal_occurred_at[5]),",
    "                    as.numeric(expected$event$occurred_at[1])),",
    "          identical(as.numeric(repeat_late$terminal_available_at[5]),",
    "                    as.numeric(expected$event$available_at[1])),",
    "          identical(attr(early$as_of_time, 'tzone'), 'UTC'),",
    "          identical(as.numeric(early$as_of_time[1]),",
    "                    as.numeric(expected$run_1$as_of_time)))",
    "cat('Fresh-session history inspection passed.\\n')"
  ), child)
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") {
    "Rscript.exe"
  } else {
    "Rscript"
  })
  output <- suppressWarnings(system2(
    rscript,
    c("--vanilla", shQuote(child), shQuote(project),
      shQuote(dirname(find.package("readmit")))),
    stdout = TRUE, stderr = TRUE
  ))
  if (!is.null(attr(output, "status")) && attr(output, "status") != 0L) {
    stop(paste(output, collapse = "\n"))
  }
  stopifnot(any(grepl("Fresh-session history inspection passed", output,
                     fixed = TRUE)),
            identical(rrp_project_status(project)$run_count, 3L),
            identical(rrp_inspect_history(project), history),
            length(readRDS(file.path(project, "provider-requests.rds"))) == 13L,
            !dir.exists(file.path(project, "state", "products")))
  cat("Stage 3 installed-package acceptance workflow passed.\n")
}

stage3_workflow()
