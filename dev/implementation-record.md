# readmit v1.1.0 — Implementation Record

- **Project:** `readmit` / Readmission Risk Pool (RRP)
- **Target release:** v1.1.0
- **Current development version:** `1.0.0.9000`
- **Status:** Stage 1 complete; v1.1.0 implementation in progress
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

**Status:** Detailed plan established; implementation not started. See [Stage 2 in the implementation plan](implementation-plan.md#stage-2--simplify-terminal-events-and-analytical-history).

## Stage 3 — Update project guidance and public documentation

**Status:** Not started. No implementation recorded.

## Stage 4 — Verify the integrated development candidate

**Status:** Not started. No implementation recorded.

## Stage 5 — Prepare and publish v1.1.0

**Status:** Not started. No implementation recorded.
