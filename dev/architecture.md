# readmit v1.0.0 — Architecture Specification

- **Target release:** `readmit` v1.0.0
- **Status:** Draft — under active development
- **Document type:** Living architectural specification
- **Scope:** Intended architecture for the v1.0.0 release

This is the current source of truth for the planned v1.0.0 architecture. It describes the intended release, not the current implementation or an ultimate system. It will be refined as decisions are made, with Git preserving its evolution. The function names and directory layout proposed below are provisional until maintainer review.

## Architectural foundation

`readmit` is the R package implementing the Readmission Risk Pool (RRP) analytical platform. An analyst installs one conventional R package, then uses its exported functions from RStudio, scripts, or noninteractive R to create and operate any number of independent, user-owned RRP projects. CRAN is an intended distribution channel; standard R package tooling handles installation, dependencies, documentation, tests, and checks.

Each project owns its configuration, clinical source integration, risk-provider code, persistent analytical history, generated products, and Shiny application. The package supplies reusable analytical operations and a synthetic reference project; installed package resources remain distinct from initialized project copies. The previous platform's software installation, realization, qualification, and distribution machinery is outside this architecture.

RRP's analytical purpose is to combine clinical source data and risk predictions into a longitudinal view of patient readmission risk, retain historical assessments, produce analytical views, and present those views in an interactive application. The reference platform's principal target is remaining readmission risk within 30 days after discharge, conditioned on the episode's status at an analytical time. That product concept carries forward; its exact target contract remains to be defined.

## Public R API and project operations

The proposed ordinary exported functions express the core lifecycle. Each operates on an explicit project path or creates one at an explicit destination. Returned R values should expose useful status and identities for subsequent operations; their exact shape is to be defined.

| Proposed function | Primary responsibility and user-facing behavior | Existing CLI reference | Project effect |
| --- | --- | --- | --- |
| `rrp_project_init()` | Create an editable project with configuration, authoring surfaces, and a project-contained Shiny app. It does not initialize analytical state or run assessments. | `rrp project init` | Creates project. |
| `rrp_reference_init()` | Create a working copy of the synthetic reference project, including its reproducible source data and reference provider. | `rrp reference init` + `rrp reference prepare-source` | Creates project and synthetic source. |
| `rrp_project_validate()` | Check project configuration and the availability of its source and provider interfaces without executing an assessment. | `rrp project validate` | Reads project. |
| `rrp_state_init()` | Establish persistent analytical state for an existing project as a separate, explicit action. | `rrp state init` | Creates project state. |
| `rrp_run()` | Execute source canonicalization and eligible risk assessments at a selected analytical time, retain the results, and return an identity for the run. | `rrp run` | Operates on project; modifies history. |
| `rrp_refresh_products()` | Generate and publish application-ready products from selected retained assessments; it does not re-execute the source or provider. | `rrp products materialize` | Modifies generated products. |
| `rrp_project_status()` | Summarize configuration, state, run, product freshness, and application readiness. This combines related diagnostic reads. | `rrp project status` / `doctor`, `rrp state inspect`, `rrp products status` | Reads project. |
| `rrp_inspect_history()` | Inspect a selected run or episode's retained assessments and effective history. | `rrp history scope` / `episode` / `current` | Reads project history. |
| `rrp_run_app()` | Launch the project's Shiny app against published products. Users may also use `shiny::runApp()` directly. | `rrp app launch` | Operates app; reads products. |

This is a proposed user-facing surface, not a one-for-one CLI translation. No custom CLI is required. The old `software` commands, resource-catalog entry points, raw registration helpers, and separate `app init` / `app refresh` / `app validate` lifecycle are not part of this core API. Whether v1.0.0 also needs focused public backup, restore, or history-correction functions is to be defined.

## RRP project structure

An initialized project is an ordinary directory that its owner can inspect, edit, version-control, copy, and operate with familiar R tooling. The representative layout below identifies responsibilities; `*` marks a configuration file whose format and final name are to be defined.

```text
my-rrp-project/
├── README.md                 # user-owned project orientation
├── rrp-project.*             # user-owned project configuration
├── R/
│   ├── produce-canonical.R  # user-owned source access and mapping
│   └── calculate-risk.R     # user-owned risk-provider implementation
├── source/                   # optional user-owned source inputs or integration files
├── state/                    # package-generated persistent analytical history
├── products/                 # package-generated analytical products
└── app/
    └── app.R                # project-contained, user-owned Shiny application
```

The `R/` filenames retain recognizable authoring roles from the reference project; their exact names and callable contracts are provisional. A project may also hold ordinary supporting R files, branding assets, or deployment configuration. `state/` and `products/` represent responsibility boundaries, not prescribed storage formats; the precise placement of generated products is to be defined. The project owns its files and environment. `readmit` operates only within the project path selected by the user and does not assume control of a broader R library, Git repository, or deployment.

## Configuration and extensibility

Project configuration identifies the project, selected source integration and risk provider, and analytical settings needed to operate it. Its exact file format and fields are to be defined. Users supply clinical data through project-owned files, connections, or other ordinary R access methods. Project-owned mapping code translates local identifiers, events, and timing into the canonical model; local data and credentials remain under the project's control.

The source interface receives an analytical cutoff and yields canonical discharge episodes and terminal events. The risk-provider interface receives an eligible episode's canonical identity, analytical time, and target context, then returns a probability or an explicit failure. It may resolve additional private predictors from project-owned sources, provided they were available by the analytical time. `readmit` owns the shared target, eligibility, execution, and history behavior. The reference platform exposes these roles through `R/produce-canonical.R` and `R/calculate-risk.R`; v1.0.0 should preserve their simple authoring experience without requiring a registration registry or private extension library. Exact R interfaces and dependency guidance are to be defined.

