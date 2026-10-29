# readmit v1.0.0 — Implementation Record

## Purpose and maintenance

This document records what the `readmit` repository currently implements. `dev/architecture.md` describes the intended product, and `dev/implementation-plan.md` describes the planned sequence. Record completed behavior and its evidence here, organized by the plan's stage and increment identifiers. Do not treat planned operations as implemented.

Each increment section describes its **current** implementation. When later work changes an earlier component, update the affected section rather than appending a duplicate entry or a chronological log; Git retains earlier versions. Use the simple statuses `In progress`, `Implemented`, `Verified`, and `Needs revision` according to the available evidence. Record dates only when supported by Git history or a performed check. Keep verification proportional to the functionality, without a separate evidence or qualification system.

## Current implementation status

- **Overall stage:** Stage 1 — Complete Structural Scaffolding is underway. Stage 1.1 is the latest verified increment.
- **Available now:** A conventional, installable R package skeleton and seven installed generic project-authoring resources. The two project-authored analytical function stubs parse and give clear errors until their owner implements them.
- **Not yet available:** Project initialization, a project-owned Shiny app, canonical processing, risk assessments, persistent history, and analytical products. The package exports no project operations yet.
- **Current use and limitation:** The template can be inspected through `system.file()`, but the package cannot yet turn it into a working project. Its project ID and branding values are placeholders for a later initializer.
- **Next increment:** Stage 1.2 — Permanent Empty-State App Shell.

## Implementation records

### Stage 1 — Complete Structural Scaffolding

#### Stage 1.1 — Project Authoring Resources

- **Status:** Verified
- **Initial implementation:** 2026-10-29 (Git commit `63d7b18`, “Stage 1.1”)
- **Last verified:** 2026-10-29

**Implementation.** `inst/project-template/` contains seven ordinary files intended for a future user-owned project. They are installed with the package and can be found with `system.file("project-template", package = "readmit")`. Their presence does not provide a project initializer or an analytical workflow.

| Component | Current responsibility |
| --- | --- |
| `README.md` | Brief guidance on project ownership, the two authoring scripts, configuration, branding, and eventual project-owned app code. |
| `rrp-project.dcf` | One `Project-ID` field with the `@@RRP_PROJECT_ID@@` placeholder. No project configuration is loaded or applied yet. |
| `rrp-authoring.dcf` | `Source-Mapping-Script: R/produce-canonical.R` and `Risk-Provider-Script: R/calculate-risk.R` identify the two authoring locations. No dispatch or configuration parser exists yet. |
| `_brand.yml` and `assets/project-logo.png` | Editable name, primary color, and logo references. The shield/trajectory PNG is byte-identical to the historical project's logo. No app or branding loader exists yet. |
| `R/produce-canonical.R` | Defines `rrp_produce_canonical(project_root, as_of_time)` and explains project-owned source population and mapping. It stops with “Project author must implement canonical source mapping.” It does not return canonical data. |
| `R/calculate-risk.R` | Defines `rrp_calculate_risk(project_root, request)` and explains project-owned prediction methodology and private predictors. It stops with “Project author must implement the risk provider.” It does not estimate risk. |

**Relationship to the plan.** The seven files fulfill the planned Stage 1.1 resource set and keep the historical two-file configuration and branding conventions in a smaller form. The historical logo was reused; historical registration, extension-library, resource-catalog, and provider-framework machinery was not carried over. There is no material deviation from the planned increment.

**Verification performed on 2026-10-29.** `R CMD INSTALL -l <temporary-library> .` passed. From the installed package, `system.file()` located the template; all seven files existed; base `read.dcf()` read both DCF files; both scripts parsed; and invoking each function produced its intended error. A byte comparison confirmed that the PNG matches the historical project asset. `R CMD build` succeeded, and `R CMD check --no-manual` on that source package finished with **Status: OK**, including the existing `testthat` load test. The repository currently has no automated test dedicated to these static resources.

The previous implementation report said an unrestricted `R CMD check` reached the PDF-manual step but could not complete because `pdflatex` was unavailable. That unrestricted check was not repeated for this record; `pdflatex` is still absent from the current environment. The successful check above is specifically `R CMD check --no-manual`.

**Current limitation.** The template has no `app/` files yet, and no code copies or substitutes its placeholders into a project. Those responsibilities belong to later Stage 1 increments.
