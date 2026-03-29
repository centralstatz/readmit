test_that("hsr_read returns a parsed HSR object for legacy mock report", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
  parsed <- hsr_read(report)

  expect_s3_class(parsed, "readmit_hsr")
})

test_that("is_hsr identifies parsed HSR objects", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
  parsed <- hsr_read(report)

  expect_true(is_hsr(parsed))
  expect_false(is_hsr(report))
  expect_false(is_hsr(NULL))
})

test_that("validate_hsr succeeds on parsed legacy objects", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
  parsed <- hsr_read(report, validate = FALSE)

  expect_invisible(readmit:::validate_hsr(parsed))
})

test_that("hsr_detect_format identifies current mock reports as legacy", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")

  expect_identical(hsr_detect_format(report), "legacy_excel")
})

test_that("parsed HSR contains required top-level fields and legacy sections", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
  parsed <- hsr_read(report)

  expect_true(all(c("meta", "sections", "cohorts", "raw", "issues") %in% names(parsed)))
  expect_true(all(c("payment_summary", "cohort_summary", "dual_stays") %in% names(parsed$sections)))
  expect_true(all(c("AMI", "COPD", "HF", "PN", "CABG", "HK") %in% names(parsed$cohorts)))
})

test_that("parsed payment summary reproduces legacy payment summary output", {
  report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
  parsed <- hsr_read(report)

  expect_equal(parsed$sections$payment_summary, hsr_payment_summary(report))
})
