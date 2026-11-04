# Implementing RRP: A Simulated Hospital Walkthrough

## A hospital’s changing question

Harbor General wants to see how remaining readmission risk changes after
a patient leaves the hospital. A single discharge prediction cannot
describe what was knowable several days later. Readmission Risk Pool
(RRP) repeats an assessment at chosen times, retains each result, and
derives views of current risk and recorded trajectories. The `readmit`
package supplies that structure; the hospital supplies its source
mapping and risk model.

For an eligible discharge episode, the target is the probability of a
**first readmission strictly after the assessment time and through 30
elapsed days after the original discharge**. Each assessment has less
follow-up remaining. A known readmission or death makes an episode
ineligible. An event’s occurrence time may differ from the time its
record became available. The example below uses both times so earlier
assessments do not acquire later knowledge.

Everything here is simulated for teaching. The model is neither
clinically validated nor evidence that acting on its estimates improves
outcomes. Run the article with `readmit`, `dplyr`, and `tidyr`
installed; its website build also uses `rmarkdown` and `pkgdown`. Once
those packages are installed, the article requires no network, hospital
connection, external dataset, or prepared model.

## Simulate Harbor General’s extracts

We create a larger **historical** cohort for model training and eight
separate **current** encounters for the operational walkthrough. The
tables resemble patient demographics, encounter/discharge records,
post-discharge observations, and terminal-event feeds. The observation
is recorded four days after discharge and becomes available a day later.
Event records also have distinct occurrence and availability times.

Show simulated source-data preparation

``` r

set.seed(6404)
day <- 24 * 60 * 60
origin <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
n_history <- 420L

historical_patients <- tibble(
  patient_id = sprintf("H%03d", seq_len(n_history)),
  age = sample(45:88, n_history, replace = TRUE)
)
historical_encounters <- tibble(
  encounter_id = sprintf("EH%03d", seq_len(n_history)),
  patient_id = historical_patients$patient_id,
  admission_time = origin - (80 - sample(0:20, n_history, replace = TRUE)) * day,
  acuity = sample(0:2, n_history, replace = TRUE),
  cohort = "historical"
) |>
  mutate(discharge_time = admission_time + sample(2:5, n_history, replace = TRUE) * day)
historical_observations <- historical_encounters |>
  transmute(
    encounter_id,
    signal = rbinom(n(), 1, plogis(-0.3 + 0.4 * acuity)),
    observed_at = discharge_time + 4 * day,
    available_at = discharge_time + 5 * day
  )

# Simulate later readmission and death outcomes for the historical cohort.
readmit_probability <- plogis(
  -2 + 0.025 * (historical_patients$age - 65) +
    0.35 * historical_encounters$acuity + 0.45 * historical_observations$signal
)
readmit_day <- ifelse(
  runif(n_history) < readmit_probability,
  sample(4:27, n_history, replace = TRUE), NA_integer_
)
death_day <- ifelse(
  runif(n_history) < 0.06,
  sample(4:27, n_history, replace = TRUE), NA_integer_
)
# A death before a simulated readmission prevents that later readmission.
readmit_day[!is.na(death_day) & !is.na(readmit_day) &
              death_day < readmit_day] <- NA_integer_
historical_readmissions <- historical_encounters |>
  mutate(event_day = readmit_day) |>
  filter(!is.na(event_day)) |>
  transmute(
    event_id = paste0("HR-", encounter_id), encounter_id,
    event_type = "readmission",
    occurred_at = discharge_time + event_day * day,
    available_at = occurred_at + sample(0:2, n(), replace = TRUE) * day
  )
historical_deaths <- historical_encounters |>
  mutate(event_day = death_day) |>
  filter(!is.na(event_day)) |>
  transmute(
    event_id = paste0("HD-", encounter_id), encounter_id,
    event_type = "death",
    occurred_at = discharge_time + event_day * day,
    available_at = occurred_at + sample(0:2, n(), replace = TRUE) * day
  )

current_patients <- tibble(
  patient_id = paste0("C", 1:8),
  age = c(72, 64, 61, NA, 70, 58, 68, 77)
)
current_encounters <- tibble(
  encounter_id = paste0("E", 1:8),
  patient_id = current_patients$patient_id,
  discharge_time = origin + c(0, 2, 6, 1, -27, 8, 14, 0) * day,
  acuity = c(2, 1, 0, 2, 1, 1, 2, 0),
  cohort = "current"
) |>
  mutate(admission_time = discharge_time - 2 * day)
current_observations <- current_encounters |>
  transmute(
    encounter_id, signal = c(1, 1, 1, 0, 0, 1, 1, 0),
    observed_at = discharge_time + 4 * day,
    available_at = discharge_time + 5 * day
  )
current_events <- tibble(
  event_id = c("ER-E1", "ED-E2"),
  encounter_id = c("E1", "E2"),
  event_type = c("readmission", "death"),
  occurred_at = origin + c(8.5, 13) * day,
  available_at = origin + c(10.5, 13.5) * day
)

patients <- bind_rows(historical_patients, current_patients)
encounters <- bind_rows(historical_encounters, current_encounters)
observations <- bind_rows(historical_observations, current_observations)
events <- bind_rows(historical_readmissions, historical_deaths, current_events)
stopifnot(
  !anyDuplicated(patients$patient_id),
  !anyDuplicated(encounters$encounter_id),
  !anyDuplicated(events$event_id),
  all(encounters$patient_id %in% patients$patient_id),
  all(events$encounter_id %in% encounters$encounter_id),
  all(events$occurred_at <= events$available_at)
)
```

