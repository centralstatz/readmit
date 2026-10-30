refresh_test_time <- function(value) as.POSIXct(value, tz = "UTC")

refresh_test_project <- function(state = TRUE) {
  project <- tempfile("rrp-refresh-")
  rrp_project_init(project, "refresh-test")
  if (state) rrp_state_init(project)
  project
}

refresh_test_write <- function(project, run_id, as_of_time, created_at,
                               outcomes = character(), probabilities = numeric()) {
  ids <- if (length(outcomes)) names(outcomes) else character()
  n <- length(outcomes)
  discharge <- rep(refresh_test_time("2026-01-01 00:00:00.125"), n)
  discharge[outcomes == "window_closed"] <-
    refresh_test_time("2025-11-01 00:00:00.125")
  risk <- rep(NA_real_, n)
  risk[outcomes == "accepted"] <-
    unname(probabilities[ids[outcomes == "accepted"]])
  failure_kind <- rep(NA_character_, n)
  failure_reason <- rep(NA_character_, n)
  failure_kind[outcomes == "provider_failure"] <- "reported"
  failure_reason[outcomes == "provider_failure"] <- "No estimate"
  event_id <- rep(NA_character_, n)
  event_type <- rep(NA_character_, n)
  known <- outcomes %in% c("known_readmission", "known_death")
  event_id[known] <- paste0("event-", ids[known])
  event_type[outcomes == "known_readmission"] <- "readmission"
  event_type[outcomes == "known_death"] <- "death"
  event_time <- as.POSIXct(rep(NA_real_, n),
                           origin = "1970-01-01", tz = "UTC")
  event_time[known] <- refresh_test_time("2026-01-05 00:00:00.5")
  assessments <- data.frame(
    episode_id = ids, patient_id = ids, index_encounter_id = ids,
    admission_time = discharge - 3600, discharge_time = discharge,
    followup_window_end = discharge + 30 * 24 * 60 * 60,
    disposition = unname(outcomes), probability = risk,
    failure_kind = failure_kind, failure_reason = failure_reason,
    terminal_event_id = event_id, terminal_event_type = event_type,
    terminal_occurred_at = event_time, terminal_available_at = event_time
  )
  readmit:::rrp_write_history(project, list(
    run_id = run_id, project_id = "refresh-test",
    as_of_time = refresh_test_time(as_of_time),
    created_at = refresh_test_time(created_at),
    source_mapping_script = "R/produce-canonical.R",
    risk_provider_script = "R/calculate-risk.R"
  ), assessments)
}

refresh_test_files <- function(project) {
  file.path(normalizePath(project, winslash = "/"), "state", "products", c(
    "current-remaining-risk.csv", "remaining-risk-trajectory.csv",
    "operational-scope-summary.csv"
  ))
}

