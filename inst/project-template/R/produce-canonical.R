# Supply canonical discharge episodes and terminal events from your clinical
# sources. Select the discharge population appropriate to as_of_time and map
# your local identities and event classifications here. `readmit` will determine
# episode eligibility and run the shared analytical workflow.
# The detailed canonical table contract will be documented with those operations.
rrp_produce_canonical <- function(project_root, as_of_time) {
  stop("Project author must implement canonical source mapping.", call. = FALSE)
}
