test_that("File exists", {
  expect_equal(file.exists(hsr_example(hsr_example())), TRUE)
})
