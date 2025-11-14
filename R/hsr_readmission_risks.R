#' Compute discharge-level readmission risks in a Hospital-Specific Report (HSR)
#'
#' @param file File path to a report
#' @param cohort Cohort to compute readmission risks for. One of `c("AMI", "COPD", "HF", "PN", "CABG", "HK")`
#'
#' @description
#' Computes the _predicted_ and _expected_ readmission risks for each eligible discharge in the specified cohort.
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
#' * `ID Number`: The unique discharge identifier (see [hsr_extract_discharges()])
#' * `Predicted`: The predicted readmission risk for the discharge
#' * `Expected`: The expected readmission risk for the discharge
#'
#' @export
#'
#' @examples
#' # Access a report
#' my_report <- hsr_mock_reports("FY2025_HRRP_MockHSR.xlsx")
#'
#' # Compute readmission risks for HF discharges
#' hf_risks <- hsr_readmission_risks(my_report, "HF")
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
#'
#' # Check that this matches the report table
#' hsr_extract_cohort_summary(my_report) |>
#'  dplyr::select(
#'   dplyr::matches(
#'      paste0(
#'        "^Measure|",
#'        "^Number of Eligible Discharges|",
#'        "^Predicted|",
#'        "^Expected|",
#'        "^Excess"
#'      )
#'    )
#'  )
hsr_readmission_risks <-
  function(file, cohort) {
    # Extract the discharges
    discharges <-
      hsr_extract_discharges(
        file = file,
        cohort = cohort,
        discharge_phi = FALSE,
        risk_factors = TRUE,
        eligible_only = TRUE
      )

    # Extract model coefficients
    model_weights <-
      hsr_extract_coefficients(
        file = file,
        cohort = cohort
      ) |>

      # Rename for relevance
      dplyr::rename(Weight = Value)

    # Extract intercepts
    intercepts <-
      model_weights |>
      dplyr::filter(stringr::str_detect(Factor, "_EFFECT$")) |>
      tidyr::pivot_wider(names_from = Factor, values_from = Weight)

    # Compute probabilities
    discharges |>

      # Send down the rows
      tidyr::pivot_longer(
        cols = -c(dplyr::all_of("ID Number")),
        names_to = "Factor",
        values_to = "Value"
      ) |>

      # Join to attach model weights
      dplyr::inner_join(
        y = model_weights,
        by = "Factor"
      ) |>

      # Compute weighted-sum
      dplyr::summarize(
        LP = sum(Value * Weight),
        .by = `ID Number`
      ) |>

      # Add intercept terms; map to probability scale
      dplyr::mutate(
        Predicted = LP + intercepts$HOSP_EFFECT,
        Expected = LP + intercepts$AVG_EFFECT,
        dplyr::across(
          c(Predicted, Expected),
          \(x) 1 / (1 + exp(-x))
        )
      ) |>

      # Remove linear predictor
      dplyr::select(-LP)
  }
