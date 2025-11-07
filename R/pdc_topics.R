#' List the topics from the Provider Data Catalog (PDC)
#'
#' @description Provides the collection of topics from the CMS Provider Data Catalog (PDC) (https://data.cms.gov/provider-data/) in which various datasets are available for. This is typically used to retrieve a topic selection for downstream use in \code{\link{pdc_datasets}}.
#'
#' @return A character vector
#' @export
#'
#' @examples
#' pdc_topics()
pdc_topics <-
  function() {
    # URL to query
    url <- "https://data.cms.gov/provider-data/api/1/search?fulltext=theme&page=1&page-size=20&sort-order=desc&facets=theme"

    # Request results
    request <- httr::GET(url)

    # Check for success
    if (request$status_code != 200) {
      stop("Request did not return a successful status code.")
    }

    # Extract the content
    request <- httr::content(request)

    # Extract needed components
    results <- request$facets

    # Iterate result, collect topic names
    topics <- c()
    for (i in seq_along(results)) {
      topics <- c(topics, results[[i]]$name)
    }

    # Return the topics
    topics
  }
