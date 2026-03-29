hsr_fixture_path <- function(name) {
  testthat::test_path("fixtures", name)
}

test_that("one artifact can yield one conceptual component", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_minimal"))

  expect_equal(nrow(bundle$components$payment_summary), 2)
  expect_equal(nrow(bundle$lineage), 1)
  expect_identical(unique(bundle$lineage$component), "payment_summary")
})

test_that("one artifact can yield multiple conceptual components", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_multioutput"))

  expect_equal(sort(unique(bundle$lineage$component)), c("coefficients", "discharges"))
  expect_equal(nrow(bundle$components$discharges), 2)
  expect_equal(nrow(bundle$components$coefficients), 2)
})

test_that("multiple artifacts can contribute to the same component", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_partial"))

  discharge_lineage <- bundle$lineage |>
    dplyr::filter(.data$component == "discharges")

  expect_equal(nrow(discharge_lineage), 2)
  expect_equal(nrow(bundle$components$discharges), 3)
})

test_that("parser config can override embedded component column", {
  bundle_path <- file.path(tempdir(), "embedded_component_override")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(
      component_type = c("discharges", "coefficients"),
      cohort = c("HF", "HF"),
      id = c(1001, NA),
      term = c(NA, "AGE"),
      value = c(NA, 0.25)
    ),
    file.path(bundle_path, "hf_source.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    components = list(
      coefficients = list(
        layout = list(
          embedded_component_column = "component_type"
        )
      )
    )
  )

  bundle <- hsr_parse(bundle_path, spec = spec)

  expect_equal(sort(unique(bundle$lineage$component)), c("coefficients", "discharges"))
})
