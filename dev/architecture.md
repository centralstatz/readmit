# readmit v1.0.0 — Architecture Specification

- **Target release:** `readmit` v1.0.0
- **Status:** Draft — under active development
- **Document type:** Living architectural specification
- **Scope:** Intended architecture for the v1.0.0 release

This is the current source of truth for the intended v1.0.0 architecture. It will be refined as decisions are made, with Git preserving its evolution. The product concepts and lifecycle below are accepted direction. Proposed function names, exact R signatures, and physical file details remain provisional.

## Architectural foundation

`readmit` is the R package implementing the Readmission Risk Pool (RRP) analytical platform. An analyst installs one conventional R package and uses exported functions from RStudio, scripts, or noninteractive R sessions to create and operate independent, user-owned RRP projects. CRAN is an intended distribution channel. Standard R package tooling handles installation, dependencies, documentation, tests, and checks.

Each project owns its configuration, clinical source integration, risk-provider code, persistent analytical history, generated products, and Shiny application. The package supplies the shared analytical operations and a synthetic reference project. Installed package resources remain separate from initialized project copies.

RRP integrates clinical source data and risk predictions into longitudinal assessments of patient readmission risk, retains those assessments, derives analytical products, and presents them in an interactive application. The v1.0.0 analytical target and data concepts are specified below; no general system for project-defined risk targets is required.

## Public R API and project operations

The public interface is a small set of ordinary exported R functions. Each operation uses an explicit project path or creates a project at an explicit destination. The names below are proposed; exact arguments and return structures remain implementation details. Runs should return an identity or other context sufficient to inspect their results and generate products.

| Proposed function | Intended user-facing responsibility | Project effect |
| --- | --- | --- |
| `rrp_project_init()` | Create editable configuration, source and provider scripts, project guidance, and a Shiny app. It does not initialize analytical state or run assessments. | Creates a project. |
| `rrp_reference_init()` | Create an immediately usable synthetic project with source data, mapping, provider, configuration, and app. | Creates a project and its synthetic source. |
| `rrp_project_validate()` | Check project configuration and the presence of callable source and provider interfaces without running an assessment. | Reads a project. |
| `rrp_state_init()` | Establish the project's persistent analytical state before its first run. | Creates project state. |
| `rrp_run()` | Canonicalize source data, assess eligible episodes at an analytical time, and retain results in history. | Runs analytics and modifies history. |
| `rrp_refresh_products()` | Derive and write the available analytical products from retained history; it does not rerun the source adapter or provider. | Modifies generated products. |
| `rrp_project_status()` | Summarize project configuration, state, runs, and product availability. | Reads a project. |
| `rrp_inspect_history()` | Read selected run or episode assessments and retained history. | Reads project history. |
| `rrp_run_app()` | Launch the project's Shiny application; ordinary `shiny::runApp()` remains available. | Runs the app against available products. |

Project initialization, state initialization, assessment execution, product refresh, inspection, and app launch remain distinct. The v1.0.0 public API does not include backup, restore, retry, invalidation, or restatement operations. It does not reproduce the previous platform's software-management commands or require a custom CLI.

## RRP project structure

An initialized project is an ordinary directory its owner can inspect, edit, version-control, copy, and operate with familiar R tooling. This representative layout uses the established authoring names and the current storage preferences; exact generated paths can be settled during implementation.

```text
my-rrp-project/
├── README.md                 # project guidance; user-editable
├── rrp-project.dcf           # preferred project identity and selection configuration
├── rrp-authoring.dcf         # preferred mapping and provider configuration
├── R/
│   ├── produce-canonical.R  # user-editable source access and mapping
│   └── calculate-risk.R     # user-editable risk-provider implementation
├── source/                   # optional user-owned source data or integration files
├── app/
│   ├── app.R                # generated once, then user-owned and editable
│   └── www/                 # optional user-owned styling and assets
├── state/                    # generated when analytical state is initialized
│   └── history.duckdb       # preferred historical store
└── products/                 # generated on product refresh; CSV preferred
```

