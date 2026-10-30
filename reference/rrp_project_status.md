# Summarize an RRP project's retained history

Read project identity and completed-run status without sourcing the
project's analytical scripts, executing an assessment, or changing
state. This also works before analytical state has been initialized.

## Usage

``` r
rrp_project_status(path)
```

## Arguments

- path:

  Path to an existing RRP project directory.

## Value

An ordinary named list containing character `project_id`, logical
`state_initialized`, integer `run_count`, character `latest_run_id`, and
UTC `POSIXct` `latest_as_of_time`. The latest fields are typed missing
values when there are no runs.

## Details

The latest run is the most recently recorded completed run by
`created_at`, not the largest analytical `as_of_time`. Ties in recorded
creation time are broken by `run_id`. Reads use a read-only connection
and do not initialize state.

## Examples

``` r
project <- tempfile("rrp-status-")
rrp_project_init(project, "example-rrp")
rrp_project_status(project)
#> $project_id
#> [1] "example-rrp"
#> 
#> $state_initialized
#> [1] FALSE
#> 
#> $run_count
#> [1] 0
#> 
#> $latest_run_id
#> [1] NA
#> 
#> $latest_as_of_time
#> [1] NA
#> 
unlink(project, recursive = TRUE)
```
