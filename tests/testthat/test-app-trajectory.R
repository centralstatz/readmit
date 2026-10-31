app52_time <- "2026-01-15T12:00:00.125000Z"

app52_project <- function() {
  project <- tempfile("readmit-app52-")
  rrp_project_init(project, "app52")
  project
}

app52_products <- function(project) {
  directory <- file.path(project, "state", "products")
  dir.create(directory, recursive = TRUE)
  current <- data.frame(
    selected_run_id = rep("run-current", 4L),
    as_of_time = rep(app52_time, 4L),
    episode_id = c("episode-a", "episode-b", "episode-c", "episode-d"),
    discharge_time = rep("2026-01-02T01:00:00.125000Z", 4L),
    followup_window_end = rep("2026-02-01T01:00:00.125000Z", 4L),
    disposition = c("accepted", "provider_failure", "provider_failure",
                    "accepted"),
    probability = c(0.82, NA_real_, NA_real_, 0.125)
  )
  trajectory <- data.frame(
    selected_run_id = rep("run-current", 7L),
    run_id = c("run-a1", "run-a2", "run-current", "run-b1", "run-b2",
               "run-b3", "run-current"),
    as_of_time = c("2026-01-10T12:00:00.125000Z",
                   "2026-01-12T12:00:00.125000Z", app52_time,
                   "2026-01-10T12:00:00.125000Z",
                   "2026-01-10T12:00:00.125000Z",
                   "2026-01-12T12:00:00.125000Z", app52_time),
    created_at = c("2026-01-10T12:01:00.125000Z",
                   "2026-01-12T12:01:00.125000Z",
                   "2026-01-15T12:01:00.125000Z",
                   "2026-01-10T12:01:00.125000Z",
                   "2026-01-10T12:02:00.125000Z",
                   "2026-01-12T12:01:00.125000Z",
                   "2026-01-15T12:01:00.125000Z"),
    episode_id = c(rep("episode-a", 3L), rep("episode-b", 3L), "episode-d"),
    probability = c(0.2, 0.6, 0.82, 0.4, 0.4, 0.5, 0.125)
  )
  scope <- data.frame(
    selected_run_id = "run-current", project_id = "app52",
    as_of_time = app52_time,
    created_at = "2026-01-15T12:01:00.125000Z",
    episodes_assessed = 4L, eligible_count = 4L, accepted_count = 2L,
    provider_failure_count = 2L, ineligible_count = 0L,
    window_closed_count = 0L, known_readmission_count = 0L,
    known_death_count = 0L
  )
  write <- function(data, filename) utils::write.csv(
    data, file.path(directory, filename), row.names = FALSE, na = "",
    fileEncoding = "UTF-8"
  )
  write(current, "current-remaining-risk.csv")
  write(trajectory, "remaining-risk-trajectory.csv")
  write(scope, "operational-scope-summary.csv")
  list(directory = directory, current = current, trajectory = trajectory,
       scope = scope, write = write)
}

app52_app <- function(project) {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(file.path(project, "app"))
  local <- new.env(parent = globalenv())
  list(app = source("app.R", local = local)$value, functions = local)
}

test_that("sparklines encode only accepted observations on a fixed scale", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  skip_if_not_installed("plotly")
  project <- app52_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  app <- app52_app(project)
  time <- as.POSIXct(c("2026-01-10 12:00:00", "2026-01-12 12:00:00"),
                     tz = "UTC")
  html <- as.character(app$functions$rrp_sparkline(data.frame(
    as_of_time = time, probability = c(0, 1)
  )))
  expect_match(html, 'viewBox="0 0 100 32"', fixed = TRUE)
  expect_match(html, 'cx="5.00" cy="28.00"', fixed = TRUE)
  expect_match(html, 'cx="95.00" cy="4.00"', fixed = TRUE)
  expect_match(html, "2 recorded accepted risk estimates", fixed = TRUE)
  expect_match(as.character(app$functions$rrp_sparkline(NULL)), "No history")

  single <- as.character(app$functions$rrp_sparkline(data.frame(
    as_of_time = time[1L], probability = 0.4
  )))
  expect_match(single, 'cx="50.00"', fixed = TRUE)
  expect_false(grepl("polyline", single, fixed = TRUE))
})

