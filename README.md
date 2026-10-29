
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readmit <img src="man/figures/logo.png" align="right" height="138" alt="" />

<!-- badges: start -->

[![CRAN
Status](https://www.r-pkg.org/badges/version/readmit)](https://cran.r-project.org/package=readmit)
![CRAN_Download_Counter](http://cranlogs.r-pkg.org/badges/grand-total/readmit)
[![Codecov test
coverage](https://codecov.io/gh/centralstatz/readmit/graph/badge.svg)](https://app.codecov.io/gh/centralstatz/readmit)
[![R-CMD-check](https://github.com/centralstatz/readmit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/centralstatz/readmit/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`readmit` creates editable, user-owned Readmission Risk Pool (RRP)
projects. Each project includes configuration, source-mapping and
risk-provider scripts, branding, and its own Shiny application. Risk
assessment, persistent history, and analytical products are not yet
available.

## Create and open a project

After installing `readmit`, create a project at a new destination:

``` r
library(readmit)

project <- rrp_project_init(
  path = "my-rrp-project",
  project_id = "my-project"
)

rrp_project_validate(project)
```

The path is relative to your current working directory unless you supply
an absolute path. Its parent directory must already exist, and the
destination must not exist, even as an empty directory. The generated
files belong to you: edit `rrp-project.dcf`, `rrp-authoring.dcf`,
`_brand.yml`, `R/produce-canonical.R`, and `R/calculate-risk.R` for your
project. `rrp_project_validate()` checks that the configuration and both
authoring functions load; it does not run them. Both generated functions
begin as deliberate stubs, so the untouched project passes this
structural check. Implement the source mapper to return the canonical
discharge episodes and terminal events described in the project README,
then validate again after editing. The package can invoke that mapper
internally, but there is no public analytical execution command yet.

The application uses `shiny`, `bslib`, and `yaml` in the environment
where it runs. Install them there, then launch the app directly from the
same working directory used in the example:

``` r
install.packages(c("shiny", "bslib", "yaml"))
shiny::runApp("my-rrp-project/app")
```

The app opens with Current Risk Pool and Overview views and shows empty
states until analytical products become available in a later development
stage.
