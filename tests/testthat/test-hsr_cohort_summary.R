test_that("No argument error", {
  expect_error(hsr_cohort_summary())
})

test_that("cohort summary supports parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "cohort_summary_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(measure = "HF", discharges = 25),
    file.path(bundle_path, "cohort_summary.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(hsr_cohort_summary(bundle), hsr_cohort_summary(bundle_path))
})

test_that("cohort summary fails clearly when component is unpopulated", {
  expect_error(
    hsr_cohort_summary(testthat::test_path("fixtures", "hsr_csv_bundle_partial")),
    "missing or unpopulated"
  )
})
