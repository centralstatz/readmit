# readmit — CRAN and GitHub Release Procedure

This is the maintainer's working procedure for updating the existing CRAN
`readmit` package. When the first Readmission Risk Pool (RRP) release began,
CRAN carried the earlier `0.0.1` package; `1.0.0` was published on 2026-11-04.
CRAN-requested corrections could have made the accepted version a later patch.
Publish the matching GitHub release **only after CRAN acceptance**, then derive
the next development version from the version CRAN accepted. Use ordinary
`usethis`, `devtools`, R, and Git tools.
Recheck their current prompts and behavior when executing a release.

The commands below document the first RRP release sequence; they were not
instructions to run during Stage 6.2. Run shell blocks from the repository
root unless a step says otherwise. Run R blocks with this package as the active
project. The initial `"major"` choice is specific to the first
`0.0.1.9000` → `1.0.0` transition; choose an appropriate increment for later
releases.

## 1. Finish the development-version candidate (Stage 6.7)

- Complete the package, exported help, tests, README and public status
  messaging, worked tutorial and installed vignette, and published website.
- Review `DESCRIPTION` author/maintainer, CentralStatz copyright holder,
  Apache License 2.0 declaration, dependencies, and URLs. Preserve the
  historical `readmit` `0.0.1` NEWS entry.
- Finish RRP release notes under `# readmit (development version)`. Prepare
  `cran-comments.md` with concise submission context, relevant CRAN and
  reverse-dependency information, and the changed purpose, breaking API, and
  MIT-to-Apache-2.0 license transition. Populate final test environments and
  check results from exact release-version checks in Stage 6.8, before
  submission; remove the pending text then.
- Run relevant local package checks and external checks (for example,
  `devtools::check_win_devel()` when appropriate), inspect the actual results,
  and resolve release-blocking issues. Review the existing CRAN check page and
  affected reverse dependencies, if any. Confirm a clean, reviewed Git source
  state and record the release-candidate outcome.

`devtools::check()` is a conventional local check; it may also regenerate
documentation, so inspect Git afterward. Remote-builder helpers upload a source
package to an external check service and send results by email. Stage 6.7
remains at a **development version**: do not run `use_version()`, submit to
CRAN, or publish a GitHub release. Its checks do not replace the exact-version
checks in Stage 6.8.

## 2. Start release execution (Stage 6.8)

Proceed only after Stage 6.7 is approved and the maintainer is ready for
externally visible submission and publication. Review the branch, pending
changes, current version, and latest commit:

```sh
git status --short --branch
git log -1 --oneline
```

Resolve unrelated work and start from the intended clean development source.
Keep the release on the normal development branch; no release branch is needed.

## 3. Set and review the release version

For the **first RRP submission only**, run:

```r
usethis::use_version("major")
```

From `0.0.1.9000`, expect `1.0.0`. This helper changes `DESCRIPTION` and
replaces the leading development NEWS heading with the release heading. In an
interactive Git project it can offer to commit those changes; an optional
`push = TRUE` can push when safe. **Check whether a commit actually occurred.**
For later releases, select the increment appropriate to the current version
and release intent.

```r
read.dcf("DESCRIPTION")[1, "Version"]
readLines("NEWS.md", n = 1)
```

```sh
git status --short
git diff --check
git diff -- DESCRIPTION NEWS.md cran-comments.md
git log -1 --oneline
```

Review the committed changes as well (`git show --stat HEAD`). Update
`cran-comments.md` with any release-specific facts not yet recorded. Commit all
reviewed source changes with ordinary Git if the helper did not commit them;
do not assume the helper's prompt created the final release commit. Confirm
the release version, NEWS heading, and clean source tree before checking the
release package.

## 4. Check the exact release-version source

Build and check a source bundle from the clean, committed release-version
tree. Run this shell block **from the repository root**; it puts check output
in a fresh temporary directory. It reads the release version from
`DESCRIPTION` rather than assuming `1.0.0`:

```sh
repo_dir=$(pwd)
release_version=$(Rscript -e 'cat(read.dcf("DESCRIPTION")[1, "Version"])')
check_dir=$(mktemp -d)
cd "$check_dir"
R CMD build "$repo_dir"
R CMD check --as-cran "readmit_${release_version}.tar.gz"
cd "$repo_dir"
```

Review the complete check log, source archive metadata, warnings, and notes;
resolve actual issues before submission. The build should include the package
files and exclude `cran-comments.md`. Use relevant additional platform checks
when indicated. Return to the repository root before the next step and verify
the intended release commit SHA with `git rev-parse HEAD` and a clean Git
status. If a check prompts any source or CRAN-comment change, commit the
reviewed change and repeat the appropriate release-version build and checks.