test_that("selected episodes keep current risk separate from exact history", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  skip_if_not_installed("plotly")
  project <- app52_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app52_products(project)
  app <- app52_app(project)$app

  shiny::testServer(app$serverFuncSource(), {
    expect_match(output$rrp_episode_detail$html, "Select an episode")
    expect_match(output$rrp_pool_table, "rrp-sparkline")
    expect_match(output$rrp_pool_table, "No history")
    expect_match(output$rrp_pool_table,
                 "1 recorded accepted risk estimates", fixed = TRUE)
    expect_identical(history_by_episode()[["episode-b"]]$run_id,
                     c("run-b1", "run-b2", "run-b3"))
    expect_null(history_by_episode()[["episode-c"]])

    session$setInputs(rrp_pool_table__reactable__selected = 1L)
    detail <- output$rrp_episode_detail$html
    expect_match(detail, "episode-a", fixed = TRUE)
    expect_match(detail, "82%", fixed = TRUE)
    expect_match(detail, "Accepted in selected assessment", fixed = TRUE)
    expect_match(detail, "run-a1", fixed = TRUE)
    expect_match(detail, "run-a2", fixed = TRUE)
    expect_match(detail, "run-current", fixed = TRUE)
    expect_match(detail, "Recorded assessments", fixed = TRUE)
    expect_match(detail, "12:00:00.125000 UTC", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "run-a1", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "markers", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "82%", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "UTC", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot,
                 "2026-01-15T12:00:00.125000Z", fixed = TRUE)

    session$setInputs(rrp_pool_table__reactable__sorted = list(
      list(id = "probability", desc = TRUE)
    ))
    expect_match(output$rrp_episode_detail$html, "episode-a", fixed = TRUE)

    session$setInputs(rrp_pool_table__reactable__selected = 2L)
    detail <- output$rrp_episode_detail$html
    expect_match(detail, "episode-b", fixed = TRUE)
    expect_match(detail, "Unavailable", fixed = TRUE)
    expect_match(detail, "Provider failure", fixed = TRUE)
    expect_match(detail, "run-b1", fixed = TRUE)
    expect_match(detail, "run-b2", fixed = TRUE)
    expect_match(detail, "40%", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "run-b1", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "run-b2", fixed = TRUE)

    session$setInputs(rrp_pool_table__reactable__selected = 3L)
    expect_match(output$rrp_episode_detail$html, "episode-c", fixed = TRUE)
    expect_match(output$rrp_episode_detail$html, "No accepted history")
    expect_match(output$rrp_episode_detail$html, "Unavailable", fixed = TRUE)

    session$setInputs(rrp_pool_table__reactable__selected = 4L)
    expect_match(output$rrp_episode_detail$html, "episode-d", fixed = TRUE)
    expect_match(output$rrp_episode_detail$html, "12.5%", fixed = TRUE)
    expect_match(output$rrp_trajectory_plot, "run-current", fixed = TRUE)

    session$setInputs(rrp_search = "episode-b")
    expect_match(output$rrp_episode_detail$html, "Select an episode")
    session$setInputs(rrp_search = "", rrp_range = c(0.5, 1))
    session$setInputs(rrp_pool_table__reactable__selected = 1L)
    expect_match(output$rrp_episode_detail$html, "episode-a", fixed = TRUE)
    session$setInputs(rrp_range = c(0, 0.3))
    expect_match(output$rrp_episode_detail$html, "Select an episode")
    expect_match(output$rrp_pool_table, "episode-b", fixed = TRUE)
    session$setInputs(rrp_search = "no-match")
    expect_match(output$rrp_episode_detail$html, "Select an episode")

    session$setInputs(rrp_search = "", rrp_range = c(0, 1))
    session$setInputs(rrp_pool_table__reactable__selected = 2L)
    expect_match(output$rrp_episode_detail$html, "episode-b", fixed = TRUE)
    updated <- fixture$trajectory
    updated$probability[updated$run_id == "run-b3"] <- 0.7
    fixture$write(updated, "remaining-risk-trajectory.csv")
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_episode_detail$html, "episode-b", fixed = TRUE)
    expect_match(output$rrp_episode_detail$html, "70%", fixed = TRUE)

    unlink(file.path(fixture$directory, "remaining-risk-trajectory.csv"))
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_episode_detail$html, "History unavailable")
    expect_match(output$rrp_episode_detail$html, "Unavailable", fixed = TRUE)
    expect_match(output$rrp_pool_table, "History unavailable", fixed = TRUE)
    expect_match(output$rrp_pool_table, "episode-b", fixed = TRUE)

    fixture$write(fixture$trajectory, "remaining-risk-trajectory.csv")
    reduced <- fixture$current[fixture$current$episode_id != "episode-b", ]
    fixture$write(reduced, "current-remaining-risk.csv")
    scope <- fixture$scope
    scope$eligible_count <- 3L
    scope$provider_failure_count <- 1L
    scope$episodes_assessed <- 3L
    fixture$write(scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 3L)
    expect_match(output$rrp_episode_detail$html, "Select an episode")
  })
})

test_that("unusable or mismatched history stays separate from a valid pool", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  skip_if_not_installed("plotly")
  project <- app52_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app52_products(project)
  app <- app52_app(project)$app

  shiny::testServer(app$serverFuncSource(), {
    session$setInputs(rrp_pool_table__reactable__selected = 2L)
    expect_match(output$rrp_episode_detail$html, "run-b1", fixed = TRUE)

    bad <- fixture$trajectory
    bad$selected_run_id <- "other-run"
    fixture$write(bad, "remaining-risk-trajectory.csv")
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_episode_detail$html, "History unavailable")
    expect_match(output$rrp_pool_table, "History unavailable", fixed = TRUE)
    expect_match(output$rrp_product_notice$html,
                 "remaining-risk-trajectory.csv", fixed = TRUE)

    bad <- fixture$trajectory
    bad$episode_id[[1L]] <- "episode-outside-pool"
    fixture$write(bad, "remaining-risk-trajectory.csv")
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_episode_detail$html, "History unavailable")
    expect_match(output$rrp_pool_table, "episode-b", fixed = TRUE)

    bad <- fixture$trajectory
    names(bad)[6L] <- "wrong_probability"
    fixture$write(bad, "remaining-risk-trajectory.csv")
    session$setInputs(rrp_reload = 3L)
    expect_match(output$rrp_episode_detail$html, "History unavailable")
    expect_match(output$rrp_pool_table, "episode-b", fixed = TRUE)

    fixture$write(fixture$trajectory[FALSE, ],
                  "remaining-risk-trajectory.csv")
    session$setInputs(rrp_reload = 4L)
    expect_match(output$rrp_episode_detail$html, "No accepted history")
    expect_match(output$rrp_pool_table, "No history", fixed = TRUE)
  })
})
