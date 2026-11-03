# Getting Started with readmit

Readmission Risk Pool (RRP) estimates the probability of a **first
readmission strictly after an assessment time through 30 elapsed days
after discharge**. The endpoint stays anchored to the original
discharge. `readmit` supplies the project, eligibility, history, and
product operations; the project owner supplies the source mapping and
risk provider.

This small example uses one fixed analytical time and an illustrative
formula. It does not provide a clinically validated model. For source
mapping, a trained assessment-time model, repeated assessments, and
application customization, see [Implementing RRP: A Simulated Hospital
Walkthrough](https://readmit.centralstatz.com/articles/implementing-rrp.html).

## Create a project and supply canonical facts

Initialization creates an ordinary project directory. Its
`R/produce-canonical.R` and `R/calculate-risk.R` scripts are the owner’s
two analytical implementation points. We replace their initial stubs
below.

``` r

project <- rrp_project_init(tempfile("rrp-getting-started-"), "example-rrp")
as_of_time <- as.POSIXct("2026-01-10 12:00:00", tz = "UTC")
discharge_time <- as.POSIXct(c(
  "2026-01-08 12:00:00", "2026-01-01 12:00:00",
  "2025-12-01 12:00:00", "2026-01-04 12:00:00"
), tz = "UTC")
episodes <- data.frame(
  episode_id = paste0("episode-", 1:4),
  patient_id = paste0("patient-", 1:4),
  index_encounter_id = paste0("encounter-", 1:4),
  admission_time = discharge_time - 2 * 86400,
  discharge_time = discharge_time
)
events <- data.frame(
  terminal_event_id = c("event-2", "event-4"),
  episode_id = c("episode-2", "episode-4"),
  event_type = c("readmission", "death"),
  occurred_at = as.POSIXct(c(
    "2026-01-06 12:00:00", "2026-01-07 12:00:00"
  ), tz = "UTC"),
  available_at = as.POSIXct(c(
    "2026-01-07 12:00:00", "2026-01-08 12:00:00"
  ), tz = "UTC")
)
saveRDS(list(discharge_episode = episodes, terminal_event = events),
        file.path(project, "canonical.rds"))
```

All four episodes were discharged by this assessment time. Episode 1 is
still eligible, episode 2 has a known readmission, episode 3 has passed
its original 30-day endpoint, and episode 4 has a known death. The event
occurrence and availability times are separate UTC facts. An operational
source mapper should select the complete relevant discharge population
for *each* assessment time; this saved list is only a one-snapshot
example.

The project-authored mapper reads those typed facts. The provider’s
illustrative probability is 0.30 scaled by the share of the original
30-day interval still remaining. It uses the package’s
`remaining_seconds` request field, so it does not restart the follow-up
window. This formula has no clinical meaning.

``` r

writeLines(c(
  "rrp_produce_canonical <- function(project_root, as_of_time) {",
  "  readRDS(file.path(project_root, 'canonical.rds'))",
  "}"
), file.path(project, "R", "produce-canonical.R"))
writeLines(c(
  "rrp_calculate_risk <- function(project_root, request) {",
  "  list(probability = 0.30 * request$remaining_seconds / (30 * 86400))",
  "}"
), file.path(project, "R", "calculate-risk.R"))
rrp_project_validate(project)
rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
```

[`rrp_project_validate()`](https://readmit.centralstatz.com/reference/rrp_project_validate.md)
checks that required project resources and functions load. It does not
test the supplied data, formula, or clinical suitability.

## Run and inspect an assessment

``` r

assessment <- rrp_run(project, as_of_time)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
assessment[c("episodes_processed", "accepted", "provider_failures", "ineligible")]
#> $episodes_processed
#> [1] 4
#> 
#> $accepted
#> [1] 1
#> 
#> $provider_failures
#> [1] 0
#> 
#> $ineligible
#> [1] 3

status <- rrp_project_status(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
status[c("state_initialized", "run_count")]
#> $state_initialized
#> [1] TRUE
#> 
#> $run_count
#> [1] 1
history <- rrp_inspect_history(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
history[c("episode_id", "disposition", "probability")]
#>   episode_id       disposition probability
#> 1  episode-1          accepted        0.28
#> 2  episode-2 known_readmission          NA
#> 3  episode-3     window_closed          NA
#> 4  episode-4       known_death          NA
stopifnot(assessment$accepted == 1L, assessment$ineligible == 3L,
          isTRUE(all.equal(history$probability[history$disposition == "accepted"],
                           0.28)))
```

The package called the provider only for eligible episode 1 and retained
its 0.28 illustrative estimate. The other three rows explain why those
episodes were ineligible. History remains available for later
inspection.

## Refresh the three products

Products are derived from retained history; refreshing them does not
repeat the assessment or edit the project-owned application.

``` r

products <- rrp_refresh_products(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp69sCom/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
current_risk <- read.csv(products$files[["current_risk"]])
trajectory <- read.csv(products$files[["trajectory"]])
scope <- read.csv(products$files[["scope"]])

current_risk[c("episode_id", "disposition", "probability")]
#>   episode_id disposition probability
#> 1  episode-1    accepted        0.28
trajectory[c("episode_id", "probability")]
#>   episode_id probability
#> 1  episode-1        0.28
scope[c("episodes_assessed", "eligible_count", "accepted_count",
        "known_readmission_count", "known_death_count", "window_closed_count")]
#>   episodes_assessed eligible_count accepted_count known_readmission_count
#> 1                 4              1              1                       1
#>   known_death_count window_closed_count
#> 1                 1                   1
stopifnot(nrow(current_risk) == 1L, nrow(trajectory) == 1L,
          scope$episodes_assessed == 4L)
```

The current-risk CSV contains eligible episode 1; the trajectory CSV
contains its recorded accepted estimate; and the scope CSV counts all
four outcomes. The project-contained Shiny app reads these products.
After installing its runtime packages as listed in the project’s
`README.md`, launch it manually:

``` r

shiny::runApp(file.path(project, "app"))
```
