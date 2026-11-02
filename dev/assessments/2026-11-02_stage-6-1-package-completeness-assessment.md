# Stage 6.1.A — Package completeness and public API assessment

- **Assessment date:** 2026-11-02
- **Repository / branch:** `readmit` / `main`
- **Inspected commit:** `34890c1d02fcf40827bdc7a68a27e552e236ec73`
- **Package version:** `0.0.1.9000` (unchanged)
- **Scope:** Assessment and proposed 6.1 work only; no remediation or release operation.

## Purpose and method

Assess whether the completed Stage 1–5 platform is coherent as a publicly distributed R package and identify only the work needed for Increment 6.1. I read `AGENTS.md`, the architecture, implementation plan and record, relevant open questions, and the initial repository assessment. I inspected package metadata, all seven exports and their R and Rd documentation, package-level help, `NAMESPACE`, dependencies, tests, CI, README/NEWS, and every installed project-template file. I built a source package, checked it, installed it in a separate temporary library, inspected its help and contents, initialized a fresh project with that installation, compared regenerated roxygen documentation in a temporary copy, and measured local `covr` coverage. The browser evidence below comes from the completed Stage 5 record; I did not rerun the browser scenarios.

The public boundary remains sound: `readmit` supplies shared project and analytical operations; the generated project owns clinical mapping, risk estimation, state, products, branding, and the app. No API redesign or new framework is justified by this assessment.

## Findings and release relevance

### F01 — Public package description is too thin

