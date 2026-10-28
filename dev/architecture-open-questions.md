# readmit v1.0.0 — Open Architectural Questions

This working companion to `dev/architecture.md` preserves the original questions, proposed directions, and maintainer answers. The accepted direction is incorporated into `dev/architecture.md`, which remains authoritative. `Resolved` means an answer supplied sufficient architectural direction; `Deferred` marks a choice to settle during implementation. The original suggested directions remain proposals and may differ from the accepted answers. This companion can be retired when it is no longer useful.

**Initial scaffolding priorities answered:** Q01–Q05 establish the analytical meaning, shared data, project authoring points, project contents, and operation boundaries. Q06–Q09 also have accepted direction. Q10–Q11 are deferred implementation choices with recorded preferences.

## Analytical contract

### Q01 — Initial risk target and eligibility

- **Question:** Is the initial v1.0.0 target the remaining probability of readmission within 30 days after discharge, conditional on the episode being alive and readmission-free at the assessment time? How should death and an already completed readmission affect eligibility?
- **Why it matters:** The target determines which episodes receive a prediction and what a risk value means across runs, history, products, and the app.
- **Options:** Fix this single target for v1.0.0; or allow projects to define additional targets from the outset.
- **Suggested direction:** **Proposed:** Begin with the single reference target and explicit eligibility and competing-event semantics. Do not add a general target system for the initial release.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** Yes this is the intended fixed target. Conceptually, it should affect eligibility in the way it is currently handled in the refererence repository. However, this does not necessarily imply the detailed mechanics, validation mechanisms, contracts, etc. must remain as strict as in the reference repo. But conceptually they should be the same. 

### Q02 — Minimum canonical data contract

- **Question:** Are discharge episodes and terminal events the complete shared canonical input for the initial workflow, and which identity and time concepts must every project provide?
- **Why it matters:** All source adapters must produce the same minimum information before assessment and history can be meaningful.
- **Options:** Require the two reference domains; or add further shared domains before the first end-to-end workflow.
- **Suggested direction:** **Proposed:** Use discharge episodes and terminal events, including stable episode identity and event occurrence and availability times. Keep local crosswalks and private predictors in project code. Define exact columns during implementation.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** Yes this is the intended fixed target. Conceptually, it should be the same as what is done in the reference repo: minimal information like the discharge episodes, terminal events, times, and occurrences are what is supplied to the canonical model. Users are free to incorporate for predictors in the context of their private model provider as done in the reference repo. 

## Project authoring and structure

### Q03 — Source and risk-provider interfaces

- **Question:** What is the smallest user-authored R interface for canonical source production and risk prediction, and does one project select one implementation of each for the initial workflow?
- **Why it matters:** These are the main extension points and determine how an analyst turns local data and a model into an operable project.
- **Options:** One source callable and one provider callable per project; or a selectable collection of adapters and providers from the start.
- **Suggested direction:** **Proposed:** Start with one of each, called with explicit project and analytical context. Define the minimum return behavior and failure meaning without carrying over the old registration machinery or full request envelope.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** It should be reflective of what is representative in the reference repository. In fact, an RRP project structure should essentially be carried over verbatim, conceptually, in terms of how users interact with these components. They essentially just have to fill in an R script for each one of these without having to mess with the internal platform mechanics of propogating it all.

### Q04 — Required project contents and ownership

- **Question:** Which configuration, authoring, and app files must `rrp_project_init()` create, and which generated locations should appear only after state initialization, execution, or product refresh?
- **Why it matters:** The initialized directory is a user-facing contract. It must be understandable before the first run and distinguish editable files from generated state.
- **Options:** Create the full directory skeleton immediately; or create only editable project files and add generated locations when first needed.
- **Suggested direction:** **Proposed:** Create a small editable configuration, two authoring files, a README, and a runnable project app. Establish state and products through their own operations. Treat exact file names as provisional.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** It should be reflective of what is representative in the reference repository.
- **Clarification:** The v1.0.0 project retains the reference initializer's two DCF files, `R/register.R`, two user-authored R scripts, README, branding file, and logo. It adds a project-owned app at initialization. State and products appear through later operations; reference initialization also supplies synthetic source files.

## Public R API and lifecycle

### Q05 — Operation boundaries

- **Question:** Should project creation, analytical-state initialization, assessment execution, product refresh, and app launch remain separate public operations, as proposed in the specification?
- **Why it matters:** This determines what each exported function changes and whether an analyst can inspect or repeat a step without unintentionally running another.
- **Options:** Keep the stages explicit; or combine some stages into a single convenience operation.
- **Suggested direction:** **Proposed:** Preserve the separate operations for the initial skeleton, especially assessment execution versus product refresh. Revisit convenience composition only after the workflow works end to end.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** Preserve. It should be reflective of what is representative in the reference repository and how the current architecture proposes it. Keep it simple.

