app51_time <- "2026-01-15T12:00:00.125000Z"

app51_project <- function() {
  project <- tempfile("readmit-app51-")
  rrp_project_init(project, "app51")
  project
}

app51_products <- function(project) {
  directory <- file.path(project, "state", "products")
  dir.create(directory, recursive = TRUE)
  current <- data.frame(
    selected_run_id = rep("run-current", 3L),
    as_of_time = rep(app51_time, 3L),
    episode_id = c("episode-a", "episode-b", "episode-c"),
    discharge_time = rep("2026-01-02T01:00:00.125000Z", 3L),
    followup_window_end = rep("2026-02-01T01:00:00.125000Z", 3L),
    disposition = c("accepted", "accepted", "provider_failure"),
    probability = c(0, 0.82, NA_real_)
  )
  trajectory <- data.frame(
    selected_run_id = rep("run-current", 2L),
    run_id = c("run-old", "run-current"),
    as_of_time = c("2026-01-10T12:00:00.125000Z", app51_time),
    created_at = c("2026-01-10T12:01:00.125000Z",
                   "2026-01-15T12:01:00.125000Z"),
    episode_id = c("episode-a", "episode-b"),
    probability = c(0, 0.82)
  )
  scope <- data.frame(
    selected_run_id = "run-current", project_id = "app51",
    as_of_time = app51_time,
    created_at = "2026-01-15T12:01:00.125000Z",
    episodes_assessed = 3L, eligible_count = 3L, accepted_count = 2L,
    provider_failure_count = 1L, ineligible_count = 0L,
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

app51_reader <- function(project) {
  local <- new.env(parent = globalenv())
  sys.source(file.path(project, "app", "R", "read-products.R"), envir = local)
  local
}

app51_app <- function(project) {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(file.path(project, "app"))
  source("app.R", local = TRUE)$value
}

test_that("project app reader distinguishes missing, valid, and invalid CSVs", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  project <- app51_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  reader <- app51_reader(project)

  missing <- reader$rrp_app_read_products(project)
  expect_identical(vapply(missing, `[[`, character(1), "status"),
                   c(current = "missing", trajectory = "missing",
                     scope = "missing"))

  fixture <- app51_products(project)
  products <- reader$rrp_app_read_products(project)
  expect_true(all(vapply(products, function(x) x$status == "ok", logical(1))))
  expect_identical(products$current$data$episode_id,
                   c("episode-a", "episode-b", "episode-c"))
  expect_identical(products$current$data$probability, c(0, 0.82, NA_real_))
  expect_identical(attr(products$current$data$as_of_time, "tzone"), "UTC")
  expect_identical(as.numeric(products$current$data$as_of_time[1L]),
                   as.numeric(as.POSIXct("2026-01-15 12:00:00.125", tz = "UTC")))
  expect_true(all(vapply(products$scope$data[5:12], is.integer, logical(1))))

  unlink(file.path(fixture$directory, "remaining-risk-trajectory.csv"))
  partial <- reader$rrp_app_read_products(project)
  expect_identical(partial$current$status, "ok")
  expect_identical(partial$trajectory$status, "missing")
  expect_identical(partial$scope$status, "ok")
  fixture$write(fixture$trajectory, "remaining-risk-trajectory.csv")

  fixture$write(fixture$current[FALSE, ], "current-remaining-risk.csv")
  fixture$write(fixture$trajectory[FALSE, ], "remaining-risk-trajectory.csv")
  empty <- reader$rrp_app_read_products(project)
  expect_identical(empty$current$status, "ok")
  expect_identical(empty$trajectory$status, "ok")
  expect_identical(nrow(empty$current$data), 0L)
  expect_s3_class(empty$current$data$as_of_time, "POSIXct")

  fixture$write(fixture$current, "current-remaining-risk.csv")
  fixture$write(fixture$trajectory, "remaining-risk-trajectory.csv")
  bad <- fixture$current
  names(bad)[7L] <- "wrong_probability"
  fixture$write(bad, "current-remaining-risk.csv")
  invalid <- reader$rrp_app_read_products(project)
  expect_identical(invalid$current$status, "invalid")
  expect_match(invalid$current$message, "current-remaining-risk.csv", fixed = TRUE)
  expect_identical(invalid$scope$status, "ok")

  unlink(file.path(fixture$directory, "current-remaining-risk.csv"))
  dir.create(file.path(fixture$directory, "current-remaining-risk.csv"))
  unreadable <- reader$rrp_app_read_products(project)
  expect_identical(unreadable$current$status, "invalid")
})

test_that("reader flags snapshot mismatches without discarding current risk", {
  project <- app51_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app51_products(project)
  reader <- app51_reader(project)

  scope <- fixture$scope
  scope$selected_run_id <- "other-run"
  fixture$write(scope, "operational-scope-summary.csv")
  mismatch <- reader$rrp_app_read_products(project)
  expect_identical(mismatch$current$status, "ok")
  expect_identical(mismatch$scope$status, "mismatch")
  expect_match(mismatch$scope$message, "operational-scope-summary.csv",
               fixed = TRUE)

  fixture$write(fixture$scope, "operational-scope-summary.csv")
  trajectory <- fixture$trajectory
  trajectory$selected_run_id <- "other-run"
  fixture$write(trajectory, "remaining-risk-trajectory.csv")
  mismatch <- reader$rrp_app_read_products(project)
  expect_identical(mismatch$current$status, "ok")
  expect_identical(mismatch$trajectory$status, "mismatch")

  fixture$write(fixture$trajectory, "remaining-risk-trajectory.csv")
  scope <- fixture$scope
  scope$eligible_count <- 2L
  scope$accepted_count <- 1L
  scope$ineligible_count <- 1L
  scope$window_closed_count <- 1L
  fixture$write(scope, "operational-scope-summary.csv")
  mismatch <- reader$rrp_app_read_products(project)
  expect_identical(mismatch$current$status, "ok")
  expect_identical(mismatch$scope$status, "mismatch")

  fixture$write(fixture$scope, "operational-scope-summary.csv")
  fixture$write(fixture$trajectory, "remaining-risk-trajectory.csv")
  current <- fixture$current
  current$as_of_time <- "not-a-timestamp"
  fixture$write(current, "current-remaining-risk.csv")
  invalid <- reader$rrp_app_read_products(project)
  expect_identical(invalid$current$status, "invalid")
  expect_match(invalid$current$message, "UTC timestamp")
})

test_that("app distinguishes a new project from an incomplete product set", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  project <- app51_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  app <- app51_app(project)

  shiny::testServer(app$serverFuncSource(), {
    expect_match(output$rrp_pool_region$html, "No analytical products yet")
    expect_null(output$rrp_product_notice)
    fixture <- app51_products(project)
    unlink(file.path(fixture$directory, "current-remaining-risk.csv"))
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_pool_region$html,
                 "Current risk product unavailable")
    expect_match(output$rrp_pool_region$html,
                 "current-remaining-risk.csv", fixed = TRUE)
    expect_match(output$rrp_product_notice$html,
                 "current-remaining-risk.csv", fixed = TRUE)
    fixture$write(fixture$current, "current-remaining-risk.csv")
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_pool_count,
                 "3 of 3 eligible episodes displayed")
  })
})

