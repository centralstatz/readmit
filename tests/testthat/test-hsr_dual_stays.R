test_that("No argument error", {
  expect_error(hsr_dual_stays())
})

test_that("dual stays supports parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "dual_stays_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(ID = c(1001, 1002), cohort = c("HF", "HF")),
    file.path(bundle_path, "dual_stays.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(hsr_dual_stays(bundle), hsr_dual_stays(bundle_path))
})

test_that("dual stays fails clearly when component is unpopulated", {
  expect_error(
    hsr_dual_stays(testthat::test_path("fixtures", "hsr_csv_bundle_partial")),
    "missing or unpopulated"
  )
})
