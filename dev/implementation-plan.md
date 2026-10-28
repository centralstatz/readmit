# readmit v1.0.0 — High-Level Implementation Plan

## Purpose and approach

This plan describes the current route from the minimal `readmit` R package to a minimally working v1.0.0 release. `dev/architecture.md` describes the current intended product; this plan describes the current intended sequence for building it. Neither document is frozen. Implementation findings may justify simplifying or revising either one, and Git will preserve those changes. Detailed planning occurs one stage at a time, immediately before that stage begins.

Build a complete structural skeleton first, then make its ordinary project workflow work from end to end. Keep the package valid and installable throughout. Use familiar R package tools, direct functions, focused tests, and `R CMD check` after implementation increments. Later stages may be divided, combined, or reordered as the working code clarifies what is needed. Stop when the agreed minimal v1.0.0 functionality works; no separate qualification or change-control system is needed.

## Staged roadmap

### Stage 1 — Complete structural scaffolding

- **Objective:** Establish the full package and project shape before implementing the analytical workflow.
- **Major scope:** Organize package code and documentation around the proposed public R operations; create generic project resources with the two project-authored analytical scripts, configuration, branding, and a project-contained Shiny app. Establish the app's navigation and empty-product behavior.
- **Expected outcome:** The installable package can create a structurally complete user-owned project. Its app can launch and show its normal views with empty states before analytical products exist.
- **Verification:** Install and check the package; inspect the generated project layout and exercise the empty app shell.
- **Dependencies or boundaries:** Begins from the existing package skeleton. Defer canonical processing, risk calculation, persistence, and product generation. No required project registration file or custom installation machinery.

### Stage 2 — Project authoring and canonical source

- **Objective:** Make the two ordinary project authoring points usable.
- **Major scope:** Load project configuration and the supplied source and provider functions; make project validation useful; document the minimal discharge-episode and terminal-event input contract, including the expectation that supplied episodes have been discharged by analytical time `t`. Add only checks needed for operations to proceed.
- **Expected outcome:** A project owner can supply canonical data through the source-mapping script according to a clear contract; the package can use those shared facts for later eligibility and history.
- **Verification:** Focused tests with small test-suite fixtures for project loading, essential structure, and use of the documented canonical input; package check.
- **Dependencies or boundaries:** Requires Stage 1 project files and resources. Defer assessment persistence and products. The project author owns source population, clinical definitions, source quality, and private model predictors; comprehensive contract enforcement is outside this stage.

### Stage 3 — Risk assessment and persistent history

- **Objective:** Execute the fixed remaining-readmission-risk target and retain assessments across runs.
- **Major scope:** Initialize project analytical state; apply analytical time, the 30-day window, and known readmission/death eligibility to canonical episodes processed through the normal workflow; invoke the project risk provider for eligible episodes and check its probability or failure result; retain meaningful accepted, failed, and ineligible outcomes in project-owned history; expose useful run, status, and history reads. Use DuckDB where it naturally fits the established history requirement.
- **Expected outcome:** A user-owned project can execute assessments at more than one analytical time. Its ordinary analytical outcomes and earlier results remain inspectable after later runs.
- **Verification:** Focused tests with small test-suite fixtures for target and eligibility meaning, event availability, provider outcomes, ineligible dispositions, repeated runs, and persisted reads; package check.
- **Dependencies or boundaries:** Requires usable canonical source and provider interfaces from Stage 2. Product publication and app data display remain later stages. Do not add special handling for inappropriate canonical input, validate private predictors, or add a public backup, restore, or history-correction lifecycle.

### Stage 4 — Analytical products

- **Objective:** Turn retained history into the three established analytical product categories.
- **Major scope:** Generate current remaining risk, observed risk trajectories, and operational scope summaries; implement the separate product-refresh operation and write project-owned CSV data under the state area.
- **Expected outcome:** A completed run can produce readable files for analysis and app consumption without executing another assessment. Its scope summary describes the assessed population and retained outcomes.
- **Verification:** Focused checks of product meaning against retained history, including an empty or zero-result case where meaningful; package check.
- **Dependencies or boundaries:** Requires Stage 3 history. The exact source-history selection and physical CSV details can be chosen when this stage begins. Do not add an elaborate freshness framework or modify app source during refresh.

### Stage 5 — Populated Shiny experience

- **Objective:** Connect the already runnable project app to generated analytical products.
- **Major scope:** Read available products into Current Risk Pool, episode trajectory, and Overview views; retain the empty states from Stage 1; support ordinary Shiny launch and the package convenience function.
- **Expected outcome:** After product refresh, a project app displays its generated results. Project owners can edit app code and styling without a later refresh overwriting those files.
- **Verification:** Practical Shiny smoke checks before products and after refresh using small test-suite fixtures; package check.
- **Dependencies or boundaries:** Requires Stage 4 products. The app consumes available products and does not execute analytics, manage deployment, or enforce product freshness.

### Stage 6 — v1.0.0 package completeness

- **Objective:** Bring the working vertical workflow to a coherent, documented package release candidate.
- **Major scope:** Complete public function documentation, generic project guidance, focused automated coverage of important behavior, and ordinary package metadata and dependency declarations needed by the implemented code. Remove temporary scaffolding that no longer serves the package.
- **Expected outcome:** An analyst can install `readmit`, initialize a generic project, supply its source mapping and risk provider, run the normal lifecycle, inspect retained results, generate products, and use the project-owned app.
- **Verification:** A minimal end-to-end public lifecycle using small test-suite fixtures, focused `testthat` tests, a practical app smoke test, and successful `R CMD check`.
- **Dependencies or boundaries:** Requires the preceding working capabilities. Address observed defects and genuine release needs without adding certification, distribution, deployment, or speculative infrastructure.

## Progressive stage planning

Before each stage, inspect the code produced so far and plan only the immediate work needed for that stage. Reassess its scope, dependencies, and verification using actual behavior. If implementation reveals a better route or a material architectural change, update `dev/architecture.md` and this plan together. Future stages remain high-level until their turn; they are not a fixed task inventory.

## v1.0.0 completion criteria

- `readmit` is a valid, installable, conventional R package with documented public project operations.
- A user can initialize an independent project and operate it through the intended lifecycle after supplying source mapping and a risk provider.
- Assessments implement the accepted remaining-readmission-risk meaning, including analytical time, eligibility, and canonical event information availability. Episodes processed through the normal workflow have meaningful, inspectable accepted, failed, or ineligible outcomes.
- Historical assessments and episode dispositions persist across runs and can be inspected.
- Product refresh generates the current-risk, trajectory, and scope-summary outputs from retained history.
- A project-owned Shiny app launches with empty states before products and displays generated products afterward.
- Focused `testthat` tests, a minimal public lifecycle workflow using test-suite fixtures, a practical Shiny smoke test, and `R CMD check` succeed.
