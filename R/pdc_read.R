#' Import a dataset from the Provider Data Catalog (PDC)
#'
#' @param datasetid A dataset identifier (see \code{\link{pdc_datasets}}).
#' @param ... Additional arguments passed to \code{\link[readr]{read_csv}}
#'
#' @description Imports a complete dataset from the CMS Provider Data Catalog (PDC) (https://data.cms.gov/provider-data/). Dataset identifiers can be discovered on the webpage and/or with \code{\link{pdc_datasets}}.
#'
#' @return A \code{\link[tibble]{tibble}} containing the requested dataset.
#' @export
#'
#' @examples
#' pdc_datasets("Hospitals") |> dplyr::filter(stringr::str_detect(title, "(?i)readmission"))
#' pdc_read("9n3s-kdb3")
pdc_read <-
  function(datasetid, ...) {
    # Check arguments
    if (rlang::is_missing(datasetid)) {
      stop("Please specify a dataset identifier.")
    }

    # Make the url
    url <- paste0(
      "https://data.cms.gov/provider-data/api/1/metastore/schemas/dataset/items/",
      datasetid,
      "?show-reference-ids=false"
    )

    # Make the request, extract the content
    request <- httr::content(httr::GET(url))

    # Update the variable
    downloadurl <- request$distribution[[1]]$data$downloadURL

    # Import the dataset
    readr::read_csv(
      file = downloadurl,
      ...
    )
  }
