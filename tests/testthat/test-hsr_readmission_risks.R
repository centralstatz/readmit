test_that("No argument error", {
  expect_error(hsr_readmission_risks())
})

test_that("readmission risks support parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "readmission_risks_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF"),
      `ID Number` = c(1001, 1002),
      AGE = c(1, 0)
    ),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF", "HF"),
      term = c("AGE", "HOSP_EFFECT", "AVG_EFFECT"),
      value = c(0.25, -0.10, -0.20)
    ),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(
    hsr_readmission_risks(bundle_path, "HF"),
    hsr_readmission_risks(bundle, "HF")
  )
})

test_that("readmission risks work with alias overrides on parsed bundles", {
  bundle_path <- file.path(tempdir(), "readmission_risks_alias_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      measure = c("HF", "HF"),
      id = c(1001, 1002),
      AGE = c(1, 0)
    ),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      measure = c("HF", "HF", "HF"),
      factor = c("AGE", "HOSP_EFFECT", "AVG_EFFECT"),
      weight = c(0.25, -0.10, -0.20)
    ),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    components = list(
      discharges = list(
        column_aliases = list(
          cohort = c("measure"),
          `ID Number` = c("id")
        )
      ),
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
  risks <- hsr_readmission_risks(bundle, "HF")

  expect_true(all(c("ID Number", "Predicted", "Expected") %in% names(risks)))
  expect_equal(nrow(risks), 2)
})

test_that("readmission risks fail clearly when required fields are missing", {
  bundle_path <- file.path(tempdir(), "readmission_risks_missing_fields")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF"),
      `ID Number` = c(1001, 1002)
    ),
    file.path(bundle_path, "discharges.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      cohort = c("HF", "HF"),
      term = c("AGE", "HOSP_EFFECT")
    ),
    file.path(bundle_path, "coefficients.csv"),
    row.names = FALSE
  )

  expect_error(
    hsr_readmission_risks(bundle_path, "HF"),
    "missing required fields|must contain both|risk factor fields"
  )
})
