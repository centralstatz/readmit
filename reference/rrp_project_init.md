# Create an RRP project

Copy the installed project template into a new, user-owned directory.
The project contains editable configuration, branding, source-mapping
and risk-provider scripts, and a Shiny application. Initialization does
not create analytical state or products. The project owner must
implement the two analytical scripts before running assessments.

## Usage

``` r
rrp_project_init(path, project_id)
```

## Arguments

- path:

  Destination for the new project. Its parent directory must exist, and
  the destination itself must not exist, even as an empty directory.

- project_id:

  A nonempty project identifier beginning with a letter or digit and
  containing only letters, digits, `.`, `_`, or `-`. It fills the
  project identity and initial branding fields; edit `_brand.yml`
  afterward to change the displayed name or styling.

## Value

The normalized project path, invisibly.

## Details

The project-owned application runs separately with ordinary Shiny
tooling, for example `shiny::runApp("path/to/project/app")`, after its
dependencies are installed as described in the project's `README.md`.

## Examples

``` r
project <- file.path(tempdir(), "example-rrp-project")
if (!file.exists(project)) {
  rrp_project_init(project, "example-rrp-project")
}
```
