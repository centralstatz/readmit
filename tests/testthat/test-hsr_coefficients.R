test_that("No argument error", {
  expect_error(hsr_coefficients())
})

test_that("coefficients support parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "coefficients_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF"),
      term = c("AGE", "HOSP_EFFECT"),
      value = c(0.25, -0.10)
    ),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(hsr_coefficients(bundle, "HF"), hsr_coefficients(bundle_path, "HF"))
})

test_that("coefficients work with alias overrides on parsed bundles", {
  bundle_path <- file.path(tempdir(), "coefficients_alias_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      measure = c("HF", "HF"),
      factor = c("AGE", "HOSP_EFFECT"),
      weight = c(0.25, -0.10)
    ),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    components = list(
      coefficients = list(
        column_aliases = list(
          cohort = c("measure"),
          term = c("factor"),
          value = c("weight")
        )
      )
    )
  )

  bundle <- hsr_parse(bundle_path, spec = spec)
  result <- hsr_coefficients(bundle, "HF")

  expect_true(all(c("Factor", "Value") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("coefficients fail clearly when required fields are missing", {
  bundle_path <- file.path(tempdir(), "coefficients_missing_fields")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(term = c("AGE", "HOSP_EFFECT")),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  expect_error(
    hsr_coefficients(bundle_path, "HF"),
    "missing required fields"
  )
})
