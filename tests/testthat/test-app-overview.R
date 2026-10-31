app53_time <- "2026-01-15T12:00:00.125000Z"

app53_skip_runtime <- function() {
  for (package in c("shiny", "bslib", "reactable", "plotly", "yaml")) {
    testthat::skip_if_not_installed(package)
  }
}

app53_project <- function() {
  project <- tempfile("readmit-app53-")
  rrp_project_init(project, "app53")
  project
}

app53_products <- function(project) {
  directory <- file.path(project, "state", "products")
  dir.create(directory, recursive = TRUE)
  current <- data.frame(
    selected_run_id = rep("run-current", 5L),
    as_of_time = rep(app53_time, 5L),
    episode_id = paste0("episode-", letters[1:5]),
    discharge_time = rep("2026-01-02T01:00:00.125000Z", 5L),
    followup_window_end = rep("2026-02-01T01:00:00.125000Z", 5L),
    disposition = c("accepted", "provider_failure", "accepted",
                    "provider_failure", "accepted"),
    probability = c(0, NA_real_, 0.2, NA_real_, 0.8)
  )
  trajectory <- data.frame(
    selected_run_id = "run-current", run_id = "run-old",
    as_of_time = "2026-01-10T12:00:00.125000Z",
    created_at = "2026-01-10T12:01:00.125000Z",
    episode_id = "episode-b", probability = 0.95
  )
  scope <- data.frame(
    selected_run_id = "run-current", project_id = "app53",
    as_of_time = app53_time,
    created_at = "2026-01-15T12:01:00.125000Z",
    episodes_assessed = 8L, eligible_count = 5L, accepted_count = 3L,
    provider_failure_count = 2L, ineligible_count = 3L,
    window_closed_count = 1L, known_readmission_count = 1L,
    known_death_count = 1L
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

app53_app <- function(project) {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(file.path(project, "app"))
  source("app.R", local = TRUE)$value
}

test_that("Overview shows complete scope and accepted current risks", {
  app53_skip_runtime()
  project <- app53_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app53_products(project)
  app <- app53_app(project)

  shiny::testServer(app$serverFuncSource(), {
    scope <- output$rrp_overview_scope$html
    expect_match(scope, "EPISODES ASSESSED", fixed = TRUE)
    expect_match(scope, "<strong>8</strong>", fixed = TRUE)
    expect_match(scope, "Eligible episodes</span>\n", fixed = TRUE)
    expect_match(scope, "<strong>5</strong>", fixed = TRUE)
    expect_match(scope, "Accepted estimates", fixed = TRUE)
    expect_match(scope, "Provider failures", fixed = TRUE)
    expect_match(scope, "Ineligible episodes", fixed = TRUE)
    expect_match(scope, "Follow-up window closed", fixed = TRUE)
    expect_match(scope, "Known readmission", fixed = TRUE)
    expect_match(scope, "Known death", fixed = TRUE)
    expect_match(scope, "Accepted estimates</dt>\\s*<dd>3</dd>")
    expect_match(scope, "Provider failures</dt>\\s*<dd>2</dd>")
    expect_match(scope, "Follow-up window closed</dt>\\s*<dd>1</dd>")
    expect_match(scope, "Known readmission</dt>\\s*<dd>1</dd>")
    expect_match(scope, "Known death</dt>\\s*<dd>1</dd>")
    expect_match(scope, "Assessed = eligible + ineligible", fixed = TRUE)
    expect_match(scope, "Eligible = accepted estimates + provider failures",
                 fixed = TRUE)

    risk <- output$rrp_overview_risk$html
    expect_match(risk, "3 accepted current estimates among 5 eligible episodes",
                 fixed = TRUE)
    expect_match(risk, "Minimum", fixed = TRUE)
    expect_match(risk, "Median", fixed = TRUE)
    expect_match(risk, "Maximum", fixed = TRUE)
    expect_match(risk, "0%", fixed = TRUE)
    expect_match(risk, "20%", fixed = TRUE)
    expect_match(risk, "80%", fixed = TRUE)
    expect_false(grepl("95%", risk, fixed = TRUE))
    expect_match(output$rrp_overview_snapshot$html,
                 "Jan 15, 2026 12:00:00.125 UTC", fixed = TRUE)

    session$setInputs(rrp_search = "episode-b", rrp_range = c(0.5, 1))
    session$setInputs(rrp_pool_table__reactable__selected = 1L)
    session$setInputs(rrp_pool_table__reactable__sorted = list(
      list(id = "probability", desc = TRUE)
    ))
    expect_identical(output$rrp_overview_scope$html, scope)
    expect_identical(output$rrp_overview_risk$html, risk)

    updated <- fixture$current
    updated$probability[updated$episode_id == "episode-c"] <- 0.3
    fixture$write(updated, "current-remaining-risk.csv")
    updated_scope <- fixture$scope
    updated_scope$episodes_assessed <- 9L
    updated_scope$ineligible_count <- 4L
    updated_scope$window_closed_count <- 2L
    fixture$write(updated_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_overview_scope$html,
                 "<strong>9</strong>", fixed = TRUE)
    expect_match(output$rrp_overview_risk$html, "30%", fixed = TRUE)
    expect_false(identical(output$rrp_overview_risk$html, risk))
  })
})

test_that("Overview distinguishes no products, zero rows, and all failures", {
  app53_skip_runtime()
  project <- app53_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  app <- app53_app(project)

  shiny::testServer(app$serverFuncSource(), {
    expect_match(output$rrp_overview_scope$html, "No analytical products yet")
    expect_match(output$rrp_overview_risk$html, "No analytical products yet")
    expect_match(output$rrp_overview_snapshot$html,
                 "No analytical product snapshot loaded")

    fixture <- app53_products(project)
    fixture$write(fixture$current[FALSE, ], "current-remaining-risk.csv")
    fixture$write(fixture$trajectory[FALSE, ],
                  "remaining-risk-trajectory.csv")
    zero <- fixture$scope
    zero[1L, 5:12] <- 0L
    fixture$write(zero, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_overview_scope$html, "<strong>0</strong>",
                 fixed = TRUE)
    expect_match(output$rrp_overview_risk$html,
                 "No current numerical risk estimates available")
    expect_false(grepl("rrp-risk-metric", output$rrp_overview_risk$html,
                       fixed = TRUE))
    expect_match(output$rrp_overview_snapshot$html,
                 "Jan 15, 2026", fixed = TRUE)

    all_failed <- fixture$current
    all_failed$disposition <- "provider_failure"
    all_failed$probability <- NA_real_
    fixture$write(all_failed, "current-remaining-risk.csv")
    failed_scope <- fixture$scope
    failed_scope$accepted_count <- 0L
    failed_scope$provider_failure_count <- 5L
    fixture$write(failed_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_overview_scope$html, "Provider failures")
    expect_match(output$rrp_overview_scope$html,
                 "Provider failures</dt>\\s*<dd>5</dd>")
    expect_match(output$rrp_overview_risk$html,
                 "0 accepted current estimates", fixed = TRUE)
    expect_match(output$rrp_overview_risk$html,
                 "Provider failures are not zero risk", fixed = TRUE)
    expect_false(grepl("95%", output$rrp_overview_risk$html, fixed = TRUE))
  })
})

test_that("Overview preserves valid regions across missing and bad products", {
  app53_skip_runtime()
  project <- app53_project()
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  fixture <- app53_products(project)
  app <- app53_app(project)

  shiny::testServer(app$serverFuncSource(), {
    unlink(file.path(fixture$directory, "operational-scope-summary.csv"))
    session$setInputs(rrp_reload = 1L)
    expect_match(output$rrp_overview_scope$html,
                 "Operational scope unavailable")
    expect_match(output$rrp_overview_scope$html,
                 "operational-scope-summary.csv", fixed = TRUE)
    expect_match(output$rrp_overview_risk$html, "Median")

    bad_scope <- fixture$scope
    bad_scope$eligible_count <- 4L
    fixture$write(bad_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 2L)
    expect_match(output$rrp_overview_scope$html,
                 "incompatible product values", fixed = TRUE)
    expect_match(output$rrp_overview_risk$html, "Median")

    bad_scope <- fixture$scope
    bad_scope$selected_run_id <- "other-run"
    fixture$write(bad_scope, "operational-scope-summary.csv")
    session$setInputs(rrp_reload = 3L)
    expect_match(output$rrp_overview_scope$html,
                 "different analytical snapshot", fixed = TRUE)
    expect_match(output$rrp_overview_risk$html, "Median")

    fixture$write(fixture$scope, "operational-scope-summary.csv")
    unlink(file.path(fixture$directory, "current-remaining-risk.csv"))
    session$setInputs(rrp_reload = 4L)
    expect_match(output$rrp_overview_scope$html, "EPISODES ASSESSED")
    expect_match(output$rrp_overview_risk$html,
                 "Current risk summary unavailable")
    expect_match(output$rrp_overview_risk$html,
                 "current-remaining-risk.csv", fixed = TRUE)
    expect_match(output$rrp_overview_snapshot$html,
                 "Jan 15, 2026", fixed = TRUE)

    bad_current <- fixture$current
    names(bad_current)[7L] <- "wrong_probability"
    fixture$write(bad_current, "current-remaining-risk.csv")
    session$setInputs(rrp_reload = 5L)
    expect_match(output$rrp_overview_scope$html, "EPISODES ASSESSED")
    expect_match(output$rrp_overview_risk$html,
                 "Current risk summary unavailable")
    expect_match(output$rrp_overview_risk$html,
                 "current-remaining-risk.csv", fixed = TRUE)
  })
})
