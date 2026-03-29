hsr_fixture_path <- function(name) {
  testthat::test_path("fixtures", name)
}

test_that("hsr_parse returns a parsed bundle from a path", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_minimal"))

  expect_s3_class(bundle, "readmit_hsr_bundle")
  expect_true(is_hsr_bundle(bundle))
})

test_that("hsr_parse returns a parsed bundle from a source object", {
  source <- hsr_resolve_source(hsr_fixture_path("hsr_csv_bundle_minimal"))
  bundle <- hsr_parse(source)

  expect_s3_class(bundle, "readmit_hsr_bundle")
  expect_invisible(readmit:::validate_hsr_bundle(bundle))
})

test_that("parsed bundles contain required top-level fields and component slots", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_partial"))

  expect_true(all(c("meta", "source", "components", "lineage", "raw", "issues") %in% names(bundle)))
  expect_true(all(readmit:::hsr_get_component_names() %in% names(bundle$components)))
})

test_that("partial bundles remain structurally valid with empty components", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_partial"))

  expect_gt(nrow(bundle$components$discharges), 0)
  expect_equal(nrow(bundle$components$coefficients), 0)
  expect_equal(nrow(bundle$components$payment_summary), 0)
  expect_invisible(readmit:::validate_hsr_bundle(bundle))
})

test_that("parsed bundle validation checks lineage against source artifacts", {
  bundle <- hsr_parse(hsr_fixture_path("hsr_csv_bundle_minimal"))
  bundle$lineage$artifact_id[[1]] <- "missing_artifact"

  expect_error(readmit:::validate_hsr_bundle(bundle), "known source artifacts")
})

test_that("hsr_parse honors alias overrides when parsing component columns", {
  bundle_path <- file.path(tempdir(), "parse_alias_override")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(name = "payment_adjustment_factor", amount = 0.98),
    file.path(bundle_path, "payment_summary.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    components = list(
      payment_summary = list(
        column_aliases = list(
          metric = c("name"),
          value = c("amount")
        )
      )
    )
  )

  bundle <- hsr_parse(bundle_path, spec = spec)

  expect_true(all(c("metric", "value") %in% names(bundle$components$payment_summary)))
})
