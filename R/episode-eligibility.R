# Evaluate Stage 2 canonical facts at one UTC as_of_time. Return one row per
# episode in source order, with a fixed endpoint 30 elapsed days after discharge.
# Risk, when eligible, concerns (as_of_time, followup_window_end]. An event is
# known only if both occurrence and availability are at or before as_of_time.
# The earliest known event determines ineligibility; readmission wins a death
# tie, then event ID settles any remaining tie. Retain only that event's context
# so a later assessment can explain its decision without copying all events.
# The mapper promises episodes discharged by as_of_time. A pre-discharge row
# gets an internal result here, but is not a new persisted disposition.
rrp_evaluate_eligibility <- function(canonical, as_of_time) {
  if (length(as_of_time) != 1L) {
    stop("`as_of_time` must be one finite UTC POSIXct instant.", call. = FALSE)
  }
  rrp_check_utc_time(as_of_time, "as_of_time")
  rrp_check_canonical_source(canonical)

  episodes <- canonical$discharge_episode
  events <- canonical$terminal_event
  result <- episodes[c("episode_id", "patient_id", "index_encounter_id",
                       "admission_time", "discharge_time")]
  result$followup_window_end <- episodes$discharge_time + 30 * 24 * 60 * 60
  result$disposition <- rep("eligible", nrow(episodes))
  result$terminal_event_id <- rep(NA_character_, nrow(episodes))
  result$terminal_event_type <- rep(NA_character_, nrow(episodes))
  result$terminal_occurred_at <- as.POSIXct(
    rep(NA_real_, nrow(episodes)), origin = "1970-01-01", tz = "UTC"
  )
  result$terminal_available_at <- as.POSIXct(
    rep(NA_real_, nrow(episodes)), origin = "1970-01-01", tz = "UTC"
  )

  result$disposition[as_of_time < episodes$discharge_time] <-
    "not_yet_discharged"
  result$disposition[as_of_time >= result$followup_window_end] <-
    "window_closed"

  known <- events[
    events$occurred_at <= as_of_time & events$available_at <= as_of_time,
    , drop = FALSE
  ]
  if (nrow(known)) {
    known <- known[order(known$episode_id, known$occurred_at,
                         known$event_type != "readmission",
                         known$terminal_event_id), , drop = FALSE]
    selected <- known[!duplicated(known$episode_id), , drop = FALSE]
    index <- match(result$episode_id, selected$episode_id)
    affected <- which(!is.na(index) & result$disposition == "eligible")
    if (length(affected)) {
      events_for_episodes <- selected[index[affected], , drop = FALSE]
      result$disposition[affected] <- ifelse(
        events_for_episodes$event_type == "readmission",
        "known_readmission", "known_death"
      )
      result$terminal_event_id[affected] <-
        events_for_episodes$terminal_event_id
      result$terminal_event_type[affected] <- events_for_episodes$event_type
      result$terminal_occurred_at[affected] <-
        events_for_episodes$occurred_at
      result$terminal_available_at[affected] <-
        events_for_episodes$available_at
    }
  }
  result
}
