# Build the shared request for one episode marked eligible by Stage 3.1.
# Private predictors remain in project-owned code and data under project_root.
rrp_provider_request <- function(episode, as_of_time) {
  endpoint <- episode$followup_window_end[1L]
  list(
    episode_id = episode$episode_id[[1L]],
    patient_id = episode$patient_id[[1L]],
    index_encounter_id = episode$index_encounter_id[[1L]],
    admission_time = episode$admission_time[1L],
    discharge_time = episode$discharge_time[1L],
    as_of_time = as_of_time,
    followup_window_end = endpoint,
    remaining_seconds = as.numeric(difftime(endpoint, as_of_time, units = "secs"))
  )
}

# Interpret exactly one ordinary, one-field provider result.
rrp_interpret_provider_result <- function(value) {
  failure <- function(reason) {
    list(disposition = "provider_failure", probability = NA_real_,
         failure_kind = "unusable_result", failure_reason = reason)
  }
  if (!is.list(value) || is.object(value)) {
    return(failure("Provider result must be a one-field named list."))
  }
  if (identical(names(value), "probability")) {
    probability <- value$probability
    if (!is.numeric(probability) || is.object(probability) ||
        length(probability) != 1L ||
        is.na(probability) || !is.finite(probability) ||
        probability < 0 || probability > 1) {
      return(failure("Provider probability must be one finite number between 0 and 1."))
    }
    return(list(disposition = "accepted", probability = as.numeric(probability),
                failure_kind = NA_character_, failure_reason = NA_character_))
  }
  if (identical(names(value), "failure")) {
    reason <- value$failure
    if (!is.character(reason) || is.object(reason) ||
        length(reason) != 1L ||
        is.na(reason) || !nzchar(trimws(reason))) {
      return(failure("Provider failure reason must be one nonblank string."))
    }
    return(list(disposition = "provider_failure", probability = NA_real_,
                failure_kind = "reported", failure_reason = reason))
  }
  failure("Provider result must contain exactly probability or failure.")
}

# Complete eligible rows in source order. The provider is loaded by the Stage 2
# project loader before this call; only provider invocation errors are isolated.
rrp_assess_eligible_episodes <- function(eligibility, as_of_time, project_root,
                                         provider) {
  if (length(as_of_time) != 1L) {
    stop("`as_of_time` must be one finite UTC POSIXct instant.", call. = FALSE)
  }
  rrp_check_utc_time(as_of_time, "as_of_time")
  if (!is.function(provider)) {
    stop("`provider` must be a function.", call. = FALSE)
  }

  result <- eligibility
  result$probability <- rep(NA_real_, nrow(result))
  result$failure_kind <- rep(NA_character_, nrow(result))
  result$failure_reason <- rep(NA_character_, nrow(result))
  for (i in which(result$disposition == "eligible")) {
    request <- rrp_provider_request(result[i, , drop = FALSE], as_of_time)
    attempt <- tryCatch(
      list(value = provider(project_root, request)),
      error = function(error) list(error = conditionMessage(error))
    )
    outcome <- if ("error" %in% names(attempt)) {
      reason <- trimws(attempt$error)
      if (!nzchar(reason)) reason <- "Provider raised an error."
      list(disposition = "provider_failure", probability = NA_real_,
           failure_kind = "error", failure_reason = reason)
    } else {
      rrp_interpret_provider_result(attempt$value)
    }
    result$disposition[i] <- outcome$disposition
    result$probability[i] <- outcome$probability
    result$failure_kind[i] <- outcome$failure_kind
    result$failure_reason[i] <- outcome$failure_reason
  }
  result
}
