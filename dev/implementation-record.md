# readmit v1.0.0 — Implementation Record

## Purpose and maintenance

This document records what the `readmit` repository currently implements. `dev/architecture.md` describes the intended product, and `dev/implementation-plan.md` describes the planned sequence. Record completed behavior and its evidence here, organized by the plan's stage and increment identifiers. Do not treat planned operations as implemented.

Each increment section describes its **current** implementation. When later work changes an earlier component, update the affected section rather than appending a duplicate entry or a chronological log; Git retains earlier versions. Use the simple statuses `In progress`, `Implemented`, `Verified`, and `Needs revision` according to the available evidence. Record dates only when supported by Git history or a performed check. Keep verification proportional to the functionality, without a separate evidence or qualification system.

## Current implementation status

- **Overall stage:** Stage 1 — Complete Structural Scaffolding is underway. Stage 1.2 is the latest verified increment.
- **Available now:** A conventional, installable R package skeleton; the Stage 1.1 project-authoring resources; and a project-contained Shiny app with branding, Current Risk Pool and Overview navigation, and empty analytical views. The two analytical authoring functions remain stubs.
- **Not yet available:** Public project initialization, canonical processing, risk assessments, persistent history, and analytical products. The package exports no project operations; a package app launcher is not planned.
- **Current use and limitation:** The installed template can be copied into a project and its app launched directly with `shiny::runApp()` when the project's documented app packages are installed. The package cannot yet create a project or replace template identity placeholders for the user. Application-only packages are not package dependencies.
- **Next increment:** Stage 1.3 — Project Initializer.

## Implementation records

### Stage 1 — Complete Structural Scaffolding

#### Stage 1.1 — Project Authoring Resources

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `63d7b18`, “Stage 1.1”)
- **Last verified:** 2026-10-29

**Implementation.** Stage 1.1 added seven ordinary authoring and branding files under `inst/project-template/`; Stage 1.2 later added app files alongside them. The template is installed with the package and can be found with `system.file("project-template", package = "readmit")`. These resources do not provide a project initializer or an analytical workflow.

| Component | Current responsibility |
| --- | --- |
| `README.md` | Brief guidance on project ownership, the two authoring scripts, configuration, branding, the app's runtime packages and their installation, and direct Shiny launch. |
| `rrp-project.dcf` | One `Project-ID` field with the `@@RRP_PROJECT_ID@@` placeholder. No project configuration is loaded or applied yet. |
| `rrp-authoring.dcf` | `Source-Mapping-Script: R/produce-canonical.R` and `Risk-Provider-Script: R/calculate-risk.R` identify the two authoring locations. No dispatch or configuration parser exists yet. |
| `_brand.yml` and `assets/project-logo.png` | Editable name, primary color, and logo references. The shield/trajectory PNG is byte-identical to the historical project's logo. The Stage 1.2 app now reads this branding and serves the logo. |
| `R/produce-canonical.R` | Defines `rrp_produce_canonical(project_root, as_of_time)` and explains project-owned source population and mapping. It stops with “Project author must implement canonical source mapping.” It does not return canonical data. |
| `R/calculate-risk.R` | Defines `rrp_calculate_risk(project_root, request)` and explains project-owned prediction methodology and private predictors. It stops with “Project author must implement the risk provider.” It does not estimate risk. |

**Relationship to the plan.** The seven files fulfill the planned Stage 1.1 resource set and keep the historical two-file configuration and branding conventions in a smaller form. The historical logo was reused; historical registration, extension-library, resource-catalog, and provider-framework machinery was not carried over. There is no material deviation from the planned increment.

**Verification performed on 2026-10-29.** `R CMD INSTALL -l <temporary-library> .` passed. From the installed package, `system.file()` located the template; all seven files existed; base `read.dcf()` read both DCF files; both scripts parsed; and invoking each function produced its intended error. A byte comparison confirmed that the PNG matches the historical project asset. `R CMD build` succeeded, and `R CMD check --no-manual` on that source package finished with **Status: OK**, including the existing `testthat` load test. The repository currently has no automated test dedicated to these static resources.

The previous implementation report said an unrestricted `R CMD check` reached the PDF-manual step but could not complete because `pdflatex` was unavailable. That unrestricted check was not repeated for this record; `pdflatex` is still absent from the current environment. The successful check above is specifically `R CMD check --no-manual`.

**Current limitation.** No code copies the template into a new project or substitutes its identity placeholders. Those responsibilities belong to Stage 1.3; the analytical scripts still require project-owner implementation.

#### Stage 1.2 — Permanent Empty-State App Shell

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `5110904`, “Started 1.2”)
- **Last verified:** 2026-10-29

**Implementation.** The installed template includes a project-owned Shiny app. `app/app.R` reads the parent project's `_brand.yml`, serves its logo from the project `assets/` directory through Shiny, and builds a `bslib` navbar with **Current Risk Pool** and **Overview**. Current estimates, an episode trajectory, current-risk summary, and operational scope each have an intentional empty state. The app does not read source data, state, or products and has no analytical server behavior. `app/www/rrp.css` supplies the navy/teal styling, cards, and responsive layout. The project `README.md` documents installing the app's actual runtime packages (`shiny`, `bslib`, and `yaml`) and direct launch with `shiny::runApp("app")` or RStudio. These app-only packages are absent from `readmit`'s `Imports` and `Suggests`; its package R code does not execute the app.

**Relationship to the plan.** The app is the actual editable project interface for future populated views, as planned. It adapts the historical logo, branded navbar, page hierarchy, paired risk/trajectory cards, overview grouping, and empty-state treatment. It omits the historical product loader, table/chart packages, inactive filters and paging, freshness controls, data adapters, and deployment machinery. One `app.R` and one stylesheet suffice; no supporting `app/R/` file was needed. There is no material scope deviation.

**Verification performed on 2026-10-29.** The package installed successfully with no app-only dependency declarations. Loading its namespace did not load `shiny`, `bslib`, or `yaml`; `system.file()` still located the installed app files. A temporary project copied from the installed template had no `source/`, `state/`, or products. `shiny::runApp()` served the app locally; HTTP requests returned its page, stylesheet, and project logo, with the latter two matching the project files. The page contained both navigation views and all four empty regions; a headless browser selected **Overview** and showed its two empty summaries. The app source and CSS are unchanged from the prior desktop and responsive visual inspection. `R CMD build` succeeded, and `R CMD check --no-manual` finished with **Status: OK**, including the existing `testthat` load test and no unused-imports NOTE. An unrestricted PDF-manual check was not run because `pdflatex` is unavailable.

**Current limitation.** The app always shows empty states until later product-reading work; this is the intended Stage 1.2 behavior. Project initialization belongs to Stage 1.3. The app packages are installed in this R environment, so installation was not tested in an environment where they are physically absent; the package metadata and namespace check establish the intended separation here.
