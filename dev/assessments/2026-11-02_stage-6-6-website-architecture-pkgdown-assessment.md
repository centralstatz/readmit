# Stage 6.6.A — Website Architecture and pkgdown Assessment

- **Assessment date:** 2026-11-02
- **Repository / branch:** `readmit` / `main`
- **Inspected commit:** `ab54c95` (Stage 6.5 closeout)
- **Package version:** `0.0.1.9000`; installed local pkgdown version: `2.1.3`
- **Scope:** Website architecture assessment only. No site redesign, workflow change, publication, or release operation.

## Executive summary

Keep pkgdown as the single website generator. Give the website its own platform-first homepage at `pkgdown/index.md`, while `README.Rmd` continues to generate the GitHub `README.md`. In this repository, that location is simpler than root `index.md`: pkgdown 2.1.3 gives it highest homepage precedence, and the existing `.Rbuildignore` already excludes the whole `pkgdown/` directory from the R package source bundle. Use `_pkgdown.yml` for a modest navigation and Bootstrap 5/bslib theme update, with a small `pkgdown/extra.scss` or `extra.css` only for presentation that theme variables cannot express. Reuse the two existing tutorials and generated reference at their current routes. The current GitHub Actions build and `gh-pages` deployment need no change for this approach.

The proposed site can explain RRP as a platform without turning the homepage into a second tutorial or replacing package documentation. This is a recommendation for maintainer review, not an approved design. The build and publication contract for both tutorials is a hard boundary for later work.

## Current state and evidence

| Area | Observed repository behavior | Evidence basis |
| --- | --- | --- |
| Homepage | `_pkgdown.yml` has no `home` setting or authored `index.md`. Installed pkgdown selects `README.md` as the homepage source. The README leads with the RRP banner, package hex, platform explanation, workflow, and development installation instructions. | `pkgdown:::as_pkgdown()` and `path_index()` on this tree; `README.Rmd`/`README.md`; inspected ignored local `docs/index.html`. |
| Navigation | No `navbar`, `articles`, or `reference` sections are configured. pkgdown's current default provides Reference, an Articles menu containing both tutorials, Changelog from `NEWS.md`, search, and GitHub. There is no automatic top-level “Get started” entry because neither vignette is named `readmit`. | `_pkgdown.yml`; `pkgdown:::navbar_articles()` and `template_navbar()` on this tree. |
| Appearance | `_pkgdown.yml` selects Bootstrap 5 and bslib colors `#F6E2BE` / `#4E6E57`, a tan navbar, and Google Lexend, Tomorrow, and JetBrains Mono fonts. There is no `pkgdown/extra.scss`, `extra.css`, or `pkgdown/templates/` override. These colors predate the accepted navy/blue/violet identity. | Configuration and tracked-file inspection; installed pkgdown theme functions. |
| Assets | `man/figures/logo.png` is the conventional package hex and is also pkgdown's detected site logo. Platform dark/light logos, banner, and package hex vector source live in `man/figures/`, which pkgdown copies to `reference/figures/`. `pkgdown/favicon/` contains the active favicon set; `pkgdown/rrp-favicon-candidate.svg` is only a candidate and is not auto-copied by the current asset rule. | Tracked assets; 6.5 record; inspected identity preview; installed `copy_figures()`, `copy_favicons()`, `copy_assets()`, and `find_logo()`. |
| Output | `docs/` is ignored by Git and contains local generated pages and copied figures from prior builds. Some older reference pages remain there, so its contents are evidence of local rendering, not a clean current build or live deployment. | `git ls-files docs` returned no files; local `docs/` inspection. |

The live domain and its two article routes could not be fetched through the available browser tool during this assessment. The maintainer previously confirmed that the accepted logos render on the existing website; this assessment does not claim fresh live-site verification.

## Technical findings

### Homepage source and content