The initializer creates the editable project files and app, but no analytical history or products. `state/` and `products/` represent project-owned generated content; users manage their project as a whole, while package operations write analytical data there. A generic project need not contain source data by default. The reference project does contain synthetic source data. Additional ordinary project files and packages are permitted. No private extension library or project registration file is part of the required user authoring surface.

## Configuration and extensibility

The preferred configuration approach follows the reference project's small declarative DCF files. `rrp-project.dcf` identifies the project and selected source and provider; `rrp-authoring.dcf` records mapping and provider implementation information. Their exact fields and whether both files remain necessary can be simplified during implementation. Configuration is user-owned; it does not install dependencies or control the user's wider R environment.

The normal authoring task is to edit two R scripts. A source-mapping function, conceptually `rrp_produce_canonical(project_root, as_of_time)`, obtains project-approved clinical source data, maps local identities and event codes, and supplies the shared discharge-episode and terminal-event tables as known at the analytical time. A risk-provider function, conceptually `rrp_calculate_risk(project_root, request)`, receives an eligible episode's canonical identity and assessment context, resolves any private model inputs, and returns one risk probability in `[0,1]` or a clear failure. Its private predictors must have been available by the assessment time. The exact R signatures and failure representation are provisional; users should only need to fill in these two scripts and relevant configuration.

`readmit` locates the conventional scripts in the selected project, loads the named functions, and invokes them during a run. It owns target and eligibility logic, execution, and history recording. Project authors own source access, mapping, model inputs, and the risk calculation. Source-native identifiers, crosswalks, credentials, and private predictors stay in project-controlled code and data rather than entering the shared canonical tables. Any internal wiring needed to load these scripts is package-managed and not a required authoring task.

## Canonical data model

The initial shared model has two domains:

| Domain | Required analytical concepts |
| --- | --- |
| Discharge episodes | A stable episode identity, patient and index-encounter context, admission and discharge times, and the end of the 30-day follow-up window. Multiple episodes may belong to one patient. |
| Terminal events | An event identity, the episode to which it belongs, readmission or death type, when it occurred, and when that information became available. |

The source adapter translates local data into these common concepts. Event occurrence and information availability are distinct: an event that occurred earlier but was not known by an assessment time cannot be treated as known at that assessment. The model contains the minimum shared facts needed for eligibility and history; arbitrary model predictors and local crosswalks remain private. Exact R column names, types, and validation details can be set during implementation while preserving these meanings.

## Analytical target and eligibility

The fixed v1.0.0 target is the probability of a first readmission in the remaining portion of the 30 elapsed days after discharge. At analytical time `t`, the episode must have been discharged, remain before the end of that window, and be alive and readmission-free according to information available through `t`. The target interval begins after `t` and includes the day-30 endpoint. An episode already readmitted or known to have died by `t` is not eligible for a new remaining-risk estimate; death is a competing event. A readmission and death at the same known time are treated as a readmission for this purpose. Planned and unplanned readmissions are not distinguished by this initial target.

Assessment uses both occurrence and availability time: only events that occurred **and** were available by `t` can affect the known episode state. This keeps the meaning of an estimate tied to what could have been known at the time. `readmit` determines eligibility from canonical facts before calling the provider. The provider estimates risk for an eligible episode; it does not redefine the target or eligibility. The precise time representation and edge-case validation mechanics remain implementation choices.

## Analytical execution lifecycle

1. **Initialize a project:** Create its editable configuration, source and provider scripts, and app. Reference initialization also supplies ready-to-use synthetic data and implementations.
2. **Initialize analytical state:** Establish persistent project history as a distinct operation.
3. **Execute assessments:** At a chosen analytical time, canonicalize source data, determine eligibility, invoke the project provider for eligible episodes, and record accepted estimates or other dispositions. Return an identity or context for the run.
4. **Inspect history:** Read retained assessments and their outcomes across runs without changing them.
5. **Refresh products:** Derive the current risk view, observed trajectories, and scope summary from retained history and write the files consumed by the app. This operation does not execute new assessments.
6. **Use the app:** Launch the project-contained Shiny application, which reads whatever generated products are available to it. It does not run the source adapter or provider or write history.

