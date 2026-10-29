test_that("freshly initialized project passes structural validation", {
  project <- tempfile("rrp-validation-")
  rrp_project_init(project, "validation-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)

  result <- withVisible(rrp_project_validate(project))

  expect_identical(result$value, TRUE)
  expect_false(result$visible)
  expect_false(any(file.exists(file.path(project, c(
    "source", "state", "state.dcf", "history.duckdb"
  )))))
})

test_that("validation respects edited authoring configuration", {
  project <- tempfile("rrp-validation-")
  rrp_project_init(project, "validation-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  dir.create(file.path(project, "R", "custom"))
  expect_true(file.rename(
    file.path(project, "R", "produce-canonical.R"),
    file.path(project, "R", "custom", "mapping.R")
  ))
  writeLines(c(
    "Source-Mapping-Script: R/custom/mapping.R",
    "Risk-Provider-Script: R/calculate-risk.R"
  ), file.path(project, "rrp-authoring.dcf"))

  expect_identical(rrp_project_validate(project), TRUE)
})

test_that("app and branding are not analytical validation gates", {
  project <- tempfile("rrp-validation-")
  rrp_project_init(project, "validation-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  unlink(file.path(project, c("README.md", "_brand.yml", "assets", "app")),
         recursive = TRUE)

  expect_identical(rrp_project_validate(project), TRUE)
})

test_that("public validation preserves specific loader errors", {
  missing <- tempfile("rrp-missing-")
  expect_error(rrp_project_validate(missing), "existing project directory")

  project <- tempfile("rrp-validation-")
  rrp_project_init(project, "validation-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  project_dcf <- file.path(project, "rrp-project.dcf")
  authoring_dcf <- file.path(project, "rrp-authoring.dcf")
  producer <- file.path(project, "R", "produce-canonical.R")

  unlink(project_dcf)
  expect_error(rrp_project_validate(project), "rrp-project.dcf")
  writeLines("Project-ID: validation-test", project_dcf)
  writeLines("invalid DCF", authoring_dcf)
  expect_error(rrp_project_validate(project), "Could not read rrp-authoring.dcf")
  writeLines("Risk-Provider-Script: R/calculate-risk.R", authoring_dcf)
  expect_error(rrp_project_validate(project), "Source-Mapping-Script")
  writeLines(c(
    "Source-Mapping-Script: R/missing.R",
    "Risk-Provider-Script: R/calculate-risk.R"
  ), authoring_dcf)
  expect_error(rrp_project_validate(project),
               "Configured source-mapping script does not exist")
  writeLines(c(
    "Source-Mapping-Script: R/produce-canonical.R",
    "Risk-Provider-Script: R/calculate-risk.R"
  ), authoring_dcf)
  writeLines("other_function <- function() NULL", producer)
  expect_error(rrp_project_validate(project),
               "must define rrp_produce_canonical")
  writeLines("rrp_produce_canonical <- function(project_root) NULL", producer)
  expect_error(rrp_project_validate(project),
               "must have arguments project_root, as_of_time")
})
