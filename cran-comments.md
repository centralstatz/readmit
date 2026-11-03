## Submission context

This updates the existing CRAN `readmit` package, released as 0.0.1. The package
retains its hospital-readmissions focus while evolving from exploratory
readmission-data and reporting utilities into the Readmission Risk Pool (RRP),
a project-based framework for repeated risk assessment. The public API is
intentionally changed. The license changes from MIT to Apache License 2.0;
current author, maintainer, and copyright attribution are in `DESCRIPTION`.

## R CMD check results

During Stage 6.6, a local source build and `R CMD check --no-manual` completed
with Status: OK, including examples, tests, and vignette rebuilding. The
maintainer also reports successful `devtools::test()` and `devtools::check()`
after Stage 6.6; their logs were not independently reviewed for these comments.
Final development-candidate and exact release-version CRAN-oriented checks have
not yet been performed. This section will be reconciled with their actual
results before submission.

## CRAN checks and reverse dependencies

On 2026-11-03, the [CRAN package page](https://cran.r-project.org/package=readmit)
listed version 0.0.1. The [CRAN check page](https://cran.r-project.org/web/checks/check_results_readmit.html),
updated 2026-11-03 21:00 CET, showed five OK and eight ERROR results for that
version. The detailed errors involve its earlier `pdc_read()` examples and
tests failing to retrieve CMS data (HTTP 403). That function is absent from
the revised RRP API; the new source requires its own checks.

A 2026-11-03 lookup of the [CRAN `PACKAGES.gz` index](https://cran.r-project.org/src/contrib/PACKAGES.gz) using
`tools::package_dependencies()` found no packages that depend on, import,
link to, suggest, or enhance `readmit`. Recheck this context with the final
candidate and report any changed result before submission.
