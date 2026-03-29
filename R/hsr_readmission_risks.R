#' Compute discharge-level readmission risks in a Hospital-Specific Report (HSR)
#'
#' @param file A parsed HSR bundle or a local source bundle path.
#' @param cohort Cohort to compute readmission risks for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#'
#' @description
#' Computes the _predicted_ and _expected_ readmission risks for each eligible
#' discharge in the specified cohort from parsed HSR components.
#'
#' @details
#' The [readmission measure](https://qualitynet.cms.gov/inpatient/measures/readmission) is what [CMS](https://www.cms.gov/) uses to grade performance
#' in the [Hospital Readmissions Reduction Program (HRRP)](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp).
#'
#' Individual discharges are assigned an adjusted readmission risk (based on clinical history), which then get aggregated into a
#' hospital-level score and compared to peer groups for penalty determination. Specifically, a random-intercept logistic regression model
#' is built for each cohort ([see methodology](https://qualitynet.cms.gov/inpatient/measures/readmission/methodology)) which serves as the
#' basis for two (2) readmission risks assigned to each discharge:
#'
#' * _Predicted_: Adjusted for patient-specific clinical factors plus the _hospital-specific_ effect (random intercept term)
#' * _Expected_: Adjusted for patient-specific clinical factors plus the _hospital-average_ effect
#'
#' These quantities are then aggregated across all discharges and their ratio is taken to form the _Excess Readmission Ratio (ERR)_, which
#' is then used as the cohort-specific comparison metric. Thus, it is a comparative measure of how likely patients are to be readmitted at
#' _your_ hospital versus the _average_ hospital, given your hospital's clinical characteristics.
#'
#' @return A [tibble::tibble()] containing the following columns:
#'
#' * `ID Number`: The unique discharge identifier (see [hsr_discharges()])
#' * `Predicted`: The predicted readmission risk for the discharge
#' * `Expected`: The expected readmission risk for the discharge
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
#'     AGE = c(1, 0)
#'   ),
#'   file.path(bundle_path, "discharges.csv"),
#'   row.names = FALSE
#' )
#' utils::write.csv(
#'   data.frame(
#'     cohort = c("HF", "HF", "HF"),
#'     term = c("AGE", "HOSP_EFFECT", "AVG_EFFECT"),
#'     value = c(0.25, -0.10, -0.20)
#'   ),
#'   file.path(bundle_path, "coefficients.csv"),
#'   row.names = FALSE
#' )
#'
#' # Compute readmission risks for HF discharges
#' hf_risks <- hsr_readmission_risks(bundle_path, "HF")
#' hf_risks
#'
#' # Compute the ERR from scratch
#' hf_risks |>
#'  dplyr::summarize(
#'    Discharges = dplyr::n(),
#'    Predicted = mean(Predicted),
#'    Expected = mean(Expected),
#'    ERR = Predicted / Expected
#'  )
#'
hsr_readmission_risks <-
  function(file, cohort) {
    if (rlang::is_missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }
    cohort <- rlang::arg_match(
      cohort,
      values = c("AMI", "COPD", "HF", "PN", "CABG", "HK")
    )

    discharges <-
      hsr_require_component(file, "discharges") |>
      hsr_require_fields("discharges", c("cohort", "ID Number")) |>
      hsr_filter_component_cohort("discharges", cohort)

    inclusion_fields <- hsr_component_inclusion_fields(discharges)
    if (length(inclusion_fields) > 0) {
      discharges <- discharges |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::all_of(inclusion_fields),
            \(.inc) .inc == "0"
          )
        )
    }

    risk_factor_fields <- hsr_risk_factor_fields(discharges)
    if (length(risk_factor_fields) < 1) {
      stop(
        "HSR component `discharges` does not contain any risk factor fields for ",
        "readmission risk calculation."
      )
    }

    coefficients <-
      hsr_require_component(file, "coefficients") |>
      hsr_require_fields("coefficients", c("cohort", "term", "value")) |>
      hsr_filter_component_cohort("coefficients", cohort) |>
      dplyr::mutate(value = as.numeric(.data$value))

    intercepts <-
      coefficients |>
      dplyr::filter(.data$term %in% c("HOSP_EFFECT", "AVG_EFFECT"))

    if (!all(c("HOSP_EFFECT", "AVG_EFFECT") %in% intercepts$term)) {
      stop(
        "HSR component `coefficients` must contain both `HOSP_EFFECT` and ",
        "`AVG_EFFECT` for readmission risk calculation."
      )
    }

    model_weights <-
      coefficients |>
      dplyr::filter(!stringr::str_detect(.data$term, "_EFFECT$")) |>
      dplyr::transmute(Factor = .data$term, Weight = .data$value)

    if (nrow(model_weights) < 1) {
      stop(
        "HSR component `coefficients` does not contain any non-intercept model ",
        "weights for readmission risk calculation."
      )
    }

    long_discharges <-
      discharges |>
      dplyr::select(dplyr::all_of(c("ID Number", risk_factor_fields))) |>
      tidyr::pivot_longer(
        cols = -dplyr::all_of("ID Number"),
        names_to = "Factor",
        values_to = "Value"
      ) |>
      dplyr::mutate(Value = as.numeric(.data$Value))

    joined <-
      long_discharges |>
      dplyr::inner_join(
        y = model_weights,
        by = "Factor"
      )

    if (nrow(joined) < 1) {
      stop(
        "No overlapping risk factor terms were found between the parsed ",
        "`discharges` and `coefficients` components."
      )
    }

    intercept_values <-
      intercepts |>
      dplyr::select(.data$term, .data$value) |>
      tibble::deframe()

    joined |>
      dplyr::summarize(
        LP = sum(.data$Value * .data$Weight),
        .by = .data$`ID Number`
      ) |>
      dplyr::mutate(
        Predicted = .data$LP + intercept_values[["HOSP_EFFECT"]],
        Expected = .data$LP + intercept_values[["AVG_EFFECT"]],
        dplyr::across(
          c(.data$Predicted, .data$Expected),
          \(x) 1 / (1 + exp(-x))
        )
      ) |>
      dplyr::select(-.data$LP)
  }
