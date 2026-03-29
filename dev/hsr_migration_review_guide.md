# HSR Migration Review Guide

This is a developer-facing review guide for the migrated HSR architecture in `readmit`.

The goal is not to restate package features. The goal is to help me trace the code as if I wrote it myself:
- what the original implementation did
- what the migrated implementation does now
- where responsibilities moved
- what assumptions are now explicit
- where legacy behavior still exists

Use this as a structured review checklist and dependency map.

## 1. Architecture Shift: Old vs New

### Original model

The original HSR implementation treated the report as a format-specific file and let each exported helper parse what it needed directly.

Primary characteristics:
- HSR support was centered on legacy Excel workbooks.
- Exported helpers owned both parsing and analysis.
- Many helpers repeated workbook-specific behavior:
  - sheet discovery
  - `readxl::read_xlsx()`
  - control-character cleanup
  - positional assumptions
  - report-specific column selection logic
- Readmission risk computation depended on intermediate outputs shaped by those workbook readers.

Core examples:
- [`R/hsr_payment_summary.R`](../R/hsr_payment_summary.R)
- [`R/hsr_cohort_summary.R`](../R/hsr_cohort_summary.R)
- [`R/hsr_discharges.R`](../R/hsr_discharges.R)
- [`R/hsr_coefficients.R`](../R/hsr_coefficients.R)
- [`R/hsr_dual_stays.R`](../R/hsr_dual_stays.R)
- [`R/hsr_readmission_risks.R`](../R/hsr_readmission_risks.R)

### Migrated model

The new architecture separates the HSR flow into layers:

1. source resolution
2. parser config/spec
3. parsing into conceptual components
4. component access / validation
5. analysis helpers

Primary characteristics:
- HSR input is now treated as a source bundle, not a workbook.
- Parsing variability is handled upstream.
- Analysis helpers operate on conceptual components only.
- CSV-first parsing is configurable through a parser config object.
- Legacy workbook support still exists, but it is no longer the architectural center.

Review question:
- Can I clearly point to the line where parsing stops and analysis begins?

---

## 2. Source Layer

### Read first

- [`R/hsr_source.R`](../R/hsr_source.R)

### Key functions

- `hsr_resolve_source()`
- `hsr_resolve_local()`
- `is_hsr_source()`
- `print.readmit_hsr_source()`
- `validate_hsr_source()`
- `hsr_guess_artifact_role()`

### Responsibility

This layer inventories a local source bundle and assigns coarse metadata to source artifacts.

It owns:
- path validation
- artifact discovery
- artifact IDs
- file inclusion filtering
- filename-based role hints
- source object construction

It does not own:
- conceptual component extraction
- column mapping
- analysis semantics

### What changed from the original implementation

Before migration, there was no dedicated source object. A path usually meant “open this workbook”.

Now:
- a path can mean “resolve this directory into source artifacts”
- artifact role hints are source metadata, not analysis truth
- local directory resolution is explicit and testable

### Assumptions to pay attention to

- `role_hint` is intentionally only a hint
- source resolution is currently local-only
- artifact discovery is spec-driven through `include_pattern`
- no assumption is made that all required components exist

### Questions to answer while reviewing

- Where does the source object stop short of parsing?
- Which fields are structural vs advisory?
- If a bundle has zero usable artifacts, does the source layer still behave coherently?

---

## 3. Parser Config / Spec Layer

### Read next

- [`R/hsr_parser_config.R`](../R/hsr_parser_config.R)

### Key functions

- `hsr_parser_config()`
- `validate_hsr_parser_config()`
- `is_hsr_parser_config()`
- `hsr_component_config()`
- `hsr_find_column()`
- `hsr_apply_alias_map()`

### Responsibility

This layer defines parser-facing assumptions:
- file inclusion pattern
- artifact role hint patterns
- column alias mappings
- embedded component-column assumptions
- component-specific parsing hints

It is the mechanism for:
- package defaults
- user overrides

It should not leak into analysis helpers directly.

### What changed from the original implementation

Originally, parsing assumptions were mostly hardcoded:
- specific sheet names
- specific Excel placement
- specific column names or positional structures

