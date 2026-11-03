# Run an RRP assessment and retain its history

Run the configured project source mapper at one analytical time,
determine which discharge episodes remain eligible for first readmission
in the remaining 30-day follow-up window, and call the project risk
provider once per eligible episode. Accepted estimates, provider
failures, and ineligible outcomes are retained together as one completed
run.

## Usage

``` r
rrp_run(path, as_of_time)
```

## Arguments

- path:

  Path to an existing RRP project with initialized analytical state.

- as_of_time:

  One finite UTC `POSIXct` analytical instant. This same time is used
  for source production, eligibility, provider requests, and history.

## Value

An ordinary list with `run_id`, `as_of_time`, `episodes_processed`,
`accepted`, `provider_failures`, and `ineligible`. Counts are integers;
the run ID belongs to a successfully committed run.

## Details

Call
[`rrp_state_init()`](https://readmit.centralstatz.com/reference/rrp_state_init.md)
before the first run. The project owner must implement the configured
`rrp_produce_canonical()` and `rrp_calculate_risk()` functions. A
provider failure affects its episode, while a source or persistence
failure stops the run without a partial completed record. Inspect
retained rows with
[`rrp_inspect_history()`](https://readmit.centralstatz.com/reference/rrp_inspect_history.md)
and generate analytical products separately with
[`rrp_refresh_products()`](https://readmit.centralstatz.com/reference/rrp_refresh_products.md).

## Examples

``` r
project <- tempfile("rrp-run-")
rrp_project_init(project, "example-rrp")
time <- as.POSIXct("2026-01-10 12:00:00", tz = "UTC")
episode <- data.frame(
  episode_id = "episode-1", patient_id = "patient-1",
  index_encounter_id = "encounter-1",
  admission_time = time - 2 * 86400, discharge_time = time - 86400
)
events <- data.frame(
  terminal_event_id = character(), episode_id = character(),
  event_type = character(), occurred_at = time[FALSE],
  available_at = time[FALSE]
)
saveRDS(list(discharge_episode = episode, terminal_event = events),
        file.path(project, "canonical.rds"))
# Replace both generated stubs; this constant risk is illustrative only.
writeLines(
  c("rrp_produce_canonical <- function(project_root, as_of_time) {",
    "  readRDS(file.path(project_root, 'canonical.rds'))", "}"),
  file.path(project, "R", "produce-canonical.R")
)
writeLines(
  "rrp_calculate_risk <- function(project_root, request) list(probability = 0.2)",
  file.path(project, "R", "calculate-risk.R")
)
rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp1QHfvZ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
assessment <- rrp_run(project, time)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp1QHfvZ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp1QHfvZ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
assessment$accepted
#> [1] 1
unlink(project, recursive = TRUE)
```
