# readmit v1.0.0 — Architecture Specification

- **Target release:** `readmit` v1.0.0
- **Status:** Draft — under active development
- **Document type:** Living architectural specification
- **Scope:** Intended architecture for the v1.0.0 release

This is the current source of truth for the intended v1.0.0 architecture. It will be refined as decisions are made, with Git preserving its evolution. The product concepts and lifecycle below are accepted direction. Proposed function names, exact R signatures, and physical file details remain provisional.

## Architectural foundation

`readmit` is the R package implementing the Readmission Risk Pool (RRP) analytical platform. An analyst installs one conventional R package and uses exported functions from RStudio, scripts, or noninteractive R sessions to create and operate independent, user-owned RRP projects. CRAN is an intended distribution channel. Standard R package tooling handles installation, dependencies, documentation, tests, and checks.

Each project owns its configuration, clinical source integration, risk-provider code, persistent analytical history, generated products, and Shiny application. The package supplies the shared analytical operations; the project owner supplies source mapping and a risk provider for their data and model.

RRP integrates clinical source data and risk predictions into longitudinal assessments of patient readmission risk, retains those assessments, derives analytical products, and presents them in an interactive application. The v1.0.0 analytical target and data concepts are specified below; no general system for project-defined risk targets is required.

## Public R API and project operations

The public interface is a small set of ordinary exported R functions. Each operation uses an explicit project path or creates a project at an explicit destination. The names below are proposed; exact arguments and return structures remain implementation details. Runs should return an identity or other context sufficient to inspect their results and generate products.

| Proposed function | Intended user-facing responsibility | Project effect |
| --- | --- | --- |
| `rrp_project_init()` | Create editable configuration, source and provider scripts, project guidance, branding, and a Shiny app. It does not initialize analytical state or run assessments. | Creates a project. |
| `rrp_project_validate()` | Make lightweight checks of required project structure and the availability of source and provider functions without running an assessment. | Reads a project. |
| `rrp_state_init()` | Establish the project's persistent analytical state before its first run. | Creates project state. |
| `rrp_run()` | Obtain canonical data from the project source mapper, assess eligible episodes at an analytical time, and retain results in history. | Runs analytics and modifies history. |
| `rrp_refresh_products()` | Derive and write the available analytical products from retained history; it does not rerun the source adapter or provider. | Modifies generated products. |
| `rrp_project_status()` | Summarize project configuration, state, runs, and product availability. | Reads a project. |
| `rrp_inspect_history()` | Read selected run or episode assessments and retained history. | Reads project history. |

Project initialization, state initialization, assessment execution, product refresh, and inspection remain distinct package operations. Users launch the generated app directly with ordinary Shiny tooling. The v1.0.0 public API does not include backup, restore, retry, invalidation, or restatement operations. It does not reproduce the previous platform's software-management commands or require a custom CLI.

## RRP project structure

An initialized project is an ordinary directory its owner can inspect, edit, version-control, copy, and operate with familiar R tooling. The v1.0.0 initializer retains the established configuration, two analytical authoring scripts, README, and branding assets, and creates the project-owned Shiny app at the same time:

```text
my-rrp-project/
├── README.md                 # project guidance
├── rrp-project.dcf           # project identity, component selection, state location
├── rrp-authoring.dcf         # source mapping and provider implementation details
├── _brand.yml               # editable project branding
├── assets/
│   └── project-logo.png     # initial branding asset
├── R/
│   ├── produce-canonical.R  # user-authored source access and mapping
│   └── calculate-risk.R     # user-authored risk-provider implementation
└── app/
    ├── app.R                # generated once, then user-owned Shiny entry point
    ├── R/                   # optional supporting Shiny source; then user-owned
    └── www/                 # styling and assets; then user-owned
```

The app's entry point, supporting source, styling, and assets are user-owned after generation. The initializer creates no `source/`, `state/`, or products by default. Project owners may add local source files or connect to their sources through the mapping script. State initialization creates `state/history.duckdb`; product refresh later writes generated CSV products under `state/products/`. These generated paths are distinct from the editable configuration, authoring scripts, branding, and app source.

## Configuration and extensibility

