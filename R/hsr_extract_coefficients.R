hsr_extract_coefficients <-
  function(file, cohort) {
    # Check arguments
    if (missing(file)) {
      stop("Specify path to a CMS HRRP Hospital-Specific Report (HSR)")
    }
    cohort <- match.arg(
      cohort,
      choices = c("AMI", "COPD", "HF", "PN", "CABG", "HK")
    )

    # Sheet names extracted from the report
    sheets <- readxl::excel_sheets(file)

    # Import file
    readxl::read_xlsx(
      path = file,
      sheet = stringr::str_subset(
        sheets,
        pattern = paste0("\\s", cohort, "\\s")
      ),
      skip = 6,
      n_max = 1,
      na = "--"
    ) |>

      # Convert all columns to numeric
      dplyr::mutate(
        dplyr::across(
          dplyr::everything(),
          as.numeric
        )
      ) |>

      # Send down the rows
      tidyr::pivot_longer(
        cols = everything(),
        names_to = "Factor",
        values_to = "Value"
      ) |>

      # Remove non-coefficient columns
      dplyr::filter(!is.na(Value))
  }
