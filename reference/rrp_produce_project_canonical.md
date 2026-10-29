# Project canonical source contract

The project-authored `rrp_produce_canonical(project_root, as_of_time)`
function returns a named list with two data frames. `discharge_episode`
requires character `episode_id`, `patient_id`, and `index_encounter_id`,
plus UTC `POSIXct` `admission_time` and `discharge_time`.
`terminal_event` requires character `terminal_event_id`, `episode_id`,
and `event_type` (`"readmission"` or `"death"`), plus UTC `POSIXct`
`occurred_at` and `available_at`. Either table may have zero rows if it
retains its required typed columns. Identifiers must be nonmissing and
nonblank, and timestamps must be finite. Episode and terminal-event IDs
must be unique, and every terminal event must reference a supplied
episode. Additional columns are left unchanged but are not used by
`readmit`.

## Usage

``` r
rrp_produce_project_canonical(project_root, as_of_time)
```

## Arguments

- project_root:

  Path to the project that owns the source-mapping script.

- as_of_time:

  One finite UTC `POSIXct` analytical instant.

## Value

The validated canonical list, with its two data frames unchanged.

## Details

`as_of_time` is one finite UTC `POSIXct` instant. The project author
supplies episodes discharged by that time and truthful event occurrence
and availability times. An event may have occurred by `as_of_time` but
become available later; canonical validation does not filter it. The
project owns clinical source selection, mapping, and private predictors.
`readmit` owns the fixed 30-elapsed-day endpoint, which is derived from
`discharge_time` during later analytical execution and is not a
canonical input column.
