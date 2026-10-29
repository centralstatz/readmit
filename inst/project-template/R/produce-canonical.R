# Supply episodes discharged by as_of_time, a UTC POSIXct instant. Return a
# named list with discharge_episode and terminal_event data frames. Required
# discharge columns: character episode_id, patient_id, index_encounter_id;
# UTC POSIXct admission_time, discharge_time. Required terminal-event columns:
# character terminal_event_id, episode_id, event_type (readmission or death);
# UTC POSIXct occurred_at, available_at. Keep these columns in empty tables.
# Each event refers to a supplied episode; occurrence and availability are
# distinct concepts and may fall on either side of the analytical time.
# `readmit` derives the 30-elapsed-day endpoint from discharge_time.
# See this project's README.md for the canonical contract. You may source
# supporting project-owned scripts using paths built from project_root.
rrp_produce_canonical <- function(project_root, as_of_time) {
  stop("Project author must implement canonical source mapping.", call. = FALSE)
}
