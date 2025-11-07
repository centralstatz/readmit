# List the topics from the Provider Data Catalog (PDC)

Provides the collection of topics from the CMS Provider Data Catalog
(PDC) (https://data.cms.gov/provider-data/) in which various datasets
are available for. This is typically used to retrieve a topic selection
for downstream use in
[`pdc_datasets`](https://centralstatz.github.io/readmit/reference/pdc_datasets.md).

## Usage

``` r
pdc_topics()
```

## Value

A character vector

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
```
