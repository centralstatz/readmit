#' Check an RRP project's authoring structure
#'
#' Check that an existing project has readable `rrp-project.dcf` and
#' `rrp-authoring.dcf` files and that their configured scripts define
#' `rrp_produce_canonical(project_root, as_of_time)` and
#' `rrp_calculate_risk(project_root, request)`. A newly initialized project's
#' deliberate function stubs pass this check.
#'
#' @param path Path to an existing RRP project directory.
#' @return `TRUE`, invisibly, when the essential configuration and authoring
#'   functions load successfully. Missing or unusable resources raise an error.
#'
#' @details The project-authored scripts are sourced, so their top-level R code
#'   can run. Neither authoring function is called. This is a structural check;
#'   it does not test source data, model behavior, analytical readiness, or the
#'   project's Shiny application.
#'
#' @examples
#' project <- tempfile("rrp-validation-")
#' rrp_project_init(project, "example-rrp")
#' rrp_project_validate(project)
#' unlink(project, recursive = TRUE)
#'
#' @export
rrp_project_validate <- function(path) {
  rrp_load_project_authoring(path)
  invisible(TRUE)
}