test_that("refresh writes three readable products and preserves other resources", {
  expect_true("rrp_refresh_products" %in% getNamespaceExports("readmit"))
  expect_identical(names(formals(rrp_refresh_products)), "path")
  project <- refresh_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  refresh_test_write(project, "old", "2026-01-10 00:00:00.125",
                     "2026-01-10 01:00:00.375",
                     c(a = "accepted", b = "accepted", c = "accepted"),
                     c(a = 0.20, b = 0.24, c = 0.40))
  refresh_test_write(project, "current", "2026-01-20 00:00:00.125",
                     "2026-01-20 01:00:00.375",
                     c(a = "accepted", b = "provider_failure",
                       c = "known_readmission", d = "window_closed"),
                     c(a = 0.31))
  before_runs <- readmit:::rrp_read_runs(project)
  before_history <- readmit:::rrp_read_assessments(project)
  app <- file.path(project, "app", "app.R")
  css <- file.path(project, "app", "www", "rrp.css")
  brand <- file.path(project, "_brand.yml")
  owner_files <- lapply(c(app, css, brand), readLines, warn = FALSE)
  source_script <- file.path(project, "R", "produce-canonical.R")
  provider_script <- file.path(project, "R", "calculate-risk.R")
  writeLines("stop('Source script was sourced')", source_script)
  writeLines("stop('Provider script was sourced')", provider_script)

  result <- rrp_refresh_products(project)
  files <- refresh_test_files(project)
  expect_identical(names(result), c("selected_run_id", "as_of_time", "files"))
  expect_identical(result$selected_run_id, "current")
  expect_identical(result$as_of_time,
                   refresh_test_time("2026-01-20 00:00:00.125"))
  expect_identical(unname(result$files), files)
  expect_setequal(list.files(file.path(project, "state", "products")),
                  basename(files))
  expect_true(all(file.exists(files)))
  expect_true(all(vapply(files, function(file) {
    identical(readLines(file, n = 1L, warn = FALSE),
              paste0('"', paste(names(utils::read.csv(file, nrows = 0L)),
                                collapse = '\",\"'), '"'))
  }, logical(1L))))

  current <- utils::read.csv(files[[1L]], na.strings = "",
                             stringsAsFactors = FALSE)
  trajectory <- utils::read.csv(files[[2L]], stringsAsFactors = FALSE)
  scope <- utils::read.csv(files[[3L]], stringsAsFactors = FALSE)
  expect_identical(names(current), names(readmit:::rrp_calculate_products(
    project)$current_risk))
  expect_identical(names(trajectory), names(readmit:::rrp_calculate_products(
    project)$trajectory))
  expect_identical(names(scope), names(readmit:::rrp_calculate_products(
    project)$scope))
  expect_identical(current$episode_id, c("a", "b"))
  expect_identical(current$disposition, c("accepted", "provider_failure"))
  expect_identical(current$probability[1L], 0.31)
  expect_true(is.na(current$probability[2L]))
  expect_type(current$probability, "double")
  expect_match(readLines(files[[1L]], warn = FALSE)[3L], ",$")
  expect_false(any(grepl('"NA"|,NA$', readLines(files[[1L]], warn = FALSE))))
  expect_identical(trajectory$episode_id, c("a", "a", "b"))
  expect_identical(trajectory$run_id, c("old", "current", "old"))
  expect_identical(trajectory$probability, c(0.20, 0.31, 0.24))
  expect_identical(scope$selected_run_id, "current")
  expect_identical(unname(unlist(scope[1L, 5:12])),
                   c(4L, 2L, 1L, 1L, 2L, 1L, 1L, 0L))
  expect_true(all(vapply(scope[5:12], is.integer, logical(1L))))
  expect_identical(nrow(current), scope$eligible_count)
  expect_true(all(grepl("^2026-01-20T00:00:00\\.125000Z$",
                        current$as_of_time)))
  parsed <- as.POSIXct(current$as_of_time,
                       format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  expect_identical(as.numeric(parsed),
                   rep(as.numeric(result$as_of_time), nrow(current)))
  expect_true(all(grepl("[.]\\d{6}Z$", trajectory$created_at)))
  expect_identical(readmit:::rrp_read_runs(project), before_runs)
  expect_identical(readmit:::rrp_read_assessments(project), before_history)
  expect_identical(lapply(c(app, css, brand), readLines, warn = FALSE),
                   owner_files)
  expect_identical(readLines(source_script), "stop('Source script was sourced')")
  expect_identical(readLines(provider_script),
                   "stop('Provider script was sourced')")
  expect_identical(list.files(file.path(project, "state")),
                   c("history.duckdb", "products"))

  first_content <- lapply(files, readLines, warn = FALSE)
  rrp_refresh_products(project)
  expect_identical(lapply(files, readLines, warn = FALSE), first_content)
  refresh_test_write(project, "backfill", "2026-01-15 00:00:00.125",
                     "2026-01-30 01:00:00.375", c(b = "accepted"),
                     c(b = 0.25))
  rrp_refresh_products(project)
  expect_identical(utils::read.csv(files[[1L]])$selected_run_id,
                   rep("current", 2L))
  expect_identical(utils::read.csv(files[[2L]])$run_id,
                   c("old", "current", "old", "backfill"))
  refresh_test_write(project, "later", "2026-01-21 00:00:00.125",
                     "2026-01-21 01:00:00.375",
                     c(a = "provider_failure", b = "provider_failure"))
  rrp_refresh_products(project)
  failed <- utils::read.csv(files[[1L]], na.strings = "")
  expect_identical(failed$selected_run_id, rep("later", 2L))
  expect_true(all(is.na(failed$probability)))
  expect_identical(nrow(failed), 2L)
  expect_identical(utils::read.csv(files[[3L]])$provider_failure_count, 2L)
})

test_that("no run fails while zero and ineligible runs publish empty episode files", {
  uninitialized <- refresh_test_project(state = FALSE)
  on.exit(unlink(uninitialized, recursive = TRUE), add = TRUE)
  expect_error(rrp_refresh_products(uninitialized), "not initialized")
  expect_false(dir.exists(file.path(uninitialized, "state")))

  project <- refresh_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  expect_error(rrp_refresh_products(project), "no completed runs")
  expect_false(dir.exists(file.path(project, "state", "products")))
  refresh_test_write(project, "empty", "2026-01-20 00:00:00.125",
                     "2026-01-20 01:00:00.375")
  rrp_refresh_products(project)
  files <- refresh_test_files(project)
  expect_identical(nrow(utils::read.csv(files[[1L]])), 0L)
  expect_identical(nrow(utils::read.csv(files[[2L]])), 0L)
  expect_identical(length(names(utils::read.csv(files[[1L]]))), 7L)
  expect_identical(length(names(utils::read.csv(files[[2L]]))), 6L)
  expect_identical(unname(unlist(utils::read.csv(files[[3L]])[1L, 5:12])),
                   rep(0L, 8L))
  refresh_test_write(project, "ineligible", "2026-01-21 00:00:00.125",
                     "2026-01-21 01:00:00.375",
                     c(a = "known_readmission", b = "known_death",
                       c = "window_closed"))
  rrp_refresh_products(project)
  expect_identical(nrow(utils::read.csv(files[[1L]])), 0L)
  expect_identical(nrow(utils::read.csv(files[[2L]])), 0L)
  scope <- utils::read.csv(files[[3L]])
  expect_identical(scope$selected_run_id, "ineligible")
  expect_identical(scope$episodes_assessed, 3L)
  expect_identical(scope$eligible_count, 0L)
  expect_identical(scope$ineligible_count, 3L)
})

test_that("CSV identifiers round trip through UTF-8", {
  project <- refresh_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  episode_id <- paste0("episode-", intToUtf8(233L))
  refresh_test_write(project, "unicode", "2026-01-20 00:00:00.125",
                     "2026-01-20 01:00:00.375",
                     stats::setNames("accepted", episode_id),
                     stats::setNames(0.42, episode_id))
  rrp_refresh_products(project)
  current <- utils::read.csv(refresh_test_files(project)[[1L]],
                             fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  expect_identical(enc2utf8(current$episode_id), enc2utf8(episode_id))
  expect_identical(current$probability, 0.42)
})

test_that("pre-replacement failures preserve existing product files", {
  project <- refresh_test_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  refresh_test_write(project, "good", "2026-01-20 00:00:00.125",
                     "2026-01-20 01:00:00.375",
                     c(a = "accepted", b = "provider_failure"),
                     c(a = 0.31))
  rrp_refresh_products(project)
  files <- refresh_test_files(project)
  baseline <- lapply(files, readLines, warn = FALSE)

  testthat::with_mocked_bindings(
    expect_error(rrp_refresh_products(project), "calculation failed"),
    rrp_calculate_products = function(path) stop("calculation failed"),
    .package = "readmit"
  )
  expect_identical(lapply(files, readLines, warn = FALSE), baseline)

  invalid <- readmit:::rrp_calculate_products(project)
  invalid$current_risk$probability[2L] <- 0
  testthat::with_mocked_bindings(
    expect_error(rrp_refresh_products(project), "products are invalid"),
    rrp_calculate_products = function(path) invalid,
    .package = "readmit"
  )
  expect_identical(lapply(files, readLines, warn = FALSE), baseline)

  testthat::with_mocked_bindings(
    expect_error(rrp_refresh_products(project)),
    rrp_product_csv_data = function(data) {
      data$unexpected <- rep("extra", nrow(data))
      data
    },
    .package = "readmit"
  )
  expect_identical(lapply(files, readLines, warn = FALSE), baseline)
  expect_false(any(grepl("^products-stage-",
                         list.files(file.path(project, "state")))))
})