`devtools::submit_cran()` makes a **fresh** source build for upload. The checked
bundle and that later upload come from the same reviewed source when Git is
clean, but separately built archives are not asserted to be byte-identical.
No custom manifest or tarball-preservation step is required.

## 5. Submit to CRAN and confirm

With the final source and SHA reviewed, run from the repository in R:

```r
devtools::submit_cran()
```

Review its maintainer-email and upload prompts. It builds and uploads a source
package; it does **not** replace the checks above. After a successful upload
in this Git repository, it writes `CRAN-SUBMISSION` with the version, UTC
submission time, and current `HEAD` SHA, and ensures that file is in
`.Rbuildignore`. Inspect the record and compare its version/SHA with the
release commit identified before submission. Do not fabricate or commit this
temporary record. Review any tracked `.Rbuildignore` change separately; a
later commit of that ignore entry is not the submitted source commit.

Follow the confirmation link in the maintainer email. Upload alone is not a
completed submission, and email confirmation is **not CRAN acceptance**. Wait
for CRAN check results or correspondence; do not send a replacement while the
current submission remains pending.

## 6. Respond to CRAN feedback if needed

Read the specific response and correct the relevant source or documentation.
For a rejected submission, review any pending `.Rbuildignore` change from the
last upload, then normally advance the patch version unless CRAN explicitly
directs otherwise:

```r
usethis::use_version("patch")
```

For example, rejected `1.0.0` normally becomes `1.0.1`. The helper can add a
new top NEWS heading while leaving the unreleased `1.0.0` notes below it;
review and arrange the notes so the eventual published version is described
accurately. Add a short **Resubmission** section to `cran-comments.md` that
answers CRAN's feedback and update actual check results. Review the changes,
commit the corrected version/source, rebuild, and rerun appropriate checks
from step 4. Submit again with `devtools::submit_cran()`, confirm the new email,
and inspect the new `CRAN-SUBMISSION` version/SHA. Each submission has its own
version and corresponding source commit. Do not publish a rejected version as
an accepted GitHub release.

## 7. Confirm acceptance, then publish on GitHub

Wait for explicit CRAN acceptance. Confirm the accepted version, the final
submitted source, and the latest `CRAN-SUBMISSION` version and SHA agree. If
the record is missing or inconsistent, investigate the accepted source before
publication: `use_github_release()` can otherwise fall back to the **current
HEAD**, which may be a later commit.

Only after this checkpoint, run:

```r
usethis::use_github_release()
```

It may push the branch, then asks GitHub to create a release and `v<accepted
version>` tag at the recorded SHA. It uses NEWS at that source commit for
release notes and removes `CRAN-SUBMISSION` after successful publication.
Verify the GitHub release's version, tag, and target commit against the
accepted CRAN submission. GitHub's automatic ZIP/tar source downloads are
repository snapshots, not CRAN's `R CMD build` package bundle. A manual CRAN
tarball attachment is not required.

| CRAN acceptance | GitHub tag/release | Next development version |
| --- | --- | --- |
| `1.0.0` | `v1.0.0` | `1.0.0.9000` |
| `1.0.1` after correction | `v1.0.1` | `1.0.1.9000` |

## 8. Return to development

After the GitHub release succeeds, with `DESCRIPTION` still at the accepted
three-component version, run:

```r
usethis::use_dev_version()
```

It adds `.9000` to the accepted version in `DESCRIPTION` and adds a fresh
development NEWS heading. In an interactive Git project it can offer a commit
and optional push. Verify the resulting version and NEWS heading, review Git
status/log, and commit/push the development state as intended. Do not derive
this version from an earlier rejected submission.

## Completion check

- CRAN accepted the final submitted version and its source commit is known.
- GitHub published `v<accepted version>` at that commit, after acceptance.
- The new development version is `<accepted version>.9000`; its NEWS heading,
  commit, and intended push are complete.
- The temporary `CRAN-SUBMISSION` record was removed by the release helper or
  any exception was investigated; the repository is ready for further work.

## Authoritative references

- [*R Packages*: Releasing to CRAN](https://r-pkgs.org/release.html)
- [`usethis::use_version()` and `use_dev_version()`](https://usethis.r-lib.org/reference/use_version.html)
- [`usethis::use_github_release()`](https://usethis.r-lib.org/reference/use_github_release.html)
- [`devtools::submit_cran()`](https://devtools.r-lib.org/reference/submit_cran.html)
- [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html)
