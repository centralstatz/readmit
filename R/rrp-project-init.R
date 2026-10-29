#' Create an RRP project
#'
#' Copy the installed project template into a new, user-owned directory. The
#' project contains editable configuration, branding, source-mapping and
#' risk-provider scripts, and a Shiny application. Initialization does not
#' create analytical state or products. The project owner must implement the
#' two analytical scripts before running assessments.
#'
#' @param path Destination for the new project. Its parent directory must
#'   exist, and the destination itself must not exist, even as an empty
#'   directory.
#' @param project_id A nonempty project identifier beginning with a letter or
#'   digit and containing only letters, digits, `.`, `_`, or `-`. It fills the
#'   project identity and initial branding fields; edit `_brand.yml` afterward
#'   to change the displayed name or styling.
#'
#' @return The normalized project path, invisibly.
#'
#' @details The project-owned application runs separately with ordinary Shiny
#'   tooling, for example `shiny::runApp("path/to/project/app")`, after its
#'   dependencies are installed as described in the project's `README.md`.
#'
#' @examples
#' project <- file.path(tempdir(), "example-rrp-project")
#' if (!file.exists(project)) {
#'   rrp_project_init(project, "example-rrp-project")
#' }
#'
#' @export
rrp_project_init <- function(path, project_id) {
  if (missing(path) || !is.character(path) || length(path) != 1L ||
      is.na(path) || !nzchar(path)) {
    stop("`path` must be one nonempty destination path.", call. = FALSE)
  }
  if (missing(project_id) || !is.character(project_id) ||
      length(project_id) != 1L || is.na(project_id) ||
      !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", project_id)) {
    stop("`project_id` must contain only letters, digits, '.', '_', or '-', and begin with a letter or digit.",
         call. = FALSE)
  }
  if (file.exists(path)) {
    stop("The project destination already exists; choose a new path.",
         call. = FALSE)
  }
  if (!dir.exists(dirname(path))) {
    stop("The destination's parent directory must already exist.",
         call. = FALSE)
  }

  template <- system.file("project-template", package = "readmit")
  if (!nzchar(template)) {
    stop("The installed project template could not be found.", call. = FALSE)
  }
  if (!dir.create(path)) {
    stop("Could not create the project destination.", call. = FALSE)
  }
  complete <- FALSE
  on.exit(if (!complete) unlink(path, recursive = TRUE), add = TRUE)

  resources <- list.files(template, all.files = TRUE, no.. = TRUE,
                          full.names = TRUE)
  copied <- file.copy(resources, path, recursive = TRUE)
  if (length(copied) != length(resources) || !all(copied)) {
    stop("Could not copy the complete project template.", call. = FALSE)
  }

  placeholder <- "@@RRP_PROJECT_ID@@"
  for (file in c("rrp-project.dcf", "_brand.yml")) {
    destination_file <- file.path(path, file)
    lines <- readLines(destination_file, warn = FALSE)
    if (!any(grepl(placeholder, lines, fixed = TRUE))) {
      stop(sprintf("Project template placeholder is missing from %s.", file),
           call. = FALSE)
    }
    writeLines(gsub(placeholder, project_id, lines, fixed = TRUE),
               destination_file)
  }

  complete <- TRUE
  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}
