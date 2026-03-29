hsr_fixture_path <- function(name) {
  testthat::test_path("fixtures", name)
}

test_that("hsr_parser_config returns a parser spec object", {
  spec <- hsr_parser_config()

  expect_s3_class(spec, "readmit_hsr_spec")
  expect_invisible(readmit:::validate_hsr_parser_config(spec))
})

test_that("hsr_resolve_source returns a source bundle for local CSV fixtures", {
  source <- hsr_resolve_source(hsr_fixture_path("hsr_csv_bundle_minimal"))

  expect_s3_class(source, "readmit_hsr_source")
  expect_true(is_hsr_source(source))
})

test_that("source bundles contain required structural fields", {
  source <- hsr_resolve_source(hsr_fixture_path("hsr_csv_bundle_minimal"))

  expect_true(all(c("meta", "location", "artifacts", "issues") %in% names(source)))
  expect_true(all(c("artifact_id", "path", "format", "role_hint", "name") %in% names(source$artifacts)))
  expect_invisible(readmit:::validate_hsr_source(source))
})

test_that("role hints are hints and unknown hints remain structurally valid", {
  source <- hsr_resolve_source(hsr_fixture_path("hsr_csv_bundle_multioutput"))

  expect_true("unknown" %in% source$artifacts$role_hint)
  expect_invisible(readmit:::validate_hsr_source(source))
})

test_that("source validation checks artifact path existence", {
  source <- hsr_resolve_source(hsr_fixture_path("hsr_csv_bundle_minimal"))
  source$artifacts$path[[1]] <- file.path(tempdir(), "missing.csv")

  expect_error(readmit:::validate_hsr_source(source), "must exist")
})

test_that("source resolution honors role hint overrides", {
  bundle_path <- file.path(tempdir(), "source_role_hint_override")
  dir.create(bundle_path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data.frame(metric = "payment_adjustment_factor", value = 0.98),
    file.path(bundle_path, "summary_table.csv"),
    row.names = FALSE
  )

  spec <- hsr_parser_config(
    artifacts = list(
      role_hints = list(
        payment_summary = c("summary_table")
      )
    )
  )

  source <- hsr_resolve_source(bundle_path, spec = spec)

  expect_identical(source$artifacts$role_hint[[1]], "payment_summary")
})
