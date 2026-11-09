# readmit v1.1.0 — High-Level Implementation Plan

- **Target release:** `readmit` v1.1.0
- **Current development version:** `1.0.0.9000`
- **Status:** Proposed / Pending maintainer review
- **Starting point:** The published v1.0.0 RRP platform is implemented; its project lifecycle, provider interface, history, products, Shiny app, and release procedure are already in place.

## Purpose and approach

This living plan covers only the remaining work needed to deliver v1.1.0. The [architecture](architecture.md) defines the target platform; the [v1.1.0 assessment](assessments/2026-11-09_v1-1-0-canonical-contract-and-future-discharge-assessment.md) identifies the changes from the current implementation. The release scope is [Issue #26](https://github.com/centralstatz/readmit/issues/26), [Issue #27](https://github.com/centralstatz/readmit/issues/27), and the integration, documentation, verification, and publication those changes require.

Use Structure Before Sophistication: make focused changes to the existing workflow, preserve unaffected behavior, and use conventional R package checks. Detail only the next stage after the preceding stage is completed and verified. Keep `DESCRIPTION` at `1.0.0.9000` through development and candidate verification; set the exact release version only during final release preparation.

## Staged roadmap

### Stage 1 — Enforce the discharge-time input contract

- **Status:** Complete — 2026-11-09. See the [implementation record](implementation-record.md#stage-1--enforce-the-discharge-time-input-contract).
- **Objective:** Reject canonical discharge episodes whose discharge time is later than the requested assessment time.
- **Scope:** Add a clear check at the existing canonical production boundary and focused regression coverage for rejection, equality, and early failure before provider or history work. Leave eligibility status handling and DuckDB constraints otherwise unchanged.
- **Completion criteria:** A valid discharge at `as_of_time` proceeds normally; a later discharge produces an actionable input error without invoking the provider or adding history; valid historical assessments still run.
- **Dependency:** Begins from the existing working v1.0.0 assessment pipeline and can be verified independently before the wider event-contract change.

#### Increment 1.1 — Validate discharge time before assessment

- **Status:** Complete — 2026-11-09; implementation and focused verification are recorded in the implementation record.
- **Objective:** Enforce `discharge_episode$discharge_time <= as_of_time` for every episode returned by the project mapper. Reject an invalid canonical result rather than filtering episodes or recording another disposition.
- **Implementation scope:** In `R/canonical-source.R`, check discharge times in `rrp_produce_project_canonical()` after `rrp_check_canonical_source()` has established the required columns and finite UTC timestamps. Report `discharge_episode$discharge_time`, `as_of_time`, and at least one offending `episode_id` in a clear input error. Keep the check before `rrp_run()` calls eligibility, the risk provider, or `rrp_write_history()`. Leave the current terminal-event `available_at` contract, eligibility statuses (including internal `not_yet_discharged`), DuckDB schema and constraints, and transaction handling unchanged.
- **Regression coverage:** Extend the existing canonical-source and integrated-run tests with a future discharge, a discharge exactly at `as_of_time`, and a valid historical assessment whose mapper returns only episodes discharged by that time. For the rejected first run, establish that no provider request or completed run/assessment is created. Adapt the existing later-run failure test to assert the informative upstream error, no provider call for the rejected attempt, and unchanged prior runs and assessment rows; a subsequent valid run should still succeed. Use current five-field terminal-event fixtures so this increment remains independent of Stage 2.
- **Verification:** Run focused `testthat` coverage for `test-canonical-source.R` and `test-rrp-run.R`, including the existing `test-episode-eligibility.R` checks that protect the unchanged internal pre-discharge behavior. Review the source call order and resulting history counts to confirm the error precedes eligibility, provider invocation, and persistence. No package-wide check is needed for this focused increment; Stage 4 covers integrated candidate checks.
- **Completion criteria:** The focused tests pass; equality and historical runs succeed; a later discharge names the invalid field, assessment time, and offending episode; rejected attempts invoke no provider and leave both empty and previously completed history unchanged. Record the implementation and actual verification in the implementation record before marking Stage 1 complete.

### Stage 2 — Simplify terminal events and analytical history

- **Objective:** Make terminal-event occurrence the sole platform time used to decide event-related eligibility.
- **Scope:** Require only event identity, associated episode, type, and `occurred_at`; remove platform interpretation of event availability from canonical checks, eligibility, assessment rows, new DuckDB history, and history inspection. Update focused analytical and persistence tests using newly initialized projects. Preserve event ordering, the fixed 30-day target, provider requests, and existing outcome meanings.
- **Completion criteria:** Four-field terminal-event tables work through assessment and history inspection; events at or before assessment time affect eligibility, later events do not; new persisted and inspected assessments contain selected event identity, type, and occurrence time without an availability field.
- **Dependency:** Follows Stage 1 so the future-discharge correction has its own verified boundary; shared canonical fixtures can then be adapted to the simplified event contract.

#### Increment 2.1 — Apply the occurrence-only event contract end to end

- **Objective:** Make a four-field terminal-event table usable from canonical production through assessment, newly initialized history, and inspection without an event-availability field.
- **Implementation scope:** In `R/canonical-source.R`, require and validate only `terminal_event_id`, `episode_id`, `event_type`, and UTC `occurred_at`; retain identity, reference, type, typed-empty, and additional-column checks, as well as Stage 1's `discharge_time <= as_of_time` check. In `R/episode-eligibility.R`, select events using `occurred_at <= as_of_time` alone and remove `terminal_available_at` from eligibility rows. Preserve the 30-day endpoint, window precedence, earliest-occurrence ordering, readmission/death tie rules, dispositions, and internal pre-discharge behavior. The existing provider assessment passes eligibility rows through; verify that this smaller row shape reaches persistence without changing provider requests or `rrp_run()` orchestration. In `R/project-history.R`, omit `terminal_available_at` from the new `assessments` table and writer field/type lists. Verify `rrp_inspect_history()` returns the revised columns through the existing history reader; no old-schema projection or migration is needed.
- **Regression coverage:** Adapt `test-canonical-source.R` for four-field nonempty and typed-empty event tables, required-field/UTC occurrence checks, and extra columns, including an `available_at` column that receives no special validation or interpretation. Adapt `test-episode-eligibility.R` for events before, exactly at, and after `as_of_time`, including an earlier occurrence with a later extra `available_at` value; retain closed-window precedence, death competition, deterministic ties, and typed empty output. Update the shared fixtures and expected outcomes in `test-rrp-run.R`, `test-provider-assessment.R`, `test-project-history.R`, `test-project-inspection.R`, and `test-authoring-workflow.R` to cover the smaller assessment shape, unchanged provider request, persisted selected event identity/type/occurrence, empty history, and inspection with and without filters. Adapt directly affected product and installed-workflow fixtures and assertions (`test-analytical-products.R`, `test-product-refresh.R`, `tests/stage3-installed-workflow.R`, and `tests/stage5-installed-workflow.R`) where they supply or expect availability; retain their product and workflow meanings. Use newly initialized projects and state throughout persistence and integration tests.
- **Verification:** Run the affected focused `testthat` files and the directly affected installed-workflow checks against a temporary installed development package. Confirm the fresh DuckDB `assessments` schema, written rows, and `rrp_inspect_history()` output omit `terminal_available_at` while retaining selected event identity, type, and UTC occurrence time. Confirm four-field events flow through `rrp_run()`, provider calls still match eligible episodes, Stage 1 future-discharge rejection still works, and product calculations/CSV meanings remain intact. Review the diff for availability interpretation outside user-owned predictor code. Full documentation rendering and `R CMD check` belong to later stages.
- **Completion criteria:** Focused and installed-workflow verification passes on fresh projects; occurrence-only timing gives the expected outcomes at all three assessment-time boundaries; four-field and extra-column canonical inputs behave as specified; new history and inspection expose no event-availability field; selected event context, provider requests, Stage 1 validation, and unaffected analytical behavior remain correct. Record the actual implementation and evidence before marking Stage 2 complete.

This is one increment because canonical validation, eligibility rows, history writes, and the new database schema must agree for an assessment to complete. Stage 3 will update project templates, package help/examples, tutorials, READMEs, NEWS, and website wording. No v1.0.0 database migration, legacy inspection handling, old-state compatibility test, active rejection or deletion of older state, replacement availability concept, or project-owned predictor-timing change is part of Stage 2.

### Stage 3 — Update project guidance and public documentation

- **Objective:** Present the revised v1.1.0 contract consistently to project authors and package users.
- **Scope:** Update the generated project guidance, package help and examples, READMEs, installed vignette, executable synthetic walkthrough, website source, and development NEWS. Revise examples and narrative whose results change under occurrence-only eligibility. Keep project-owned predictor timing separate from platform terminal-event semantics.
- **Completion criteria:** User-facing materials and generated project resources describe the four required event fields, occurrence-based eligibility, and the discharge-time input rule; worked examples execute with their stated results; the website presentation remains coherent without a new information-availability framework.
- **Dependency:** Follows the settled analytical behavior in Stage 2 so examples and explanations reflect the implemented contract.

### Stage 4 — Verify the integrated development candidate

- **Objective:** Establish that the complete v1.1.0 behavior works across the existing project lifecycle before changing the package version.
- **Scope:** Exercise a newly initialized project from canonical mapping through assessment, history inspection, product refresh, and empty and populated Shiny views. Verify documentation and website output, run focused tests and conventional package checks, review actual findings, and prepare the release candidate and applicable CRAN-facing information.
- **Completion criteria:** The development-version source passes the relevant integrated workflow, documentation, Shiny smoke, and `R CMD check` gates; the release candidate and any material limitations are reviewed. `DESCRIPTION` remains `1.0.0.9000`.
- **Dependency:** Follows the core and documentation stages; candidate verification assesses their combined result without rebuilding unaffected platform components.

### Stage 5 — Prepare and publish v1.1.0

- **Objective:** Carry the verified candidate through the established CRAN and GitHub release procedure.
- **Scope:** Set and review the exact `1.1.0` version and release metadata only at final preparation; build and check the committed release-version source; submit and confirm the CRAN submission with maintainer approval; respond to actual CRAN correspondence if needed. After acceptance, publish the matching GitHub tag/release, update public release-status wording, verify publication, and return to the development version derived from the accepted release.
- **Completion criteria:** CRAN has accepted a known version and source commit; the matching GitHub release and tag are verified; public status is accurate; the next development version and temporary submission-record disposition follow [the release procedure](release-procedure.md).
- **Dependency:** Requires an approved Stage 4 candidate. CRAN acceptance precedes GitHub publication and the subsequent development-version transition.

## Scope and planning boundaries

The two issues are separate workstreams even where they share canonical source files and tests. Additional canonical columns remain permitted but have no special event-availability meaning. Compatibility with project databases or persisted state created under v1.0.0 is outside scope: do not plan migration, schema detection, conditional inspection, or old-database compatibility tests. Use new project state for integration verification.

The existing remaining-readmission-risk estimand, user-owned project structure, provider interface, analytical products, Shiny app, and public operations remain in place. No replacement availability mechanism, new feature, generalized validation framework, broad persistence refactor, or custom release process is planned. Detailed increments will be defined only for the next stage after this high-level roadmap is accepted.
