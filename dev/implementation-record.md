# readmit v1.0.0 — Implementation Record

## Purpose and maintenance

This document records what the `readmit` repository currently implements. `dev/architecture.md` describes the intended product, and `dev/implementation-plan.md` describes the planned sequence. Record completed behavior and its evidence here, organized by the plan's stage and increment identifiers. Do not treat planned operations as implemented.

Each increment section describes its **current** implementation. When later work changes an earlier component, update the affected section rather than appending a duplicate entry or a chronological log; Git retains earlier versions. Use the simple statuses `In progress`, `Implemented`, `Verified`, and `Needs revision` according to the available evidence. Record dates only when supported by Git history or a performed check. Keep verification proportional to the functionality, without a separate evidence or qualification system.

## Current implementation status

- **Overall stage:** Stage 1 — Complete Structural Scaffolding and Stage 2 — Project Authoring and Canonical Source are both **Verified / Complete**.
- **Available now:** A conventional, installable R package; `rrp_project_init()` creates complete user-owned resources and a branded, empty-state Shiny app. `rrp_project_validate()` checks essential project configuration and authoring-function structure. Internal operations load configured authoring functions, call a project source mapper, and check its canonical return structure. The installed-package authoring workflow has been verified.
- **Not yet available:** Risk-provider execution, risk assessments, persistent history, analytical products, or populated Shiny views. Project owners must implement the generated source mapper and provider stubs; a package app launcher is not planned.
- **Current use and limitation:** Create a project at a new destination with `rrp_project_init(path, project_id)`, edit its configuration, authoring scripts, and branding, validate its structural setup with `rrp_project_validate(path)`, and launch its app directly with Shiny after installing the app's documented packages. Validation does not establish analytical readiness; canonical source production remains internal package machinery, initialization creates no analytical state, and application-only packages are not package dependencies.
- **Next stage:** Stage 3 — Risk Assessment and Persistent History.

## Implementation records

### Stage 1 — Complete Structural Scaffolding

#### Stage 1.1 — Project Authoring Resources

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `63d7b18`, “Stage 1.1”)
- **Last verified:** 2026-10-29

**Implementation.** Stage 1.1 added seven ordinary authoring and branding files under `inst/project-template/`; Stage 1.2 later added app files alongside them. The template is installed with the package and can be found with `system.file("project-template", package = "readmit")`. These resources do not provide a project initializer or an analytical workflow.

| Component | Current responsibility |
| --- | --- |
| `README.md` | Guidance on project ownership, configuration, branding, the canonical source contract, authoring scripts, app runtime packages, and direct Shiny launch. |
| `rrp-project.dcf` | One `Project-ID` field with the `@@RRP_PROJECT_ID@@` placeholder; Stage 2.1 now reads the initialized value. |
| `rrp-authoring.dcf` | `Source-Mapping-Script: R/produce-canonical.R` and `Risk-Provider-Script: R/calculate-risk.R` identify the two authoring locations read by the Stage 2.1 loader and checked by the Stage 2.3 public validator. No registration is required. |
| `_brand.yml` and `assets/project-logo.png` | Editable name, primary color, and logo references. The shield/trajectory PNG is byte-identical to the historical project's logo. The Stage 1.2 app now reads this branding and serves the logo. |
| `R/produce-canonical.R` | Defines `rrp_produce_canonical(project_root, as_of_time)` and summarizes the canonical source contract and project-owned mapping. It stops with “Project author must implement canonical source mapping.” It does not return canonical data. |
| `R/calculate-risk.R` | Defines `rrp_calculate_risk(project_root, request)` and explains project-owned prediction methodology and private predictors. It stops with “Project author must implement the risk provider.” It does not estimate risk. |

**Relationship to the plan.** The seven files fulfill the planned Stage 1.1 resource set and keep the historical two-file configuration and branding conventions in a smaller form. The historical logo was reused; historical registration, extension-library, resource-catalog, and provider-framework machinery was not carried over. There is no material deviation from the planned increment.

