# readmit v1.0.0 — High-Level Implementation Plan

## Purpose and approach

This plan describes the current route from the minimal `readmit` R package to a minimally working v1.0.0 release. `dev/architecture.md` describes the current intended product; this plan describes the current intended sequence for building it. Neither document is frozen. Implementation findings may justify simplifying or revising either one, and Git will preserve those changes. Detailed planning occurs one stage at a time, immediately before that stage begins.

Build a complete structural skeleton first, then make its ordinary project workflow work from end to end. Keep the package valid and installable throughout. Use familiar R package tools, direct functions, focused tests, and `R CMD check` after implementation increments. Later stages may be divided, combined, or reordered as the working code clarifies what is needed. Stop when the agreed minimal v1.0.0 functionality works; no separate qualification or change-control system is needed.

## Staged roadmap

### Stage 1 — Complete structural scaffolding

**Objective and boundary.** Make an installable package that creates the complete generic project described in the architecture. The generated, user-owned app must launch directly through Shiny with its intended navigation, styling, and useful empty states. Implement `rrp_project_init()` now; add other public operations when their stages begin. Stage 1 does not process canonical data, execute a provider, determine eligibility, create DuckDB state or products, or populate analytical views. It does not create a reference project, package-specific app launcher, or deployment workflow.

**Starting point.** Stage 1 began from a conventional package skeleton: `DESCRIPTION` (R >= 4.1, roxygen2 and `testthat` configured), `NAMESPACE`, one package-level file at `R/readmit-package.R`, generated package help, and a single load test at `tests/testthat/test-readmit.R`. `README.Rmd`, a package logo, and pkgdown assets were present; no project template or exported project operation existed. Add package dependencies only for actual package use. Document the generated app's own runtime dependencies in its project README rather than declaring them in `readmit` merely because the template contains app code.

**Historical design to carry forward.** The historical repository is a user-facing reference, with these specific files worth consulting during implementation:

| Area | Retain or adapt | Simplify or exclude |
| --- | --- | --- |
| App: `resources/application/portable/R/application-ui.R` and `www/rrp.css` | The `bslib` navbar with **Current Risk Pool** and **Overview**, project identity in the header, page introductions, card layout for accepted estimates and an episode trajectory, overview summary area, responsive navy/teal styling, and readable empty-state treatment. Keep these as the Stage 5 display regions. | The historical UI assumes loaded products; its search, filters, paging, `reactable` table, `plotly` chart, status/freshness banner, and count reconciliation depend on later data and need not appear as inactive controls in Stage 1. Reimplement the shell in direct Shiny code. |
| App operation: `resources/application/standalone/app.R`, `resources/application/portable/R/application-server.R`, and `product-loader.R` | A project-contained `app.R` with local supporting R and CSS files, and an app that reads generated products only when available. | The historical app requires a product snapshot and uses managed loaders, product contracts, integrity checks, and freshness logic. Stage 1 must launch with no state or products; defer ordinary CSV reading and populated interactions to Stage 5. |
| Project: `resources/templates/project/` and `packages/rrpplatform/R/project-initializer.R` | The two DCF files, `_brand.yml`, shield/trajectory logo, README, two normal authoring scripts, explicit project destination, and copying editable resources into a user-owned directory. | Omit `R/register.R`, extension-library fields, catalog and contract machinery, complex staging/proof routines, synthetic source, and platform-specific project management. Preserve the recognizable authoring experience with concise guidance and direct file copying. |
| Authoring: `resources/templates/project/R/produce-canonical.R` and `calculate-risk.R` | Function names, explicit `project_root`, analytical-time argument for the source mapper, and assessment request for the provider. Explain that local source access and model inputs belong in these scripts. | Remove exact historical envelopes, request schemas, version declarations, `rrpplatform` failure helpers, and the old predictor-timing rule. The generated functions should clearly signal that the owner must supply their implementation; they should not fabricate results. |