The two established configuration files remain distinct. `rrp-project.dcf` identifies the project, canonical profile, selected source producer and risk provider, and state location. `rrp-authoring.dcf` describes the producer implementation, source mapping, provider implementation, and any model or project dependency information needed for that authoring experience. Their v1.0.0 fields may be simpler than the historical files, particularly because no private extension library is required. Both files are user-editable; configuration does not install dependencies or control the user's wider R environment.

The normal authoring task is to edit two R scripts. A source-mapping function, conceptually `rrp_produce_canonical(project_root, as_of_time)`, obtains project-owned clinical source data, maps local identities and event codes, and supplies the shared discharge-episode and terminal-event tables for the run. The risk-provider function, `rrp_calculate_risk(project_root, request)`, is invoked once for each eligible episode and receives its canonical identity and assessment context. It returns exactly one of `list(probability = p)`, where `p` is one finite number in `[0,1]`, or `list(failure = reason)`, where `reason` is one nonblank string. The project author chooses and constructs private predictors, defines the model and its estimation behavior, and is responsible for the clinical and statistical appropriateness of the prediction engine. `readmit` does not inspect or enforce private predictor timing, provenance, or model methodology. Users should only need to fill in these two scripts and relevant configuration.

`R/produce-canonical.R` and `R/calculate-risk.R` are the only required project-authored analytical interfaces. `readmit` is responsible for locating, loading, and invoking their supplied functions in the selected project; users do not provide a registration file or manage dispatch. An internal helper may be chosen during implementation if useful. Users integrate their data and model by editing these two scripts and relevant configuration. `readmit` owns target and eligibility logic, execution, and history recording. Project authors own source access, mapping, model inputs, and the risk calculation. Source-native identifiers, crosswalks, credentials, and private predictors stay in project-controlled code and data rather than entering the shared canonical tables.

## Canonical data model

The initial shared model has two domains:

| Domain | Required analytical concepts |
| --- | --- |
| Discharge episodes | A stable episode identity, patient and index-encounter context, and admission and discharge times. Multiple episodes may belong to one patient. |
| Terminal events | An event identity, the episode to which it belongs, readmission or death type, when it occurred, and when that information became available. |

The documented canonical contract defines the expected structure and meaning of these tables. The project source mapper supplies the relevant discharge population: canonical discharge episodes represent discharges that have occurred by analytical time `t`. For operational use, the project owner is responsible for supplying a coherent, complete relevant discharge cohort at each assessment, such as during a daily reassessment. The owner does not need to reproduce the package's eligibility rules in source queries; `readmit` applies them to supplied episodes. The project supplies `discharge_time`; `readmit` derives the fixed follow-up endpoint as 30 elapsed days after discharge when analytical operations need it. The endpoint is neither a project-supplied canonical field nor a project-configurable horizon. Event occurrence and information availability are distinct: an event that occurred earlier but was not known by `t` cannot be treated as known at that assessment. The model contains only the shared facts needed for eligibility and history; arbitrary model predictors and local crosswalks remain private.

`readmit` checks canonical structural integrity at the boundary: required tables, columns, and basic types; nonmissing required identities and timestamps; unique episode and terminal-event identities; recognized event types; and terminal-event references to supplied episodes. These checks establish that the shared facts can be interpreted, not that their underlying clinical meaning is correct. The project author remains responsible for the supplied discharge population, source mapping, clinical definitions and event classification, truthful occurrence and availability times, and underlying source quality. `readmit` does not assess those source-specific choices or validate private predictors. Exact R columns and necessary checks can be settled during implementation without a general validation framework.

## Analytical target and eligibility

The fixed v1.0.0 target is the probability of a first readmission in the remaining portion of the 30 elapsed days after discharge. `readmit` derives that endpoint from `discharge_time`. At analytical time `t`, the episode must have been discharged, remain before the end of that window, and be alive and readmission-free according to information available through `t`. The target interval begins after `t` and includes the day-30 endpoint. An episode already readmitted or known to have died by `t` is not eligible for a new remaining-risk estimate; death is a competing event. A readmission and death at the same known time are treated as a readmission for this purpose. Planned and unplanned readmissions are not distinguished by this initial target.

Assessment uses both occurrence and availability time: only events that occurred **and** were available by `t` can affect the known episode state. This keeps the meaning of an estimate tied to what could have been known at the time. `readmit` determines eligibility from canonical facts before calling the provider. The provider estimates risk for an eligible episode; it does not redefine the target or eligibility. A failed prediction leaves an otherwise eligible episode in the risk pool with an unavailable estimate, not a zero-risk estimate. The precise time representation and edge-case validation mechanics remain implementation choices.