Now:
- defaults are centralized
- user overrides can be injected without reshaping data upstream
- parsing variability is handled before analysis helpers run

### Assumptions to pay attention to

- this is not a full ETL DSL
- the config layer is intentionally lightweight
- alias mapping is only mild canonicalization, not full schema normalization
- the spec is consumed by source/parsing, not by analysis

### Questions to answer while reviewing

- Which assumptions are package defaults vs user-overridable?
- Which helpers in this file are safe to extend without contaminating analysis?
- Are we only canonicalizing fields that downstream helpers truly need?

---

## 4. Parser Layer

### Read after source + config

- [`R/hsr_parse.R`](../R/hsr_parse.R)
- [`R/hsr_parse_csv.R`](../R/hsr_parse_csv.R)

### Key functions

From `R/hsr_parse.R`:
- `hsr_parse()`
- `is_hsr_bundle()`
- `print.readmit_hsr_bundle()`
- `validate_hsr_bundle()`

From `R/hsr_parse_csv.R`:
- `hsr_parse_csv_bundle()`
- `hsr_parse_artifact()`
- `hsr_collect_component_output()`
- `hsr_embedded_component_column()`
- `hsr_apply_component_aliases()`

### Responsibility

This layer transforms source artifacts into conceptual bundle components.

It owns:
- iterating artifacts
- reading CSVs
- splitting one artifact into zero / one / many outputs
- applying config-driven alias mapping
- aggregating outputs into conceptual component tables
- recording lineage

It does not own:
- downstream analysis behavior
- helper-specific business logic

### What changed from the original implementation

Originally:
- exported helpers each parsed their own section directly
- no shared parsed-bundle abstraction existed

Now:
- there is one parsed bundle object
- artifacts can produce multiple conceptual outputs
- parser output is aggregated into stable component slots
- lineage and raw parser output are preserved

### Assumptions to pay attention to

- one artifact may yield multiple outputs if the embedded component column exists
- no assumption is made that a bundle contains all components
- parsed bundles can be structurally valid while still incomplete for a given analysis

### Questions to answer while reviewing

- How does one artifact become multiple conceptual outputs?
- Where do alias mappings get applied?
- How are unsupported or unknown components handled?
- Does parsing ever directly call an analysis helper? It should not.

---

## 5. Component Abstraction Layer

### Read after parsing

- [`R/hsr_components.R`](../R/hsr_components.R)

### Key functions

- `hsr_as_bundle()`
- `hsr_get_component()`
- `hsr_require_component()`
- `hsr_require_fields()`
- `hsr_filter_component_cohort()`
- `hsr_component_inclusion_fields()`
- `hsr_risk_factor_fields()`
- `hsr_get_component_names()`

### Responsibility

This is the seam between parsing and analysis.

It owns:
- bundle coercion from path to parsed bundle
- component retrieval
- “component exists and is populated” checks
- “component contains required fields” checks
- simple cohort filtering
- small shared schema helpers used by analysis

### What changed from the original implementation

Originally, helpers reached directly into raw imported data or workbook sections.

Now:
- helpers enter through bundle coercion
- helpers request conceptual components explicitly
- missing-data failures are centralized and clearer

### Assumptions to pay attention to

- this layer is intentionally narrow
- it validates structure needed by analysis, not parser internals
- it should remain free of file-format logic

### Questions to answer while reviewing

- If a helper fails, is the failure because the bundle is invalid, the component is missing, or required fields are absent?
- Are the shared schema helpers minimal, or are they starting to become a second parser?

---

## 6. Migrated Simple Helpers

### Read next

- [`R/hsr_payment_summary.R`](../R/hsr_payment_summary.R)
- [`R/hsr_cohort_summary.R`](../R/hsr_cohort_summary.R)
- [`R/hsr_dual_stays.R`](../R/hsr_dual_stays.R)

### Key functions

- `hsr_payment_summary()`
- `hsr_payment_penalty()`
- other payment summary convenience helpers
- `hsr_cohort_summary()`
- `hsr_dual_stays()`

### Responsibility

These are the simplest examples of migrated analysis readers.

