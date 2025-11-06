test_that("File exists", {
  expect_equal(file.exists(hsr_mock_reports(hsr_mock_reports()[1])), TRUE)
})