The current encounters and terminal events used below are:

``` r

current_encounters |>
  select(encounter_id, patient_id, discharge_time, acuity)
#> # A tibble: 8 × 4
#>   encounter_id patient_id discharge_time      acuity
#>   <chr>        <chr>      <dttm>               <dbl>
#> 1 E1           C1         2026-01-01 00:00:00      2
#> 2 E2           C2         2026-01-03 00:00:00      1
#> 3 E3           C3         2026-01-07 00:00:00      0
#> 4 E4           C4         2026-01-02 00:00:00      2
#> 5 E5           C5         2025-12-05 00:00:00      1
#> 6 E6           C6         2026-01-09 00:00:00      1
#> 7 E7           C7         2026-01-15 00:00:00      2
#> 8 E8           C8         2026-01-01 00:00:00      0
current_events |>
  select(encounter_id, event_type, occurred_at, available_at)
#> # A tibble: 2 × 4
#>   encounter_id event_type  occurred_at         available_at       
#>   <chr>        <chr>       <dttm>              <dttm>             
#> 1 E1           readmission 2026-01-09 12:00:00 2026-01-11 12:00:00
#> 2 E2           death       2026-01-14 00:00:00 2026-01-14 12:00:00
```

The first current readmission occurs on January 9 but is not available
until January 11. The second current terminal event is a death.
Encounter E4 has no age; its otherwise eligible episode will illustrate
a provider failure. E5’s follow-up window has already closed by the
first assessment. E3, E6, and E7 enter the supplied discharge population
on different days.

## Create a project and map the sources

