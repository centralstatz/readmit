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

- **Objective:** Reject canonical discharge episodes whose discharge time is later than the requested assessment time.
- **Scope:** Add a clear check at the existing canonical production boundary and focused regression coverage for rejection, equality, and early failure before provider or history work. Leave eligibility status handling and DuckDB constraints otherwise unchanged.
- **Completion criteria:** A valid discharge at `as_of_time` proceeds normally; a later discharge produces an actionable input error without invoking the provider or adding history; valid historical assessments still run.
- **Dependency:** Begins from the existing working v1.0.0 assessment pipeline and can be verified independently before the wider event-contract change.

### Stage 2 — Simplify terminal events and analytical history

- **Objective:** Make terminal-event occurrence the sole platform time used to decide event-related eligibility.
- **Scope:** Require only event identity, associated episode, type, and `occurred_at`; remove platform interpretation of event availability from canonical checks, eligibility, assessment rows, new DuckDB history, and history inspection. Update focused analytical and persistence tests using newly initialized projects. Preserve event ordering, the fixed 30-day target, provider requests, and existing outcome meanings.
- **Completion criteria:** Four-field terminal-event tables work through assessment and history inspection; events at or before assessment time affect eligibility, later events do not; new persisted and inspected assessments contain selected event identity, type, and occurrence time without an availability field.
- **Dependency:** Follows Stage 1 so the future-discharge correction has its own verified boundary; shared canonical fixtures can then be adapted to the simplified event contract.

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