**Verification performed on 2026-10-29.** `R CMD INSTALL -l <temporary-library> .` passed. From the installed package, `system.file()` located the template; all seven files existed; base `read.dcf()` read both DCF files; both scripts parsed; and invoking each function produced its intended error. A byte comparison confirmed that the PNG matches the historical project asset. `R CMD build` succeeded, and `R CMD check --no-manual` on that source package finished with **Status: OK**, including the existing `testthat` load test. Stage 1.3 later added automated coverage of the installed template's copied resources.

The previous implementation report said an unrestricted `R CMD check` reached the PDF-manual step but could not complete because `pdflatex` was unavailable. That unrestricted check was not repeated for this record; `pdflatex` is still absent from the current environment. The successful check above is specifically `R CMD check --no-manual`.

**Current limitation.** The analytical scripts still require project-owner implementation. Stage 1.3 now copies these resources and substitutes their project identity placeholders.

#### Stage 1.2 — Permanent Empty-State App Shell

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `5110904`, “Started 1.2”)
- **Last verified:** 2026-10-29

**Implementation.** The installed template includes a project-owned Shiny app. `app/app.R` reads the parent project's `_brand.yml`, serves its logo from the project `assets/` directory through Shiny, and builds a `bslib` navbar with **Current Risk Pool** and **Overview**. Current estimates, an episode trajectory, current-risk summary, and operational scope each have an intentional empty state. The app does not read source data, state, or products and has no analytical server behavior. `app/www/rrp.css` supplies the navy/teal styling, cards, and responsive layout. The project `README.md` documents installing the app's actual runtime packages (`shiny`, `bslib`, and `yaml`) and direct launch with `shiny::runApp("app")` or RStudio. These app-only packages are absent from `readmit`'s `Imports` and `Suggests`; its package R code does not execute the app.

**Relationship to the plan.** The app is the actual editable project interface for future populated views, as planned. It adapts the historical logo, branded navbar, page hierarchy, paired risk/trajectory cards, overview grouping, and empty-state treatment. It omits the historical product loader, table/chart packages, inactive filters and paging, freshness controls, data adapters, and deployment machinery. One `app.R` and one stylesheet suffice; no supporting `app/R/` file was needed. There is no material scope deviation.

**Verification performed on 2026-10-29.** The package installed successfully with no app-only dependency declarations. Loading its namespace did not load `shiny`, `bslib`, or `yaml`; `system.file()` still located the installed app files. A temporary project copied from the installed template had no `source/`, `state/`, or products. `shiny::runApp()` served the app locally; HTTP requests returned its page, stylesheet, and project logo, with the latter two matching the project files. The page contained both navigation views and all four empty regions; a headless browser selected **Overview** and showed its two empty summaries. The app source and CSS are unchanged from the prior desktop and responsive visual inspection. `R CMD build` succeeded, and `R CMD check --no-manual` finished with **Status: OK**, including the existing `testthat` load test and no unused-imports NOTE. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Current limitation.** The app always shows empty states until later product-reading work; this is the intended Stage 1.2 behavior. Stage 1.3 copies it into initialized projects without changing its source. The app packages are installed in this R environment, so installation was not tested in an environment where they are physically absent; the package metadata and namespace check establish the intended separation here.

#### Stage 1.3 — Project Initializer

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `a4375d9`, “Stage 1.3 complete”)
- **Last verified:** 2026-10-29

**Implementation.** `rrp_project_init(path, project_id)` is the first exported project operation. Both arguments are required. `path` names a new destination whose parent already exists; `project_id` is a nonempty ASCII identifier beginning with a letter or digit and otherwise containing letters, digits, `.`, `_`, or `-`. The function returns the normalized project path invisibly. Its roxygen help documents the created resources, authoring responsibility, absence of analytical state, and direct Shiny launch. `R/rrp-project-init.R` implements the operation; roxygen generated its `NAMESPACE` export and `man/rrp_project_init.Rd`. `tests/testthat/test-rrp-project-init.R` covers the ordinary copy and destination behavior. No package dependency was added.

**Copying and safety.** The function locates `inst/project-template/` through `system.file()` in the installed package, creates the requested directory, and copies all template entries, including nested and hidden files, with base `file.copy()`. It replaces `@@RRP_PROJECT_ID@@` only in `rrp-project.dcf` and `_brand.yml`, filling the DCF identity and the initial brand names and logo text. All other files, including the app, styling, and authoring stubs, are copied unchanged and become user-owned. Existing directories (even empty ones) and files are rejected before creation; repeat initialization cannot overwrite edits. If copying or substitution fails after directory creation, the function attempts to remove only that newly created incomplete destination. It does not create `source/`, `state/`, or products.