**Stage 1 design decisions.** Make these practical choices while implementing the increments; none requires a separate architecture change or maintainer decision before work starts.

| Decision | Options and recommendation | When |
| --- | --- | --- |
| Template location | Store ordinary files under a single `inst/` project-template directory, accessed with `system.file()`, rather than embedding long file contents in R code. This makes the installed copy inspectable and easy to copy. | Increment 1 |
| Initialization behavior | Accept an explicit destination, require it to be absent, copy the template tree with base R, substitute only a few project identity/branding values, and report copy failures plainly. Avoid the historical resource catalog and project-generation framework. Settle the small initializer argument set with its roxygen documentation. | Increment 3 |
| App root and branding | Have `app.R` use its project-contained location to find the parent project's `_brand.yml` and logo, with local app CSS in `app/www/`. Use conventional Shiny static-resource handling and a small YAML reader if needed; avoid an installed-package loader or encoded logo pipeline. | Increment 2 |
| App dependencies and structure | Use `shiny` and `bslib` for the real shell, with supporting files under `app/R/` only if useful. Document the app's actual dependencies in the generated project; distributing app templates alone does not require them in `readmit`'s `Imports` or `Suggests`. Defer `reactable`, `plotly`, and product-reading code until populated views need them. | Increment 2 |
| Public API timing | Export and document `rrp_project_init()` when functional. Leave later-stage operations absent until implemented, rather than create placeholder modules or simulated results. | Increment 3 |

**Ordered implementation increments.** Each increment should leave the package installable and be reviewed before extending it.

1. **Project authoring resources.** Add installed templates for `README.md`, `rrp-project.dcf`, `rrp-authoring.dcf`, `_brand.yml`, `assets/project-logo.png`, and the two scripts under `R/`. Use the historical project templates above for recognizable roles, but keep DCF fields and script comments limited to Stage 1 needs. The script functions should identify their future inputs and stop with a clear "project author must implement" message. **Deliverable:** an inspectable template that explains where source mapping and model code belong. **Verify:** installed resource paths and file contents are present after package installation; template scripts parse. **Boundary:** no canonical schema, dispatch, registration, source data, or working provider is finalized here.
2. **Permanent empty-state app shell.** Add `app/app.R`, small supporting source under `app/R/` as useful, and styling under `app/www/`. Adapt the historical navbar, brand treatment, risk-pool/trajectory arrangement, overview region, and responsive CSS. Show specific empty messages where current estimates, trajectory observations, and overview summaries will later appear; keep the interface coherent without nonfunctional filters or fabricated numbers. Document the app's actual runtime packages and how the project owner installs them. **Deliverable:** independently runnable, project-owned app files that the initializer will copy and Stage 5 will populate. **Verify:** launch the app directly with `shiny::runApp()` from a template-shaped project with no `state/` or products; navigate both pages and inspect their empty regions and branding. **Boundary:** no product loader, analytical calls, data-driven table/chart, freshness state, deployment code, or package dependency declarations based solely on distributed app files.
3. **Project initializer.** Add a direct R function for `rrp_project_init()` and its roxygen documentation, declaring package dependencies according to actual package use. Initialization copies the complete template into a new explicit destination, fills basic identity/branding values, leaves every generated file editable, and creates no `source/`, `state/`, or products. Use the current `R/readmit-package.R` and historical `project-initializer.R` only as orientation for package style and project shape. **Deliverable:** the working public initializer and a complete user-owned project. **Verify:** install the package, initialize in a temporary directory, inspect the exact architecture layout, and launch its app directly with `shiny::runApp()` in an environment with its documented dependencies. **Boundary:** no custom app launcher, later-stage public stubs, project validation framework, or app rewriting after initialization.
4. **Focused integration and package check.** Add `testthat` coverage for generated files, editable template content, absence of analytical state/products, and the initializer's ordinary destination behavior; perform a practical direct-Shiny smoke check of both empty views. Confirm that the generated project documents app dependencies and that app-only packages are not declared in `readmit` solely for template distribution. Update Stage 1 user guidance for initialization and opening the app. **Deliverable:** a reviewable structural workflow with basic documentation. **Verify:** package installation, focused tests, app smoke check in an environment with its documented dependencies, and `R CMD check` succeed. **Boundary:** do not test hypothetical analytical failures or build custom test or dependency-management infrastructure.

