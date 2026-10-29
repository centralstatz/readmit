# Read the one-record DCF files created by rrp_project_init().
rrp_read_project_dcf <- function(root, file, required_field) {
  path <- file.path(root, file)
  if (!file.exists(path) || dir.exists(path)) {
    stop(sprintf("Required project configuration file is missing: %s.", file),
         call. = FALSE)
  }
  record <- tryCatch(
    read.dcf(path),
    error = function(error) {
      stop(sprintf("Could not read %s: %s", file, conditionMessage(error)),
           call. = FALSE)
    }
  )
  if (nrow(record) != 1L) {
    stop(sprintf("%s must contain one DCF record.", file), call. = FALSE)
  }
  for (field in required_field) {
    if (!field %in% colnames(record) || is.na(record[1L, field]) ||
        !nzchar(trimws(record[1L, field]))) {
      stop(sprintf("%s needs a nonempty %s field.", file, field),
           call. = FALSE)
    }
  }
  as.list(record[1L, , drop = TRUE])
}

# Source one configured project script and retain its lexical environment.
rrp_load_project_function <- function(root, relative_path, binding, arguments,
                                      label) {
  if (grepl("^(/|[A-Za-z]:[/\\\\])", relative_path) ||
      startsWith(relative_path, "~")) {
    stop(sprintf("%s script path must be project-relative.", label),
         call. = FALSE)
  }
  path <- file.path(root, relative_path)
  if (!file.exists(path) || dir.exists(path)) {
    stop(sprintf("Configured %s script does not exist: %s.", label,
                 relative_path), call. = FALSE)
  }
  environment <- new.env(parent = globalenv())
  tryCatch(
    sys.source(path, envir = environment, chdir = FALSE),
    error = function(error) {
      stop(sprintf("Could not load %s script %s: %s", label, relative_path,
                   conditionMessage(error)), call. = FALSE)
    }
  )
  if (!exists(binding, envir = environment, inherits = FALSE)) {
    stop(sprintf("%s script must define %s().", label, binding),
         call. = FALSE)
  }
  callable <- get(binding, envir = environment, inherits = FALSE)
  if (!is.function(callable)) {
    stop(sprintf("%s binding in %s script must be a function.", binding,
                 label), call. = FALSE)
  }
  if (!identical(names(formals(callable)), arguments)) {
    stop(sprintf("%s() must have arguments %s.", binding,
                 paste(arguments, collapse = ", ")), call. = FALSE)
  }
  list(path = normalizePath(path, winslash = "/", mustWork = TRUE),
       callable = callable)
}

# Return project identity, resolved script paths, and the two authoring functions.
# Loading evaluates top-level project code but never calls either function.
rrp_load_project_authoring <- function(project_root) {
  if (!is.character(project_root) || length(project_root) != 1L ||
      is.na(project_root) || !nzchar(project_root) ||
      !dir.exists(project_root)) {
    stop("`project_root` must be an existing project directory.",
         call. = FALSE)
  }
  root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  project <- rrp_read_project_dcf(root, "rrp-project.dcf", "Project-ID")
  authoring <- rrp_read_project_dcf(
    root, "rrp-authoring.dcf",
    c("Source-Mapping-Script", "Risk-Provider-Script")
  )
  producer <- rrp_load_project_function(
    root, authoring[["Source-Mapping-Script"]], "rrp_produce_canonical",
    c("project_root", "as_of_time"), "source-mapping"
  )
  provider <- rrp_load_project_function(
    root, authoring[["Risk-Provider-Script"]], "rrp_calculate_risk",
    c("project_root", "request"), "risk-provider"
  )
  list(
    project_root = root,
    project_id = project[["Project-ID"]],
    source_mapping_script = producer$path,
    risk_provider_script = provider$path,
    produce_canonical = producer$callable,
    calculate_risk = provider$callable
  )
}
