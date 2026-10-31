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

  # A later snapshot makes the current-failure/accepted-history distinction
  # explicit without changing the Stage 3 expectations above.
  expected_files <- c(
    "README.md", "rrp-project.dcf", "rrp-authoring.dcf", "_brand.yml",
    "assets/project-logo.png", "R/produce-canonical.R", "R/calculate-risk.R",
    "app/app.R", "app/www/rrp.css"
  )
  stopifnot(all(file.exists(file.path(project, expected_files))))
  writeLines(source_lines, source_script)
  provider_lines_4 <- c(
    provider_lines[1:5],
    "  if (request$episode_id == 'episode-1')",
    "    return(list(failure = 'Current predictor unavailable'))",
    "  if (request$episode_id == 'episode-2')",
    "    return(list(probability = 0.4))",
    provider_lines[8:13]
  )
  writeLines(provider_lines_4, provider_script)
  stopifnot(isTRUE(rrp_project_validate(project)))
  time_4 <- stage3_time("2026-01-14 12:00:00.125")
  extra <- episodes[1L, , drop = FALSE]
  extra$episode_id <- "episode-8"
  extra$patient_id <- "patient-8"
  extra$index_encounter_id <- "encounter-8"
  saveRDS(list(discharge_episode = rbind(episodes, extra),
               terminal_event = events), file.path(project, "canonical.rds"))
  run_4 <- rrp_run(project, time_4)
  saveRDS(canonical, file.path(project, "canonical.rds"))
  time_5 <- stage3_time("2026-01-15 12:00:00.125")
  run_5 <- rrp_run(project, time_5)
  stopifnot(identical(unlist(run_4[c("episodes_processed", "accepted",
                                     "provider_failures", "ineligible")],
                              use.names = FALSE), c(8L, 2L, 3L, 3L)),
            identical(unlist(run_5[c("episodes_processed", "accepted",
                                     "provider_failures", "ineligible")],
                              use.names = FALSE), c(7L, 1L, 3L, 3L)),
            identical(rrp_inspect_history(project, run_id = run_4$run_id)$
                        disposition[8], "accepted"))
  current_history <- rrp_inspect_history(project)
  current_run <- rrp_inspect_history(project, run_id = run_5$run_id)
  stopifnot(identical(rrp_project_status(project)$run_count, 5L),
            nrow(current_history) == 36L,
            identical(rrp_inspect_history(project, run_id = run_1$run_id),
                      early),
            identical(rrp_inspect_history(project, run_id = run_2$run_id),
                      late),
            identical(rrp_inspect_history(project, run_id = run_3$run_id),
                      repeat_late),
            identical(current_run$disposition, c(
              "provider_failure", "accepted", "provider_failure",
              "provider_failure", "known_readmission", "known_death",
              "window_closed"
            )),
            is.na(current_run$probability[1]),
            identical(current_run$probability[2], 0.4),
            identical(early$probability[1], 0.25),
            identical(late$probability[1], 0.25),
            identical(repeat_late$probability[1], 0.25))

  owned_files <- file.path(project, expected_files)
  owned_before <- tools::md5sum(owned_files)
  source_before <- readRDS(file.path(project, "source-times.rds"))
  requests_before <- readRDS(file.path(project, "provider-requests.rds"))
  refresh <- rrp_refresh_products(project)
  product_names <- c(
    current_risk = "current-remaining-risk.csv",
    trajectory = "remaining-risk-trajectory.csv",
    scope = "operational-scope-summary.csv"
  )
  stopifnot(identical(refresh$selected_run_id, run_5$run_id),
            identical(refresh$as_of_time, time_5),
            identical(names(refresh$files), names(product_names)),
            identical(unname(refresh$files),
                      file.path(root, "state", "products",
                                unname(product_names))),
            all(file.exists(refresh$files)),
            identical(rrp_project_status(project)$run_count, 5L),
            identical(rrp_inspect_history(project), current_history),
            identical(readRDS(file.path(project, "source-times.rds")),
                      source_before),
            identical(readRDS(file.path(project, "provider-requests.rds")),
                      requests_before),
            identical(tools::md5sum(owned_files), owned_before))

  # A completed empty run writes headers and a zero-count scope; no run fails.
  zero_project <- tempfile("readmit-stage4-zero-")
  on.exit(unlink(zero_project, recursive = TRUE), add = TRUE)
  rrp_project_init(zero_project, "stage4-zero")
  writeLines(c(
    "rrp_produce_canonical <- function(project_root, as_of_time) list(",
    "  discharge_episode = data.frame(",
    "    episode_id = character(), patient_id = character(),",
    "    index_encounter_id = character(),",
    "    admission_time = as.POSIXct(character(), tz = 'UTC'),",
    "    discharge_time = as.POSIXct(character(), tz = 'UTC')),",
    "  terminal_event = data.frame(",
    "    terminal_event_id = character(), episode_id = character(),",
    "    event_type = character(),",
    "    occurred_at = as.POSIXct(character(), tz = 'UTC'),",
    "    available_at = as.POSIXct(character(), tz = 'UTC'))",
    ")"
  ), file.path(zero_project, "R", "produce-canonical.R"))
  writeLines(
    "rrp_calculate_risk <- function(project_root, request) list(probability = 0.5)",
    file.path(zero_project, "R", "calculate-risk.R")
  )
  stopifnot(isTRUE(rrp_project_validate(zero_project)))
  rrp_state_init(zero_project)
  stage3_expect_error(rrp_refresh_products(zero_project),
                      "no completed runs")
  zero_time <- stage3_time("2026-01-16 12:00:00.125")
  zero_run <- rrp_run(zero_project, zero_time)
  stopifnot(identical(zero_run$episodes_processed, 0L),
            identical(rrp_project_status(zero_project)$run_count, 1L),
            nrow(rrp_inspect_history(zero_project)) == 0L)
  zero_refresh <- rrp_refresh_products(zero_project)
  stopifnot(identical(zero_refresh$selected_run_id, zero_run$run_id),
            identical(zero_refresh$as_of_time, zero_time),
            all(file.exists(zero_refresh$files)),
            identical(rrp_project_status(zero_project)$run_count, 1L))

  # Read actual CSV bytes in a fresh R process using base R alone.
  saveRDS(list(run_1 = run_1, run_2 = run_2, run_3 = run_3,
               run_4 = run_4, run_5 = run_5, zero_run = zero_run),
          file.path(project, "product-expected.rds"))
  csv_child <- tempfile("readmit-stage4-csv-", fileext = ".R")
  on.exit(unlink(csv_child), add = TRUE)
  writeLines(c(
    "args <- commandArgs(trailingOnly = TRUE)",
    "project <- args[[1L]]; zero_project <- args[[2L]]",
    "expected <- readRDS(file.path(project, 'product-expected.rds'))",
    "read_product <- function(root, name) read.csv(",
    "  file.path(root, 'state', 'products', name),",
    "  check.names = FALSE, stringsAsFactors = FALSE, na.strings = '')",
    "current <- read_product(project, 'current-remaining-risk.csv')",
    "trajectory <- read_product(project, 'remaining-risk-trajectory.csv')",
    "scope <- read_product(project, 'operational-scope-summary.csv')",
    "stopifnot(identical(names(current), c(",
    "  'selected_run_id', 'as_of_time', 'episode_id', 'discharge_time',",
    "  'followup_window_end', 'disposition', 'probability')),",
    "  identical(names(trajectory), c(",
    "    'selected_run_id', 'run_id', 'as_of_time', 'created_at',",
    "    'episode_id', 'probability')),",
    "  identical(names(scope), c(",
    "    'selected_run_id', 'project_id', 'as_of_time', 'created_at',",
    "    'episodes_assessed', 'eligible_count', 'accepted_count',",
    "    'provider_failure_count', 'ineligible_count', 'window_closed_count',",
    "    'known_readmission_count', 'known_death_count')))",
    "selected <- expected$run_5$run_id",
    "stopifnot(identical(current$episode_id, paste0('episode-', 1:4)),",
    "  !anyDuplicated(current$episode_id),",
    "  identical(current$disposition, c(",
    "    'provider_failure', 'accepted', 'provider_failure',",
    "    'provider_failure')),",
    "  identical(current$probability, c(NA_real_, 0.4, NA_real_, NA_real_)),",
    "  all(current$selected_run_id == selected),",
    "  all(current$as_of_time == '2026-01-15T12:00:00.125000Z'),",
    "  identical(as.numeric(as.POSIXct(current$as_of_time,",
    "    format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')),",
    "    rep(as.numeric(expected$run_5$as_of_time), 4L)))",
    "stopifnot(identical(trajectory$episode_id, c(",
    "  rep('episode-1', 3L), rep('episode-2', 2L))),",
    "  identical(trajectory$run_id, c(expected$run_1$run_id,",
    "    expected$run_2$run_id, expected$run_3$run_id,",
    "    expected$run_4$run_id, selected)),",
    "  identical(trajectory$probability, c(0.25, 0.25, 0.25, 0.4, 0.4)),",
    "  all(trajectory$selected_run_id == selected),",
    "  identical(trajectory$as_of_time, c(",
    "    '2026-01-10T12:00:00.125000Z',",
    "    '2026-01-13T12:00:00.125000Z',",
    "    '2026-01-13T12:00:00.125000Z',",
    "    '2026-01-14T12:00:00.125000Z',",
    "    '2026-01-15T12:00:00.125000Z')),",
    "  all(as.POSIXct(trajectory$as_of_time,",
    "    format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC') <=",
    "    expected$run_5$as_of_time),",
    "  all(trajectory$episode_id %in% current$episode_id),",
    "  !any(trajectory$episode_id %in% paste0('episode-', 5:8)),",
    "  !any(trajectory$run_id[trajectory$episode_id == 'episode-1'] == selected),",
    "  all(nzchar(trajectory$created_at)))",
    "counts <- c(episodes_assessed = 7L, eligible_count = 4L,",
    "  accepted_count = 1L, provider_failure_count = 3L,",
    "  ineligible_count = 3L, window_closed_count = 1L,",
    "  known_readmission_count = 1L, known_death_count = 1L)",
    "stopifnot(nrow(scope) == 1L,",
    "  identical(scope$selected_run_id, selected),",
    "  identical(scope$project_id, 'stage3-acceptance'),",
    "  identical(scope$as_of_time, '2026-01-15T12:00:00.125000Z'),",
    "  all(vapply(scope[names(counts)], is.integer, logical(1L))),",
    "  identical(unlist(scope[names(counts)], use.names = TRUE), counts),",
    "  scope$eligible_count == nrow(current),",
    "  scope$eligible_count + scope$ineligible_count == scope$episodes_assessed,",
    "  scope$accepted_count + scope$provider_failure_count ==",
    "    scope$eligible_count,",
    "  scope$window_closed_count + scope$known_readmission_count +",
    "    scope$known_death_count == scope$ineligible_count,",
    "  nzchar(scope$created_at))",
    "zero_current <- read_product(zero_project, 'current-remaining-risk.csv')",
    "zero_trajectory <- read_product(zero_project, 'remaining-risk-trajectory.csv')",
    "zero_scope <- read_product(zero_project, 'operational-scope-summary.csv')",
    "stopifnot(identical(names(zero_current), names(current)),",
    "  identical(names(zero_trajectory), names(trajectory)),",
    "  identical(names(zero_scope), names(scope)),",
    "  nrow(zero_current) == 0L, nrow(zero_trajectory) == 0L,",
    "  nrow(zero_scope) == 1L,",
    "  identical(zero_scope$selected_run_id, expected$zero_run$run_id),",
    "  identical(zero_scope$project_id, 'stage4-zero'),",
    "  identical(zero_scope$as_of_time, '2026-01-16T12:00:00.125000Z'),",
    "  all(vapply(zero_scope[names(counts)], is.integer, logical(1L))),",
    "  all(unlist(zero_scope[names(counts)], use.names = FALSE) == 0L))",
    "cat('Fresh-process CSV inspection passed.\\n')"
  ), csv_child)
  csv_output <- suppressWarnings(system2(
    rscript, c("--vanilla", shQuote(csv_child), shQuote(project),
               shQuote(zero_project)), stdout = TRUE, stderr = TRUE
  ))
  if (!is.null(attr(csv_output, "status")) && attr(csv_output, "status") != 0L) {
    stop(paste(csv_output, collapse = "\n"))
  }
  stopifnot(any(grepl("Fresh-process CSV inspection passed", csv_output,
                     fixed = TRUE)))
  cat("Stage 4 installed-package acceptance workflow passed.\n")
}

stage3_workflow()
