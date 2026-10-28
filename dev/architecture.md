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
| `rrp_project_init()` | Create editable configuration, source and provider scripts, project guidance, branding, and a Shiny app. It does not initialize analytical state or run assessments. | Creates a project. |
| `rrp_reference_init()` | Create an immediately usable synthetic project with source data, mapping, provider, configuration, and app. | Creates a project and its synthetic source. |
| `rrp_project_validate()` | Check project configuration and the presence of callable source and provider interfaces without running an assessment. | Reads a project. |
| `rrp_state_init()` | Establish the project's persistent analytical state before its first run. | Creates project state. |
| `rrp_run()` | Canonicalize source data, assess eligible episodes at an analytical time, and retain results in history. | Runs analytics and modifies history. |
| `rrp_refresh_products()` | Derive and write the available analytical products from retained history; it does not rerun the source adapter or provider. | Modifies generated products. |
| `rrp_project_status()` | Summarize project configuration, state, runs, and product availability. | Reads a project. |
| `rrp_inspect_history()` | Read selected run or episode assessments and retained history. | Reads project history. |
| `rrp_run_app()` | Launch the project's Shiny application, including before any products exist; ordinary `shiny::runApp()` remains available. | Runs the app against available products or its empty state. |

Project initialization, state initialization, assessment execution, product refresh, inspection, and app launch remain distinct. The v1.0.0 public API does not include backup, restore, retry, invalidation, or restatement operations. It does not reproduce the previous platform's software-management commands or require a custom CLI.

## RRP project structure

An initialized project is an ordinary directory its owner can inspect, edit, version-control, copy, and operate with familiar R tooling. The historical generic initializer creates `README.md`, two DCF files, three R scripts, `_brand.yml`, and `assets/project-logo.png`. The v1.0.0 initializer retains this recognizable layout and adds the project-owned Shiny app at the same time:

```text
my-rrp-project/
├── README.md                 # project guidance
├── rrp-project.dcf           # project identity, component selection, state location
├── rrp-authoring.dcf         # source mapping and provider implementation details
├── _brand.yml               # editable project branding
├── assets/
│   └── project-logo.png     # initial branding asset
├── R/
│   ├── register.R           # thin generated wiring; normally not edited
│   ├── produce-canonical.R  # user-authored source access and mapping
│   └── calculate-risk.R     # user-authored risk-provider implementation
└── app/
    ├── app.R                # generated once, then user-owned Shiny entry point
    ├── R/                   # supporting Shiny source; then user-owned
    └── www/                 # styling and assets; then user-owned
```

The app's entry point, supporting source, styling, and assets are user-owned after generation. The generic initializer creates no `source/`, `state/`, or products by default. Project owners may add local source files or connect to other approved sources through the mapping script. State initialization later creates `state/`, preferably with `state.dcf` and `history.duckdb`; product refresh writes generated CSV products under `state/products/`. These generated paths are distinct from the editable configuration, authoring scripts, branding, and app source. Exact generated metadata and storage details can be settled during implementation.

The reference initializer adds `R/generate-source.R` as an inspectable teaching script and, for v1.0.0, also supplies `source/generated/` with synthetic stays, events, an identity crosswalk, and source description. No separate source-preparation step is needed. Both kinds of project remain user-owned directories; the extra reference files demonstrate the ordinary authoring contract rather than a second project architecture.

## Configuration and extensibility

The two established configuration files remain distinct. `rrp-project.dcf` identifies the project, canonical profile, selected source producer and risk provider, and state location. `rrp-authoring.dcf` describes the producer implementation, source mapping, provider implementation, and any model or project dependency information needed for that authoring experience. Their v1.0.0 fields may be simpler than the historical files, particularly because no private extension library is required. Both files are user-editable; configuration does not install dependencies or control the user's wider R environment.

The normal authoring task is to edit two R scripts. A source-mapping function, conceptually `rrp_produce_canonical(project_root, as_of_time)`, obtains project-approved clinical source data, maps local identities and event codes, and supplies the shared discharge-episode and terminal-event tables as known at the analytical time. A risk-provider function, conceptually `rrp_calculate_risk(project_root, request)`, receives an eligible episode's canonical identity and assessment context, resolves any private model inputs, and returns one risk probability in `[0,1]` or a clear failure. Its private predictors must have been available by the assessment time. The exact R signatures and failure representation are provisional; users should only need to fill in these two scripts and relevant configuration.

`readmit` loads the selected project's configuration and thin generated `R/register.R` wiring to find the two conventional scripts and their named functions, then invokes them during a run. The wiring is produced once by the initializer and is not part of normal project authoring. Users integrate their data and model by editing `R/produce-canonical.R`, `R/calculate-risk.R`, and relevant configuration, without changing registration mechanics. `readmit` owns target and eligibility logic, execution, and history recording. Project authors own source access, mapping, model inputs, and the risk calculation. Source-native identifiers, crosswalks, credentials, and private predictors stay in project-controlled code and data rather than entering the shared canonical tables.

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

