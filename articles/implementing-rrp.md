# Implementing RRP: A Simulated Hospital Walkthrough

## A hospital’s changing question

Harbor General wants to reassess patients after they leave the hospital.
A prediction made at discharge cannot use observations collected later.
It also does not, by itself, answer how much risk remains several days
into follow-up. Readmission Risk Pool (RRP) lets the hospital assess
that remaining risk at chosen times, keep each result, and examine the
current pool and earlier estimates. The `readmit` package supplies this
workflow; the hospital supplies its source mapping and risk model.

For an eligible discharge episode, the target is the probability of a
**first readmission strictly after the assessment time and through 30
elapsed days after the original discharge**. The 30-day endpoint stays
fixed even when the hospital assesses an episode again. An estimate may
change as less time remains or as the hospital gains new information for
its model; it need not move in a particular direction. A readmission or
death occurring by the assessment time makes an episode ineligible for a
new remaining-risk estimate.

Everything here is simulated for teaching. The model is neither
clinically validated nor evidence that acting on its estimates improves
outcomes. Run the article with `readmit`, `dplyr`, and `tidyr`
installed; its website build also uses `rmarkdown` and `pkgdown`. Once
those packages are installed, the article requires no network, hospital
connection, external dataset, or prepared model.

## Simulate Harbor General’s extracts

We create a larger **historical** group of patients to train an
illustrative model, then use eight separate **current** encounters to
show how that model would be used in repeated assessments. Different
discharge dates let patients enter the assessed population at different
times. Readmissions and deaths show when a patient can no longer receive
a new remaining-risk estimate. One patient has missing information, so
the model cannot estimate that patient’s risk.

The tables resemble patient demographics, encounter and discharge
records, post-discharge observations, and readmission and death records.
An observation is recorded four days after discharge but becomes
available to the hospital a day later. The hospital uses that
availability time to choose private model inputs; the platform uses
event occurrence time to decide eligibility.

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
    occurred_at = discharge_time + event_day * day
  )
