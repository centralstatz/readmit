test_that("initialized project configuration loads both authoring functions", {
  project <- tempfile("rrp-authoring-")
  rrp_project_init(project, "loader-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  had_producer <- exists("rrp_produce_canonical", envir = .GlobalEnv,
                         inherits = FALSE)
  had_provider <- exists("rrp_calculate_risk", envir = .GlobalEnv,
                         inherits = FALSE)

  loaded <- readmit:::rrp_load_project_authoring(project)

  expect_identical(loaded$project_id, "loader-test")
  expect_identical(loaded$project_root,
                   normalizePath(project, winslash = "/"))
  expect_identical(loaded$source_mapping_script,
                   normalizePath(file.path(project, "R/produce-canonical.R"),
                                 winslash = "/"))
  expect_identical(loaded$risk_provider_script,
                   normalizePath(file.path(project, "R/calculate-risk.R"),
                                 winslash = "/"))
  expect_true(is.function(loaded$produce_canonical))
  expect_true(is.function(loaded$calculate_risk))
  expect_identical(names(formals(loaded$produce_canonical)),
                   c("project_root", "as_of_time"))
  expect_identical(names(formals(loaded$calculate_risk)),
                   c("project_root", "request"))
  expect_identical(exists("rrp_produce_canonical", envir = .GlobalEnv,
                          inherits = FALSE), had_producer)
  expect_identical(exists("rrp_calculate_risk", envir = .GlobalEnv,
                          inherits = FALSE), had_provider)
})

test_that("configured script path and ordinary lexical helpers work", {
  project <- tempfile("rrp-authoring-")
  rrp_project_init(project, "loader-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  alternative <- file.path(project, "R", "alternate-mapping.R")
  writeLines(c(
    "mapping_helper <- function() 42L",
    "rrp_produce_canonical <- function(project_root, as_of_time) mapping_helper()"
  ), alternative)
  writeLines(c(
    "Source-Mapping-Script: R/alternate-mapping.R",
    "Risk-Provider-Script: R/calculate-risk.R"
  ), file.path(project, "rrp-authoring.dcf"))
  had_helper <- exists("mapping_helper", envir = .GlobalEnv,
                       inherits = FALSE)

  loaded <- readmit:::rrp_load_project_authoring(project)

  expect_identical(loaded$source_mapping_script,
                   normalizePath(alternative, winslash = "/"))
  expect_identical(loaded$produce_canonical(project, Sys.time()), 42L)
  expect_identical(exists("mapping_helper", envir = .GlobalEnv,
                          inherits = FALSE), had_helper)
})

test_that("essential configuration errors are clear", {
  project <- tempfile("rrp-authoring-")
  rrp_project_init(project, "loader-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  project_dcf <- file.path(project, "rrp-project.dcf")
  authoring_dcf <- file.path(project, "rrp-authoring.dcf")

  unlink(project_dcf)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "rrp-project.dcf")
  writeLines("Project-ID: loader-test", project_dcf)
  writeLines("not a DCF record", project_dcf)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "Could not read rrp-project.dcf")
  writeLines("Other-Field: value", project_dcf)
  expect_error(readmit:::rrp_load_project_authoring(project), "Project-ID")
  writeLines("Project-ID: loader-test", project_dcf)

  writeLines("Source-Mapping-Script: R/produce-canonical.R", authoring_dcf)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "Risk-Provider-Script")
})

test_that("missing or incompatible authoring scripts fail plainly", {
  project <- tempfile("rrp-authoring-")
  rrp_project_init(project, "loader-test")
  on.exit(unlink(project, recursive = TRUE), add = TRUE)
  authoring_dcf <- file.path(project, "rrp-authoring.dcf")
  provider <- file.path(project, "R", "calculate-risk.R")

  writeLines(c(
    "Source-Mapping-Script: R/produce-canonical.R",
    "Risk-Provider-Script: R/missing.R"
  ), authoring_dcf)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "Configured risk-provider script does not exist")
  writeLines(c(
    "Source-Mapping-Script: R/produce-canonical.R",
    "Risk-Provider-Script: R/calculate-risk.R"
  ), authoring_dcf)

  writeLines('stop("broken script")', provider)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "Could not load risk-provider script")
  writeLines("other_function <- function() NULL", provider)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "must define rrp_calculate_risk")
  writeLines("rrp_calculate_risk <- 1", provider)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "must be a function")
  writeLines("rrp_calculate_risk <- function(project_root) NULL", provider)
  expect_error(readmit:::rrp_load_project_authoring(project),
               "must have arguments project_root, request")
})
