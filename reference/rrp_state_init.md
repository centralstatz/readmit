# Initialize persistent history for an RRP project

Create `state/history.duckdb` and its empty `runs` and `assessments`
tables for an existing project. This is separate from project creation
and does not execute assessments or generate analytical products.

## Usage

``` r
rrp_state_init(path)
```

## Arguments

- path:

  Path to an existing RRP project that passes structural validation.

## Value

The normalized project path, invisibly.

## Details

Initialization refuses to overwrite any existing `state/` directory.
Project-authored scripts are loaded during structural validation, but
their source-mapping and risk-provider functions are not called.

## Examples

``` r
project <- tempfile("rrp-state-")
rrp_project_init(project, "example-rrp")
rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpBBpqUp/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
unlink(project, recursive = TRUE)
```