- **Domain / priority / group:** Metadata; **Required for 6.1**; Group A.
- **Observed state and evidence:** `DESCRIPTION:1-24` has an appropriate package name, title, development version, author/maintainer and copyright roles, Apache 2 license declaration, URL and issue tracker, UTF-8 encoding, R `>= 4.1.0`, roxygen settings, and plausible dependency fields. Its one-sentence `Description` (`DESCRIPTION:5`) says the platform “facilitates hospital readmissions prediction and management.” It does not explain the R implementation, owner-supplied mapping/model, retained history, or products, and “management” may imply clinical operations outside this package. The field passes `R CMD check`, but that is insufficient for a first public RRP platform release. [R Packages describes `Description` as the package's substantive public description](https://r-pkgs.org/description.html).
- **Recommended remediation:** Replace only the `Description` field with this exact DCF-formatted paragraph during 6.1:

```text
Description: Provides the R implementation of the Readmission Risk Pool (RRP)
    analytical platform for reassessing the remaining probability of a first
    hospital readmission through 30 days after discharge. Distributed as the
    'readmit' package, it creates user-owned projects, applies shared eligibility
    rules at explicit assessment times, retains completed assessments as
    history, and generates CSV analytical products for a project-owned
    interactive application. Project authors supply clinical source-mapping
    and risk-provider functions; no clinically validated prediction model is
    included.
```

- **Why / verification:** CRAN readers should understand the product and its limits before installation. The proposed field parsed successfully with `read.dcf()` in a temporary file. After editing, verify `read.dcf("DESCRIPTION")`, source build, and `R CMD check`; review rendered package metadata.

### F02 — Two central operations lack runnable help examples

- **Domain / priority / group:** Public API and help; **Required for 6.1**; Group A.
- **Observed state and evidence:** `NAMESPACE:3-9` exports `rrp_project_init(path, project_id)`, `rrp_project_validate(path)`, `rrp_state_init(path)`, `rrp_run(path, as_of_time)`, `rrp_project_status(path)`, `rrp_inspect_history(path, run_id = NULL, episode_id = NULL)`, and `rrp_refresh_products(path)`. All have generated Rd help with argument and return documentation. Five have executable examples. `man/rrp_run.Rd:34-39` puts its entire example in `\dontrun{}` and presumes a project with implemented scripts; `man/rrp_refresh_products.Rd` has no example. The installed help index exposes all seven exports; `README.md` and the generated project `README.md` do describe their sequence. [R Packages recommends useful, executable examples for exported functions](https://r-pkgs.org/man.html).
- **Recommended remediation:** Add compact, runnable examples for the run/refresh sequence in roxygen source, using a temporary project and minimal owner functions or a small shared example helper only if necessary. Keep examples fast, self-contained, and clear about the deliberate template stubs. Regenerate Rd; do not hand-edit `man/` or change the API.
- **Why / verification:** An external user should be able to learn and exercise the complete lifecycle from installed help. Run examples via `R CMD check`, inspect installed help, and verify the example actually creates a run and three products.

### F03 — Coverage upload and badge are not operationally established

- **Domain / priority / group:** Tests, CI, public badge; **Required for 6.1**; Group B.
- **Observed state and evidence:** `.github/workflows/R-CMD-check.yaml:3-51` runs standard package checks on `main`/`master` pushes and pull requests but has no coverage job or upload. `codecov.yml:1-14` configures informational project/patch status with `target: auto` and `threshold: 1%`. `README.Rmd:12` and `README.md:12` use the conventional `centralstatz/readmit` Codecov badge URL, matching the GitHub repository slug. The badge's live status could not be independently verified here, and no successful upload was evidenced. A local `covr::package_coverage()` run on the extracted source package reported **93.48404%** line coverage and ran `stage3-installed-workflow.R`, `stage5-installed-workflow.R`, and `testthat.R`. This is a local measurement, not a Codecov result or proof of analytical validity.
- **Recommended remediation:** Add a small dedicated `.github/workflows/test-coverage.yaml`, triggered by pushes to `main` and pull requests (plus optional manual dispatch). Use the existing r-lib setup pattern; install `covr` and `xml2` in CI as development tools, measure with `covr::package_coverage()`, export Cobertura XML with `covr::to_cobertura()`, and upload that file with the maintained `codecov/codecov-action`. Make upload failure visible. Keep these tools out of analytical `Imports`. [covr package coverage](https://covr.r-lib.org/reference/package_coverage.html), [Cobertura export](https://covr.r-lib.org/reference/to_cobertura.html), and the [Codecov action](https://github.com/codecov/codecov-action) support this conventional path. Decide whether the existing informational status YAML is useful; its 1% thresholds are not a needed release criterion, so simplify or remove them if they obscure results. No numeric coverage gate is recommended.
- **External setup / verification:** The repository is publicly visible on [GitHub](https://github.com/centralstatz/readmit), but public visibility alone does not establish token-free uploads for a default-branch run. [Codecov's token documentation](https://docs.codecov.com/docs/codecov-tokens) says protected/default-branch uploads normally require a repository token unless organization settings allow otherwise. The maintainer should confirm Codecov repository onboarding and, if required, add `CODECOV_TOKEN` as a GitHub Actions secret; do not store it in Git. Check current action version and token behavior when implementing. Verify one successful `main` upload, visible commit coverage in Codecov, and a rendered README/pkgdown badge. Pull requests from forks may need separate token handling; do not expose secrets to untrusted PR code.
- **Coverage boundary:** This metric instruments package R code exercised by package tests, including the two standalone scripts when run through `covr` here. It does not measure the copied project app's R code as package code or replace direct installed-project and browser checks. Add focused tests only if line-level inspection reveals a meaningful missed behavior.

### F04 — Return-shape details could be easier to find

- **Domain / priority / group:** Public help; **Recommended for 6.1**; Group A.
- **Observed state and evidence:** `man/rrp_inspect_history.Rd:16-20` describes categories of returned columns but does not name the exact schema. `man/rrp_refresh_products.Rd:13-16` says `files` is named but does not give its three keys; the filenames are correctly listed in Details. The other public returns and material side effects are well described. The package-level help (`man/readmit-package.Rd`) is a short overview; README and project guidance carry the complete sequence.
- **Recommended remediation / verification:** While editing help for F02, name the stable return fields or link directly to an existing authoritative schema description, and add concise workflow links where useful. Compare documentation with actual return values in a fresh installed project. Avoid duplicating long internal schema tables or adding API surface.

### F05 — Existing CRAN history needs explicit v1.0.0 release communication

- **Domain / priority / group:** Release context; **Defer to 6.2** (with README messaging in 6.3); Group C handoff.
- **Observed state and evidence:** [CRAN currently lists `readmit` 0.0.1](https://cran.r-project.org/package=readmit), published in 2025 for earlier HRRP/PDC functionality under MIT. Local `DESCRIPTION` is `0.0.1.9000`, describes RRP, and declares Apache 2; `NEWS.md:5-7` correctly records the earlier initial CRAN submission. The README's CRAN badge therefore points to an existing, older public package. This v1.0.0 is the first public **RRP platform** release, not the package's first CRAN submission.
- **Recommended remediation / verification:** In 6.2, describe the major functional shift and license history accurately in release notes and CRAN communication, and confirm the intended license/copyright metadata before submission. In 6.3, make README wording clear about what is current development functionality versus the CRAN 0.0.1 release. Do not erase the historical NEWS entry. Verify final CRAN-facing material against the exact release source.

## Reviewed domains with no 6.1 action identified

| Domain | Evidence and conclusion |
| --- | --- |
| API behavior and errors | `R/rrp-project-init.R`, `R/rrp-project-validate.R`, `R/project-history.R`, `R/rrp-run.R`, `R/project-inspection.R`, and `R/product-refresh.R` match the documented lifecycle. Help describes preconditions, important failures, output, files, and side effects. No demonstrated public API defect warrants redesign. |
| Dependencies | `DESCRIPTION:10-24` uses `DBI`/`duckdb` for package history/products, and suggests `shiny`, `bslib`, `reactable`, `plotly`, `yaml`, and `testthat`. The app source uses those app libraries through namespace-qualified calls, and its README documents direct installation. No missing analytical runtime dependency or reason to move app libraries into `Imports` was found. `covr` belongs to CI only. No present vignette or system requirement justifies `VignetteBuilder` or `SystemRequirements` now. |
| Source and installed contents | The built tarball contains `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `README.md`, R sources, Rd files, tests, and all ten template files: two DCFs, two owner scripts, README, brand YAML, logo, app entry point, product reader, and CSS. `.Rbuildignore` excludes `dev/`, `AGENTS.md`, CI/site configuration, and other development-only inputs. The separate installation contains callable code, help, NEWS, and `project-template`; tests and raw README/Rd source are ordinary source-package contents, not installed resources. No missing initializer resource or unintended generated artifact was found. |
| Generated-project use | `inst/project-template/README.md`, the DCFs, stub comments, and `app/app.R` explain ownership, canonical and provider contracts, state/refresh sequence, runtime app packages, and direct launch. A fresh project copied all ten files, passed structural validation, reported zero runs before state, initialized state, and returned an intentional mapper-stub error on an attempted run. Its app has a defined no-products state; Stage 5.4's installed-project direct-launch and browser evidence covers that state and populated products. A full ready-to-run educational reference project is a 6.4 concern, not a missing 6.1 API. |
| Tests and checks | Sixteen `testthat` files cover structure, canonical input, eligibility, provider, run, persistence, products, inspection, and app data/interaction. Two standalone installed-workflow scripts cover Stages 3 and 5. `R CMD check` ran both and `testthat.R`. Stage 5.4 recorded direct app launch, browser navigation and interaction at multiple widths, empty/mixed/failure/zero-episode states, and preservation of owner files. No specific untested public behavior was identified by this review. Coverage measurement complements these checks; it does not certify clinical correctness. |

## Suggested implementation groups for maintainer review

These are recommendations, not an approved detailed plan or completed work.

1. **Group A — Public metadata and help (F01, F02, F04).** Update the `Description` field and roxygen help/examples, regenerate Rd, run examples and package check, inspect installed help. This group is local, reviewable, and does not depend on Codecov setup.
2. **Group B — Coverage reporting (F03).** Add one CI workflow and minimal Codecov configuration changes, arrange any required external repository token, then verify an actual default-branch upload and badge. It may proceed alongside Group A, but completion requires a live CI run.
3. **Group C — Stage 6 handoff (F05).** Carry the existing CRAN history, release messaging, and license confirmation into 6.2/6.3. No 6.1 implementation change is proposed for this group.

## Open questions

- **Maintainer / Codecov:** Is the repository connected to the intended Codecov organization, and does its policy require a `CODECOV_TOKEN` secret for default-branch uploads? Resolve while implementing Group B; the local repository cannot answer account settings.
- **Maintainer / release:** Confirm that the Apache 2 license and current copyright holder are intended for the repurposed v1.0.0 package, given the earlier MIT-licensed CRAN release. Resolve in 6.2 before submission.
- **Maintainer / wording:** The exact F01 paragraph is ready to use; editorial changes may be made during Group A if they preserve the analytical scope and owner-supplied model distinction.

## Verification performed and limitations

All commands below ran from an external temporary directory against the unchanged development source, except the read-only Git and repository inspection commands:

- `R CMD build /Users/alexzajichek/Documents/GitHub/Repositories/readmit` — passed; produced `readmit_0.0.1.9000.tar.gz`.
- `R CMD check --no-manual readmit_0.0.1.9000.tar.gz` — passed, **Status: OK**; it executed the two standalone workflow scripts and `testthat.R`. Repository-index access warnings appeared in dependency lookup under the restricted network but produced no check NOTE or WARNING. The manual PDF check was not run.
- `R CMD INSTALL -l lib readmit_0.0.1.9000.tar.gz` — passed in a separate temporary R library; the installed namespace exposed seven public functions and its project template was present.
- In the installed-package session, initialized a fresh project, validated it, inspected empty status/history, initialized state, and confirmed the deliberate unimplemented source-mapper error.
- In a temporary extraction, `roxygen2::roxygenise()` completed; generated Rd and `NAMESPACE` matched the repository copies. `covr::package_coverage()` completed and reported **93.48404%** line coverage.
- Parsed the proposed replacement Description with `read.dcf()` from a temporary file.

No live GitHub Actions run, Codecov account inspection/upload, badge rendering, full release-candidate audit, or fresh browser smoke was performed. The current local build/check establishes package mechanics, not public documentation completeness. **Increment 6.1 remains in progress** until targeted remediation and its verification are agreed and completed.
