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
