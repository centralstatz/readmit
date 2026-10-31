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
For operational assessments, supply the complete relevant discharge cohort each
time. `readmit` applies its eligibility rules to those episodes; your source
query need not reproduce them. A later partial run can become the selected
current snapshot without merging episodes from an earlier run.

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
readmit::rrp_refresh_products(".")
```

State initialization creates `state/history.duckdb` with empty run and
assessment tables. It refuses an existing `state/` directory and does not call
your source mapper or risk provider. Each `rrp_run()` call appends a completed
run and its episode outcomes; it does not generate products.
`rrp_project_status()` works before state initialization and reports run count
and the most recently recorded run. `rrp_inspect_history()` requires state and
returns stored assessment rows, with optional exact run and episode filters.
Neither inspection function sources your scripts. A provider failure is
retained for that episode while other eligible episodes continue.
Completed runs append history; later event knowledge does not rewrite earlier
assessment rows.

After at least one completed run, `rrp_refresh_products()` derives three CSVs
under `state/products/` from retained history. It selects the run with the
greatest analytical `as_of_time`, not necessarily the most recently executed
run. `current-remaining-risk.csv` includes every clinically eligible episode;
provider failures have a missing probability, not zero or an earlier estimate.
`remaining-risk-trajectory.csv` contains only recorded accepted estimates for
those current eligible episodes, and `operational-scope-summary.csv` counts all
outcomes in the selected run. Read the files with ordinary CSV tools, for example
`read.csv("state/products/current-remaining-risk.csv")` from the project root.
Refresh does not invoke your mapper or provider,
change history, or edit the app. Its three-file replacement is staged but not
fully atomic if a filesystem error occurs during final replacement.

`readmit` owns the shared analytical target, eligibility rules, history, and
products. You supply the source mapping and prediction engine for your project.
The Shiny application lives under `app/`; its source and styling belong to you.
Its runtime packages are separate from the dependencies needed for `readmit`'s
analytical operations. In the R environment that will run the app, install:

```r
install.packages(c("shiny", "bslib", "reactable", "plotly", "yaml"))
```

From the project root, launch it with `shiny::runApp("app")`, or open `app/app.R`
in RStudio and use Run App. The app reads generated CSVs at launch. **Reload Data**
rereads those files while the app is open; it does not run an assessment
or regenerate products. Run `readmit::rrp_refresh_products(".")` separately
after assessments to update the files.

The Current Risk Pool shows every clinically eligible episode in the selected
snapshot, including provider failures. Accepted probabilities appear as
percentages and fixed-scale bars from 0% to 100%; bar color is a visual aid, not
a clinical risk category. A true 0% has a numeric label and an empty bar. A
failed estimate says **Unavailable** and has no bar; an older estimate is never
used as its current value. The selected analytical time is shown above the
pool. Click a column heading to sort, use **Find episode ID** to search, and
adjust **Current probability range** to filter numeric estimates. Failed
predictions remain visible under that range filter. The count above the table
shows displayed rows against all eligible episodes. Clicking a row highlights
its episode and opens its detail card. The card labels the **current** estimate
separately from recorded **historical** accepted assessments. Plotly markers
show those assessments at their analytical times; hover shows UTC time, risk,
and run ID. The small table lists every observation, including separate runs
with the same time or probability. Table sparklines use only those accepted
observations on a fixed 0% to 100% scale; a faint connector guides the eye but
does not represent estimates between assessments. A failed current prediction
remains **Unavailable** even when its episode has earlier accepted history.

**No history** means the available trajectory product has no accepted
observations for that episode. **History unavailable** means the trajectory
CSV is missing, invalid, or incompatible with the current snapshot; the
current pool remains usable. **Reload Data** rereads both current and historical
CSV rows, updating the detail and sparklines. It keeps an episode selected only
while that episode remains visible.

**Overview** summarizes the selected analytical snapshot, not live status.
**Episodes assessed** counts every episode considered in the selected run:
eligible plus ineligible. Eligible episodes comprise accepted estimates and
provider failures; the ineligible breakdown is closed follow-up windows, known
readmissions, and known deaths. Minimum, median, and maximum remaining risk use
only accepted **current** numerical estimates. Missing predictions and older
historical estimates do not enter those statistics; no accepted estimates
produce an explicit empty summary, not zero-valued risk. Pool search, sorting,
range filtering, and selection do not change Overview. **Reload Data** updates
it from the reread CSVs. If scope or current risk is missing, invalid, or from
another snapshot, its area is marked unavailable while an independent valid
area remains visible.

The branded app launches normally before products exist and explains the empty
state. A completed snapshot with zero eligible episodes shows a distinct empty
pool. If an existing CSV cannot be read or products disagree on their selected
snapshot, the app shows a named data message while keeping independent valid
regions available where possible. Your app code and styling remain editable and
are not overwritten by analytical runs or product refreshes.
