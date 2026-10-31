# This app belongs to the project. Run it with shiny::runApp("app") from the
# project root, or pass the app directory to shiny::runApp().

project_root <- normalizePath("..", winslash = "/", mustWork = TRUE)
source(file.path("R", "read-products.R"), local = TRUE)
brand <- yaml::read_yaml(file.path(project_root, "_brand.yml"))
project_name <- brand$meta$name$full
primary_color <- brand$color$primary
logo_file <- file.path(project_root, brand$logo$medium$path)

shiny::addResourcePath("rrp-project-brand", dirname(logo_file))
logo_url <- paste0("rrp-project-brand/", basename(logo_file))

rrp_risk_colors <- grDevices::colorRampPalette(c("#147789", "#ad6654"))(101L)

rrp_risk_cell <- function(value) {
  if (is.na(value)) {
    return(shiny::tags$span(class = "rrp-risk-unavailable", "Unavailable"))
  }
  label <- sub("\\.0%$", "%", sprintf("%.1f%%", 100 * value))
  shiny::tags$div(
    class = "rrp-risk-cell",
    shiny::tags$strong(class = "rrp-risk-value", label),
    shiny::tags$span(
      class = "rrp-risk-track", `aria-hidden` = "true",
      shiny::tags$span(
        class = "rrp-risk-fill",
        style = sprintf("width:%.2f%%;background-color:%s;",
                        100 * value,
                        rrp_risk_colors[[round(100 * value) + 1L]])
      )
    )
  )
}

rrp_utc_label <- function(value) {
  format(value, "%b %d, %Y %H:%M:%OS3 UTC", tz = "UTC")
}

empty_state <- function(title, detail) {
  shiny::tags$div(
    class = "rrp-empty-state",
    role = "status",
    shiny::tags$h3(title),
    shiny::tags$p(detail)
  )
}