### Q06 — Minimum inspection and recovery surface

- **Question:** Which read and recovery operations must be public in v1.0.0 beyond the core lifecycle: project status, history inspection, backup and restore, or history correction?
- **Why it matters:** These choices affect whether users can understand and recover persistent analytical state without exposing every old CLI operation.
- **Options:** Include focused status and history reads first; or also include backup, restore, retry, invalidation, and restatement in the initial public API.
- **Suggested direction:** **Proposed:** Keep status and history reads in the initial API. Decide the minimum recovery and correction operations from demonstrated state-management needs before calling v1.0.0 complete.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** We don't need to do recovery in v1.0.0. Minimal necessary for desired functionality. If they do a run and something is added to history, that's on them. They can always read the database if they'd like or get a status.

## Products and application

### Q07 — Product selection and freshness

- **Question:** Must product refresh name a specific assessment run and history cutoff, and what should the app display when its published products no longer represent the selected history?
- **Why it matters:** Product meaning and app interpretation depend on knowing the source assessment and whether the displayed view is current for that source.
- **Options:** Require explicit run and cutoff; or let refresh choose the most recent available run. For stale products, display a visible status or refuse to open them.
- **Suggested direction:** **Proposed:** Use an explicit run and cutoff and preserve source identity with the products. Make stale but valid products visibly distinguishable; settle exact freshness behavior with the product contract.
- **Classification:** Architecture
- **Status:** Resolved
- **Answer:** Keep flexible with a principle of minimum necessary for a working product. The app should just read whatever products it has access to. It's up to the user to maintain freshness.

### Q08 — Project app customization boundary

- **Question:** Which parts of the initialized Shiny app may the project owner edit, and how should it behave before products exist?
- **Why it matters:** The app belongs to the project, yet it must consume the same generated product contract as other projects. Initialization precedes product generation.
- **Options:** Provide editable app source backed by package data access; or provide package-owned app code with project-only configuration. Before products exist, show a clear empty/setup state or require products before launch.
- **Suggested direction:** **Proposed:** Provide an editable conventional Shiny starter app that reads published products through `readmit`. Define a clear no-products state without adding a separate app export lifecycle.
- **Classification:** Architecture
- **Status:** Resolved
**Answer:** Similar behavior as reference repo. The app is generated by default one time. The user can then edit the app and/or styling as they wish. Refreshing products only changes the source that the app reads.
- **Clarification:** The app must launch immediately after project initialization. Its normal navigation remains visible and product-dependent views show empty states until products exist. Refresh changes only generated data, preserving user-edited app code and styling.

### Q09 — Reference project first-use experience

- **Question:** Should `rrp_reference_init()` also prepare its synthetic source, or should source preparation remain a second explicit user action?
- **Why it matters:** The reference project should demonstrate the ordinary project contract while offering a short, reliable path to a complete workflow.
- **Options:** One-step initialization with synthetic source; or initialization followed by a dedicated preparation call.
- **Suggested direction:** **Proposed:** Include reproducible synthetic source in the initialized working copy, then use the same state, run, product, and app functions as any project.
- **Classification:** Architecture
- **Status:** Resolved
**Answer:** Yeah the user should be able to get the reference project as "fully working" meaning it has source data available to run and load into history, and propagte through normal desired project progression without changing or adding anything. Key is that it starts with the source data available, but the user should still need to execute progression to, for example, initialize history, generate products, and run the app. The main thing is that they have source data readily available, source mapping preconfigured, and a model provider prebuilt (or prewritten) so they just have to worry about seeing how the package functions work in sequence.

## Deferrable implementation choices

### Q10 — Physical history and product storage

- **Question:** Which ordinary R-accessible storage formats should hold retained assessments and generated products?
- **Why it matters:** The choice affects implementation and maintenance, but the user-facing requirements are persistence, inspection, and reproducible product generation.
- **Options:** Use simple files; or use a local database if the required behavior warrants it.
- **Suggested direction:** **Proposed:** Defer the mechanism until the first history and product functions are built. Choose the simplest approach that meets observed data and reliability needs; do not inherit the reference platform's database by default.
- **Classification:** Implementation
- **Status:** Deferred
- **Answer**: Sure we can defer for now. I'd say generally use what the reference repo does: DuckDB holds history, CSV files hold generated products for the app.

### Q11 — Configuration serialization

- **Question:** What file format should represent the editable project configuration once its required concepts are agreed?
- **Why it matters:** The format affects parsing and authoring convenience but need not change the architectural responsibilities of configuration.
- **Options:** A plain R file or a simple declarative text format.
- **Suggested direction:** **Proposed:** Decide alongside the project initializer using familiar R tooling and a small set of fields. Avoid a custom configuration framework.
- **Classification:** Implementation
- **Status:** Deferred
- **Answer**: Sure we can defer. Lean towards using what's established in the reference repo, but open to alternatives if there's a reason for it.