**Relationship to the plan.** This is the planned small, installed-template initializer. It adds no launcher, analytical operation, template framework, or application dependency. The project ID uses a simple filename-friendly syntax so the same value can fill the existing unquoted DCF and quoted YAML fields without a template-rendering dependency. No material scope deviation was needed.

**Verification performed on 2026-10-29.** Focused `testthat` tests passed for complete template copying, identity substitution, unchanged app and script resources, absence of analytical state, and rejection of existing empty directories, nonempty directories, files, and repeat initialization without changing their contents. `R CMD INSTALL` succeeded. Using that installed package, the public export and generated help were found; a project was created; both DCF files remained readable; `_brand.yml` parsed with the app's YAML package and contained the selected identity; and the generated file tree matched the installed template. Loading only the `readmit` namespace did not load `shiny`, `bslib`, or `yaml`. The initialized project's app launched directly with `shiny::runApp()` and served both navigation views, all four empty states, the selected brand, CSS, and logo; the served CSS and logo matched the project files. `R CMD build` succeeded, and `R CMD check --no-manual` finished with **Status: OK**, including tests and examples, with no check NOTE or WARNING. Repository-index access emitted warnings in this restricted environment but did not change the check status. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Current limitation.** The initializer provides the generic editable project only. The owner must implement the two analytical scripts; analytical state, execution, and products remain future work. The application runtime packages were available in this verification environment, so physical installation without those packages was not exercised.

#### Stage 1.4 — Focused Integration and Package Check

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `e53fe15`, “Stage 1 complete”)
- **Last verified:** 2026-10-29

**Implementation and review.** Stage 1.1–1.3 already supplied the intended structural workflow. The existing `testthat` tests cover complete template copying, identity substitution, unchanged nested authoring and app files, absence of analytical state, editable project ownership, and rejection of existing destinations without changing them. They were retained without duplicate tests or package-code changes. The genuine gap was package-level guidance: `README.Rmd` now describes the working initializer, new-destination and parent-directory rules, editable project resources, app dependency installation and direct launch, empty views, and the analytical operations still unavailable. `README.md` was regenerated from it. The generated project README already documented its ownership, authoring files, branding, app packages, and direct launch, so it was unchanged. The maintainer also reported successful project creation, app launch, and repeat-destination rejection; this supplements the reproducible checks below.

**Dependency boundary.** `DESCRIPTION` still declares only R and test-only `testthat`; `shiny`, `bslib`, and `yaml` remain documented app runtime packages, not `readmit` dependencies. The initializer uses base R to copy files and did not load those packages in the installed-package verification. No launcher or dependency-management code was added.

**Verification performed on 2026-10-29.** Focused `testthat` tests passed. `R CMD build` and installation of the built package succeeded. Through the installed public API, a fresh project was created at the requested path with the expected normalized return value; its file tree matched the installed template, DCF files were readable, YAML branding parsed with the selected identity, the authoring stubs and app resources matched the template, and no `source/`, `state/`, or products existed. The generated app launched directly through `shiny::runApp()` and served Current Risk Pool, Overview, all four empty states, project identity, CSS, and logo; the served CSS and logo matched project files. The app source contains no analytical or package operation calls. Existing automated tests also establish repeat-destination protection and preservation of user edits. `R CMD check --no-manual` finished with **Status: OK**, including tests and examples, with no check NOTE or WARNING. Restricted-network repository-index warnings occurred during the check, and README rendering warned that external badge images could not be fetched; neither affected the generated README or package check. `git diff --check` passed. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Stage 1 completion and limits.** Stage 1's install, initialize, inspect/edit, and empty-app workflow is complete. Source mapping, risk calculation, validation, analytical state, execution, and products belong to later stages. The app packages were present in this environment, so physical installation without them was not tested; the metadata and unloaded namespace support the intended dependency separation.

### Stage 2 — Project Authoring and Canonical Source

- **Status:** Verified / Complete