No automatic synchronization is required between a run, product refresh, and the app. The project owner chooses when to refresh products and maintain their currency. The exact way a refresh selects source history remains to be defined; v1.0.0 does not require an elaborate freshness validator or mandatory run-and-cutoff selection mechanism.

## Historical state and persistence

Project-owned history retains the analytical time, run and episode context, eligibility or failure disposition, accepted estimates, and enough source and provider context to interpret past assessments. Later runs do not erase earlier assessments. History is authoritative for product generation; products are derived views. Project status and history inspection provide ordinary reads, and the project owner may also inspect their stored data directly.

DuckDB is the current preference for the historical store, following the reference implementation. This does not imply a general storage-adapter framework or prescribe the physical schema. v1.0.0 does not provide public recovery, backup, or history-correction operations. The owner is responsible for runs that add to their history.

## Analytical products

The initial product set carries three established concepts: **current remaining risk** holds the effective accepted estimate for each episode in the selected analytical view; **remaining-risk trajectory** contains actual retained estimates at their assessment times, without invented intermediate values; and **operational scope summary** describes the population and the accepted, failed, and ineligible outcomes of an analytical run. Products are derived from history, not from fresh source or provider execution.

CSV files are the current preference for generated products consumed by the app. Their exact schemas, names, and placement can be settled during implementation. Product refresh updates generated data, not the project's app source or styling. The app reads available products; the project owner is responsible for deciding when they need refreshing. Simple source context may be recorded to make a product interpretable, without requiring elaborate freshness enforcement.

## Shiny application architecture

Each project receives a conventional Shiny app when it is initialized. It is generated once, then belongs to the project owner, who may edit its R source, styling, and assets and run or deploy it with established Shiny tooling. Later product refreshes alter only the data the app reads; they do not overwrite user-edited application files. `rrp_run_app()` is a convenience launch function.

The reference app experience has two main views. **Current Risk Pool** displays accepted current episode estimates and an episode's actual risk trajectory. **Overview** summarizes current risk and the analytical scope. The app presents descriptive analysis, not clinical recommendations or intervention workflows. It consumes generated products rather than raw clinical sources, model predictors, or live provider calls. What the generated app should display before the first product refresh remains to be defined.

## Reference project

The package bundles a visibly synthetic, nonclinical project using the same structure and operations as other projects. `rrp_reference_init()` creates a working copy with synthetic stays and events, local-to-canonical identity mapping, a configured source script, a working reference provider, project configuration, and an editable Shiny app. The synthetic source is available immediately, with no extra preparation or programming step. The user still initializes state, runs assessments, refreshes products, and launches the app through the ordinary public functions. Installed reference resources remain separate from the working copy.

## Testing and validation

Use `R CMD check` and conventional R package documentation and dependency checks. Focused functional tests should cover canonicalization, eligibility and risk meaning, the source and provider interfaces, retained history, product generation, and project operations. An end-to-end reference-project test should exercise initialization through app-ready products, with an app smoke check where practical. This establishes reasonable confidence without importing the previous platform's formal qualification infrastructure.

## Architectural boundaries and remaining choices

v1.0.0 does not require custom installation or package-management systems, software-realization registries, formal qualification authorities, elaborate evidence frameworks, a mandatory custom CLI, separate application export or deployment lifecycle machinery, or speculative infrastructure. Necessary safeguards may still be added when actual RRP requirements justify them.

The accepted direction leaves a few implementation decisions open: final exported names and signatures; exact canonical and product columns; small DCF field sets; DuckDB tables and CSV layout; and how product refresh selects source history. The app's behavior before products exist also needs an explicit user-facing choice. These details should be resolved as the minimal working implementation is developed, without reopening the accepted product or lifecycle principles.
