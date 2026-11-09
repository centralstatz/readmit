# readmit v1.1.0 — Implementation Record

- **Project:** `readmit` / Readmission Risk Pool (RRP)
- **Target release:** v1.1.0
- **Current development version:** `1.0.0.9000`
- **Status:** Stages 1–2 complete; v1.1.0 implementation in progress
- **Starting point:** The published v1.0.0 platform and current development source.

## Purpose and boundaries

This living record documents completed v1.1.0 work. The accepted [architecture](architecture.md), [implementation plan](implementation-plan.md), and [assessment](assessments/2026-11-09_v1-1-0-canonical-contract-and-future-discharge-assessment.md) are the primary references. The release is limited to the two accepted GitHub issues and associated documentation, integration, verification, and release work. Compatibility with persisted project state created under v1.0.0 is outside scope. `DESCRIPTION` stays at `1.0.0.9000` through development and candidate verification; the exact `1.1.0` version transition belongs to final release preparation.

The plan defines what remains to be done. This record documents what has actually been done. Add concise, chronological entries within each stage after increments are implemented and verified. Record the changes, meaningful verification and results, relevant commits or references, and any material decisions, deviations, or outstanding issues. Distinguish completed work from pending work without duplicating full test output or prepopulating future stages.

## Stage 1 — Enforce the discharge-time input contract

**Status:** Complete — 2026-11-09.

### Increment 1.1 — Validate discharge time before assessment

**Status:** Complete — 2026-11-09. In `R/canonical-source.R`, `rrp_produce_project_canonical()` now rejects any mapped episode discharged after `as_of_time`, following structural and timestamp checks and before eligibility, provider calls, or history writes. The error names the invalid field, requested time, and an offending episode and its discharge time. Equality remains valid. The terminal-event contract, eligibility logic, and DuckDB behavior were unchanged.

Extended `tests/testthat/test-canonical-source.R` to cover a future discharge in a nonfirst row, error details, and equality. Extended `tests/testthat/test-rrp-run.R` to cover a rejected first run, a mapper-filtered historical run with an episode discharged exactly at assessment time, and a rejected later run followed by a valid one. The first rejection creates no provider request or history rows; the later rejection leaves the provider-request log and complete prior run and assessment rows identical.

**Verification:** With R 4.4.1 and the current source loaded through `pkgload`, all tests in `test-canonical-source.R`, `test-rrp-run.R`, and the unchanged `test-episode-eligibility.R` passed. `git diff --check` passed. No material deviation from the accepted plan or outstanding Stage 1 criterion remains. A package-wide check is reserved for Stage 4.

## Stage 2 — Simplify terminal events and analytical history

**Status:** Complete — 2026-11-09.

### Increment 2.1 — Apply the occurrence-only event contract end to end

**Status:** Complete — 2026-11-09. `R/canonical-source.R` now requires and checks four terminal-event fields and ignores additional `available_at` columns. `R/episode-eligibility.R` selects events by `occurred_at <= as_of_time` and no longer carries `terminal_available_at` into assessment rows. `R/project-history.R` omits that field from new DuckDB assessments tables and writes; the existing reader and `rrp_inspect_history()` return the revised columns from newly initialized state. Event ordering, the fixed 30-day window, provider requests, and Stage 1 future-discharge rejection remain unchanged. No migration or legacy-state handling was added.

Updated the existing canonical, eligibility, run, provider, history, inspection, authoring, product, and refresh `testthat` fixtures and assertions, plus `tests/stage3-installed-workflow.R` and `tests/stage5-installed-workflow.R`. The installed workflows now place the later readmission at its actual later occurrence time, preserving their intended early and later snapshot cases. Extra `available_at` input is tested as an uninterpreted column. New-state schema checks and empty, populated, and filtered inspection checks establish that `terminal_available_at` is absent while selected event identity, type, and UTC occurrence remain.

**Verification:** All nine affected focused `testthat` files passed with R 4.4.1 and `pkgload::load_all()`. A temporary installation of development version `1.0.0.9000` under R 4.6.2 succeeded; both the Stage 3 and Stage 5 installed-workflow scripts passed against it, including the Stage 3 script's product and fresh-process checks and the Stage 5 app smoke checks. The run tests still pass for provider requests and Stage 1 rejection before provider calls or history writes. No acceptance criterion remains open. Public help, examples, templates, and website wording await Stage 3; full documentation rendering and `R CMD check` await later stages.

## Stage 3 — Update project guidance and public documentation

