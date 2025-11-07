test_that("A data frame is returned", {
  expect_equal(is(pdc_datasets("Hospitals"), "data.frame"), TRUE)
})