They now:
- accept parsed bundles or local bundle paths
- use conceptual components
- fail clearly if a component is missing or unpopulated

They still retain legacy-file fallback behavior where applicable.

### What changed from the original implementation

Originally:
- these helpers each parsed workbook tabs directly

Now:
- they prefer parsed bundle components
- local bundle paths are coerced through `hsr_parse()`
- workbook parsing is no longer their primary logic path

### Assumptions to pay attention to

- these helpers are the cleanest examples of the new analysis pattern
- they show the intended public API shape for the migrated architecture

### Questions to answer while reviewing

- Where exactly does each helper choose between parsed-bundle mode and legacy fallback?
- Are convenience helpers still compatible with the new return shapes?

---

## 7. Migrated Discharges / Coefficients Readers

### Read after simple helpers

- [`R/hsr_discharges.R`](../R/hsr_discharges.R)
- [`R/hsr_coefficients.R`](../R/hsr_coefficients.R)

### Key functions

- `hsr_discharges()`
- `hsr_coefficients()`
- internal legacy-only helpers:
  - `hsr_discharges_legacy()`
  - `hsr_coefficients_legacy()`

### Responsibility

These helpers now read only from:
- `bundle$components$discharges`
- `bundle$components$coefficients`

They own:
- component-level field validation
- cohort filtering
- small helper-specific behavior

They do not own:
- parsing
- alias interpretation
- source inspection

### What changed from the original implementation

Originally:
- both helpers directly parsed Excel structure
- both encoded report-layout assumptions

Now:
- both operate on parsed component data only
- required fields are explicit
- alias-based variability is already resolved upstream
- legacy Excel extraction still exists, but only as internal compatibility support for the old legacy parser

### Assumptions to pay attention to

For `hsr_discharges()`:
- required fields: `cohort`, `ID Number`
- `eligible_only` works only if inclusion fields exist
- custom `discharge_phi` / `risk_factors` selection is deliberately restricted for now

For `hsr_coefficients()`:
- required fields: `cohort`, `term`, `value`
- output is reshaped back into the legacy-facing `Factor` / `Value` interface

### Questions to answer while reviewing

- Which parts of the old discharge/coefficient logic were intentionally not preserved yet?
- Are the current clear failures preferable to silent guesses?
- What minimum parsed schema is now required for each helper?

---

## 8. Readmission Risk Computation

### Read after discharges + coefficients

- [`R/hsr_readmission_risks.R`](../R/hsr_readmission_risks.R)

### Key function

- `hsr_readmission_risks()`

### Responsibility

This helper now computes risks strictly from conceptual components.

It owns:
- cohort filtering
- eligible discharge filtering when inclusion fields are available
- risk factor extraction from parsed discharge data
- coefficient extraction and intercept handling
- matrix-style weighted-sum logic through long-form joins
- logistic transform to `Predicted` and `Expected`

It does not own:
- parser variability
- file layout interpretation

### What changed from the original implementation

Originally:
- it delegated to legacy-shaped `hsr_discharges()` and `hsr_coefficients()` outputs
- those outputs were themselves produced by workbook parsing

Now:
- it goes directly to parsed bundle components
- the required schema is explicit
- overlap between risk-factor fields and coefficient terms is enforced
- errors are clearer when the bundle is structurally valid but not computation-ready

### Assumptions to pay attention to

- required coefficient intercepts:
  - `HOSP_EFFECT`
  - `AVG_EFFECT`
- risk factor fields are whatever remains in discharges after removing:
  - `cohort`
  - `ID Number`
  - cohort inclusion fields
- no parser spec is consulted here

### Questions to answer while reviewing

- What happens if the bundle is structurally valid but has no overlapping factor terms?
- Is the current “risk factor fields are all remaining columns” rule sufficient for now?
- Which assumptions here will need to become more formal if future parsed bundles grow richer metadata?

---

## 9. Legacy Compatibility Layer

### Read after the new path is clear

- [`R/hsr_read.R`](../R/hsr_read.R)
- [`R/hsr_legacy_parse.R`](../R/hsr_legacy_parse.R)

### Key functions

