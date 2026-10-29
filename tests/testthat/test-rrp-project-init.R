test_that("initializer copies and identifies a complete project", {
  parent <- tempfile("rrp-projects-")
  dir.create(parent)
  on.exit(unlink(parent, recursive = TRUE), add = TRUE)
  project <- file.path(parent, "ward-risk")

  result <- rrp_project_init(project, "ward-risk")
  expect_identical(result, normalizePath(project, winslash = "/"))

  template <- system.file("project-template", package = "readmit")
  files <- function(path) sort(list.files(
    path, recursive = TRUE, all.files = TRUE, no.. = TRUE,
    include.dirs = TRUE
  ))
  expect_identical(files(project), files(template))
  expect_identical(unname(read.dcf(file.path(project, "rrp-project.dcf"))[
    1, "Project-ID"]), "ward-risk")
  expect_identical(unname(read.dcf(file.path(project, "rrp-authoring.dcf"))[
    1, "Source-Mapping-Script"]), "R/produce-canonical.R")
  brand <- readLines(file.path(project, "_brand.yml"))
  expect_true(any(grepl('full: "ward-risk"', brand, fixed = TRUE)))
  expect_false(any(grepl("@@RRP_PROJECT_ID@@", brand, fixed = TRUE)))
  for (file in c("R/produce-canonical.R", "R/calculate-risk.R",
                 "app/app.R", "app/www/rrp.css", "assets/project-logo.png")) {
    expect_identical(
      unname(tools::md5sum(file.path(project, file))),
      unname(tools::md5sum(file.path(template, file)))
    )
  }
  expect_false(any(file.exists(file.path(project, c(
    "source", "state", "state.dcf", "history.duckdb"
  )))))
})

test_that("initializer leaves existing destinations untouched", {
  parent <- tempfile("rrp-projects-")
  dir.create(parent)
  on.exit(unlink(parent, recursive = TRUE), add = TRUE)

  empty <- file.path(parent, "empty")
  dir.create(empty)
  expect_error(rrp_project_init(empty, "test"), "already exists")
  expect_length(list.files(empty), 0L)

  occupied <- file.path(parent, "occupied")
  dir.create(occupied)
  writeLines("keep", file.path(occupied, "keep.txt"))
  expect_error(rrp_project_init(occupied, "test"), "already exists")
  expect_identical(readLines(file.path(occupied, "keep.txt")), "keep")

  existing_file <- file.path(parent, "file")
  writeLines("keep", existing_file)
  expect_error(rrp_project_init(existing_file, "test"), "already exists")
  expect_identical(readLines(existing_file), "keep")

  project <- file.path(parent, "new")
  rrp_project_init(project, "test")
  config <- file.path(project, "rrp-project.dcf")
  writeLines("edited", config)
  expect_error(rrp_project_init(project, "other"), "already exists")
  expect_identical(readLines(config), "edited")
})