Installed pkgdown 2.1.3 checks `pkgdown/index.md`, root `index.md`, then `README.md` in that order. Its `build_home_index()` renders the chosen Markdown into `index.html`; `build_site_github_pages()` invokes the ordinary full site build, so a new `pkgdown/index.md` would be picked up by the existing workflow after a push. This agrees with [pkgdown's home-page documentation](https://pkgdown.r-lib.org/reference/build_home.html). A root `index.md` also works, but it would need an R package build-exclusion decision because `.Rbuildignore` does not currently exclude that root file. `pkgdown/index.md` uses the already excluded site directory and keeps GitHub's README workflow intact.

Markdown headings, links, and limited semantic HTML can form a distinct landing page within the normal pkgdown page wrapper; Bootstrap classes can structure restrained cards or calls to action. No internal template override is needed for a hero, capability summary, installation route, or documentation links. A disposable Markdown render preserved relative links to both existing article routes and `reference/index.html`, plus an image path under `reference/figures/`. Those paths are appropriate for the root `index.html`; pages under `articles/` need their own relative depth or site-root-aware links. The configured `url` is `https://readmit.centralstatz.com/`, so the planned homepage is at the domain root. Avoid hard-coding GitHub Pages repository subpaths. Test links and image loading in a clean full build and after deployment.

The banner was composed for GitHub README use. A platform logo plus concise text may be a better website hero than repeating the entire banner; this is a visual choice for Stage 6.6 implementation. The established asset family offers both treatments without new machinery.

### Information architecture and navigation

Use one short homepage to answer what RRP is, why repeated assessment matters, what the package supplies versus what the organization supplies, the main capabilities, current pre-release status, and two routes into the documentation. Preserve clinical and analytical precision through concise copy and links into the existing tutorials. Put the full source mapping, trained-model example, repeated assessments, product interpretation, and app customization in the comprehensive article. Keep the installed vignette as the portable first operational walkthrough. Generated function help remains the authoritative API reference; `NEWS.md` remains the chronological package change record.

A practical navbar is **Home** (through the site title/logo), **Get started** (explicit link to `articles/getting-started.html`), **Implementation guide** (link to `articles/implementing-rrp.html`), **Reference**, and **News**, with search and GitHub retained. An Articles dropdown containing both existing resources is also viable if the navbar becomes crowded on narrow screens; the two links should remain visible from the homepage and articles index. `_pkgdown.yml` supports navbar structure/components and article-index organization without moving source files. If an `articles:` index is added, include both current vignette names; installed `data_articles_index()` errors when non-intro articles are omitted. Avoid a second motivation/capabilities page until the homepage proves too dense. [Pkgdown's customization guide](https://pkgdown.r-lib.org/articles/customise.html) describes these supported navigation controls.

### Theme, typography, and site assets

Bootstrap 5 is already selected. Installed pkgdown passes `_pkgdown.yml` `template.bslib` values to `bslib::bs_theme()`, uses `pkgdown/extra.scss` as a site-specific Sass rule layer, and links `pkgdown/extra.css` after default CSS. It copies `pkgdown/assets/` to the website root and `pkgdown/favicon/` into the output root. These are supported extension points, documented in [pkgdown's customization guide](https://pkgdown.r-lib.org/articles/customise.html). `pkgdown/templates/` can override internal layouts, but that would couple this site to pkgdown markup and is not justified by the requested presentation.

Use bslib variables for deep navy `#0B1428`, readable foreground, blue `#75B7FF`, violet `#A38BFA` accents, navbar treatment, and type hierarchy. Add a narrowly scoped stylesheet for homepage composition, spacing, responsive cards, and perhaps a subtle trajectory motif. Check contrast, keyboard focus, mobile wrapping, reference/article readability, code blocks, tables, and the default search/nav controls. The current Google font specifications can trigger network fetches during a fresh local build; either retain them with a reliable build environment or use bundled/system fonts as a design decision. Introducing a second CSS system, site framework, or broad template override would create maintenance cost without a demonstrated benefit.

The homepage should lead with the RRP platform logo variant suited to its surface. Keep the `readmit` hex recognizable in the pkgdown navbar and technical/package reference contexts. Installed pkgdown's global site-logo lookup uses conventional root or `man/figures/` `logo.svg`/`logo.png` paths; there is no separate configured platform-logo path in this repository. A homepage platform wordmark plus existing package site logo is the simplest supported distinction. Replacing the global logo independently would need additional markup or file-precedence handling and should be considered only if visual review shows a real need. Consider the RRP favicon candidate as the website icon, because the domain is platform-oriented. The candidate SVG alone is not a complete replacement for the existing PNG/ICO/manifest set: if adopted, prepare consistent favicon files under `pkgdown/favicon/` and inspect browser behavior. This is presentation work in 6.6, not unfinished 6.5 work. `usethis::use_logo()` is unnecessary for that website-only choice and could affect the conventional package logo/README references.

### Application visuals and development status

The app itself is complete and project-owned. One cropped static screenshot showing the Current Risk Pool and trajectory with clearly labelled **simulated** data would help prospective users understand the finished workflow; the Overview can be a second image only if it materially adds clarity. Use an optimized image at a desktop aspect ratio, a responsive width rule, informative alt text, and a narrow-screen review. `pkgdown/assets/` is a supported site-only location for such an image; no Shiny build or app code change is needed. The homepage could show one preview linked to the tutorial's app section; a gallery or live embedded app is unnecessary.

The website should label the RRP package implementation as development version `0.0.1.9000`, link to GitHub installation, and say explicitly that CRAN `readmit` 0.0.1 is older, different functionality. Do not imply that RRP v1.0.0 has been submitted to or accepted by CRAN, or that its demonstration model is clinically validated. Keep this in ordinary homepage prose, with one clearly identified text update in Stage 6.8 after CRAN acceptance; no dynamic release-status service or badge logic is needed. Cross-check the homepage against `README.md`, `DESCRIPTION`, and the eventual `NEWS.md` release heading.

### Existing documentation and publication lifecycle

`vignettes/getting-started.Rmd` has `rmarkdown::html_vignette` metadata and a vignette index entry. `DESCRIPTION` declares `VignetteBuilder: knitr` and suggests `knitr`/`rmarkdown`. Ordinary `R CMD build` renders and bundles it under `inst/doc/`; installed users can find it with `vignette(package = "readmit")`. Independently, pkgdown recursively discovers this source under `vignettes/` and maps it to `articles/getting-started.html`. The Stage 6.4 record verified build, installation, and local article rendering. The current default Articles menu contains it.

`vignettes/articles/implementing-rrp.Rmd` is discovered by pkgdown's recursive vignette scan and maps to `articles/implementing-rrp.html`. Its source and render use `readmit`, `dplyr`, and `tidyr`; the latter two are declared under `Config/Needs/website`, so the workflow's `needs: website` installation supplies them. `.Rbuildignore` excludes `^vignettes/articles$`, keeping the comprehensive source out of the package bundle while pkgdown still sees it in the repository checkout. The Stage 6.4 record verified local rendering and its absence from a built/installed package. The current Articles menu and generated index include it. Moving it outside `vignettes/`, changing its basename, or dropping the website dependencies would change or break this behavior.

Pkgdown reads the package's `man/*.Rd` topics and generates `reference/index.html` and individual `reference/<topic>.html` pages. With no configured `reference:` index, it uses its default grouping. Navbar/homepage edits do not stop automatic topic generation; an explicit reference index must continue to include discoverable public topics. The workflow also builds `news/index.html` from `NEWS.md` and a Bootstrap 5 local search index.

`.github/workflows/pkgdown.yaml` triggers on pushes to `main` or `master`, pull requests, published releases, and manual dispatch. It checks out the repository, installs Pandoc and R, then uses `r-lib/actions/setup-r-dependencies@v2` with `extra-packages: any::pkgdown, local::.` and `needs: website`. Its R step runs `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`: the installed package and source checkout together supply function examples and both article sources; pkgdown builds `docs/`, writes `.nojekyll`, and derives `CNAME` from `_pkgdown.yml`'s root URL. On non-PR runs, `JamesIves/github-pages-deploy-action@v4.5.0` publishes `docs/` to `gh-pages` with `clean: false`. GitHub Pages repository settings and DNS are external prerequisites; this assessment inspected configuration but did not exercise deployment or verify live branch/settings. `clean: false` can leave old remote files after route removals, another reason to retain article routes. Source `docs/` is Git-ignored, and `^docs$` is excluded from the package source. The prior implementation record reports a local full-site build blocked by a `crandb.r-pkg.org` news lookup; this assessment's disposable build also encountered blocked font/CDN downloads. Neither is evidence that a custom homepage requires a workflow change.

## Architecture options and tradeoffs

| Option | Benefit | Cost / conclusion |
| --- | --- |
| Keep README as homepage | Zero new source file; existing automatic build. | README must serve GitHub and platform site simultaneously; harder to create a focused site hierarchy. Adequate fallback, but weak for the stated platform-first goal. |
| Add root `index.md` | Official pkgdown-supported independent homepage; straightforward authoring. | Would need a decision about excluding a new root file from the package bundle. No benefit over `pkgdown/index.md` here. |
| Add `pkgdown/index.md` | Official source precedence, independent GitHub README, already excluded from package build, and picked up by the existing site command. | Requires maintaining concise homepage copy and testing relative asset/doc links. **Recommended.** |
| Use broad custom templates or a second framework | Maximum layout control. | Fragile pkgdown internals, duplicated documentation/publication pipeline, and extra maintenance. No concrete limitation found that justifies this route. |

## Documentation preservation contract for Stage 6.6

The redesign may change homepage text, theme, and navigation. It must preserve the existing **push → GitHub Actions → pkgdown build → published site** path for both tutorials, with no manual export, copy, separate build, or separate publication step.

| Resource | Preserve | Regression check before accepting later site changes |
| --- | --- | --- |
| Installed getting-started vignette | `vignettes/getting-started.Rmd`, vignette YAML/index entry, `VignetteBuilder: knitr`, `knitr`/`rmarkdown` dependency declarations, and route `articles/getting-started.html`. | `R CMD build` and separate-library install expose `inst/doc/getting-started.html` and `vignette("getting-started", package = "readmit")`; clean pkgdown build renders the article and its homepage/navbar link. |
| Website-only implementation article | `vignettes/articles/implementing-rrp.Rmd`, website `dplyr`/`tidyr` dependencies, `.Rbuildignore` exclusion, and route `articles/implementing-rrp.html`. | Built package omits `vignettes/articles/`; clean pkgdown build renders the page, articles index, and homepage/navbar link using the existing workflow dependency set. |
| Function reference | `man/*.Rd` generation through normal roxygen/package workflow; pkgdown `reference/index.html` and public topic pages. | Clean pkgdown build produces reference index and expected exported-function pages; navbar/search links resolve. |
| Publication | Existing workflow trigger, `needs: website`, `build_site_github_pages(...)`, `docs/` output, `gh-pages` deployment, configured domain/CNAME. | CI run on a pushed change completes the pkgdown build and deployment; inspect deployed home, both articles, reference, search, images, CSS, favicon, responsive nav, and links on the live domain. PR build may check rendering but does not deploy. |

Do not treat a local rendering check as a substitute for the later pushed-workflow and live-site verification. If future site work changes a build or publication input, document the reason and repeat the affected checks above.

## Change risk and implementation implications

**Presentation-only, preferred:** Add `pkgdown/index.md`; edit `_pkgdown.yml` theme and navbar; add small `pkgdown/extra.scss`/`extra.css` if needed; reference accepted platform assets; add an optimized simulated-app screenshot under `pkgdown/assets/` if approved; update text links and status language. These leave tutorial discovery, package build, function reference generation, and deployment commands intact. The current favicon set may be replaced as a website asset decision without changing package logo handling.

**Build/publication changes, not presently recommended:** Moving either vignette, changing `.Rbuildignore`, changing `Config/Needs/website` or `VignetteBuilder`, altering pkgdown article/reference generation, changing the GitHub Actions build command or deployment branch/folder, adding website frameworks or template packages. No such change is necessary for the recommended design. If a later concrete need requires one, identify the affected resource and route, preserve automatic rendering, and run the corresponding preservation checks plus a pushed CI/live-site check.

Likely later workstreams are: agree on the homepage hierarchy and concise platform copy; apply theme/nav/style to a local preview; select and integrate site logo/favicon and possibly one app screenshot; verify the clean local build and both documentation routes; then publish through the existing workflow and review the live desktop/mobile site. These are work areas for subsequent collaborative planning, not detailed 6.6 sub-increments.

## Open decisions for maintainer review

1. Approve `pkgdown/index.md` as the separate platform homepage and the proposed short navigation, or adjust the top-level labels/order.
2. Choose whether the website favicon should switch to the RRP candidate, with matching PNG/ICO/manifest files, or retain the package-oriented set.
3. Decide whether one simulated-app screenshot materially improves the homepage and whether to use a platform logo hero or the existing wide banner. The technical placement and build path are resolved; these are editorial/visual choices.

No decision is needed about moving tutorials, replacing pkgdown, or changing the publication workflow based on current evidence.

## Verification and limitations

Read `AGENTS.md`, architecture/plan/record, the earlier repository and Stage 6 assessments, README source/output, `_pkgdown.yml`, `DESCRIPTION`, vignette/article source, `.Rbuildignore`, asset files and identity preview, the pkgdown and package-check workflows, release guidance, and the ignored local `docs/` tree. Inspected installed pkgdown 2.1.3 functions for homepage selection, article discovery/routes, navbar, reference generation, theme/style injection, asset copying, full-site build, and GitHub Pages files. A disposable copy verified README → root `index.md` → `pkgdown/index.md` precedence; a focused Markdown render verified a custom homepage heading plus both article links, the reference-index link, and a figure path. All disposable files were removed. Official [home-page](https://pkgdown.r-lib.org/reference/build_home.html), [customization](https://pkgdown.r-lib.org/articles/customise.html), and [article-build](https://pkgdown.r-lib.org/reference/build_articles.html) documentation supports the same mechanisms.

A full disposable page build could not finish because this environment could not resolve Google Fonts or CDN hosts; a narrower render succeeded. The prior 6.5 local build verified homepage/reference figure paths but hit a network-dependent news lookup during full-site build. This assessment did not run package tests/checks, push a commit, run GitHub Actions, or verify the live Pages site. The CI configuration supports the recommended approach, but its behavior after a future homepage/style change must be verified in a real pushed run. CI's future installed pkgdown version may differ from the local 2.1.3 because `any::pkgdown` is not pinned; test the actual CI build and avoid unsupported internals.