- `hsr_read()`
- `hsr_detect_format()`
- `validate_hsr()`
- `hsr_parse_legacy_excel()`
- `hsr_parse_legacy_*()` helpers

### Responsibility

This is the old legacy-first compatibility path.

It exists so that:
- the older parsed-legacy-object tests still pass
- legacy Excel support remains available while the new architecture becomes primary

Crucially:
- this layer is no longer the center of the architecture
- it should not drive new design decisions

### What changed from the original implementation

Originally, this effectively was the architecture.

Now it is:
- a side branch
- a compatibility bridge
- partly isolated from the new public component-based helpers

Important transition detail:
- once `hsr_discharges()` and `hsr_coefficients()` moved to parsed-bundle components, the old legacy parser could no longer safely call them
- internal legacy-only helpers were added so the legacy parser can still build its own object without depending on the new component path

### Assumptions to pay attention to

- this branch is intentionally separate
- do not use it as the mental model for the new architecture
- changes here should be justified as compatibility fixes, not as new HSR design

### Questions to answer while reviewing

- Where do the legacy-only internal helpers protect the new architecture boundary?
- What can eventually be removed once legacy support is retired?

---

## 10. Tests As Behavioral Documentation

### Read last

Core HSR migration tests:
- [`tests/testthat/test-hsr_source.R`](../tests/testthat/test-hsr_source.R)
- [`tests/testthat/test-hsr_parse.R`](../tests/testthat/test-hsr_parse.R)
- [`tests/testthat/test-hsr_parse_artifacts.R`](../tests/testthat/test-hsr_parse_artifacts.R)
- [`tests/testthat/test-hsr_payment_summary.R`](../tests/testthat/test-hsr_payment_summary.R)
- [`tests/testthat/test-hsr_cohort_summary.R`](../tests/testthat/test-hsr_cohort_summary.R)
- [`tests/testthat/test-hsr_dual_stays.R`](../tests/testthat/test-hsr_dual_stays.R)
- [`tests/testthat/test-hsr_discharges.R`](../tests/testthat/test-hsr_discharges.R)
- [`tests/testthat/test-hsr_coefficients.R`](../tests/testthat/test-hsr_coefficients.R)
- [`tests/testthat/test-hsr_readmission_risks.R`](../tests/testthat/test-hsr_readmission_risks.R)
- [`tests/testthat/test-hsr_read.R`](../tests/testthat/test-hsr_read.R)

Fixtures:
- [`tests/testthat/fixtures/hsr_csv_bundle_minimal/`](../tests/testthat/fixtures/hsr_csv_bundle_minimal)
- [`tests/testthat/fixtures/hsr_csv_bundle_multioutput/`](../tests/testthat/fixtures/hsr_csv_bundle_multioutput)
- [`tests/testthat/fixtures/hsr_csv_bundle_partial/`](../tests/testthat/fixtures/hsr_csv_bundle_partial)

### Why these tests matter

These tests are the clearest expression of intended behavior for the migrated architecture:
- source resolution expectations
- parsed bundle invariants
- artifact-to-component aggregation
- one-artifact / multi-output behavior
- role-hint overrides
- alias override behavior
- helper coercion from path to parsed bundle
- clear error behavior for incomplete or malformed components

### Questions to answer while reviewing

- Which tests validate structural contracts vs helper semantics?
- Which tests are protecting migration behavior vs legacy compatibility?
- If I changed the parser config layer, which tests should fail first?

---

## 11. Dependency / Execution Trees

### New primary path

```text
local bundle path
  -> hsr_resolve_source()
    -> hsr_resolve_local()
      -> source object (readmit_hsr_source)
  -> hsr_parse()
    -> hsr_parse_csv_bundle()
      -> hsr_parse_artifact()
        -> hsr_apply_component_aliases()
      -> hsr_collect_component_output()
      -> parsed bundle (readmit_hsr_bundle)
  -> analysis helper
    -> hsr_as_bundle()
    -> hsr_require_component()
    -> hsr_require_fields()
    -> helper-specific logic
```

### New helper path examples