1. **Initialize a project:** Create its configuration, authoring scripts, generated registration wiring, branding, and editable app. Reference initialization also supplies ready-to-use synthetic data and implementations.
2. **Initialize analytical state:** Establish persistent project history as a distinct operation.
3. **Execute assessments:** At a chosen analytical time, canonicalize source data, determine eligibility, invoke the project provider for eligible episodes, and record accepted estimates or other dispositions. Return an identity or context for the run.
4. **Inspect history:** Read retained assessments and their outcomes across runs without changing them.
5. **Refresh products:** Derive the current risk view, observed trajectories, and scope summary from retained history and write the files consumed by the app. This operation does not execute new assessments.
6. **Use the app:** Launch the project-contained Shiny application at any time. Before products exist, its normal navigation and views show appropriate empty states. Once products are available, it reads and displays them. It does not run the source adapter or provider or write history.

No automatic synchronization is required between a run, product refresh, and the app. The project owner chooses when to refresh products and maintain their currency. The exact way a refresh selects source history remains to be defined; v1.0.0 does not require an elaborate freshness validator or mandatory run-and-cutoff selection mechanism.

## Historical state and persistence

Project-owned history retains the analytical time, run and episode context, eligibility or failure disposition, accepted estimates, and enough source and provider context to interpret past assessments. Later runs do not erase earlier assessments. History is authoritative for product generation; products are derived views. Project status and history inspection provide ordinary reads, and the project owner may also inspect their stored data directly.

DuckDB is the current preference for the historical store, following the reference implementation. This does not imply a general storage-adapter framework or prescribe the physical schema. v1.0.0 does not provide public recovery, backup, or history-correction operations. The owner is responsible for runs that add to their history.

## Analytical products

The initial product set carries three established concepts: **current remaining risk** holds the effective accepted estimate for each episode in the selected analytical view; **remaining-risk trajectory** contains actual retained estimates at their assessment times, without invented intermediate values; and **operational scope summary** describes the population and the accepted, failed, and ineligible outcomes of an analytical run. Products are derived from history, not from fresh source or provider execution.

CSV files under `state/products/` are the current preference for generated products consumed by the app, matching the established project state layout. Their exact schemas and names can be settled during implementation. Product refresh updates generated data, not the project's app source or styling. The app reads available products; the project owner is responsible for deciding when they need refreshing. Simple source context may be recorded to make a product interpretable, without requiring elaborate freshness enforcement.

## Shiny application architecture

Each project receives a conventional Shiny app when it is initialized. It is generated once, then belongs to the project owner, who may edit its R source, styling, and assets and run or deploy it with established Shiny tooling. Later product refreshes alter only the data the app reads; they do not overwrite user-edited application files. `rrp_run_app()` is a convenience launch function.

The app launches normally immediately after project initialization, with its established interface and navigation visible. **Current Risk Pool** displays accepted current episode estimates and an episode's actual risk trajectory when those products exist. **Overview** summarizes current risk and the analytical scope when its products exist. Views that lack products show an appropriate empty state instead of failing or blocking launch. After product refresh, the app reads and displays the available products through its normal data-access behavior. It presents descriptive analysis, not clinical recommendations or intervention workflows, and does not read raw clinical sources, model predictors, or live provider calls. No additional app lifecycle or product freshness enforcement is required.

## Reference project

The package bundles a visibly synthetic, nonclinical project using the same structure and operations as other projects. Its historical initializer adds `R/generate-source.R` to the generic project files; a separate preparation operation then creates `source/generated/source.dcf`, `stays.csv`, `events.csv`, and `identity-crosswalk.csv`. For v1.0.0, `rrp_reference_init()` supplies those source files during initialization alongside the configured mapping script, working reference provider, project configuration, branding, and editable Shiny app. The working copy also retains `R/generate-source.R` as inspectable teaching code. The synthetic source is immediately usable, with no extra preparation or programming step. The user still initializes state, runs assessments, refreshes products, and launches the app through the ordinary public functions. The app can also be opened before those analytical steps and will show empty states. Installed reference resources remain separate from the working copy.

## Testing and validation

Use `R CMD check` and conventional R package documentation and dependency checks. Focused functional tests should cover canonicalization, eligibility and risk meaning, the source and provider interfaces, retained history, product generation, and project operations. An end-to-end reference-project test should exercise initialization through app-ready products. A focused app check should cover normal launch and empty views before products, then product display after refresh. This establishes reasonable confidence without importing the previous platform's formal qualification infrastructure.

## Architectural boundaries and remaining choices

v1.0.0 does not require custom installation or package-management systems, software-realization registries, formal qualification authorities, elaborate evidence frameworks, a mandatory custom CLI, separate application export or deployment lifecycle machinery, or speculative infrastructure. Necessary safeguards may still be added when actual RRP requirements justify them.

The accepted direction leaves a few implementation decisions open: final exported names and signatures; exact canonical and product columns; DCF field sets; DuckDB tables and CSV layout; and how product refresh selects source history. These details should be resolved as the minimal working implementation is developed, without reopening the accepted product or lifecycle principles.
