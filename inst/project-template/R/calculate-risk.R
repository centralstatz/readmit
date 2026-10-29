# `readmit` will call this function with a request for an eligible episode.
# Use your own model and private predictors to estimate the specified remaining
# readmission-risk probability. Predictor construction, availability, timing,
# provenance, and estimation methodology are your responsibility.
# The precise request and response contract will be documented with assessment
# execution.
rrp_calculate_risk <- function(project_root, request) {
  stop("Project author must implement the risk provider.", call. = FALSE)
}