#### Stage 2.1 — Project Configuration and Authoring-Function Loading

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `59b4f5d`, “2.1 complete”)
- **Last verified:** 2026-10-29

**Implementation.** `R/project-authoring.R` adds the internal `rrp_load_project_authoring(project_root)` helper. It reads one record from each project DCF file with base `read.dcf()`: `Project-ID` from `rrp-project.dcf` and `Source-Mapping-Script` and `Risk-Provider-Script` from `rrp-authoring.dcf`. It resolves the configured project-relative script paths against the explicit project root, sources each script into a fresh environment whose parent is the ordinary R global environment, and obtains `rrp_produce_canonical(project_root, as_of_time)` and `rrp_calculate_risk(project_root, request)`. The returned named list contains the normalized project root, project ID, resolved script paths, and both callable functions. Sourcing evaluates top-level project code, but the loader does not call either authoring function. The template's deliberate stubs load successfully, and helpers defined within a sourced script remain available through lexical scoping. No public API, template resource, package dependency, or app behavior changed.

**Errors and boundaries.** The helper reports missing, malformed, or incomplete DCF configuration; absent, unreadable, or failing scripts; missing or non-function bindings; and incompatible formal argument names with plain errors. It does not invoke the source mapper or provider, validate canonical returns, calculate a follow-up endpoint, or run assessments. This matches the planned first loading increment; the internal representation can evolve as later operations need it.

**Verification performed on 2026-10-29.** New focused `testthat` tests in `tests/testthat/test-project-authoring.R` passed for a project created by the initializer, configured script relocation, lexical helpers, absence of global function pollution, successful loading of template stubs, and representative DCF, script, binding, and formal-argument failures. The full package test suite passed. `R CMD build` and installation of the built package succeeded; an installed-package smoke check created and loaded a project and confirmed that the app resource was unchanged and `shiny`, `bslib`, and `yaml` were not loaded. `R CMD check --no-manual` finished with **Status: OK**, including tests and examples, with no check NOTE or WARNING. Repository-index access emitted restricted-network warnings without changing the check result. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Current limitation.** The loader itself only obtains callable bindings. Stage 2.2 now calls the source mapper and checks its canonical return through a separate internal operation; the risk provider remains uninvoked.

#### Stage 2.2 — Canonical Contract and Source-Mapper Use

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `610337d`, “2.2 complete”)
- **Last verified:** 2026-10-29

**Implementation.** `R/canonical-source.R` adds the internal `rrp_produce_project_canonical(project_root, as_of_time)` operation and direct structural helpers. It checks that `as_of_time` is one finite UTC `POSIXct` instant, reuses the Stage 2.1 loader, calls only `rrp_produce_canonical(project_root, as_of_time)`, validates the returned list, and returns it unchanged. A source-mapper error is reported as a canonical source-production failure with the original message; no empty tables are substituted. The project may source supporting R scripts from inside its mapper using `project_root`. No new public operation or package dependency was added.

**Canonical contract and checks.** The mapper returns `discharge_episode` and `terminal_event` data frames. Episodes require character `episode_id`, `patient_id`, and `index_encounter_id`, plus UTC `POSIXct` `admission_time` and `discharge_time`. Events require character `terminal_event_id`, `episode_id`, and `event_type` (`readmission` or `death`), plus UTC `POSIXct` `occurred_at` and `available_at`. The helper checks required columns, nonmissing/nonblank identifiers, finite timestamps, unique episode and event IDs, recognized event types, and event references to supplied episodes. It accepts typed zero-row tables and leaves additional columns unchanged. It neither filters events by analytical time nor checks eligibility, clinical definitions, or event ordering. `followup_window_end` is not an input; the fixed endpoint remains a Stage 3 derivation.

**Documentation and relationship to the plan.** The generated project `README.md` now describes both tables, their column types, `as_of_time`, the discharge-population expectation, occurrence versus availability, platform-owned endpoint, and optional supporting project scripts. Comments in `R/produce-canonical.R` summarize that contract while retaining the deliberate stub. Roxygen generated internal help at `man/rrp_produce_project_canonical.Rd`. These changes implement the planned source boundary without provider invocation, state, or assessment logic. The provider stub and Shiny app remain unchanged.

