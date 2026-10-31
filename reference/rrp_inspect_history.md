# Inspect completed RRP assessments

Read retained assessment rows and their run context without sourcing or
invoking project-authored analytical functions. Both optional filters
use exact identifier matching and may be combined.

## Usage

``` r
rrp_inspect_history(path, run_id = NULL, episode_id = NULL)
```

## Arguments

- path:

  Path to an existing RRP project with initialized state.

- run_id:

  Optional single nonblank run ID to select.

- episode_id:

  Optional single nonblank episode ID to select.

## Value

An ordinary data frame containing stored assessment identity, times,
disposition, probability, failure detail, selected terminal-event
context, and associated run metadata. Empty results retain the same
columns and types, including UTC `POSIXct` timestamps.

## Details

Initialize state with
[`rrp_state_init()`](https://readmit.centralstatz.com/reference/rrp_state_init.md)
before inspecting history. Rows are ordered by run creation time, run
ID, and episode ID. Reads use a read-only connection and never create
state or modify history. A completed run with zero episodes contributes
no assessment row.

## Examples

``` r
project <- tempfile("rrp-inspect-")
rrp_project_init(project, "example-rrp")
rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpAUS4yQ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
rrp_inspect_history(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpAUS4yQ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#>  [1] run_id                episode_id            patient_id           
#>  [4] index_encounter_id    admission_time        discharge_time       
#>  [7] followup_window_end   disposition           probability          
#> [10] failure_kind          failure_reason        terminal_event_id    
#> [13] terminal_event_type   terminal_occurred_at  terminal_available_at
#> [16] project_id            as_of_time            created_at           
#> [19] source_mapping_script risk_provider_script 
#> <0 rows> (or 0-length row.names)
unlink(project, recursive = TRUE)
```
