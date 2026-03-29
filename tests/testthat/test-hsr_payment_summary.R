test_that("No argument error", {
  expect_error(hsr_payment_summary())
})

test_that("payment summary supports parsed bundles and path coercion", {
  bundle_path <- file.path(tempdir(), "payment_summary_bundle")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(metric = c("payment_adjustment_factor", "peer_group"), value = c(0.98, 4)),
    file.path(bundle_path, "payment_summary.csv"),
    row.names = FALSE
  )

  bundle <- hsr_parse(bundle_path)

  expect_equal(hsr_payment_summary(bundle), hsr_payment_summary(bundle_path))
})

test_that("payment summary fails clearly when component is unpopulated", {
  expect_error(
    hsr_payment_summary(testthat::test_path("fixtures", "hsr_csv_bundle_partial")),
    "missing or unpopulated"
  )
})