**Verification performed on 2026-10-29.** New focused tests in `tests/testthat/test-canonical-source.R` passed for multiple episodes (including one patient with two episodes), readmission and death events, delayed event availability, typed empty event and episode tables, supporting-script loading, source-error propagation, and representative structure, type, identity, timestamp, event-type, and reference failures. The full package suite passed. `R CMD build` and installation of the built package succeeded. An installed-package project used the updated copied template, returned canonical facts through the internal operation without state or provider execution, and retained unchanged provider and app resources. `R CMD check --no-manual` finished with **Status: OK**, including tests and examples, with no check NOTE or WARNING. Restricted-network repository-index warnings did not change the check result. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable. `git diff --check` passed.

**Current limitation.** Canonical facts are available only through an internal operation; the generated mapper still requires project-owner implementation. Stage 2.3 now provides public structural project validation. Eligibility, the 30-day endpoint, provider execution, state, and history remain later-stage work.

#### Stage 2.3 — Practical Project Validation

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `70293a9`, “2.3 complete”)
- **Last verified:** 2026-10-29

**Implementation.** Exported `rrp_project_validate(path)` is a thin wrapper around the Stage 2.1 `rrp_load_project_authoring()` helper. It checks the project root, required DCF configuration, configured scripts, required function bindings, and their formal arguments, then returns `TRUE` invisibly. Existing loader errors retain their specific messages. Sourcing the scripts can evaluate their top-level code, but validation does not invoke either authoring function. The generated stubs therefore pass. The app, branding, source data, state, and products are not validation prerequisites. Roxygen generated the export and `man/rrp_project_validate.Rd`; the generated project README briefly explains the check. No package dependency or validation framework was added.

**Verification performed on 2026-10-29.** Focused `testthat` tests passed for an initialized project with no analytical state, a relocated configured script, optional app and branding resources, and representative configuration, script, binding, and formal-argument errors. The full package test suite passed. `R CMD build` and installation of the built package succeeded. An installed-package smoke check confirmed the public export, invisible `TRUE`, copied guidance, absence of created state, and no loading of app-only packages. `R CMD check --no-manual` finished with **Status: OK**, including tests and examples, with no check NOTE or WARNING. Restricted-network repository-index warnings did not change the check result. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Current limitation.** Structural validation does not call the source mapper or risk provider and does not establish canonical-data or analytical readiness. Stage 2.4 now verifies the integrated authoring workflow. Eligibility, the 30-day endpoint, assessments, state, history, and products remain later-stage work.

#### Stage 2.4 — Integrated Authoring Workflow and Package Check

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (current working tree)
- **Last verified:** 2026-10-29

**Implementation and relationship to the plan.** A single focused `testthat` integration test initializes a temporary project through the public API, validates its untouched deliberate stubs, replaces only its project-owned producer with a small function that sources a supporting R script, and validates the edited project again. It loads both configured authoring bindings, then invokes the producer through the existing internal canonical operation. The accepted return has three discharge episodes and readmission and death events, including one that occurred before the analytical time but became available afterward; it has no project-supplied follow-up endpoint. The generated provider script remains unchanged, loadable, and uninvoked. The workflow creates no analytical state or products. No implementation defect required a package-code change, and no dependency was added. The package README now explains initialization, structural validation, deliberate stubs, the source-mapping responsibility, and the current internal execution boundary; the generated project README adds the short validate–edit–validate sequence and supporting-script guidance. The app and provider template are unchanged.

**Verification performed on 2026-10-29.** The focused integration test passed, followed by the full package test suite. `R CMD build` and installation of the built package succeeded. The same integration test passed against the separately installed build; checks also confirmed the two existing public exports, installed project guidance, unchanged app template, and absence of loaded app-only packages. `R CMD check --no-manual` finished with **Status: OK**, including installed-package tests and examples, with no check NOTE or WARNING. Repository-index access emitted restricted-network warnings without changing the check result. The README was regenerated with RStudio's bundled Pandoc; badge-fetch warnings reflected the same network restriction. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable. `git diff --check` passed.

**Current limitation.** Stage 2 provides no public analytical execution command. Provider requests and execution, eligibility, the 30-day endpoint, assessments, persistent history, products, and populated app views remain for later stages. Stage 3 is next.
