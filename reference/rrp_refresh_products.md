# Refresh an RRP project's analytical product CSVs

Derive the current clinically eligible risk pool, observed accepted-risk
trajectories, and operational scope from retained assessment history.
The selected completed run has the greatest analytical `as_of_time`;
execution `created_at` and then `run_id` break ties. A later-executed
historical backfill does not replace a newer analytical snapshot.

## Usage

``` r
rrp_refresh_products(path)
```

## Arguments

- path:

  Path to an existing RRP project with initialized analytical state and
  at least one completed assessment run.

## Value

Invisibly, a list with `selected_run_id`, UTC `as_of_time`, and named
character `files` containing the three generated CSV paths.

## Details

Files are written under `state/products/` as
`current-remaining-risk.csv`, `remaining-risk-trajectory.csv`, and
`operational-scope-summary.csv`. The current-risk file includes
clinically eligible provider-failure episodes with a missing
probability, never zero or an earlier estimate. Refresh reads history
only: it does not run the source mapper or provider, add a run, change
retained history, or edit the project-owned app. All files are staged
and checked before replacement. Replacement of the three files is not
fully atomic if a filesystem error occurs during the final replacement
sequence.