**Status:** In progress — 2026-11-09. Increments 3.1 and 3.2 are complete; Increment 3.3 remains [planned](implementation-plan.md#stage-3--update-project-guidance-and-public-documentation).

### Increment 3.1 — Align generated projects and package reference documentation

**Status:** Complete — 2026-11-09. Updated `inst/project-template/README.md` and the comments in `inst/project-template/R/produce-canonical.R` to state the four-field terminal-event contract, the mapper's `discharge_time <= as_of_time` responsibility and equality boundary, occurrence-only event eligibility, and the absence of a special platform meaning for additional `available_at`. The README now distinguishes private predictor timing from terminal-event eligibility. The provider stub already assigned predictor selection and timing to the project owner and needed no change.

Updated roxygen documentation in `R/canonical-source.R`, `R/project-inspection.R`, and `R/rrp-run.R`, plus typed-empty four-field examples in `R/rrp-run.R` and `R/product-refresh.R`. Regenerated the matching `man/rrp_produce_project_canonical.Rd`, `man/rrp_inspect_history.Rd`, `man/rrp_run.Rd`, and `man/rrp_refresh_products.Rd` from roxygen. The maintainer subsequently ran `devtools::document()`: the working tree now records roxygen 8.1.1 in `DESCRIPTION` and includes its generated author-list change in `man/readmit-package.Rd`. The package version remains `1.0.0.9000`; no analytical function or initializer behavior changed.

**Verification:** A fresh temporary `rrp_project_init()` project had the same file set as the package template; its copied README, mapper comments, and provider comments carried the intended contract and ownership boundaries, and `rrp_project_validate()` passed. `devtools::run_examples()` successfully ran all nine package example files, including history inspection and the run and refresh examples with typed-empty four-field events; the empty inspection output contained selected event identity, type, and occurrence fields without `terminal_available_at`. Reviewed the four generated help diffs against roxygen. No Increment 3.1 criterion or maintainer decision remains open. Tutorial, README, website, and NEWS updates remain in Increments 3.2 and 3.3; integrated package checks remain in Stage 4.

### Increment 3.2 — Update and execute instructional materials

**Status:** Complete — 2026-11-09. `vignettes/getting-started.Rmd` now supplies four-field terminal events and explains the mapper's discharge-time boundary and occurrence-only event timing. Its fixed January 10 example and original assertion still produce one accepted episode, three ineligible episodes, one current-risk row, and one trajectory row.

In `vignettes/articles/implementing-rrp.Rmd`, removed terminal-event availability from simulated extracts, mapper output and filtering, landmark training eligibility, displayed event tables, and history projections. Kept the eight current encounters, historical cohort, event occurrence times, assessment dates, model formula, private `observations$available_at` selection, backfill, product, and app demonstrations. The January 9 E1 readmission now makes E1 ineligible at the January 10 assessment; an executable assertion checks its selected event occurrence and the absence of `terminal_available_at` in new history. The four chronological runs have accepted counts 3, 4, 4, 4; one provider failure each; and ineligible counts 1, 2, 2, 3. Occurrence-only landmark selection yields 1,183 training rows. At January 16, the current pool contains E3, E4, E6, E7, and E8, with E4's estimate unavailable; the operational scope counts eight episodes, four accepted estimates, one provider failure, and one each of readmission, death, and closed-window ineligibility. E3's four trajectory rows include both January 10 runs, and its latest estimate matches the direct saved-model prediction.

**Verification:** Installed development version `1.0.0.9000` into a temporary R library, then rendered both tutorials with `rmarkdown::render()` into a temporary output directory using the declared `html_vignette` format for getting started and `html_document` for the website article. An initial attempt stopped before execution because Pandoc was absent from the shell path; rerunning with the existing `/Applications/quarto/bin/tools` Pandoc succeeded. All tutorial assertions and additional checks of four-field inputs, discharge populations, unchanged occurrence timestamps and assessment chronology, training counts, run dispositions, selected history, private predictor timing, current risk, scope, trajectory, and selected snapshot passed. A separate temporary rerender instrumented only the generated project's provider and confirmed that the January 10 run called it for E2, E3, E4, E6, and E8, exactly the eligible assessment rows; E1 and E5 were not sent. No generated output or project state was left in the repository. No synthetic-data adjustment, platform change, outstanding criterion, or maintainer decision remains. Increment 3.3 owns the README, website, and NEWS alignment; Stage 4 owns integrated package checks.

**Post-completion editorial refinement — 2026-11-09:** Revised the prose in both tutorials for readers new to RRP. The short vignette now introduces the practical reassessment question, walks through the four episode outcomes, explains why only one estimate is requested, labels its formula as arbitrary, and distinguishes retained history from derived CSVs. The Harbor General article now explains the two patient groups and model landmarks before their implementation details; E4 remains eligible even though missing age prevents the hospital's provider from estimating risk, and that failure is neither zero risk nor ineligibility. It also separates assessment date from execution order in the January 10 backfill, explains the three product views and app reload behavior, and keeps private observation availability distinct from event occurrence. Review of the simulation's `death_day < readmit_day` rule and training outcome's `occurred_at_readmission <= occurred_at_death` rule found that a same-time readmission takes precedence over death, consistent with platform event ordering; no code change was needed.

Rendered the getting-started vignette and website article again with `rmarkdown::render()` against a temporary installation of `1.0.0.9000`, using the local `/Applications/quarto/bin/tools` Pandoc and temporary output. All existing assertions passed; the four run summaries, 1,183 training rows, selected history and products, and direct model check matched the earlier verified results. Inspected rendered paragraphs for narrative flow and confirmed all fenced code blocks are byte-for-byte unchanged. Increment 3.2 remains complete; Stage 3 remains in progress with Increment 3.3 planned.

## Stage 4 — Verify the integrated development candidate

**Status:** Not started. No implementation recorded.

## Stage 5 — Prepare and publish v1.1.0

**Status:** Not started. No implementation recorded.
