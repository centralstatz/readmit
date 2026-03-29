#' Extract discharge-level data from a Hospital-Specific Report (HSR)
#'
#' @param file A parsed HSR bundle or a local source bundle path.
#' @param cohort Cohort to extract the discharges for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#' @param discharge_phi Should discharge PHI be included? Defaults to `TRUE` (see details).
#' @param risk_factors Should readmission risk factors be included? Defaults to `FALSE` (see details).
#' @param eligible_only Should only eligible discharges be included? Defaults to `FALSE` (see details).
#'
#' @description
#' Extracts discharge-level data for a specific cohort from a parsed HSR
#' bundle.
#'
#' @details
#' Parsed discharge components must already have any file-structure differences
#' resolved upstream by the parser layer. This helper operates only on the
#' conceptual `discharges` component in the parsed bundle.
#'
#' `eligible_only = TRUE` is supported when the parsed component contains one or
#' more cohort inclusion columns. The `discharge_phi` and `risk_factors`
#' arguments currently only support the default behavior
#' (`discharge_phi = TRUE`, `risk_factors = FALSE`); other combinations fail
#' clearly until richer discharge field metadata is available in parsed bundles.
#'
#' @return A [tibble::tibble()]
#'
#' @export
#'
#' @examples
#' bundle_path <- file.path(tempdir(), "hsr_bundle")
#' dir.create(bundle_path, recursive = TRUE)
#' utils::write.csv(
#'   data.frame(
#'     cohort = c("HF", "HF"),
#'     `ID Number` = c(1001, 1002),
#'     index_stay = c(1, 1)
#'   ),
#'   file.path(bundle_path, "discharges.csv"),
#'   row.names = FALSE
#' )
#' hsr_discharges(bundle_path, "HF")
hsr_discharges <-
  function(
    file,
    cohort,
    discharge_phi = TRUE,
    risk_factors = FALSE,
    eligible_only = FALSE
  ) {
    # Check arguments
    if (rlang::is_missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }
    cohort <- rlang::arg_match(
      cohort,
      values = c("AMI", "COPD", "HF", "PN", "CABG", "HK")
    )

    discharges <- hsr_require_component(file, "discharges") |>
      hsr_require_fields("discharges", c("cohort", "ID Number")) |>
      hsr_filter_component_cohort("discharges", cohort)

    # Check for eligible only inclusion
    if (eligible_only) {
      inclusion_cols <- names(discharges)[stringr::str_detect(names(discharges), "Cohort Inclusion")]

      if (length(inclusion_cols) < 1) {
        stop(
          "HSR component `discharges` does not contain cohort inclusion fields ",
          "required for `eligible_only = TRUE`."
        )
      }

      discharges <-
        discharges |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::all_of(inclusion_cols),
            \(.inc) .inc == "0"
          )
        )
    }

    if (!identical(discharge_phi, TRUE) || !identical(risk_factors, FALSE)) {
      stop(
        "HSR component `discharges` does not yet support customized ",
        "`discharge_phi` or `risk_factors` selection."
      )
    }

    discharges
  }

hsr_discharges_legacy <-
  function(
    file,
    cohort,
    discharge_phi = TRUE,
    risk_factors = FALSE,
    eligible_only = FALSE
  ) {
    sheets <- readxl::excel_sheets(file)

    temp_discharges <-
      readxl::read_xlsx(
        path = file,
        sheet = stringr::str_subset(
          sheets,
          pattern = paste0("\\s", cohort, "\\s")
        ),
        skip = 6,
        na = c("--", "N/A")
      ) |>
      dplyr::rename_with(
        \(x) {
          stringr::str_remove_all(x, "[[:cntrl:]]") |>
            stringr::str_replace("^ID.{0,}Number$", "ID Number")
        }
      ) |>
      dplyr::select(-dplyr::matches("_EFFECT$"))

    discharges <-
      temp_discharges |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of("ID Number"),
          \(.id) {
            dplyr::case_when(
              stringr::str_detect(.id, "[^0-9]") ~ NA_character_,
              TRUE ~ .id
            ) |>
              as.integer()
          }
        )
      ) |>
      dplyr::filter(!is.na(.data$`ID Number`))

    if (eligible_only) {
      discharges <-
        discharges |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::matches("Cohort Inclusion"),
            \(.inc) .inc == "0"
          )
        )
    }

    candidates <-
      temp_discharges[1, ] |>
      tidyr::pivot_longer(
        cols = dplyr::everything(),
        names_to = "Column",
        values_to = "Value",
        values_transform = list(Value = as.character)
      )

    if (!discharge_phi) {
      candidates <- candidates |> dplyr::filter(!is.na(.data$Value))
    }
    if (!risk_factors) {
      candidates <- candidates |> dplyr::filter(is.na(.data$Value))
    }

    discharges |>
      dplyr::select(
        dplyr::any_of(
          c(
            "ID Number",
            candidates$Column
          )
        )
      )
  }
