# RRP project

This directory is your RRP project. You own its configuration, clinical source
integration, risk model, branding, and any application code. Edit and version
these files with your usual R tools.

- `R/produce-canonical.R` is where you read your clinical sources, choose the
  discharge population, and map discharge episodes and terminal events into the
  canonical data expected by `readmit`.
- `R/calculate-risk.R` is where you use your own predictors and model to estimate
  remaining readmission risk for an eligible episode.
- `rrp-project.dcf` identifies the project. `rrp-authoring.dcf` points to the two
  authoring scripts.
- `_brand.yml` and `assets/project-logo.png` provide editable project branding.

From the project directory, `readmit::rrp_project_validate(".")` checks that
the configuration and both authoring functions load. It does not run them or
check clinical data; the initial function stubs pass this structural check.
After implementing both scripts below, validate again. The mapper is an
ordinary R function and may source supporting project-owned scripts. The
package calls it during `rrp_run()`; validation does not inspect its returned
canonical data or guarantee that an assessment will complete.

## Canonical source mapping

Implement `rrp_produce_canonical(project_root, as_of_time)` in
`R/produce-canonical.R`. `as_of_time` is one UTC `POSIXct` analytical instant.
Return a named list with two data frames; both may have zero rows but must keep
their required typed columns:

| Data frame | Required columns |
| --- | --- |
| `discharge_episode` | Character `episode_id`, `patient_id`, `index_encounter_id`; UTC `POSIXct` `admission_time`, `discharge_time`. |
| `terminal_event` | Character `terminal_event_id`, `episode_id`, `event_type`; UTC `POSIXct` `occurred_at`, `available_at`. |

Identifiers and timestamps must be present; identifiers cannot be blank.
`episode_id` and `terminal_event_id` must each be unique. Each terminal event
must refer to a supplied episode, and `event_type` is `readmission` or `death`.
Supply episodes discharged by `as_of_time`. Keep event occurrence (`occurred_at`)
distinct from when the event became known (`available_at`); an event may become
available after `as_of_time`. `readmit` derives the fixed 30-elapsed-day
follow-up endpoint from `discharge_time`; do not supply that column.

Your source mapping owns the clinical definitions and data quality. Keep
source-specific IDs, crosswalks, and private model predictors in project-owned
code and data. You may use more R files under `R/` and source them from the
mapping function with paths built from `project_root`; no registration is needed.

## Risk provider

Implement `rrp_calculate_risk(project_root, request)` in `R/calculate-risk.R`.
The package calls it once per eligible episode. `request` contains that episode's
`episode_id`, `patient_id`, `index_encounter_id`, UTC `POSIXct`
`admission_time`, `discharge_time`, `as_of_time`, and `followup_window_end`, plus
positive `remaining_seconds`. Estimate the probability of its first readmission
strictly after `as_of_time` through the inclusive 30-day endpoint. Use
`project_root` to obtain private predictors and model code; these do not belong
in the shared request.

Return exactly one of `list(probability = 0.24)` (one finite number from 0 to 1,
inclusive) or `list(failure = "Required predictor unavailable")` (one nonblank
reason). The generated function is a deliberate stub until you implement it.
Structural project validation loads this function but does not invoke it.

## Analytical state

Project creation supplies editable files and an empty-state application, but
does not create analytical state. After implementing both scripts and validating
the project, initialize its durable history and run an assessment at one UTC
analytical time:

```r
readmit::rrp_project_validate(".")
readmit::rrp_state_init(".")
assessment <- readmit::rrp_run(
  ".", as.POSIXct("2026-01-10 12:00:00", tz = "UTC")
)
readmit::rrp_project_status(".")
readmit::rrp_inspect_history(".", run_id = assessment$run_id)
```

State initialization creates `state/history.duckdb` with empty run and
assessment tables. It refuses an existing `state/` directory and does not call
your source mapper or risk provider. Each `rrp_run()` call appends a completed
run and its episode outcomes; it does not generate products.
`rrp_project_status()` works before state initialization and reports run count
and the most recently recorded run. `rrp_inspect_history()` requires state and
returns stored assessment rows, with optional exact run and episode filters.
Neither inspection function sources your scripts. The app continues to show
empty views until products are generated in a later increment. A provider
failure is retained for that episode while other eligible episodes continue.
Completed runs append history; later event knowledge does not rewrite earlier
assessment rows.

`readmit` owns the shared analytical target, eligibility rules, history, and
products. You supply the source mapping and prediction engine for your project.
The Shiny application lives under `app/`; its source and styling belong to you.
Its runtime packages are separate from the dependencies needed for `readmit`'s
analytical operations. In the R environment that will run the app, install:

```r
install.packages(c("shiny", "bslib", "yaml"))
```

From the project root, launch it with `shiny::runApp("app")`, or open `app/app.R`
in RStudio and use Run App. The app shows empty views before analytical products
are available.