## Canonical data model

The common model carries discharge episodes and terminal events. Episodes have stable canonical identities and admission, discharge, and follow-up timing; terminal events link to episodes and distinguish readmission from death, with occurrence and availability times. Source-native identifiers, local codes, crosswalks, and private predictors belong in project integration code rather than the shared analytical model. Canonicalization must support assessment using information available at the selected analytical time. Field-level schemas, types, and validation rules are to be defined.

## Analytical execution lifecycle

1. **Initialize a project:** Create user-owned configuration, authoring code, and app source. A reference initialization also supplies synthetic inputs and a provider. No analytical history or products are implied.
2. **Initialize analytical state:** Explicitly prepare the project's persistent history before the first run.
3. **Execute assessments:** At a chosen analytical time, the project source adapter prepares canonical data; `readmit` determines eligible episodes, invokes the selected risk provider, records accepted estimates and other outcomes, and returns a run identity.
4. **Retain history:** Keep assessments and their analytical context across runs so actual changes in risk can be examined. Inspecting history is a read operation.
5. **Refresh products:** Select a retained run and history cutoff, then derive and publish a coherent set of products. This is distinct from assessment execution.
6. **Use the app:** Launch the project-contained Shiny application, which reads published products without executing source integration, prediction, or history writes.

The reference CLI makes these operations separate and uses explicit run identities and cutoffs. v1.0.0 should preserve their distinct purposes while using straightforward R function calls. Exact selection, retry, and scheduling behavior is to be defined.

## Historical state and persistence

Project-owned state retains the analytical time, run and episode identities, eligibility or failure disposition, accepted risk estimates, and enough source and provider context to interpret prior assessments. An assessment remains available after later runs; effective history can be queried without treating generated products as the authoritative record. The reference implementation also supports explicit retries, invalidation, and restatement rather than silently replacing history. Which corrective operations belong in the v1.0.0 public API, along with backup behavior and physical persistence, is to be defined.

## Analytical products

The initial product set has three established categories: **current remaining risk** for accepted effective episode estimates, **remaining-risk trajectory** from actual retained assessments, and an **operational scope summary** of eligible, accepted, failed, and ineligible outcomes. Products are derived from history, identify their source run and cutoff, and are suitable for both R inspection and app consumption. Refreshing products should produce a coherent view and make freshness relative to the selected history understandable. Exact schemas, publication format, and refresh rules are to be defined.

## Shiny application architecture

The project contains a conventional Shiny app. Its major navigation follows the reference experience: **Current Risk Pool** lists accepted current estimates and provides a selected episode's observed risk trajectory; **Overview** summarizes current risk and the operational scope. The app displays descriptive analytical results, not a clinical recommendation or intervention workflow. It consumes project-generated products rather than raw source data or live provider calls. Project owners can use ordinary Shiny development and deployment tools; `rrp_run_app()` is a convenience route. UI details and the exact boundary for project customization are to be defined.

## Reference project

The package bundles a synthetic, visibly nonclinical reference implementation. `rrp_reference_init()` creates a user-owned copy following the same project contract as any other project, including configuration, source mapping, a reference risk provider, analytical state location, product location, and app source. Its synthetic stays, events, and identity mapping demonstrate translation from local source concepts to canonical episodes and terminal events; its provider demonstrates time-aware use of private input. Users can initialize state, run assessments at multiple times, refresh products, inspect history, and launch the app with the ordinary functions above. Installed reference resources remain separate from the copy.

## Testing and validation

Use `R CMD check` and conventional package documentation and dependency checks. Focused tests should cover canonical mapping, provider invocation and failure handling, persistent history, product derivation, and project operations. A reference-project end-to-end test should demonstrate initialization through app-ready products, with a focused app launch or rendering check where practical. Tests establish meaningful analytical behavior without importing the previous platform's formal qualification or software-assurance infrastructure.

## Architectural boundaries and non-goals

v1.0.0 does not require custom installation or package-management systems, software-realization registries, formal qualification authorities, elaborate evidence frameworks, a mandatory custom CLI, separate application export or deployment lifecycle machinery, infrastructure abstractions unnecessary to operate RRP, or speculative functionality for hypothetical future releases. Necessary safeguards may still be added when actual RRP requirements justify them.

## Reference interpretation and proposed simplifications

**Established concepts retained:** The previous platform defines independent projects, project-owned source mapping and provider callables, separate state and analytical runs, longitudinal assessments, the three product categories, a synthetic teaching project, and the Current Risk Pool and Overview app experience. These are visible in its CLI dispatcher, project templates, runtime contracts, product code, and Shiny UI.

**Proposed v1.0.0 simplifications:** One `readmit` package replaces the old multi-package and custom software lifecycle. Ordinary exported R functions replace the CLI as the primary interface. Reference initialization can prepare synthetic inputs in one step. Project status can combine related reads. The project contains its app from initialization, and product refresh serves the app directly instead of requiring a separate app export or refresh process.

**Reference discrepancy:** The old generic project template creates no app source, while the later CLI and `application-initializer.R` implement `app init` and `app refresh` after product publication. The older Supplied Application Guide says no standalone app exists, whereas the Standalone Application Guide and CLI dispatcher describe and implement it. This specification uses the agreed project-contained app direction, not either historical lifecycle as a required design.

## Unresolved architectural decisions

- **To be defined:** Final public function names, argument and return contracts, including how a user selects a run and cutoff.
- **To be defined:** Exact project configuration and directory names, plus the source and provider callable contracts.
- **To be defined:** Canonical schemas, target details, and product schemas appropriate to v1.0.0.
- **To be defined:** Physical history and product storage, recovery and backup behavior, and the public scope of history correction.
- **To be defined:** Product freshness behavior and the boundary between package-supplied app defaults and project-owner customization.
