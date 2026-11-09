# Changelog

## readmit (development version)

- Canonical production now rejects discharge episodes with
  `discharge_time > as_of_time` before eligibility, risk-provider calls,
  or history writes. A discharge exactly at `as_of_time` remains valid.
- Canonical terminal events now require only `terminal_event_id`,
  `episode_id`, `event_type`, and `occurred_at`. Eligibility uses
  `occurred_at <= as_of_time`; an event-availability timestamp is no
  longer required or interpreted.
- Newly initialized assessment history and
  [`rrp_inspect_history()`](https://readmit.centralstatz.com/reference/rrp_inspect_history.md)
  retain selected terminal-event identity, type, and occurrence time
  without `terminal_available_at`.

## readmit 1.0.0

CRAN release: 2026-11-03

- `readmit` retains its hospital-readmissions focus and evolves from the
  exploratory utilities in 0.0.1 into the Readmission Risk Pool (RRP), a
  project-based framework for repeated readmission risk assessment. This
  revision intentionally changes the public API and moves from MIT to
  Apache License 2.0.
- [`rrp_project_init()`](https://readmit.centralstatz.com/reference/rrp_project_init.md)
  creates a user-owned project with editable configuration,
  source-mapping and risk-provider scripts, branding, and a Shiny
  application. Project authors supply their own clinical data mapping
  and risk logic;
  [`rrp_project_validate()`](https://readmit.centralstatz.com/reference/rrp_project_validate.md)
  checks the authoring structure, and
  [`rrp_state_init()`](https://readmit.centralstatz.com/reference/rrp_state_init.md)
  establishes persistent history.
- [`rrp_run()`](https://readmit.centralstatz.com/reference/rrp_run.md)
  assesses the remaining risk of a first readmission through 30 elapsed
  days after discharge at a chosen analytical time. It applies shared
  eligibility rules to project-supplied canonical data and retains
  accepted estimates, provider failures, and ineligible outcomes. Use
  [`rrp_project_status()`](https://readmit.centralstatz.com/reference/rrp_project_status.md)
  and
  [`rrp_inspect_history()`](https://readmit.centralstatz.com/reference/rrp_inspect_history.md)
  to examine the results.
- [`rrp_refresh_products()`](https://readmit.centralstatz.com/reference/rrp_refresh_products.md)
  derives current remaining risk, recorded risk trajectories, and an
  operational scope summary as CSV files from retained history. The
  project-owned Shiny app opens with empty views before products exist
  and displays them after refresh.
- A short installed getting-started vignette and a reproducible website
  implementation guide demonstrate the project workflow with
  illustrative data and risk logic. No clinically validated prediction
  model is included.

## readmit 0.0.1

CRAN release: 2025-12-19

- Initial CRAN submission.