test_that("app presents accepted, failed, zero, and filtered states", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("yaml")
  skip_if_not_installed("reactable")
  project <- app51_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app51_products(project)
  app <- app51_app(project)
  expect_s3_class(app, "shiny.appobj")

  shiny::testServer(app$serverFuncSource(), {
    session$flushReact()
    expect_match(output$rrp_pool_count, "3 of 3 eligible episodes displayed")
    expect_match(output$rrp_snapshot$html, "Jan 15, 2026")
    expect_match(output$rrp_pool_region$html, "rrp_pool_table")
    expect_match(output$rrp_pool_table, "episode-a")
    expect_match(output$rrp_pool_table, "episode-c")
    expect_match(output$rrp_pool_table, "sortNALast")
    expect_match(output$rrp_pool_table, '"onClick":"select"', fixed = TRUE)
    expect_match(output$rrp_pool_table, "rrp-risk-fill")
    expect_match(output$rrp_pool_table, "0%", fixed = TRUE)
    expect_match(output$rrp_pool_table, "82%", fixed = TRUE)
    expect_match(output$rrp_pool_table, '"width":"0.00%"', fixed = TRUE)
    expect_match(output$rrp_pool_table, '"width":"82.00%"', fixed = TRUE)
    expect_match(output$rrp_pool_table, "Unavailable", fixed = TRUE)

    session$setInputs(rrp_search = "episode-c", rrp_range = c(0.5, 1))
    expect_match(output$rrp_pool_count, "1 of 3 eligible episodes displayed")
    expect_match(output$rrp_pool_table, "episode-c")
    session$setInputs(rrp_search = "", rrp_range = c(0.5, 1))
    expect_match(output$rrp_pool_count, "2 of 3 eligible episodes displayed")
    expect_false(grepl("episode-a", output$rrp_pool_table, fixed = TRUE))
    session$setInputs(rrp_search = "no-match")
    expect_match(output$rrp_pool_region$html, "No episodes match these filters")
    expect_match(output$rrp_pool_count, "0 of 3 eligible episodes displayed")

    session$setInputs(rrp_search = "", rrp_range = c(0, 1))
    session$setInputs(rrp_pool_table__reactable__selected = 3L)
    expect_match(output$rrp_episode_detail$html, "episode-c")
    session$setInputs(rrp_pool_table__reactable__sorted = list(
      list(id = "probability", desc = TRUE)
    ))
    expect_match(output$rrp_episode_detail$html, "episode-c")
    session$setInputs(rrp_search = "episode-b")
    expect_match(output$rrp_episode_detail$html, "Select an episode")

    fixture$write(fixture$current[FALSE, ], "current-remaining-risk.csv")
    zero_scope <- fixture$scope
    zero_scope[1L, 5:12] <- 0L
    fixture$write(zero_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_pool_region$html,
                 "No eligible episodes in this snapshot")

    failed <- fixture$current
    failed$disposition <- "provider_failure"
    failed$probability <- NA_real_
    fixture$write(failed, "current-remaining-risk.csv")
    failed_scope <- fixture$scope
    failed_scope$accepted_count <- 0L
    failed_scope$provider_failure_count <- 3L
    fixture$write(failed_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_search = "", rrp_range = c(0, 1))
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_pool_count, "3 of 3 eligible episodes displayed")
    expect_match(output$rrp_pool_table, "episode-a")
    expect_match(output$rrp_pool_table, "Unavailable", fixed = TRUE)
    expect_false(grepl("0%", output$rrp_pool_table, fixed = TRUE))
  })
})
