test_that("No argument error", {
  expect_error(hsr_discharges())
})

test_that("discharges support parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "discharges_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF"),
      `ID Number` = c(1001, 1002),
      index_stay = c(1, 1)
    ),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(hsr_discharges(bundle, "HF"), hsr_discharges(bundle_path, "HF"))
})

test_that("discharges work with alias overrides on parsed bundles", {
  bundle_path <- file.path(tempdir(), "discharges_alias_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      measure = c("HF", "HF"),
      id = c(1001, 1002),
      index_stay = c(1, 1)
    ),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    components = list(
      discharges = list(
        column_aliases = list(
          cohort = c("measure"),
          `ID Number` = c("id")
        )
      )
    )
  )

  bundle <- hsr_parse(bundle_path, spec = spec)
  result <- hsr_discharges(bundle, "HF")

  expect_true(all(c("cohort", "ID Number") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("discharges fail clearly when required fields are missing", {
  bundle_path <- file.path(tempdir(), "discharges_missing_fields")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(id = c(1001, 1002)),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )

  expect_error(
    hsr_discharges(bundle_path, "HF"),
    "missing required fields"
  )
})
