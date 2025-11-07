test_that("A data frame is returned", {
  expect_equal(is(pdc_read("xubh-q36u"), "data.frame"), TRUE)
})
test_that("An error is thrown", {
  expect_error(pdc_read())
})
