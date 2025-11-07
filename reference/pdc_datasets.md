# List the datasets available in the Provider Data Catalog (PDC)

Provides the names, identifiers, and other associated metadata of
datasets available from the CMS Provider Data Catalog (PDC)
(https://data.cms.gov/provider-data/). This can be used to explore
dataset contents/metadata and/or be used for identifying datasets to
import in
[`pdc_read`](https://centralstatz.github.io/readmit/reference/pdc_read.md).

## Usage

``` r
pdc_datasets(topics = NULL)
```

## Arguments

- topics:

  A topic to list datasets for (see
  [`pdc_topics`](https://centralstatz.github.io/readmit/reference/pdc_topics.md)).
  If NULL, all datasets will be returned.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html)
containing dataset metadata. Specifically, an entry from the `datasetid`
column can be used in
[`pdc_read`](https://centralstatz.github.io/readmit/reference/pdc_read.md).

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
pdc_datasets("Hospitals")
#> # A tibble: 67 × 7
#>    datasetid topic     title       description issued     modified   downloadurl
#>    <chr>     <chr>     <chr>       <chr>       <date>     <date>     <chr>      
#>  1 wue8-3vwe Hospitals Ambulatory… This file … 2025-07-16 2025-06-27 https://da…
#>  2 4jcv-atw7 Hospitals Ambulatory… A list of … 2025-07-16 2025-06-27 https://da…
#>  3 axe7-s95e Hospitals Ambulatory… This file … 2025-07-16 2025-06-27 https://da…
#>  4 hbf-map   Hospitals Birthing F… A list of … 2025-07-09 2025-07-16 https://da…
#>  5 muwa-iene Hospitals CMS Medica… This data … 2020-12-10 2025-07-16 https://da…
#>  6 ynj2-r877 Hospitals Complicati… Complicati… 2023-07-05 2025-07-16 https://da…
#>  7 qqw3-t4ie Hospitals Complicati… Complicati… 2020-12-10 2025-07-16 https://da…
#>  8 bs2r-24vh Hospitals Complicati… Complicati… 2020-12-10 2025-07-16 https://da…
#>  9 z8ax-x9j1 Hospitals Complicati… Prospectiv… 2024-07-31 2025-07-16 https://da…
#> 10 jfnd-nl7s Hospitals Complicati… Prospectiv… 2024-07-31 2025-07-16 https://da…
#> # ℹ 57 more rows
```
