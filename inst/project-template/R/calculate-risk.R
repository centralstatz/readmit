# `readmit` calls this function once per eligible discharge episode. Estimate
# the probability of its first readmission strictly after request$as_of_time
# through request$followup_window_end (inclusive), conditional on information
# available at request$as_of_time.
#
# request is a named list with episode_id, patient_id, index_encounter_id,
# admission_time, discharge_time, as_of_time, followup_window_end, and
# remaining_seconds. Times are UTC POSIXct; remaining_seconds is positive.
# Use project_root to access your private predictors and model code. Their
# selection, timing, provenance, and estimation methodology are your responsibility.
#
# Return either list(probability = 0.24), with one finite number in [0, 1],
# or list(failure = "Required predictor unavailable") with a nonblank reason.
# Do not return both fields. Replace this deliberate stub with your calculation.
rrp_calculate_risk <- function(project_root, request) {
  stop("Project author must implement the risk provider.", call. = FALSE)
}