historical_deaths <- historical_encounters |>
  mutate(event_day = death_day) |>
  filter(!is.na(event_day)) |>
  transmute(
    event_id = paste0("HD-", encounter_id), encounter_id,
    event_type = "death",
    occurred_at = discharge_time + event_day * day
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
  occurred_at = origin + c(8.5, 13) * day
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
  all(events$encounter_id %in% encounters$encounter_id)
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
  select(encounter_id, event_type, occurred_at)
#> # A tibble: 2 × 3
#>   encounter_id event_type  occurred_at        
#>   <chr>        <chr>       <dttm>             
#> 1 E1           readmission 2026-01-09 12:00:00
#> 2 E2           death       2026-01-14 00:00:00
```

The first current readmission occurs on January 9; the other recorded
event is a death. E4’s patient has no age. E4 can still be eligible
under the platform’s rules, but the hospital’s model needs age and
cannot produce a probability for that episode. The platform records the
failed estimate rather than treating E4 as ineligible or assigning it
zero risk. E5’s follow-up window has already closed by the first
assessment. E3, E6, and E7 enter the supplied discharge population on
different days.

## Create a project and map the sources

[`rrp_project_init()`](https://readmit.centralstatz.com/reference/rrp_project_init.md)
creates an ordinary, editable project. Its two R scripts start as
deliberate stubs: initialization does **not** supply a working hospital
model or source connection. Harbor General must write the source mapper
that translates its data into the package’s discharge-episode and
terminal-event tables, and the provider that calculates risk for
eligible episodes. We save simulated extracts inside this project only
because Harbor General is fictional; a real organization would connect
its own sources and control their access.

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
later.

The mapper below reads the extracts, connects encounters to patients,
and returns the two required tables. For each assessment date, it
supplies the complete relevant group of current encounters discharged by
that time: `discharge_time <= as_of_time`. Supplying only part of that
group at a later assessment would leave patients out of the current
view. The package derives each episode’s original 30-day endpoint and
applies its eligibility rules; the hospital does not need to reproduce
those rules in the mapper.

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
    dplyr::filter(occurred_at <= as_of_time) |>
    dplyr::transmute(
      terminal_event_id = event_id,
      episode_id = paste0("episode-", encounter_id),
      event_type, occurred_at
    )
  list(
    discharge_episode = as.data.frame(discharge_episode),
    terminal_event = as.data.frame(terminal_event)
  )
}
)---"
writeLines(mapper_code, file.path(project, "R", "produce-canonical.R"))
```

This example’s mapper also selects only events that have occurred by the
assessment date. That builds a source snapshot: the January 9
readmission is present on January 10, while a later event first appears
in a later snapshot. The platform itself uses occurrence time to decide
whether a supplied event makes an episode ineligible. Age, acuity, and
the post-discharge observation stay private to the hospital’s model
rather than entering the shared tables.

## Fit a remaining-risk demonstration model

We use the historical patients to teach a model to answer the same
question asked during current assessments. For each historical
discharge, we consider the patient at days 2, 7, and 14. Each of these
assessment points is a **landmark**. A patient contributes a training
row at a landmark only if a readmission or death has not already
occurred. Once either event occurs, there is no remaining
first-readmission risk to estimate at a later landmark.

For each row, the outcome asks whether a first readmission occurred
strictly after that landmark and by the original day-30 endpoint, before
a competing death. We learn the outcome from later records, but give the
model only predictors available at the landmark. In particular, the
hospital withholds the post-discharge observation until its own
availability time. This is a small educational logistic model of the
remaining interval, not a validated clinical prediction system. Repeated
rows per encounter and a simplified source process do not establish
calibrated risk or clinical usefulness.

Show model-training code

``` r

historical_event_times <- events |>
  semi_join(historical_encounters, by = "encounter_id") |>
  select(encounter_id, event_type, occurred_at) |>
  pivot_wider(
    names_from = event_type,
    values_from = occurred_at,
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
    is.na(occurred_at_readmission) | occurred_at_readmission > as_of_time,
    is.na(occurred_at_death) | occurred_at_death > as_of_time
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
#> 3            7       0   336
#> 4            7       1    61
#> 5           14       0   332
#> 6           14       1    34
round(stats::coef(model), 3)
#>    (Intercept)     age_scaled         acuity   signal_as_of days_remaining 
#>         -4.741          0.177          0.510          0.512          0.095
```

The model uses the days remaining and includes the post-discharge signal
only once it is available to the hospital. A death before a possible
later readmission prevents that readmission from counting as the
outcome. If both events occur at the same time, the example counts the
readmission first, as the platform does. Harbor General’s current
encounters were **not** training cases; their outcomes do not enter the
fitted model or serve as a performance evaluation.

## Supply the hospital’s risk provider

After the platform determines which episodes are eligible, `readmit`
asks the hospital’s risk provider for one estimate per eligible episode.
Each request identifies the episode, assessment time, and fixed
follow-up endpoint. The provider reads private source information and
the saved model from its own project directory. For E4, it reports that
age is unavailable; it does not invent a probability. The platform keeps
E4 in the eligible population and records the model’s failure. The
hospital is responsible for its predictors, their timing, and the
suitability of its model; `readmit` does not validate those choices.

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

The four assessments use January 6, 10, 12, and 16 as their assessment
dates. On January 6, E3, E6, and E7 have not been discharged, so the
mapper does not supply them yet. On January 10, E1’s January 9
readmission has already occurred, so E1 no longer receives a risk
estimate. E2 remains eligible until its death occurs later. More
discharges enter the assessed group over time, while readmissions,
deaths, and closed follow-up windows remove episodes from the eligible
pool.

At the January 10 assessment, four episodes receive accepted
probabilities. E4 remains eligible, but its missing age prevents the
model from producing an estimate; the run records one provider failure.
For other eligible episodes, the estimated probability may change
because the remaining period is shorter and new hospital-owned
observations may become available.

``` r

rrp_state_init(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
assessment_times <- origin + c(5.5, 9.5, 11.5, 15.5) * day
runs <- lapply(assessment_times, function(time) rrp_run(project, time))
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
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
#> 2 2026-01-10 12:00:00        4                 1          2
#> 3 2026-01-12 12:00:00        4                 1          2
#> 4 2026-01-16 12:00:00        4                 1          3

# A later-executed historical backfill does not replace the newest snapshot.
backfill <- rrp_run(project, assessment_times[[2L]])
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
status <- rrp_project_status(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
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
#> ℹ /tmp/RtmpcveeW5/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
jan10_e1 <- history |>
  filter(run_id == runs[[2L]]$run_id, episode_id == "episode-E1")
stopifnot(nrow(jan10_e1) == 1L,
          jan10_e1$disposition == "known_readmission",
          jan10_e1$terminal_occurred_at == current_events$occurred_at[[1L]],
          !"terminal_available_at" %in% names(history))
history |>
  filter(patient_id %in% c("C1", "C2", "C3", "C4")) |>
  select(patient_id, as_of_time, disposition, probability,
         terminal_occurred_at) |>
  arrange(patient_id, as_of_time) |>
  head(22)
#>    patient_id          as_of_time       disposition probability
#> 1          C1 2026-01-06 12:00:00          accepted  0.31761803
#> 2          C1 2026-01-10 12:00:00 known_readmission          NA
#> 3          C1 2026-01-10 12:00:00 known_readmission          NA
#> 4          C1 2026-01-12 12:00:00 known_readmission          NA
#> 5          C1 2026-01-16 12:00:00 known_readmission          NA
#> 6          C2 2026-01-06 12:00:00          accepted  0.14938575
#> 7          C2 2026-01-10 12:00:00          accepted  0.16712993
#> 8          C2 2026-01-10 12:00:00          accepted  0.16712993
#> 9          C2 2026-01-12 12:00:00          accepted  0.14240051
#> 10         C2 2026-01-16 12:00:00       known_death          NA
#> 11         C3 2026-01-10 12:00:00          accepted  0.09088792
#> 12         C3 2026-01-10 12:00:00          accepted  0.09088792
#> 13         C3 2026-01-12 12:00:00          accepted  0.12130465
#> 14         C3 2026-01-16 12:00:00          accepted  0.08636031
#> 15         C4 2026-01-06 12:00:00  provider_failure          NA
#> 16         C4 2026-01-10 12:00:00  provider_failure          NA
#> 17         C4 2026-01-10 12:00:00  provider_failure          NA
#> 18         C4 2026-01-12 12:00:00  provider_failure          NA
#> 19         C4 2026-01-16 12:00:00  provider_failure          NA
#>    terminal_occurred_at
#> 1                  <NA>
#> 2   2026-01-09 12:00:00
#> 3   2026-01-09 12:00:00
#> 4   2026-01-09 12:00:00
#> 5   2026-01-09 12:00:00
#> 6                  <NA>
#> 7                  <NA>
#> 8                  <NA>
#> 9                  <NA>
#> 10  2026-01-14 00:00:00
#> 11                 <NA>
#> 12                 <NA>
#> 13                 <NA>
#> 14                 <NA>
#> 15                 <NA>
#> 16                 <NA>
#> 17                 <NA>
#> 18                 <NA>
#> 19                 <NA>
```

Each run adds its episode results to history. E1’s January 6 estimate
remains there; its January 10 row instead records the readmission and
when it occurred. Earlier rows are not rewritten when a later assessment
finds that an event has occurred. E4’s row records that the model could
not produce an estimate, not a zero-risk result.

After the January 16 assessment, we run the January 10 assessment again
as a historical backfill. It receives a new run ID, and history keeps
both January 10 runs. Project status identifies this backfill as the
most recently *recorded* run. Its assessment date is still January 10,
so it is not the latest assessment snapshot. The products below select
the January 16 run.

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
#> 1   0.0864                  0.0864
```

## Generate and interpret the products

[`rrp_refresh_products()`](https://readmit.centralstatz.com/reference/rrp_refresh_products.md)
creates three CSV views from retained history. It does not call the
hospital’s source mapper or model again. “Current” means the completed
run with the latest assessment date, which is January 16 here. The
January 10 backfill ran last but does not replace that snapshot.

If a later-dated run assessed only part of the relevant discharge
population, that partial run would still become the current snapshot.
The platform does not fill in its missing episodes from older runs. An
operational mapper should therefore supply the complete relevant
population each time.

``` r

products <- rrp_refresh_products(project)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpcveeW5/duckdb
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
#> 1 episode-E3         accepted  0.08636031
#> 2 episode-E4 provider_failure          NA
#> 3 episode-E6         accepted  0.15285487
#> 4 episode-E7         accepted  0.27509739
#> 5 episode-E8         accepted  0.04086488
trajectory |>
  filter(episode_id == "episode-E3") |>
  select(episode_id, as_of_time, probability)
#>   episode_id                  as_of_time probability
#> 1 episode-E3 2026-01-10T12:00:00.000000Z  0.09088792
#> 2 episode-E3 2026-01-10T12:00:00.000000Z  0.09088792
#> 3 episode-E3 2026-01-12T12:00:00.000000Z  0.12130465
#> 4 episode-E3 2026-01-16T12:00:00.000000Z  0.08636031
scope |>
  select(episodes_assessed, eligible_count, accepted_count,
         provider_failure_count, known_readmission_count,
         known_death_count, window_closed_count)
#>   episodes_assessed eligible_count accepted_count provider_failure_count
#> 1                 8              5              4                      1
#>   known_readmission_count known_death_count window_closed_count
#> 1                       1                 1                   1
```

**Current remaining risk** shows episodes still eligible in the January
16 snapshot. E4 remains in this pool even though its probability is
missing. E1 and E2 are absent because their readmission and death have
occurred; E5’s 30-day window has closed.

**Remaining-risk trajectory** contains accepted estimates recorded
across runs for episodes in the current pool. E3’s rows include both
January 10 runs. Each point is an estimate actually recorded at an
assessment, not a continuous curve or proof that the patient’s
underlying risk changed between assessments.

**Operational scope** counts all eight episodes in the January 16
assessment: four accepted estimates, one provider failure, and three
ineligible outcomes. The CSVs are views derived from history; history
retains the completed runs.

## Explore and customize the project app

The project app already existed before the first assessment and could
have opened with empty views. After product refresh, it reads the three
CSVs. **Current Risk Pool** shows eligible episodes with accepted
estimates and E4’s unavailable estimate; selecting a row shows its
current estimate and recorded accepted estimates across runs.
**Overview** summarizes the selected assessment and the available
current probabilities.

These are separate actions:
[`rrp_run()`](https://readmit.centralstatz.com/reference/rrp_run.md)
performs a new assessment and adds history;
[`rrp_refresh_products()`](https://readmit.centralstatz.com/reference/rrp_refresh_products.md)
updates the CSV views from history; and **Reload Data** in the app
rereads those CSVs. Reloading the app does not run the model or refresh
the products.

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
