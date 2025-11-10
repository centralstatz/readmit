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
pdc_datasets("Hospitals") |>
   dplyr::filter(stringr::str_detect(title, "(?i)readmission"))
#> # A tibble: 1 × 7
#>   datasetid topic     title        description issued     modified   downloadurl
#>   <chr>     <chr>     <chr>        <chr>       <date>     <date>     <chr>      
#> 1 9n3s-kdb3 Hospitals Hospital Re… In October… 2020-12-10 2025-01-08 https://da…
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
