# Package Development Notes

Contains daily notes with details about how things were developed.
Primarily following <https://r-pkgs.org/>.

# 12/10/2025

- Adding `Suggests` dependencies for `ggplot2` and `reactable`. This
  should allow the article to work with GitHub Actions. Also adding back
  in `purrr`.

# 12/2/2025

- Converting vignette to article
  (<https://r-pkgs.org/vignettes.html#sec-vignettes-article>) because I
  want a lot of useful graphics that won’t work with vignette. Also can
  remove the `purrr` dependency then.
  `use_article("investigating-an-hsr.qmd", title = "Investigating a Hospital-Specific Report (HSR)")`.
  Notice I used quarto instead of Rmd.
- Actually per [this
  issue](https://github.com/r-lib/pkgdown/issues/2830), and the errors I
  was getting, I’m reverting back to `Rmd`
  (`use_article("investigating-an-hsr.Rmd", title = "Investigating a Hospital-Specific Report (HSR)")`)

# 12/1/2025

- Added “Suggests” dependency on `purrr` since it is used in the
  vignette (`use_package("purrr", type = "Suggests")`). Described here:
  <https://r-pkgs.org/vignettes.html#sec-vignettes-eval-option>

# 11/27/2025

- Working on finishing vignette. Realized there are more column parsing
  errors we need to correct.

# 11/26/2025

- CMS changed the HSR format for 2026. Added to documentation to note
  this change in README, vignette, and function docs.
- Changed DESCRIPTION and README package descriptions
- Fixed global binding issues
- Fixed special characters in columns by removing them

# 11/25/2025

- Adding to `README` with a description of the package
- Adding a skelaton vignette for “Investigating a Hospital-Specific
  Report (HSR)”, as it’s linked from README. Will actually write it
  later. Initialized it with `use_vignette("hsr-analysis")`.

# 11/23/2025

- Added a custom color scheme to package site. Used HEX color picker and
  uploaded package logo, then used those colors to specify
  background/font colors, and used Google fonts.

# 11/22/2025

- Changed timeline function to be `hrrp_get_dates`. For now, it just
  takes one date object and returns a subset of the included tables
  based on input setttings. Sufficient for now until different
  functionality needed.

# 11/21/2025

- Adding an extenal dataset containing key dates for HRRP
  (<https://r-pkgs.org/data.html#sec-data-data>). This will be available
  to users but also available internally to my functions.

# 11/17/2025

- Decided not to do a timeline function because it’s static output; can
  just direct people to CMS docs in documentation
- Instead, just having a single function `hrrp_program_year` that
  actually returns program year for a vector of inputs which can be
  useful for a dataset

# 11/15/2025

- Making a function called `hrrp_timeline` which will take one or more
  dates and return import dates in context to that date around the HRRP
  program. Default to current date.

# 11/14/2025

- Spacing out examples so they render better in documentation/website
- Adding function to create individual-level readmission risks
  (predicted and expected). Have the global binding issue to deal with
  again:

&nbsp;

    ❯ checking R code for possible problems ... NOTE
      hsr_readmission_risks: no visible binding for global variable ‘Value’
      hsr_readmission_risks: no visible binding for global variable ‘Factor’
      hsr_readmission_risks: no visible binding for global variable ‘Weight’
      hsr_readmission_risks: no visible binding for global variable ‘ID
        Number’
      hsr_readmission_risks: no visible binding for global variable ‘LP’
      hsr_readmission_risks: no visible binding for global variable
        ‘Predicted’
      hsr_readmission_risks: no visible binding for global variable
        ‘Expected’
      Undefined global functions or variables:
        Expected Factor ID Number LP Predicted Value Weight

    0 errors ✔ | 0 warnings ✔ | 2 notes ✖

But we’ll carry on for now.

- Also, discovered there are nuances in column names in the reports,
  such that some headers will have annoying special characters, so need
  to create more robust approach for specifiying headers (without
  drastically changing their source names).
- Renaming `_extract_` functions without prefix because it isn’t needed

# 11/13/2025

- Created function to extract the dually-eligible stays
  (`hsr_extract_dual_stays`).
- Changing all examples to use the FY2025 mock report.

# 11/12/2025

- Added formatted reference index to the package website. See [this
  issue](https://github.com/centralstatz/readmit/issues/15).
- Added function (`hsr_extract_discharges`) to import discharges for a
  specified cohort. Also gives the ability to keep certain columns
  (e.g., PHI, risk factors) and certain rows (e.g., eligible discharges
  only).

# 11/11/2025

- Created function to extract cohort summary
  (`hsr_extract_cohort_summary`). See [this
  issue](https://github.com/centralstatz/readmit/issues/10)

# 11/10/2025

- Grouping PDC functions together into common `.R` file and
  documentation (<https://github.com/centralstatz/readmit/issues/9>)
- Updated documentation across files to better align best practices
  (<https://r-pkgs.org/man.html#roxygen2-basics>)
- Changed the `hsr_extract_payment_summary` function to return wide
  format. Added helper functions (non-exported) that consolidate
  repeated code in convenience functions.
- Used `use_import_from("rlang", ".data")` to resolve the global binding
  issue. Then in the `hsr_extract_coefficients` function, used the
  `.data` pronoun (`dplyr::filter(!is.na(.data$Value))`)
- Only 1 note regarding `NEWS.md`

&nbsp;

    ❯ checking package subdirectories ... NOTE
      Problems with news in ‘NEWS.md’:
      No news entries found.

    0 errors ✔ | 0 warnings ✔ | 1 note ✖

# 11/9/2025

- Created functions to extract Table 1 HSR components:
  `hsr_extract_payment_summary` and individual functions. All of these
  are defined in the same `.R` file and are grouped in the same `Rd`
  file. Probably need to do some clean. Stil debating if default
  behavior should be a pivoted data frame or not.

# 11/7/2025

- Initialized functions to explore/import data directory from the
  [Provider Data Catalog](https://data.cms.gov/provider-data/). These
  were adapted from a previous package I already started
  (<https://github.com/zajichek/carecompare/blob/main/R/FUNCTIONS.R>).
  `pdc_topics`, `pdc_datasets`, `pdc_read`. Also initialized unit test
  files for them.
  - Added dependencies as well: `httr`, `readr`, `tibble`
  - Added inital tests for all functions
- Still have some notes about global bindings

&nbsp;

      hsr_extract_coefficients: no visible binding for global variable
        ‘Value’
      pdc_datasets: no visible binding for global variable ‘issued’
      pdc_datasets: no visible binding for global variable ‘modified’
      Undefined global functions or variables:
        Value issued modified

    0 errors ✔ | 0 warnings ✔ | 2 notes ✖

# 11/6/2025

- Added package dependencies for `readxl`, `stringr`, `dplyr`, `tidyr`,
  `rlang` with `use_package()`
- Added unit testing structure with `use_testthat()`; created initial
  (toy) test for `use_test("hsr_extract_coefficients")`
- Added a README file with `usethis::use_readme_rmd()` and built default
  `.md` file with `build_readme()`
- Added NEWS.md with `use_news_md()`
- Added badges (in anticipation): `use_cran_badge()`, `use_coverage()`,
  `use_github_action("check-standard")`
- Added logo (created with
  [hexmake](https://connect.thinkr.fr/hexmake/) + ChatGPT): `use_logo()`
- Started package website with `use_pkgdown()` and
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
  to get initial site
- Then used `usethis::use_pkgdown_github_pages()` to create GitHub
  Actions workflow to update site on commit/push. This automatically
  configures on GitHub (the branch is created and my Pages are
  configured). But I need to push the site because no `pkgdown` stuff is
  there yet.
- Added example HSR report to package, following steps here:
  <https://r-pkgs.org/data.html#sec-data-extdata>
  - Made the `inst/extdata/` directory
  - Went to QualityNet and downloaded the FY 2025 HSR
    (<https://qualitynet.cms.gov/inpatient/hrrp/reports#tab3>) (as of
    11/8/2025 @ 11:56 AM CST). Added this file to the above directory.
  - As suggested
    (<https://r-pkgs.org/data.html#sec-data-example-path-helper>) I
    created a new helper function `hsr_example()` to help identify this
    file for users. `use_r("hsr_example")`. I then copied their exact
    function definition (with changes to reflect the current package).
    Added documentation. Added unit test to ensure that example file
    exists in user file system.
  - Did final `check()`, still one (expected) note (will resolve later)
    \`\`\` ❯ checking package subdirectories … NOTE Problems with news
    in ‘NEWS.md’: No news entries found.

❯ checking R code for possible problems … NOTE hsr_extract_coefficients:
no visible binding for global variable ‘Value’ Undefined global
functions or variables: Value

0 errors ✔ \| 0 warnings ✔ \| 2 notes ✖

    * Added all FY mock reports to `extdata`. Used `rename_files("hsr_example", "hsr_mock_reports")` to rename the function to be more explicit. Changed all required areas to accomodate change.

    # 11/5/2025

    * Initialized package by creating repo here: https://github.com/centralstatz/readmit
    * Then created _New Folder from Git_ in Positron, cloning that repo
    * Then used `usethis::create_package(getwd())` to initialize package template
    * Added this file `DEVNOTES.md` to `.Rbuildignore`
    * Ran `usethis::use_r("hsr_extract_coefficients")` to create the packages first function, which extracts the list of model coefficients from a CMS Hospital Specific Report (HSR) for a specified cohort. Added argument checks.
    * Used `devtools::load_all()` to test it (works on locally downloaded report).
    * Did initial `devtools::check()` and got various warnings/notes, which is expected because nothing was configured yet.
    * Edited the `DESCRIPTION` file (with possibly to change over time as package evolves), and added MIT license with `usethis::use_mit_license()`
    * Added `roxygen2` documentation to function. Used `devtools::document()` to document it. Added `\dontrun` to roxygen for function as example doesn't work yet. Need to put external data in the package.
    * Still have warning/note as I haven't declared dependencies, so will do that soon.

❯ checking R code for possible problems … NOTE hsr_extract_coefficients:
no visible binding for global variable ‘Value’ Undefined global
functions or variables: Value

0 errors ✔ \| 1 warning ✖ \| 1 note ✖ \`\`\`

Starting [here](https://r-pkgs.org/whole-game.html#install) next…