```text
hsr_payment_summary()
  -> hsr_require_component("payment_summary")

hsr_discharges()
  -> hsr_require_component("discharges")
  -> hsr_require_fields("cohort", "ID Number")
  -> hsr_filter_component_cohort()
  -> optional inclusion filtering

hsr_coefficients()
  -> hsr_require_component("coefficients")
  -> hsr_require_fields("cohort", "term", "value")
  -> hsr_filter_component_cohort()
  -> transmute(term/value -> Factor/Value)

hsr_readmission_risks()
  -> hsr_require_component("discharges")
  -> hsr_require_component("coefficients")
  -> field validation
  -> cohort filtering
  -> intercept extraction
  -> risk factor overlap
  -> weighted sum
  -> logistic transform
```

### Legacy branch

```text
legacy workbook path
  -> hsr_read()
    -> hsr_detect_format()
    -> hsr_parse_legacy_excel()
      -> hsr_parse_legacy_payment_summary()
      -> hsr_parse_legacy_cohort_summary()
      -> hsr_parse_legacy_dual_stays()
      -> hsr_parse_legacy_discharges()
        -> hsr_discharges_legacy()
      -> hsr_parse_legacy_coefficients()
        -> hsr_coefficients_legacy()
```

Review question:
- Can I visually explain which branch is now primary and which is compatibility-only?

---

## 12. Recommended File Reading Order

Follow this order if the goal is deep understanding rather than quick navigation.

1. [`R/hsr_source.R`](../R/hsr_source.R)
2. [`R/hsr_parser_config.R`](../R/hsr_parser_config.R)
3. [`R/hsr_parse.R`](../R/hsr_parse.R)
4. [`R/hsr_parse_csv.R`](../R/hsr_parse_csv.R)
5. [`R/hsr_components.R`](../R/hsr_components.R)
6. [`R/hsr_payment_summary.R`](../R/hsr_payment_summary.R)
7. [`R/hsr_cohort_summary.R`](../R/hsr_cohort_summary.R)
8. [`R/hsr_dual_stays.R`](../R/hsr_dual_stays.R)
9. [`R/hsr_discharges.R`](../R/hsr_discharges.R)
10. [`R/hsr_coefficients.R`](../R/hsr_coefficients.R)
11. [`R/hsr_readmission_risks.R`](../R/hsr_readmission_risks.R)
12. [`R/hsr_read.R`](../R/hsr_read.R)
13. [`R/hsr_legacy_parse.R`](../R/hsr_legacy_parse.R)
14. HSR tests in `tests/testthat/`

If I want the shortest path to “how does the new architecture work?”, stop after step 11 and only then read the legacy branch.

---

## 13. Review Checklist By Layer

### Architecture

- [ ] Can I explain old vs new in one paragraph?
- [ ] Can I identify the parsing boundary?
- [ ] Can I identify the analysis boundary?

### Source

- [ ] Do I understand how artifacts are discovered?
- [ ] Do I understand what `role_hint` is and is not?

### Parser config

- [ ] Do I know what the defaults are?
- [ ] Do I know what users can override?
- [ ] Do I know where alias mapping occurs?

### Parsing

- [ ] Do I understand one-artifact / multi-output behavior?
- [ ] Do I understand where lineage is recorded?
- [ ] Do I understand what goes into `raw$artifact_outputs`?

### Components

- [ ] Do I know which helpers enforce structure?
- [ ] Do I know which errors mean “component missing” vs “field missing”?

### Analysis helpers

- [ ] Can I trace each migrated helper from bundle input to returned tibble?
- [ ] Can I identify which helpers still have legacy fallback behavior?

### Legacy branch

- [ ] Do I understand why the legacy-only helpers were added?
- [ ] Do I know what could be deleted once legacy compatibility is retired?

---

## 14. Manual Cleanup Observations

Use this section while reviewing. Add notes directly here.

### Notes on architecture boundaries

- 
- 
- 

### Notes on parser defaults that may need revision

- 
- 
- 

### Notes on helper behavior that feels temporary or overly strict

- 
- 
- 

### Legacy compatibility notes

- 
- 
- 

### Questions to revisit later

- 
- 
- 
