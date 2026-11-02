# Refresh an RRP project's analytical product CSVs

Derive the current clinically eligible risk pool, observed accepted-risk
trajectories, and operational scope from retained assessment history.
The selected completed run has the greatest analytical `as_of_time`;
execution `created_at` and then `run_id` break ties. A later-executed
historical backfill does not replace a newer analytical snapshot.

## Usage

``` r
rrp_refresh_products(path)
```

## Arguments

- path:

  Path to an existing RRP project with initialized analytical state and
  at least one completed assessment run.

## Value

Invisibly, a list with `selected_run_id`, UTC `as_of_time`, and a named
character vector `files` of generated CSV paths. Its keys are
`current_risk` (`current-remaining-risk.csv`), `trajectory`
(`remaining-risk-trajectory.csv`), and `scope`
(`operational-scope-summary.csv`); the paths identify files, not their
in-memory contents.

## Details

Files are written under `state/products/` as
`current-remaining-risk.csv`, `remaining-risk-trajectory.csv`, and
`operational-scope-summary.csv`. The current-risk file includes
clinically eligible provider-failure episodes with a missing
probability, never zero or an earlier estimate. Refresh reads history
only: it does not run the source mapper or provider, add a run, change
retained history, or edit the project-owned app. All files are staged
and checked before replacement. Replacement of the three files is not
fully atomic if a filesystem error occurs during the final replacement
sequence. Call
[`rrp_run()`](https://readmit.centralstatz.com/reference/rrp_run.md) to
retain an assessment first;
[`rrp_inspect_history()`](https://readmit.centralstatz.com/reference/rrp_inspect_history.md)
reads its stored rows.

## Examples

``` r
project <- tempfile("rrp-products-")
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
#> ℹ /tmp/RtmprfLUlN/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
rrp_run(project, time)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmprfLUlN/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmprfLUlN/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> $run_id
#> [1] "c20ef266-2c00-453c-83f9-4f4710b9fcf2"
#> 
#> $as_of_time
#> [1] "2026-01-10 12:00:00 UTC"
#> 
#> $episodes_processed
#> [1] 1
#> 
#> $accepted
#> [1] 1
#> 
#> $provider_failures
#> [1] 0
#> 
#> $ineligible
#> [1] 0
#> 
products <- rrp_refresh_products(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmprfLUlN/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
names(products$files)
#> [1] "current_risk" "trajectory"   "scope"       
file.exists(products$files)
#> [1] TRUE TRUE TRUE
unlink(project, recursive = TRUE)
```