[`rrp_project_init()`](https://readmit.centralstatz.com/reference/rrp_project_init.md)
creates an ordinary, editable project. The two R scripts start as
deliberate stubs: initialization does **not** supply a working hospital
model or source connection. We save our simulated extracts inside this
project only because Harbor General is fictional; a real organization
would connect its own sources and keep their access details under its
control.

``` r

work_dir <- tempfile("harbor-general-")
dir.create(work_dir)
project <- rrp_project_init(file.path(work_dir, "harbor-rrp"), "harbor-general")
dir.create(file.path(project, "source"))
saveRDS(patients, file.path(project, "source", "patients.rds"))
saveRDS(encounters, file.path(project, "source", "encounters.rds"))
saveRDS(observations, file.path(project, "source", "observations.rds"))
saveRDS(events, file.path(project, "source", "events.rds"))
list.files(project)
#> [1] "_brand.yml"        "app"               "assets"           
#> [4] "R"                 "README.md"         "rrp-authoring.dcf"
#> [7] "rrp-project.dcf"   "source"
```

The project contains configuration and branding, `R/produce-canonical.R`
for source mapping, `R/calculate-risk.R` for the hospital’s provider,
and `app/` for the project-owned Shiny interface. `state/` and generated
products appear only when we initialize history and refresh products
later. The mapper below reads the extracts, joins encounters to patient
identities, and returns the two required canonical data frames. It
supplies all current encounters discharged by `as_of_time`; omitting
earlier eligible patients from a later operational snapshot would change
the current pool. The package derives the 30-day endpoint and applies
eligibility rules.

Show source-mapping code

``` r

mapper_code <- r"---(
rrp_produce_canonical <- function(project_root, as_of_time) {
  source_dir <- file.path(project_root, "source")
  patients <- readRDS(file.path(source_dir, "patients.rds"))
  encounters <- readRDS(file.path(source_dir, "encounters.rds"))
  events <- readRDS(file.path(source_dir, "events.rds"))

  selected <- encounters |>
    dplyr::filter(cohort == "current", discharge_time <= as_of_time) |>
    dplyr::inner_join(dplyr::select(patients, patient_id), by = "patient_id")
  discharge_episode <- selected |>
    dplyr::transmute(
      episode_id = paste0("episode-", encounter_id),
      patient_id,
      index_encounter_id = encounter_id,
      admission_time, discharge_time
    )
  terminal_event <- events |>
    dplyr::inner_join(dplyr::select(selected, encounter_id), by = "encounter_id") |>
    dplyr::filter(occurred_at <= as_of_time, available_at <= as_of_time) |>
    dplyr::transmute(
      terminal_event_id = event_id,
      episode_id = paste0("episode-", encounter_id),
      event_type, occurred_at, available_at
    )
  list(
    discharge_episode = as.data.frame(discharge_episode),
    terminal_event = as.data.frame(terminal_event)
  )
}
)---"
writeLines(mapper_code, file.path(project, "R", "produce-canonical.R"))
```

The occurrence and availability filters ensure the January 9 readmission
is absent from the January 10 source snapshot and present on January 12
with its original occurrence time. These are distinct facts, not a later
rewrite of the January 10 result. The canonical tables contain only
shared episode and event facts; the age, acuity, and post-discharge
observation stay private to the hospital’s provider.

## Fit a remaining-risk demonstration model

We construct **landmark** training rows at days 2, 7, and 14 after each
historical discharge. A row is included while no readmission or death is
*known* by that time. Its outcome is a first readmission strictly after
the landmark and before a competing death, through that discharge’s
day-30 endpoint. The outcome is learned retrospectively, but predictors
use only information available at the landmark. This is a small
educational logistic model of the remaining interval, not an unchanged
discharge-time classifier. Its repeated rows per encounter and
simplified source process are not a clinical validation or a claim of
calibrated risk.

Show model-training code

``` r

historical_event_times <- events |>
  semi_join(historical_encounters, by = "encounter_id") |>
  select(encounter_id, event_type, occurred_at, available_at) |>
  pivot_wider(
    names_from = event_type,
    values_from = c(occurred_at, available_at),
    names_glue = "{.value}_{event_type}"
  )

training <- tidyr::crossing(
  encounter_id = historical_encounters$encounter_id,
  landmark_day = c(2L, 7L, 14L)
) |>
  left_join(historical_encounters, by = "encounter_id") |>
  left_join(historical_patients, by = "patient_id") |>
  left_join(historical_observations |>
              select(encounter_id, signal, signal_available_at = available_at),
            by = "encounter_id") |>
  left_join(historical_event_times, by = "encounter_id") |>
  mutate(
    as_of_time = discharge_time + landmark_day * day,
    followup_end = discharge_time + 30 * day,
    age_scaled = (age - 65) / 10,
    days_remaining = 30 - landmark_day,
    signal_as_of = if_else(signal_available_at <= as_of_time, signal, 0L)
  ) |>
  filter(
    is.na(occurred_at_readmission) |
      occurred_at_readmission > as_of_time |
      available_at_readmission > as_of_time,
    is.na(occurred_at_death) |
      occurred_at_death > as_of_time |
      available_at_death > as_of_time
  ) |>
  mutate(
    outcome = as.integer(
      !is.na(occurred_at_readmission) &
        occurred_at_readmission > as_of_time &
        occurred_at_readmission <= followup_end &
        (is.na(occurred_at_death) |
           occurred_at_readmission <= occurred_at_death)
    )
  )
model <- stats::glm(
  outcome ~ age_scaled + acuity + signal_as_of + days_remaining,
  family = stats::binomial(), data = training
)
dir.create(file.path(project, "model"))
model_path <- file.path(project, "model", "landmark-glm.rds")
saveRDS(model, model_path)
stopifnot(inherits(readRDS(model_path), "glm"))
```

The resulting training outcomes by landmark and fitted coefficients are:

``` r

training |>
  count(landmark_day, outcome)
#> # A tibble: 6 × 3
#>   landmark_day outcome     n
#>          <int>   <int> <int>
#> 1            2       0   341
#> 2            2       1    79
#> 3            7       0   340
#> 4            7       1    61
#> 5           14       0   337
#> 6           14       1    34
round(stats::coef(model), 3)
#>    (Intercept)     age_scaled         acuity   signal_as_of days_remaining 
#>         -4.755          0.175          0.508          0.496          0.095
```

The model uses remaining days and a post-discharge signal only once that
signal is available. Death before a future readmission makes the
training outcome zero. Harbor General’s current encounters were **not**
model-training cases; we do not use their outcomes to fit the model or
present its predictions as a performance evaluation.

## Supply the hospital’s risk provider

`readmit` asks the project provider for one eligible episode at a time.
The request gives the episode identity, assessment time, and fixed
follow-up endpoint. The provider reads private source information and
the saved model from its own project directory. E4 has no age, so it
reports a failure rather than inventing a probability. An organization
must assess its own predictor quality and timing; `readmit` does not
validate them.

Show risk-provider implementation

``` r

provider_code <- r"---(
rrp_calculate_risk <- function(project_root, request) {
  source_dir <- file.path(project_root, "source")
  patients <- readRDS(file.path(source_dir, "patients.rds"))
  encounters <- readRDS(file.path(source_dir, "encounters.rds"))
  observations <- readRDS(file.path(source_dir, "observations.rds"))

  patient <- patients[patients$patient_id == request$patient_id, , drop = FALSE]
  encounter <- encounters[
    encounters$encounter_id == request$index_encounter_id, , drop = FALSE
  ]
  if (nrow(patient) != 1L || is.na(patient$age[[1L]])) {
    return(list(failure = "Patient age unavailable"))
  }
  if (nrow(encounter) != 1L) {
    return(list(failure = "Encounter unavailable"))
  }
  available <- observations[
    observations$encounter_id == request$index_encounter_id &
      observations$available_at <= request$as_of_time, , drop = FALSE
  ]
  signal_as_of <- if (nrow(available)) {
    available$signal[[which.max(available$available_at)]]
  } else {
    0L
  }
  newdata <- data.frame(
    age_scaled = (patient$age[[1L]] - 65) / 10,
    acuity = encounter$acuity[[1L]],
    signal_as_of = signal_as_of,
    days_remaining = request$remaining_seconds / (24 * 60 * 60)
  )
  model <- readRDS(file.path(project_root, "model", "landmark-glm.rds"))
  probability <- as.numeric(stats::predict(model, newdata, type = "response"))
  list(probability = probability)
}
)---"
writeLines(provider_code, file.path(project, "R", "calculate-risk.R"))
rrp_project_validate(project)
```

Validation confirms that the project files and function signatures load.
It does not call either function or certify the simulated clinical
definitions, model, or predictions. The following real runs exercise
those interfaces.

## Assess repeatedly and inspect history

At January 6, E3, E6, and E7 have not yet been discharged. At January
10, E1’s readmission has occurred but is not yet available; E1 remains
eligible based on what the process knows. By January 12 it is a known
readmission. E2 later becomes ineligible after its known death. E4
remains eligible but has an unavailable model estimate. The model’s
remaining-time and newly available observation inputs can change
estimates for other episodes.

``` r

rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
assessment_times <- origin + c(5.5, 9.5, 11.5, 15.5) * day
runs <- lapply(assessment_times, function(time) rrp_run(project, time))
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
run_summary <- tibble(
  as_of_time = assessment_times,
  accepted = vapply(runs, `[[`, integer(1), "accepted"),
  provider_failures = vapply(runs, `[[`, integer(1), "provider_failures"),
  ineligible = vapply(runs, `[[`, integer(1), "ineligible")
)
run_summary
#> # A tibble: 4 × 4
#>   as_of_time          accepted provider_failures ineligible
#>   <dttm>                 <int>             <int>      <int>
#> 1 2026-01-06 12:00:00        3                 1          1
#> 2 2026-01-10 12:00:00        5                 1          1
#> 3 2026-01-12 12:00:00        4                 1          2
#> 4 2026-01-16 12:00:00        4                 1          3

# A later-executed historical backfill does not replace the newest snapshot.
backfill <- rrp_run(project, assessment_times[[2L]])
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
status <- rrp_project_status(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
status[c("state_initialized", "run_count")]
#> $state_initialized
#> [1] TRUE
#> 
#> $run_count
#> [1] 5
history <- rrp_inspect_history(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
history |>
  filter(patient_id %in% c("C1", "C2", "C3", "C4")) |>
  select(patient_id, as_of_time, disposition, probability,
         terminal_occurred_at, terminal_available_at) |>
  arrange(patient_id, as_of_time) |>
  head(22)
#>    patient_id          as_of_time       disposition probability
#> 1          C1 2026-01-06 12:00:00          accepted  0.31295390
#> 2          C1 2026-01-10 12:00:00          accepted  0.23734158
#> 3          C1 2026-01-10 12:00:00          accepted  0.23734158
#> 4          C1 2026-01-12 12:00:00 known_readmission          NA
#> 5          C1 2026-01-16 12:00:00 known_readmission          NA
#> 6          C2 2026-01-06 12:00:00          accepted  0.14928082
#> 7          C2 2026-01-10 12:00:00          accepted  0.16452859
#> 8          C2 2026-01-10 12:00:00          accepted  0.16452859
#> 9          C2 2026-01-12 12:00:00          accepted  0.13998748
#> 10         C2 2026-01-16 12:00:00       known_death          NA
#> 11         C3 2026-01-10 12:00:00          accepted  0.09105211
#> 12         C3 2026-01-10 12:00:00          accepted  0.09105211
#> 13         C3 2026-01-12 12:00:00          accepted  0.11972547
#> 14         C3 2026-01-16 12:00:00          accepted  0.08502147
#> 15         C4 2026-01-06 12:00:00  provider_failure          NA
#> 16         C4 2026-01-10 12:00:00  provider_failure          NA
#> 17         C4 2026-01-10 12:00:00  provider_failure          NA
#> 18         C4 2026-01-12 12:00:00  provider_failure          NA
#> 19         C4 2026-01-16 12:00:00  provider_failure          NA
#>    terminal_occurred_at terminal_available_at
#> 1                  <NA>                  <NA>
#> 2                  <NA>                  <NA>
#> 3                  <NA>                  <NA>
#> 4   2026-01-09 12:00:00   2026-01-11 12:00:00
#> 5   2026-01-09 12:00:00   2026-01-11 12:00:00
#> 6                  <NA>                  <NA>
#> 7                  <NA>                  <NA>
#> 8                  <NA>                  <NA>
#> 9                  <NA>                  <NA>
#> 10  2026-01-14 00:00:00   2026-01-14 12:00:00
#> 11                 <NA>                  <NA>
#> 12                 <NA>                  <NA>
#> 13                 <NA>                  <NA>
#> 14                 <NA>                  <NA>
#> 15                 <NA>                  <NA>
#> 16                 <NA>                  <NA>
#> 17                 <NA>                  <NA>
#> 18                 <NA>                  <NA>
#> 19                 <NA>                  <NA>
```

The retained January 10 E1 row remains an accepted assessment after the
January 12 run records a known readmission. E4’s provider failure is an
episode outcome, not zero risk. The backfill creates another run at the
January 10 analytical time; history keeps both. Status reports the most
recently *recorded* run, which is now the backfill.

We can independently compare E3’s latest accepted probability with a
direct prediction from the saved model. E3’s observation is available by
January 16.

``` r

e3_time <- assessment_times[[4L]]
e3 <- current_encounters |> filter(encounter_id == "E3")
e3_age <- current_patients$age[current_patients$patient_id == "C3"]
e3_expected <- as.numeric(stats::predict(
  readRDS(model_path),
  newdata = data.frame(
    age_scaled = (e3_age - 65) / 10,
    acuity = e3$acuity,
    signal_as_of = current_observations$signal[
      current_observations$encounter_id == "E3"
    ],
    days_remaining = as.numeric(difftime(
      e3$discharge_time + 30 * day, e3_time, units = "days"
    ))
  ),
  type = "response"
))
e3_recorded <- history |>
  filter(episode_id == "episode-E3", as_of_time == e3_time) |>
  pull(probability)
stopifnot(isTRUE(all.equal(e3_recorded, e3_expected)))
tibble(recorded = e3_recorded, direct_model_prediction = e3_expected)
#> # A tibble: 1 × 2
#>   recorded direct_model_prediction
#>      <dbl>                   <dbl>
#> 1   0.0850                  0.0850
```

## Generate and interpret the products

[`rrp_refresh_products()`](https://readmit.centralstatz.com/reference/rrp_refresh_products.md)
reads retained history; it does not call the mapper or provider again.
The current snapshot is the completed run with the greatest analytical
time, even though we executed an older backfill last. Supplying a
partial population at a later analytical time would make that partial
run the current snapshot; the platform does not merge missing episodes
from older runs. An operational mapper should supply the complete
relevant discharge cohort.

``` r

products <- rrp_refresh_products(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpFcz3Xg/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
stopifnot(products$selected_run_id == runs[[4L]]$run_id,
          status$latest_run_id == backfill$run_id)
current_risk <- read.csv(products$files[["current_risk"]])
trajectory <- read.csv(products$files[["trajectory"]])
scope <- read.csv(products$files[["scope"]])
current_risk |>
  select(episode_id, disposition, probability)
#>   episode_id      disposition probability
#> 1 episode-E3         accepted  0.08502147
#> 2 episode-E4 provider_failure          NA
#> 3 episode-E6         accepted  0.15060176
#> 4 episode-E7         accepted  0.27454746
#> 5 episode-E8         accepted  0.04055060
trajectory |>
  filter(episode_id == "episode-E3") |>
  select(episode_id, as_of_time, probability)
#>   episode_id                  as_of_time probability
#> 1 episode-E3 2026-01-10T12:00:00.000000Z  0.09105211
#> 2 episode-E3 2026-01-10T12:00:00.000000Z  0.09105211
#> 3 episode-E3 2026-01-12T12:00:00.000000Z  0.11972547
#> 4 episode-E3 2026-01-16T12:00:00.000000Z  0.08502147
scope |>
  select(episodes_assessed, eligible_count, accepted_count,
         provider_failure_count, known_readmission_count,
         known_death_count, window_closed_count)
#>   episodes_assessed eligible_count accepted_count provider_failure_count
#> 1                 8              5              4                      1
#>   known_readmission_count known_death_count window_closed_count
#> 1                       1                 1                   1
```

**Current remaining risk** includes the latest eligible episodes; E4
remains there with a missing probability. **Remaining-risk trajectory**
lists actual accepted assessments for episodes still in the current
pool, including both January 10 runs; its observations are not a
continuous risk curve. **Operational scope** counts accepted, failed,
and ineligible outcomes in the selected January 16 run. E1 and E2 are
absent from the current pool because their terminal events are known;
E5’s window is closed. The CSVs are derived outputs, while history
retains each completed assessment.

## Explore and customize the project app

The project app already existed before our first assessment and would
have opened with empty views. After refresh it reads the three product
CSVs. Its **Current Risk Pool** shows accepted and provider-failed
eligible episodes; selecting a row reveals its current estimate and
recorded accepted trajectory. **Overview** shows operational counts and
summaries of available current estimates. The app’s Reload Data control
rereads CSVs, but does not run an assessment or refresh products.

Install `shiny`, `bslib`, `reactable`, `plotly`, and `yaml` in the
environment that will run the app. Launch it manually with the following
command; the article does not launch an interactive session while
rendering.

``` r

shiny::runApp(file.path(project, "app"))
```

Harbor General can replace its project logo without changing the
package. We generate a simple PNG in the exact path named by the
project’s `_brand.yml`. Then we append one small color rule to the
project-owned stylesheet; the shared package template is untouched.
These are examples of ownership, not a new customization framework.

``` r

logo_path <- file.path(project, "assets", "project-logo.png")
grDevices::png(logo_path, width = 520, height = 150, bg = "white")
graphics::plot.new()
graphics::rect(0, 0, 1, 1, col = "#174D58", border = NA)
graphics::text(0.5, 0.53, "HARBOR GENERAL", col = "white",
               cex = 1.8, font = 2)
grDevices::dev.off()
#> agg_png 
#>       2

css_path <- file.path(project, "app", "www", "rrp.css")
cat("\n/* Harbor General project styling */\n",
    ".rrp-page-intro h1 { color: #174D58; }\n",
    file = css_path, append = TRUE)
stopifnot(file.exists(logo_path), file.info(logo_path)$size > 0,
          grepl("assets/project-logo.png", readLines(file.path(project, "_brand.yml")),
                fixed = TRUE) |> any(),
          grepl("Harbor General project styling", readLines(css_path),
                fixed = TRUE) |> any())
```

For a hosted app, Posit Connect or Posit Connect Cloud are possible
deployment choices. The deployment would need the app’s runtime
packages, this project’s app, assets, model, and generated products. The
hospital also needs a deliberate way to retain project history and run
assessments separately from app hosting; the app only reads products.
This walkthrough does not deploy or validate a production service.
