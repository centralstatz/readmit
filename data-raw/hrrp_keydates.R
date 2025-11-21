## code to prepare `hrrp_keydates` dataset goes here

# Performance periods
hrrp_performance_periods <-
  tibble::tribble(
    ~ProgramYear , ~StartDate   , ~EndDate     ,
            2027 , "2023-07-01" , "2025-06-30" ,
            2026 , "2021-07-01" , "2024-06-30" ,
            2025 , "2020-07-01" , "2023-06-30" ,
            2024 , "2019-07-01" , "2019-12-01" ,
            2024 , "2020-07-01" , "2022-06-30" ,
            2023 , "2018-07-01" , "2019-12-01" ,
            2023 , "2020-07-01" , "2021-06-30" ,
            2022 , "2017-07-01" , "2019-12-01" ,
            2021 , "2016-07-01" , "2019-06-30" ,
            2020 , "2015-07-01" , "2018-06-30" ,
            2019 , "2014-07-01" , "2017-06-30" ,
  )

# Payment periods
hrrp_payment_periods <-
  tibble::tibble(ProgramYear = c(2027:2019)) |>

  # Add consistent payment range
  dplyr::mutate(
    StartDate = paste0(ProgramYear - 1, "-10-01"),
    EndDate = paste0(ProgramYear, "-09-30"),
    dplyr::across(
      -ProgramYear,
      as.Date
    )
  )

# Review and correction periods
hrrp_review_periods <-
  tibble::tribble(
    ~ProgramYear , ~StartDate   , ~EndDate     ,
            2026 , "2025-08-12" , "2025-09-10" ,
            2025 , "2024-08-12" , "2024-09-10" ,
            2024 , "2023-08-08" , "2023-09-07" ,
            2023 , "2022-08-08" , "2022-09-07" ,
            2022 , "2021-08-09" , "2021-09-08" ,
            2021 , "2020-08-10" , "2020-09-09" ,
            2020 , "2019-08-09" , "2019-09-09" ,
            2019 , "2018-08-06" , "2018-09-05" ,
  )

# Claims snapshot
hrrp_snapshot_dates <-
  tibble::tribble(
    ~ProgramYear , ~SnapshotDate ,
            2027 , "2025-09-30"  ,
            2026 , "2024-10-22"  ,
            2025 , "2023-10-13"  ,
            2024 , "2022-09-30"  ,
            2023 , "2021-09-24"  ,
            2022 , "2020-09-25"  ,
            2021 , "2019-09-27"  ,
            2020 , "2018-09-28"  ,
            2019 , "2017-09-29"  ,
  )

# Cohort inclusion
hrrp_cohort_inclusion <-
  tibble::tribble(
    ~ProgramYear , ~AMI , ~COPD , ~HF , ~PN , ~CABG , ~HK ,
            2027 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2026 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2025 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2024 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2023 ,    1 ,     1 ,   1 ,   0 ,     1 ,   1 ,
            2022 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2021 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2020 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
            2019 ,    1 ,     1 ,   1 ,   1 ,     1 ,   1 ,
  )

## Master date table
hrrp_keydates <-
  # Performance
  hrrp_performance_periods |>
  dplyr::rename_with(\(x) paste0("Performance", x), -ProgramYear) |>

  # Payment
  dplyr::left_join(
    y = hrrp_payment_periods |>
      dplyr::rename_with(\(x) paste0("Payment", x), -ProgramYear),
    by = "ProgramYear"
  ) |>

  # Review
  dplyr::left_join(
    y = hrrp_review_periods |>
      dplyr::rename_with(\(x) paste0("Review", x), -ProgramYear),
    by = "ProgramYear"
  ) |>

  # Claims snapshot
  dplyr::left_join(
    y = hrrp_snapshot_dates,
    by = "ProgramYear"
  ) |>

  # Cohort inclusion
  dplyr::left_join(
    y = hrrp_cohort_inclusion,
    by = "ProgramYear"
  )

# Add to package
usethis::use_data(hrrp_keydates, overwrite = TRUE)
usethis::use_data(hrrp_performance_periods, overwrite = TRUE)
usethis::use_data(hrrp_payment_periods, overwrite = TRUE)
usethis::use_data(hrrp_review_periods, overwrite = TRUE)
usethis::use_data(hrrp_snapshot_dates, overwrite = TRUE)
usethis::use_data(hrrp_cohort_inclusion, overwrite = TRUE)
