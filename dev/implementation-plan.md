# readmit v1.0.0 — High-Level Implementation Plan

## Purpose and approach

This plan describes the current route from the minimal `readmit` R package to a minimally working v1.0.0 release. `dev/architecture.md` describes the current intended product; this plan describes the current intended sequence for building it. Neither document is frozen. Implementation findings may justify simplifying or revising either one, and Git will preserve those changes. Detailed planning occurs one stage at a time, immediately before that stage begins.

Build a complete structural skeleton first, then make its ordinary project workflow work from end to end. Keep the package valid and installable throughout. Use familiar R package tools, direct functions, focused tests, and `R CMD check` after implementation increments. Later stages may be divided, combined, or reordered as the working code clarifies what is needed. Stop when the agreed minimal v1.0.0 functionality works; no separate qualification or change-control system is needed.

## Staged roadmap

### Stage 1 — Complete structural scaffolding

- **Objective:** Establish the full package and project shape before implementing the analytical workflow.
- **Major scope:** Organize package code and documentation around the proposed public R operations; create generic and reference project resources with the two project-authored analytical scripts, configuration, branding, and a project-contained Shiny app. Establish the app's navigation and empty-product behavior.
- **Expected outcome:** The installable package can create structurally complete user-owned projects. Their app can launch and show its normal views with empty states before analytical products exist. The reference copy includes synthetic source resources, even though its analytical workflow is developed in later stages.
- **Verification:** Install and check the package; inspect both generated project layouts and exercise the empty app shell.
- **Dependencies or boundaries:** Begins from the existing package skeleton. Defer canonical processing, risk calculation, persistence, and product generation. No required project registration file or custom installation machinery.

### Stage 2 — Project authoring and canonical source

- **Objective:** Make the two ordinary project authoring points usable.
- **Major scope:** Load project configuration and the supplied source and provider functions; make project validation useful; implement the minimum discharge-episode and terminal-event canonical data behavior, including analytical time and event availability. Complete the synthetic reference source mapping.
- **Expected outcome:** A generic project can supply canonical source data through its own R script, and the reference project can do so without user programming.
- **Verification:** Focused tests for project loading, essential structure, and canonical source meaning; package check.
- **Dependencies or boundaries:** Requires Stage 1 project files and resources. Defer assessment persistence and products. Keep private model predictors outside the canonical data.

### Stage 3 — Risk assessment and persistent history

- **Objective:** Execute the fixed remaining-readmission-risk target and retain assessments across runs.
- **Major scope:** Initialize project analytical state; determine episode eligibility from canonical data; invoke the project risk provider; retain accepted probabilities and other outcomes in project-owned history; expose useful run, status, and history reads. Use DuckDB where it naturally fits the established history requirement.
- **Expected outcome:** The reference project can execute assessments at more than one analytical time, and earlier results remain inspectable after later runs.
- **Verification:** Focused tests for target and eligibility meaning, provider results, repeated runs, and persisted reads; package check.
- **Dependencies or boundaries:** Requires usable canonical source and provider interfaces from Stage 2. Product publication and app data display remain later stages. No public backup, restore, or history-correction lifecycle is added.

### Stage 4 — Analytical products

- **Objective:** Turn retained history into the three established analytical product categories.
- **Major scope:** Generate current remaining risk, observed risk trajectories, and operational scope summaries; implement the separate product-refresh operation and write project-owned CSV data under the state area.
- **Expected outcome:** A completed reference run can produce readable files for analysis and app consumption without executing another assessment.
- **Verification:** Focused checks of product meaning against retained history, including an empty or zero-result case where meaningful; package check.
- **Dependencies or boundaries:** Requires Stage 3 history. The exact source-history selection and physical CSV details can be chosen when this stage begins. Do not add an elaborate freshness framework or modify app source during refresh.

### Stage 5 — Populated Shiny experience

- **Objective:** Connect the already runnable project app to generated analytical products.
- **Major scope:** Read available products into Current Risk Pool, episode trajectory, and Overview views; retain the empty states from Stage 1; support ordinary Shiny launch and the package convenience function.
- **Expected outcome:** After product refresh, the reference app displays its generated results. Project owners can edit app code and styling without a later refresh overwriting those files.
- **Verification:** Practical Shiny smoke checks before products and after refresh, plus a short reference-project walkthrough; package check.
- **Dependencies or boundaries:** Requires Stage 4 products. The app consumes available products and does not execute analytics, manage deployment, or enforce product freshness.

### Stage 6 — v1.0.0 package completeness

- **Objective:** Bring the working vertical workflow to a coherent, documented package release candidate.
- **Major scope:** Complete public function documentation, project and reference guidance, focused automated coverage of important behavior, and ordinary package metadata and dependency declarations needed by the implemented code. Remove temporary scaffolding that no longer serves the package.
- **Expected outcome:** An analyst can install `readmit`, initialize and operate the synthetic reference project through the normal lifecycle, inspect retained results, generate products, and use the project-owned app.
- **Verification:** A minimal end-to-end reference workflow, focused `testthat` tests, practical app smoke test, and successful `R CMD check`.
- **Dependencies or boundaries:** Requires the preceding working capabilities. Address observed defects and genuine release needs without adding certification, distribution, deployment, or speculative infrastructure.

## Progressive stage planning

Before each stage, inspect the code produced so far and plan only the immediate work needed for that stage. Reassess its scope, dependencies, and verification using actual behavior. If implementation reveals a better route or a material architectural change, update `dev/architecture.md` and this plan together. Future stages remain high-level until their turn; they are not a fixed task inventory.

## v1.0.0 completion criteria

- `readmit` is a valid, installable, conventional R package with documented public project operations.
- A user can initialize and operate an independent project through the intended lifecycle. The bundled synthetic reference project runs without extra source preparation or custom programming.
- Assessments implement the accepted remaining-readmission-risk meaning, including analytical time, eligibility, and information availability.
- Historical assessments persist across runs and can be inspected.
- Product refresh generates the current-risk, trajectory, and scope-summary outputs from retained history.
- A project-owned Shiny app launches with empty states before products and displays generated products afterward.
- Focused `testthat` tests, a minimal reference-project end-to-end workflow, a practical Shiny smoke test, and `R CMD check` succeed.