**Stage 1 completion.** An analyst can install `readmit`, call the documented initializer to obtain the architecture's complete generic project layout, edit its configuration and two authoring scripts, and launch its branded Shiny app directly through Shiny after installing the documented app dependencies. No source data or products are needed for launch. Both main views and the trajectory area display appropriate empty states; package checks pass. The app source, styling, and runtime dependencies remain project-owned concerns, and no analytical state or products are created.

**Details to settle during Stage 1.** Choose the minimal initializer arguments and DCF fields needed to name a project and preserve the two-file configuration convention; choose the simplest supported way for the app to read `_brand.yml` and serve the logo. These decisions do not require fixing Stage 2 canonical columns, provider request fields, product CSV schemas, or populated view behavior now.

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
- **Major scope:** Read available products into Current Risk Pool, episode trajectory, and Overview views; retain the empty states from Stage 1 and direct launch through ordinary Shiny mechanisms.
- **Expected outcome:** After product refresh, a project app displays its generated results. Project owners can edit app code and styling without a later refresh overwriting those files.
- **Verification:** Practical Shiny smoke checks before products and after refresh using small test-suite fixtures; package check.
- **Dependencies or boundaries:** Requires Stage 4 products. The app consumes available products and does not execute analytics, manage deployment, or enforce product freshness.

### Stage 6 — v1.0.0 package completeness

- **Objective:** Bring the working vertical workflow to a coherent, documented package release candidate.
- **Major scope:** Complete public function documentation, generic project guidance including app runtime dependencies, focused automated coverage of important behavior, and ordinary package metadata and dependency declarations needed by actual package code, tests, or documentation. Remove temporary scaffolding that no longer serves the package.
- **Expected outcome:** An analyst can install `readmit`, initialize a generic project, supply its source mapping and risk provider, run the normal lifecycle, inspect retained results, generate products, and use the project-owned app.
- **Verification:** A minimal end-to-end public lifecycle using small test-suite fixtures, focused `testthat` tests, a practical direct-Shiny smoke test with its app dependencies available, and successful `R CMD check`.
- **Dependencies or boundaries:** Requires the preceding working capabilities. Analytical package use must not require application-only packages; declare any test-only packages used by package tests appropriately. Address observed defects and genuine release needs without adding certification, distribution, deployment, or speculative infrastructure.

## Progressive stage planning

Before each stage, inspect the code produced so far and plan only the immediate work needed for that stage. Reassess its scope, dependencies, and verification using actual behavior. If implementation reveals a better route or a material architectural change, update `dev/architecture.md` and this plan together. Future stages remain high-level until their turn; they are not a fixed task inventory.

## v1.0.0 completion criteria

- `readmit` is a valid, installable, conventional R package with documented public project operations.
- A user can initialize an independent project and operate it through the intended lifecycle after supplying source mapping and a risk provider.
- Assessments implement the accepted remaining-readmission-risk meaning, including analytical time, eligibility, and canonical event information availability. Episodes processed through the normal workflow have meaningful, inspectable accepted, failed, or ineligible outcomes.
- Historical assessments and episode dispositions persist across runs and can be inspected.
- Product refresh generates the current-risk, trajectory, and scope-summary outputs from retained history.
- A project-owned Shiny app launches directly through ordinary Shiny tooling with empty states before products and displays generated products afterward. Its runtime dependencies are documented in the generated project, while analytical package use does not require application-only packages.
- Focused `testthat` tests, a minimal public lifecycle workflow using test-suite fixtures, a practical Shiny smoke test, and `R CMD check` succeed.
