#' List the datasets available in the Provider Data Catalog (PDC)
#'
#' @param topics A topic to list datasets for (see \code{\link{pdc_topics}}). If NULL, all datasets will be returned.
#'
#' @description Provides the names, identifiers, and other associated metadata of datasets available from the CMS Provider Data Catalog (PDC) (https://data.cms.gov/provider-data/). This can be used to explore dataset contents/metadata and/or be used for identifying datasets to import in \code{\link{pdc_read}}.
#'
#' @return A \code{\link[tibble]{tibble}} containing dataset metadata. Specifically, an entry from the \code{datasetid} column can be used in \code{\link{pdc_read}}.
#' @export
#'
#' @examples
#' pdc_topics()
#' pdc_datasets("Hospitals")
pdc_datasets <-
  function(
    topics = NULL # Collection of topics to return dataset information for; returns all if left NULL
  ) {
    # Check for input topics
    if (is.null(topics)) {
      topics <- pdc_topics()
    }

    # Iterate to import metadata
    dataset_list <- list()
    for (i in seq_along(topics)) {
      # Extract this topic
      this_topic <- topics[i]

      # Make the url
      url <- paste0(
        "https://data.cms.gov/provider-data/api/1/search?sort=title&page=1&page-size=100&sort-order=asc&facets=0&theme=",
        stringr::str_replace_all(this_topic, " ", "%20")
      )

      # Request results, extract contents
      request <- httr::content(httr::GET(url))

      # Extract the needed component
      results <- request$results

      # Iterate the response to extract metadata for each dataset
      temp_dataset_list <- list()
      for (j in seq_along(results)) {
        temp_dataset_list[[j]] <- tibble::tibble(
          datasetid = results[[j]]$identifier,
          topic = this_topic,
          title = results[[j]]$title,
          description = results[[j]]$description,
          issued = results[[j]]$issued,
          modified = results[[j]]$modified,
          downloadurl = results[[j]]$distribution[[1]]$downloadURL
        )
      }

      # Bind rows
      temp_dataset_list <- dplyr::bind_rows(temp_dataset_list)

      # Add to master list
      dataset_list[[i]] <- temp_dataset_list
    }

    dataset_list |>

      # Bind rows and return
      dplyr::bind_rows() |>

      # Convert dates
      dplyr::mutate(
        dplyr::across(
          c(
            issued,
            modified
          ),
          as.Date
        )
      )
  }
