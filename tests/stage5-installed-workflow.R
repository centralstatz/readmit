# Exercise the copied project app using only an installed readmit package.
# R CMD check runs this against its installed build. It can also be run with
# R_LIBS pointing to a separate library containing a built source package.
library(readmit)

stage5_time <- function(value) as.POSIXct(value, tz = "UTC")

stage5_app <- function(project) {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(file.path(project, "app"))
  source("app.R", local = TRUE)$value
}

stage5_app_available <- function() {
  all(vapply(c("shiny", "bslib", "reactable", "plotly", "yaml"),
             requireNamespace, logical(1L), quietly = TRUE))
}

stage5_workflow <- function() {
  project <- tempfile("readmit-stage5-project-")
  zero_project <- tempfile("readmit-stage5-zero-")
  on.exit(unlink(c(project, zero_project), recursive = TRUE), add = TRUE)
  root <- rrp_project_init(project, "stage5-acceptance")
  files <- c(
    "rrp-project.dcf", "rrp-authoring.dcf", "README.md", "_brand.yml",
    "assets/project-logo.png", "R/produce-canonical.R", "R/calculate-risk.R",
    "app/app.R", "app/R/read-products.R", "app/www/rrp.css"
  )
  stopifnot(all(file.exists(file.path(root, files))),
            !dir.exists(file.path(root, "state")),
            identical(root, normalizePath(project, winslash = "/")))
  template <- system.file("project-template", package = "readmit")
  copied <- c("app/app.R", "app/R/read-products.R", "app/www/rrp.css",
              "assets/project-logo.png")
  stopifnot(identical(unname(tools::md5sum(file.path(root, copied))),
                      unname(tools::md5sum(file.path(template, copied)))))

  if (stage5_app_available()) {
    app <- stage5_app(root)
    shiny::testServer(app$serverFuncSource(), {
      stopifnot(grepl("No analytical products yet", output$rrp_pool_region$html,
                     fixed = TRUE),
                grepl("Select an episode", output$rrp_episode_detail$html,
                     fixed = TRUE),
                grepl("No analytical products yet",
                      output$rrp_overview_scope$html, fixed = TRUE),
                grepl("No analytical products yet",
                      output$rrp_overview_risk$html, fixed = TRUE))
    })
  }

  episodes <- data.frame(
    episode_id = paste0("episode-", 1:7),
    patient_id = paste0("patient-", 1:7),
    index_encounter_id = paste0("encounter-", 1:7),
    admission_time = rep(stage5_time("2026-01-01 01:00:00.125"), 7L),
    discharge_time = rep(stage5_time("2026-01-02 01:00:00.125"), 7L)
  )
  episodes$admission_time[7L] <- stage5_time("2025-11-30 01:00:00.125")
  episodes$discharge_time[7L] <- stage5_time("2025-12-01 01:00:00.125")
  events <- data.frame(
    terminal_event_id = c("event-readmission", "event-death"),
    episode_id = c("episode-5", "episode-6"),
    event_type = c("readmission", "death"),
    occurred_at = rep(stage5_time("2026-01-05 08:00:00.5"), 2L),
    available_at = c(stage5_time("2026-01-12 09:00:00.25"),
                     stage5_time("2026-01-06 09:00:00.25"))
  )
  saveRDS(list(discharge_episode = episodes, terminal_event = events),
          file.path(root, "canonical.rds"))
  source_script <- file.path(root, "R", "produce-canonical.R")
  provider_script <- file.path(root, "R", "calculate-risk.R")
  source_lines <- c(
    "rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  log <- file.path(project_root, 'source-times.rds')",
    "  times <- if (file.exists(log)) readRDS(log) else list()",
    "  times[[length(times) + 1L]] <- as_of_time",
    "  saveRDS(times, log)",
    "  readRDS(file.path(project_root, 'canonical.rds'))",
    "}"
  )
  writeLines(source_lines, source_script)
  provider_lines <- c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  log <- file.path(project_root, 'provider-requests.rds')",
    "  requests <- if (file.exists(log)) readRDS(log) else list()",
    "  requests[[length(requests) + 1L]] <- request$episode_id",
    "  saveRDS(requests, log)",
    "  current <- request$as_of_time >= as.POSIXct('2026-01-15 12:00:00.125', tz = 'UTC')",
    "  id <- request$episode_id",
    "  if (id == 'episode-1') {",
    "    if (current) return(list(failure = 'Current predictor unavailable'))",
    "    return(list(probability = 0.2))",
    "  }",
    "  if (id == 'episode-2') return(list(probability = if (current) 0 else 0.4))",
    "  if (id == 'episode-3') return(list(probability = 0.8))",
    "  if (id == 'episode-4') return(list(failure = 'No predictor'))",
    "  list(probability = 0.6)",
    "}"
  )
  writeLines(provider_lines, provider_script)
  stopifnot(isTRUE(rrp_project_validate(root)))
  owned_before <- tools::md5sum(file.path(root, files))
  rrp_state_init(root)
  earlier <- stage5_time("2026-01-10 12:00:00.125")
  current <- stage5_time("2026-01-15 12:00:00.125")
  run_1 <- rrp_run(root, earlier)
  Sys.sleep(0.02)
  run_2 <- rrp_run(root, earlier)
  run_3 <- rrp_run(root, current)
  stopifnot(identical(rrp_project_status(root)$run_count, 3L),
            identical(rrp_inspect_history(root, run_id = run_3$run_id)$
                        disposition,
                      c("provider_failure", "accepted", "accepted",
                        "provider_failure", "known_readmission",
                        "known_death", "window_closed")))
  requests_before <- readRDS(file.path(root, "provider-requests.rds"))
  times_before <- readRDS(file.path(root, "source-times.rds"))
  refresh <- rrp_refresh_products(root)
  stopifnot(identical(refresh$selected_run_id, run_3$run_id),
            identical(refresh$as_of_time, current),
            all(file.exists(refresh$files)),
            identical(tools::md5sum(file.path(root, files)), owned_before),
            identical(readRDS(file.path(root, "provider-requests.rds")),
                      requests_before),
            identical(readRDS(file.path(root, "source-times.rds")),
                      times_before))

  product_dir <- file.path(root, "state", "products")
  read_product <- function(filename) utils::read.csv(
    file.path(product_dir, filename), stringsAsFactors = FALSE, na.strings = ""
  )
  current_csv <- read_product("current-remaining-risk.csv")
  trajectory_csv <- read_product("remaining-risk-trajectory.csv")
  scope_csv <- read_product("operational-scope-summary.csv")
  stopifnot(identical(current_csv$episode_id, paste0("episode-", 1:4)),
            identical(current_csv$disposition,
                      c("provider_failure", "accepted", "accepted",
                        "provider_failure")),
            identical(current_csv$probability, c(NA_real_, 0, 0.8, NA_real_)),
            identical(current_csv$as_of_time,
                      rep("2026-01-15T12:00:00.125000Z", 4L)),
            identical(trajectory_csv$episode_id,
                      c(rep("episode-1", 2L), rep("episode-2", 3L),
                        rep("episode-3", 3L))),
            identical(trajectory_csv$probability,
                      c(0.2, 0.2, 0.4, 0.4, 0, 0.8, 0.8, 0.8)),
            identical(trajectory_csv$run_id[1:2],
                      c(run_1$run_id, run_2$run_id)),
            identical(trajectory_csv$as_of_time[1:2],
                      rep("2026-01-10T12:00:00.125000Z", 2L)),
            identical(unlist(scope_csv[1L, 5:12], use.names = FALSE),
                      c(7L, 4L, 2L, 2L, 3L, 1L, 1L, 1L)))

  # If the app sources either analytical script or queries DuckDB, this check
  # fails. The app has only the generated CSV products available here.
  writeLines("stop('source script was sourced')", source_script)
  writeLines("stop('provider script was sourced')", provider_script)
  database <- file.path(root, "state", "history.duckdb")
  saved_database <- paste0(database, ".saved")
  stopifnot(file.rename(database, saved_database))
  if (stage5_app_available()) {
    app <- stage5_app(root)
    shiny::testServer(app$serverFuncSource(), {
      stopifnot(grepl("4 of 4 eligible episodes displayed",
                     output$rrp_pool_count, fixed = TRUE),
                grepl("episode-1", output$rrp_pool_table, fixed = TRUE),
                grepl("episode-4", output$rrp_pool_table, fixed = TRUE),
                grepl("Unavailable", output$rrp_pool_table, fixed = TRUE),
                grepl("0%", output$rrp_pool_table, fixed = TRUE),
                grepl("rrp-sparkline", output$rrp_pool_table, fixed = TRUE),
                grepl("No history", output$rrp_pool_table, fixed = TRUE),
                grepl("Jan 15, 2026", output$rrp_snapshot$html, fixed = TRUE),
                grepl("<strong>7</strong>", output$rrp_overview_scope$html,
                      fixed = TRUE),
                grepl("Provider failures</dt>\\s*<dd>2</dd>",
                      output$rrp_overview_scope$html),
                grepl("2 accepted current estimates among 4 eligible episodes",
                      output$rrp_overview_risk$html, fixed = TRUE),
                grepl("40%", output$rrp_overview_risk$html, fixed = TRUE))
      session$setInputs(rrp_pool_table__reactable__selected = 1L)
      stopifnot(grepl("Provider failure", output$rrp_episode_detail$html,
                     fixed = TRUE),
                grepl("Unavailable", output$rrp_episode_detail$html,
                      fixed = TRUE),
                grepl(run_1$run_id, output$rrp_episode_detail$html,
                      fixed = TRUE),
                grepl(run_2$run_id, output$rrp_episode_detail$html,
                      fixed = TRUE),
                grepl("markers", output$rrp_trajectory_plot, fixed = TRUE))
      session$setInputs(rrp_pool_table__reactable__sorted = list(
        list(id = "probability", desc = TRUE)
      ))
      stopifnot(grepl("episode-1", output$rrp_episode_detail$html,
                     fixed = TRUE))
      session$setInputs(rrp_range = c(0.5, 1))
      stopifnot(grepl("3 of 4 eligible episodes displayed", output$rrp_pool_count,
                     fixed = TRUE),
                grepl("episode-1", output$rrp_episode_detail$html,
                      fixed = TRUE))
      session$setInputs(rrp_search = "episode-2")
      stopifnot(grepl("No episodes match these filters",
                     output$rrp_pool_region$html, fixed = TRUE),
                grepl("Select an episode", output$rrp_episode_detail$html,
                      fixed = TRUE))
      session$setInputs(rrp_search = "", rrp_range = c(0, 1))
      session$setInputs(rrp_pool_table__reactable__selected = 1L)
      session$setInputs(rrp_reload = 1L)
      stopifnot(grepl("episode-1", output$rrp_episode_detail$html,
                     fixed = TRUE))

      trajectory_path <- file.path(product_dir, "remaining-risk-trajectory.csv")
      saved_trajectory <- readLines(trajectory_path, warn = FALSE)
      unlink(trajectory_path)
      session$setInputs(rrp_reload = 2L)
      stopifnot(grepl("History unavailable", output$rrp_episode_detail$html,
                     fixed = TRUE),
                grepl("History unavailable", output$rrp_pool_table,
                      fixed = TRUE))
      writeLines(saved_trajectory, trajectory_path)

      scope_path <- file.path(product_dir, "operational-scope-summary.csv")
      saved_scope <- readLines(scope_path, warn = FALSE)
      bad_scope <- read_product("operational-scope-summary.csv")
      bad_scope$selected_run_id <- "other-run"
      utils::write.csv(bad_scope, scope_path, row.names = FALSE, na = "")
      session$setInputs(rrp_reload = 3L)
      stopifnot(grepl("different analytical snapshot",
                     output$rrp_overview_scope$html, fixed = TRUE),
                grepl("40%", output$rrp_overview_risk$html, fixed = TRUE))
      writeLines(saved_scope, scope_path)
      session$setInputs(rrp_reload = 4L)
      stopifnot(grepl("EPISODES ASSESSED", output$rrp_overview_scope$html,
                     fixed = TRUE))
    })
  }
  stopifnot(!file.exists(database), file.exists(saved_database),
            identical(readRDS(file.path(root, "provider-requests.rds")),
                      requests_before),
            identical(readRDS(file.path(root, "source-times.rds")),
                      times_before),
            file.rename(saved_database, database))

  # A later public assessment can have only failed current predictions while
  # keeping earlier accepted observations for the still eligible episodes.
  writeLines(source_lines, source_script)
  writeLines(c(
    "rrp_calculate_risk <- function(project_root, request) {",
    "  list(failure = 'Current model unavailable')",
    "}"
  ), provider_script)
  owned_before <- tools::md5sum(file.path(root, files))
  failed_run <- rrp_run(root, stage5_time("2026-01-16 12:00:00.125"))
  failed_refresh <- rrp_refresh_products(root)
  stopifnot(identical(failed_run$accepted, 0L),
            identical(failed_run$provider_failures, 4L),
            identical(failed_refresh$selected_run_id, failed_run$run_id),
            identical(tools::md5sum(file.path(root, files)), owned_before))
  if (stage5_app_available()) {
    app <- stage5_app(root)
    shiny::testServer(app$serverFuncSource(), {
      stopifnot(grepl("4 of 4 eligible episodes displayed", output$rrp_pool_count,
                     fixed = TRUE),
                grepl("0 accepted current estimates", output$rrp_overview_risk$html,
                      fixed = TRUE),
                grepl("Provider failures</dt>\\s*<dd>4</dd>",
                      output$rrp_overview_scope$html))
      session$setInputs(rrp_pool_table__reactable__selected = 1L)
      stopifnot(grepl("Unavailable", output$rrp_episode_detail$html,
                     fixed = TRUE),
                grepl(run_1$run_id, output$rrp_episode_detail$html,
                      fixed = TRUE))
    })
  }

  # A separate completed zero-episode run is still a real selected snapshot.
  rrp_project_init(zero_project, "stage5-zero")
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
  zero_run <- rrp_run(zero_project, stage5_time("2026-01-17 12:00:00.125"))
  zero_refresh <- rrp_refresh_products(zero_project)
  stopifnot(identical(zero_run$episodes_processed, 0L),
            all(file.exists(zero_refresh$files)),
            nrow(utils::read.csv(zero_refresh$files[[1L]])) == 0L,
            nrow(utils::read.csv(zero_refresh$files[[2L]])) == 0L)
  if (stage5_app_available()) {
    app <- stage5_app(zero_project)
    shiny::testServer(app$serverFuncSource(), {
      stopifnot(grepl("No eligible episodes in this snapshot",
                     output$rrp_pool_region$html, fixed = TRUE),
                grepl("<strong>0</strong>", output$rrp_overview_scope$html,
                      fixed = TRUE),
                grepl("No current numerical risk estimates available",
                      output$rrp_overview_risk$html, fixed = TRUE),
                !grepl("No analytical products yet", output$rrp_pool_region$html,
                       fixed = TRUE))
    })
  }
  cat("Stage 5 installed-project acceptance workflow passed.\n")
}

stage5_workflow()
