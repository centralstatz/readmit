# Run an RRP assessment and retain its history

Run the configured project source mapper at one analytical time,
determine which discharge episodes remain eligible for first readmission
in the remaining 30-day follow-up window, and call the project risk
provider once per eligible episode. Accepted estimates, provider
failures, and ineligible outcomes are retained together as one completed
run.

## Usage

``` r
rrp_run(path, as_of_time)
```

## Arguments

- path:

  Path to an existing RRP project with initialized analytical state.

- as_of_time:

  One finite UTC `POSIXct` analytical instant. This same time is used
  for source production, eligibility, provider requests, and history.

## Value

An ordinary list with `run_id`, `as_of_time`, `episodes_processed`,
`accepted`, `provider_failures`, and `ineligible`. Counts are integers;
the run ID belongs to a successfully committed run.

## Details

Call
[`rrp_state_init()`](https://readmit.centralstatz.com/reference/rrp_state_init.md)
before the first run. The project owner must implement the configured
`rrp_produce_canonical()` and `rrp_calculate_risk()` functions. A
provider failure affects its episode, while a source or persistence
failure stops the run without a partial completed record. Analytical
products are generated separately.

## Examples

``` r
if (FALSE) { # \dontrun{
assessment_time <- as.POSIXct("2026-01-10 12:00:00", tz = "UTC")
rrp_run("my-rrp-project", assessment_time)
} # }
```