ui <- bslib::page_navbar(
  title = shiny::tags$span(
    class = "rrp-brand-identity",
    shiny::tags$img(
      class = "rrp-brand-logo", src = logo_url,
      alt = brand$logo$medium$alt
    ),
    shiny::tags$span(class = "rrp-brand-name", project_name)
  ),
  id = "rrp_view",
  fillable = FALSE,
  theme = bslib::bs_theme(version = 5, primary = primary_color),
  header = shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", type = "text/css", href = "rrp.css")
  ),
  bslib::nav_panel(
    "Current Risk Pool",
    shiny::tags$main(
      class = "rrp-page",
      shiny::tags$div(
        class = "rrp-page-intro",
        shiny::tags$span(class = "rrp-eyebrow", "READMISSION RISK POOL"),
        shiny::tags$h1("Current Risk Pool"),
        shiny::tags$p(
          "Every clinically eligible discharge episode in the selected ",
          "assessment, including episodes without an available prediction."
        )
      ),
      shiny::tags$div(
        class = "rrp-snapshot-bar",
        shiny::uiOutput("rrp_snapshot"),
        shiny::actionButton("rrp_reload", "Reload Data",
                            class = "rrp-reload-button")
      ),
      bslib::card(
        class = "rrp-control-card",
        bslib::card_body(shiny::tags$div(
          class = "rrp-controls",
          shiny::textInput("rrp_search", "Find episode ID",
                           placeholder = "Search by episode ID"),
          shiny::tags$div(
            class = "rrp-range-control",
            shiny::sliderInput("rrp_range", "Current probability range",
                               min = 0, max = 1, value = c(0, 1), step = 0.01),
            shiny::tags$p(
              class = "rrp-control-note",
              "Unavailable estimates remain visible; the range applies only ",
              "to numeric predictions."
            )
          )
        ))
      ),
      shiny::uiOutput("rrp_product_notice"),
      bslib::layout_columns(
        col_widths = c(8, 4),
        class = "rrp-content-grid",
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$div(
            class = "rrp-panel-heading",
            shiny::tags$h2("Eligible episodes"),
            shiny::textOutput("rrp_pool_count", inline = TRUE)
          )),
          bslib::card_body(shiny::uiOutput("rrp_pool_region"))
        ),
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Episode Risk Trajectory")),
          bslib::card_body(shiny::tags$div(
            class = "rrp-trajectory-shell",
            shiny::uiOutput("rrp_selected_episode"),
            empty_state(
              "Trajectory view unavailable",
              "Recorded risk observations are not displayed in this view yet."
            )
          ))
        )
      )
    )
  ),
  bslib::nav_panel(
    "Overview",
    shiny::tags$main(
      class = "rrp-page",
      shiny::tags$div(
        class = "rrp-page-intro",
        shiny::tags$span(class = "rrp-eyebrow", "READMISSION RISK POOL"),
        shiny::tags$h1("Overview"),
        shiny::tags$p(
          "A descriptive view of current risk and the scope of assessments."
        )
      ),
      bslib::layout_columns(
        col_widths = c(6, 6),
        class = "rrp-content-grid",
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Current risk")),
          bslib::card_body(empty_state(
            "Current-risk summary unavailable",
            "Descriptive risk summaries are not displayed in this view yet."
          ))
        ),
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Operational scope")),
          bslib::card_body(empty_state(
            "Assessment summary unavailable",
            "Scope counts are not displayed in this view yet."
          ))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  products <- shiny::reactiveVal(rrp_app_read_products(project_root))
  selected_episode <- shiny::reactiveVal(NULL)

  shiny::observeEvent(input$rrp_reload, {
    products(rrp_app_read_products(project_root))
  })

  current <- shiny::reactive({
    product <- products()$current
    if (product$status == "ok") product$data else NULL
  })
  no_products <- shiny::reactive(all(vapply(
    products(), function(product) product$status == "missing", logical(1L)
  )))
  visible <- shiny::reactive({
    data <- current()
    if (is.null(data)) return(NULL)
    query <- if (is.null(input$rrp_search)) "" else trimws(input$rrp_search)
    range <- if (is.null(input$rrp_range)) c(0, 1) else input$rrp_range
    matches_id <- grepl(tolower(query), tolower(data$episode_id), fixed = TRUE)
    matches_risk <- is.na(data$probability) |
      (data$probability >= range[[1L]] & data$probability <= range[[2L]])
    data[matches_id & matches_risk, , drop = FALSE]
  })

  shiny::observeEvent(visible(), {
    rows <- visible()
    id <- selected_episode()
    if (!is.null(id) && (is.null(rows) || !id %in% rows$episode_id)) {
      selected_episode(NULL)
    }
  })
  shiny::observeEvent(
    reactable::getReactableState("rrp_pool_table", "selected"), {
      index <- reactable::getReactableState("rrp_pool_table", "selected")
      rows <- visible()
      if (length(index) == 1L && !is.null(rows) &&
          index >= 1L && index <= nrow(rows)) {
        selected_episode(rows$episode_id[[index]])
      }
    }, ignoreNULL = TRUE
  )

  output$rrp_snapshot <- shiny::renderUI({
    data <- current()
    scope <- products()$scope
    time <- if (!is.null(data) && nrow(data)) data$as_of_time[[1L]] else
      if (scope$status == "ok") scope$data$as_of_time[[1L]] else NULL
    if (is.null(time)) return(shiny::tags$span(
      class = "rrp-snapshot-empty", "No analytical product snapshot loaded"
    ))
    shiny::tags$span(
      class = "rrp-snapshot-label", "SELECTED ANALYTICAL SNAPSHOT",
      shiny::tags$strong(rrp_utc_label(time))
    )
  })
  output$rrp_product_notice <- shiny::renderUI({
    if (no_products()) return(NULL)
    issues <- vapply(products(), function(product) {
      if (product$status %in% c("missing", "invalid", "mismatch"))
        product$message else ""
    }, character(1L))
    issues <- issues[nzchar(issues)]
    if (!length(issues)) return(NULL)
    shiny::tags$div(
      class = "rrp-product-notice", role = "alert",
      shiny::tags$strong("Product data needs attention"),
      shiny::tags$p(paste(issues, collapse = " ")),
      shiny::tags$p("Check the generated CSVs and refresh products outside the app.")
    )
  })
  output$rrp_pool_count <- shiny::renderText({
    data <- current()
    if (is.null(data)) return("")
    sprintf("%d of %d eligible episodes displayed", nrow(visible()), nrow(data))
  })
  output$rrp_pool_region <- shiny::renderUI({
    product <- products()$current
    if (product$status == "missing") return(empty_state(
      if (no_products()) "No analytical products yet" else
        "Current risk product unavailable",
      if (no_products())
        "Run an assessment, then refresh products outside the app to view the current risk pool." else
        product$message
    ))
    if (product$status != "ok") return(empty_state(
      "Current risk product unavailable", product$message
    ))
    if (!nrow(product$data)) return(empty_state(
      "No eligible episodes in this snapshot",
      "The selected assessment is complete, but no supplied episodes are currently eligible."
    ))
    if (!nrow(visible())) return(empty_state(
      "No episodes match these filters",
      "Change the episode search or probability range to see more of the selected pool."
    ))
    shiny::tags$div(class = "rrp-table-wrap",
                    reactable::reactableOutput("rrp_pool_table"))
  })
  output$rrp_pool_table <- reactable::renderReactable({
    data <- visible()
    if (is.null(data) || !nrow(data)) return(NULL)
    rows <- data.frame(
      episode_id = data$episode_id,
      probability = data$probability,
      disposition = ifelse(data$disposition == "accepted",
                           "Accepted", "Provider failure"),
      discharge_time = rrp_utc_label(data$discharge_time),
      followup_window_end = rrp_utc_label(data$followup_window_end)
    )
    selected <- match(shiny::isolate(selected_episode()), data$episode_id)
    reactable::reactable(
      rows, class = "rrp-current-table", selection = "single",
      onClick = "select",
      defaultSelected = if (length(selected) == 1L && !is.na(selected))
        selected else NULL,
      highlight = TRUE, compact = TRUE, bordered = FALSE, striped = FALSE,
      defaultPageSize = 10L, showPageSizeOptions = FALSE,
      defaultColDef = reactable::colDef(headerClass = "rrp-table-header"),
      columns = list(
        episode_id = reactable::colDef(
          name = "Episode ID", minWidth = 160, rowHeader = TRUE,
          defaultSortOrder = "asc", sticky = "left"
        ),
        probability = reactable::colDef(
          name = "Remaining risk", minWidth = 160, align = "left",
          defaultSortOrder = "desc", sortNALast = TRUE,
          cell = function(value) rrp_risk_cell(value)
        ),
        disposition = reactable::colDef(
          name = "Estimate", minWidth = 145
        ),
        discharge_time = reactable::colDef(
          name = "Discharged (UTC)", minWidth = 190
        ),
        followup_window_end = reactable::colDef(
          name = "Follow-up ends (UTC)", minWidth = 190
        )
      ),
      language = reactable::reactableLang(noData = "No episodes match these filters")
    )
  })
  output$rrp_selected_episode <- shiny::renderUI({
    id <- selected_episode()
    if (is.null(id)) return(shiny::tags$p(
      class = "rrp-selected-note", "Select an episode in the table to focus this panel."
    ))
    shiny::tags$p(class = "rrp-selected-note",
                  shiny::tags$span("Selected episode"), shiny::tags$strong(id))
  })
}

shiny::shinyApp(ui, server)
