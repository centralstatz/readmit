# Import datasets from the Provider Data Catalog (PDC)

Explore and import datasets directly from the [CMS Provider Data Catalog
(PDC)](https://data.cms.gov/provider-data/).

- `pdc_topics()`: Retrieves the list of topics (subcategories) that data
  is available for

- `pdc_datasets()`: Retrieves identifiers, names, descriptions, and
  other metadata associated with the datasets in the (optionally
  specified) `topics`

- `pdc_read()`: Imports a full dataset for the given identifier
  (`datasetid`). These are found in `pdc_datasets()`.

## Usage

``` r
pdc_read(datasetid, ...)

pdc_datasets(topics = NULL)

pdc_topics()
```

## Arguments

- datasetid:

  A dataset identifier (e.g., from `pdc_datasets()`)

- ...:

  Additional arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)

- topics:

  A topic to list dataset metadata for (e.g., from `pdc_topics()`)

## Value

A character vector listing available data topics, or a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the requested data/metadata.

## Examples

``` r
# 1. See list of available data topics
pdc_topics()
#>  [1] "Dialysis facilities"                   
#>  [2] "Doctors and clinicians"                
#>  [3] "Home health services"                  
#>  [4] "Hospice care"                          
#>  [5] "Hospitals"                             
#>  [6] "Inpatient rehabilitation facilities"   
#>  [7] "Long-term care hospitals"              
#>  [8] "Nursing homes including rehab services"
#>  [9] "Physician office visit costs"          
#> [10] "Supplier directory"                    


# 2. See list of datasets available for a topic
hospital_data <- pdc_datasets("Hospitals")
hospital_data
#> # A tibble: 69 × 7
#>    datasetid topic     title       description issued     modified   downloadurl
#>    <chr>     <chr>     <chr>       <chr>       <date>     <date>     <chr>      
#>  1 axe7-s95e Hospitals Ambulatory… This file … 2025-10-01 2025-10-01 https://da…
#>  2 wue8-3vwe Hospitals Ambulatory… This file … 2025-10-01 2025-10-01 https://da…
#>  3 4jcv-atw7 Hospitals Ambulatory… A list of … 2025-10-01 2025-10-01 https://da…
#>  4 hbf-map   Hospitals Birthing F… A list of … 2025-07-09 2025-10-14 https://da…
#>  5 muwa-iene Hospitals CMS Medica… This data … 2020-12-10 2025-10-14 https://da…
#>  6 ynj2-r877 Hospitals Complicati… Complicati… 2023-07-05 2025-10-20 https://da…
#>  7 qqw3-t4ie Hospitals Complicati… Complicati… 2020-12-10 2025-10-14 https://da…
#>  8 bs2r-24vh Hospitals Complicati… Complicati… 2020-12-10 2025-10-14 https://da…
#>  9 jfnd-nl7s Hospitals Complicati… Prospectiv… 2024-07-31 2025-10-14 https://da…
#> 10 z8ax-x9j1 Hospitals Complicati… Prospectiv… 2024-07-31 2025-10-14 https://da…
#> # ℹ 59 more rows

# Find a dataset you want
hospital_data |>
   dplyr::filter(
      stringr::str_detect(
         title,
         pattern = "(?i)readmission"
      )
   )
#> # A tibble: 1 × 7
#>   datasetid topic     title        description issued     modified   downloadurl
#>   <chr>     <chr>     <chr>        <chr>       <date>     <date>     <chr>      
#> 1 9n3s-kdb3 Hospitals Hospital Re… In October… 2020-12-10 2025-01-08 https://da…


# 3. Use that data set ID to import
pdc_read("9n3s-kdb3")
#> Rows: 18510 Columns: 12
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (11): Facility Name, Facility ID, State, Measure Name, Number of Dischar...
#> dbl  (1): Footnote
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 18,510 × 12
#>    `Facility Name`     `Facility ID` State `Measure Name` `Number of Discharges`
#>    <chr>               <chr>         <chr> <chr>          <chr>                 
#>  1 SOUTHEAST HEALTH M… 010001        AL    READM-30-AMI-… 296                   
#>  2 SOUTHEAST HEALTH M… 010001        AL    READM-30-CABG… 151                   
#>  3 SOUTHEAST HEALTH M… 010001        AL    READM-30-HF-H… 681                   
#>  4 SOUTHEAST HEALTH M… 010001        AL    READM-30-HIP-… N/A                   
#>  5 SOUTHEAST HEALTH M… 010001        AL    READM-30-PN-H… 490                   
#>  6 SOUTHEAST HEALTH M… 010001        AL    READM-30-COPD… 130                   
#>  7 MARSHALL MEDICAL C… 010005        AL    READM-30-CABG… N/A                   
#>  8 MARSHALL MEDICAL C… 010005        AL    READM-30-HIP-… N/A                   
#>  9 MARSHALL MEDICAL C… 010005        AL    READM-30-HF-H… 176                   
#> 10 MARSHALL MEDICAL C… 010005        AL    READM-30-PN-H… 305                   
#> # ℹ 18,500 more rows
#> # ℹ 7 more variables: Footnote <dbl>, `Excess Readmission Ratio` <chr>,
#> #   `Predicted Readmission Rate` <chr>, `Expected Readmission Rate` <chr>,
#> #   `Number of Readmissions` <chr>, `Start Date` <chr>, `End Date` <chr>
```