## Analytical execution lifecycle

1. **Initialize a project:** Create its configuration, authoring scripts, branding, and editable app. The owner supplies source mapping and a risk provider to operate the generic project.
2. **Initialize analytical state:** Establish persistent project history as a distinct operation.
3. **Execute assessments:** At a chosen analytical time, obtain the project's discharge-episode snapshot, determine eligibility for its supplied episodes, invoke the project provider once per eligible episode, and record accepted estimates or other dispositions. A run may contain zero episodes. Return a concise run summary with its identity, assessment time, episodes processed, and accepted, failed, and ineligible counts.
4. **Inspect history:** Read retained assessments and their outcomes across runs without changing them.
5. **Refresh products:** Derive the current risk view, observed trajectories, and scope summary from retained history and write the files consumed by the app. This operation does not execute new assessments.
6. **Use the app:** Launch the project-contained application with `shiny::runApp()` or RStudio's Run App action. Before products exist, its normal navigation and views show appropriate empty states. Once products are available, it reads and displays them. It does not run the source adapter or provider or write history.

No automatic synchronization is required between a run, product refresh, and the app. The project owner chooses when to refresh products and maintain their currency. Current operational products select the completed run with the greatest analytical `as_of_time`, breaking ties by execution `created_at` and then `run_id`. This differs from the most recently executed run: a later historical backfill does not displace a newer analytical snapshot. A partial run with a later analytical time still becomes the selected snapshot; earlier episodes are not merged into it. Operational refresh is therefore intended to follow a complete-population assessment. The selected snapshot is not necessarily live clinical status. v1.0.0 does not require completeness enforcement, automatic merging or retry reconciliation, an alternate run selector, or an elaborate freshness validator.

Episodes processed through the normal analytical workflow have meaningful, inspectable outcomes: an accepted estimate, a provider failure or unusable result, or ineligibility under the established 30-day, known-readmission, and known-death rules. Explicit provider failures, unusable results, and errors thrown for one episode are distinguishable episode-level failures; they do not stop assessment of other episodes. An ineligible episode is not a failed prediction. Canonical production and persistence failures that prevent a reliable completed run terminate the run. These outcomes support interpretation of the assessed population. They do not require special statuses for discharges supplied contrary to the documented timing contract, accounting for source records omitted by the project mapper, or a separate reconciliation system for inappropriate input. Exact status names and precedence remain implementation choices.

## Historical state and persistence

Project-owned history retains the analytical time, run and episode context, eligibility or failure disposition, accepted estimates, and enough source and provider context to interpret past assessments. When a known terminal event determines ineligibility, retain the selected event's identity, type, occurrence time, and availability time to explain that decision without copying the canonical event table. History records what the platform knew and concluded at each assessment; an event learned later does not retroactively change an earlier row. It retains meaningful outcomes from the normal workflow without storing extra records solely for inappropriate input, private predictors, or whole canonical tables. Every completed run has a distinct identity, including repeated runs at the same analytical time, and earlier completed assessments remain intact. A completed run and its assessment rows are committed atomically; fatal persistence errors leave no partial completed run. History is authoritative for product generation; products are derived views. Project status provides a compact summary, and history inspection returns stable, read-only data-frame rows. The project owner may also inspect the stored data directly.

DuckDB is the current preference for the historical store, following the reference implementation. This does not imply a general storage-adapter framework or prescribe the physical schema. v1.0.0 does not provide public recovery, backup, or history-correction operations. The owner is responsible for runs that add to their history.

## Analytical products

The initial product set carries three established concepts. **Current remaining risk** contains every clinically eligible episode in the selected assessment snapshot: `accepted` episodes have a probability, while `provider_failure` episodes remain members with a missing probability. The clinically ineligible `window_closed`, `known_readmission`, and `known_death` episodes are excluded. Repeated provider failures do not remove an eligible episode; an earlier accepted estimate is not substituted for a failed current one. **Remaining-risk trajectory** contains only actual accepted historical estimates at their assessment times for members of that current eligible pool, including distinct repeated-time runs. An eligible episode can have no trajectory observations, and a prior accepted observation does not become its current estimate. No intermediate values or modeled change are invented. **Operational scope summary** counts all episodes assessed in the selected run, separating eligible accepted and provider-failed outcomes from the three ineligible dispositions. Its eligible count equals the number of current-risk rows. Products are derived from retained history, not from fresh source or provider execution.

CSV files under `state/products/` are the intended generated products consumed by the app, matching the established project state layout. The Stage 4 implementation plan specifies their fixed schemas and empty-result behavior. Product refresh reads retained history, calculates and stages the three files, and replaces generated data without rerunning the source mapper or provider or changing history. A failure before replacement leaves existing products in place; staging alone does not promise atomic replacement of all files. Refresh does not alter project-authored scripts, app source, or styling. The app reads available products; the project owner decides when to refresh them. The selected analytical time should be clear without elaborate freshness enforcement.

## Shiny application architecture

Each project receives a conventional Shiny app when it is initialized. It is generated once, then belongs to the project owner, who may edit its R source, styling, and assets and run or deploy it with established Shiny tooling. Later product refreshes alter only the data the app reads; they do not overwrite user-edited application files. No package-specific app launcher or deployment operation is required.

The app runs independently of the package's analytical operations. Its runtime dependencies are documented in the generated project and installed in the environment that runs the app. Merely distributing the app files does not make those packages dependencies of `readmit`; package dependency declarations follow actual use by package code, tests, documentation, or optional package functionality. Project initialization, assessments, history, and product generation must remain usable without installing application-only packages.

With its documented runtime dependencies installed, the app launches normally immediately after project initialization, with its established interface and navigation visible. **Current Risk Pool** shows all clinically eligible episodes in the selected snapshot, including members whose current prediction failed and whose probability is unavailable, alongside actual accepted historical trajectory observations when present. It must not show an earlier accepted probability as the current estimate after a failure. **Overview** summarizes available current estimates and the analytical scope when products exist; not every scope count needs prominent display. Views that lack products show an appropriate empty state instead of failing or blocking launch. After product refresh, the app reads and displays the available products through its normal data-access behavior and makes the selected analytical time clear. It presents descriptive analysis, not clinical recommendations or intervention workflows, and does not read raw clinical sources, model predictors, or live provider calls. No additional app lifecycle or product freshness enforcement is required.

## Testing and validation

Validation is limited to practical checks needed for project operations and analytical execution. Project validation checks essential structure and authoring functions without invoking them. When a source mapper returns canonical data, `readmit` checks the model's required tables, columns, types, identities, event references, and nonmissing timestamps before consuming it. Later assessment execution checks whether a provider result is a usable probability or clear failure. An operation should give a straightforward error when it cannot proceed. Source-data auditing, clinical-definition assessment, eligibility checks during canonical return validation, extensive timestamp-ordering rules, and a general-purpose validation framework are outside this boundary.

Use `R CMD check` and focused `testthat` tests for important analytical behavior and package functions. A minimal end-to-end test of the public lifecycle may use small fixtures created within the test suite; no bundled example project is required. A practical Shiny smoke test should cover normal launch and empty views before products, then product display after refresh. No formal qualification infrastructure, evidence registries, elaborate contract certification, or extensive hypothetical failure simulations are required.

## Implementation principles

Use conventional R package design and familiar R tools. Favor direct, readable functions and simple data structures; use DuckDB and CSV where they naturally satisfy the established history and product needs. Keep user-facing interfaces stable while allowing internal details to evolve. Avoid speculative abstractions, generalized frameworks, unnecessary indirection, and custom software lifecycle machinery. Treat the previous RRP repository as an analytical and behavioral reference, not an implementation blueprint. Favor a complete minimal working workflow over partially implemented sophisticated infrastructure.

## Architectural boundaries and remaining choices

v1.0.0 does not require custom installation or package-management systems, software-realization registries, formal qualification authorities, elaborate evidence frameworks, a mandatory custom CLI, separate application export or deployment lifecycle machinery, or speculative infrastructure. Necessary safeguards may still be added when actual RRP requirements justify them.

The accepted direction leaves a few implementation details open, including final exported signatures and small CSV-writing choices. Stage 4's snapshot selection, eligible-pool membership, and product meanings are settled above; its detailed CSV schemas and verification expectations are in the implementation plan. Remaining details should be resolved through the minimal working implementation without reopening the accepted product or lifecycle principles.
