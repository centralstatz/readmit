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

rrp_percent_label <- function(value) {
  sub("\\.0%$", "%", sprintf("%.1f%%", 100 * value))
}

rrp_risk_cell <- function(value) {
  if (is.na(value)) {
    return(shiny::tags$span(class = "rrp-risk-unavailable", "Unavailable"))
  }
  shiny::tags$div(
    class = "rrp-risk-cell",
    shiny::tags$strong(class = "rrp-risk-value", rrp_percent_label(value)),
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

rrp_utc_exact_label <- function(value) {
  format(value, "%b %d, %Y %H:%M:%OS6 UTC", tz = "UTC")
}

rrp_sparkline <- function(history) {
  if (is.null(history) || !nrow(history)) {
    return(shiny::tags$span(class = "rrp-history-unavailable", "No history"))
  }
  seconds <- as.numeric(history$as_of_time)
  x <- if (length(unique(seconds)) == 1L) rep(50, length(seconds)) else
    5 + 90 * (seconds - min(seconds)) / (max(seconds) - min(seconds))
  y <- 28 - 24 * history$probability
  shiny::tags$svg(
    class = "rrp-sparkline", viewBox = "0 0 100 32", role = "img",
    `aria-label` = sprintf("%d recorded accepted risk estimates", nrow(history)),
    shiny::tags$line(x1 = 5, y1 = 28, x2 = 95, y2 = 28,
                     class = "rrp-sparkline-baseline"),
    if (nrow(history) > 1L) shiny::tags$polyline(
      points = paste(sprintf("%.2f,%.2f", x, y), collapse = " "),
      class = "rrp-sparkline-guide"
    ),
    lapply(seq_along(x), function(i) shiny::tags$circle(
      cx = sprintf("%.2f", x[[i]]), cy = sprintf("%.2f", y[[i]]),
      r = 2.8, class = "rrp-sparkline-point"
    ))
  )
}

rrp_observation_table <- function(history) {
  shiny::tags$div(
    class = "rrp-observations",
    shiny::tags$h3("Recorded assessments"),
    shiny::tags$p("Each row is one accepted assessment. Repeated times remain separate runs."),
    shiny::tags$div(class = "rrp-observation-scroll", shiny::tags$table(
      class = "rrp-observation-table",
      shiny::tags$thead(shiny::tags$tr(
        shiny::tags$th("Assessment time (UTC)"),
        shiny::tags$th("Recorded risk"),
        shiny::tags$th("Run ID")
      )),
      shiny::tags$tbody(lapply(seq_len(nrow(history)), function(i)
        shiny::tags$tr(
          shiny::tags$td(rrp_utc_exact_label(history$as_of_time[[i]])),
          shiny::tags$td(rrp_percent_label(history$probability[[i]])),
          shiny::tags$td(history$run_id[[i]])
        )
      ))
    ))
  )
}

rrp_count_label <- function(value) {
  format(value, big.mark = ",", trim = TRUE, scientific = FALSE)
}

rrp_snapshot_ui <- function(time) {
  if (is.null(time)) return(shiny::tags$span(
    class = "rrp-snapshot-empty", "No analytical product snapshot loaded"
  ))
  shiny::tags$span(
    class = "rrp-snapshot-label", "SELECTED ANALYTICAL SNAPSHOT",
    shiny::tags$strong(rrp_utc_label(time))
  )
}

rrp_scope_ui <- function(scope) {
  shiny::tags$div(
    class = "rrp-scope-summary",
    shiny::tags$div(
      class = "rrp-scope-total",
      shiny::tags$span("EPISODES ASSESSED"),
      shiny::tags$strong(rrp_count_label(scope$episodes_assessed)),
      shiny::tags$small("Episodes considered in the selected assessment run")
    ),
    shiny::tags$div(
      class = "rrp-scope-groups",
      shiny::tags$section(
        class = "rrp-scope-group rrp-scope-eligible",
        shiny::tags$div(class = "rrp-scope-group-head",
                        shiny::tags$span("Eligible episodes"),
                        shiny::tags$strong(rrp_count_label(scope$eligible_count))),
        shiny::tags$p("Eligible for a current remaining-risk estimate"),
        shiny::tags$dl(
          shiny::tags$div(shiny::tags$dt("Accepted estimates"),
                          shiny::tags$dd(rrp_count_label(scope$accepted_count))),
          shiny::tags$div(shiny::tags$dt("Provider failures"),
                          shiny::tags$dd(rrp_count_label(scope$provider_failure_count)))
        )
      ),
      shiny::tags$section(
        class = "rrp-scope-group rrp-scope-ineligible",
        shiny::tags$div(class = "rrp-scope-group-head",
                        shiny::tags$span("Ineligible episodes"),
                        shiny::tags$strong(rrp_count_label(scope$ineligible_count))),
        shiny::tags$p("Outside the current eligible pool"),
        shiny::tags$dl(
          shiny::tags$div(shiny::tags$dt("Follow-up window closed"),
                          shiny::tags$dd(rrp_count_label(scope$window_closed_count))),
          shiny::tags$div(shiny::tags$dt("Known readmission"),
                          shiny::tags$dd(rrp_count_label(scope$known_readmission_count))),
          shiny::tags$div(shiny::tags$dt("Known death"),
                          shiny::tags$dd(rrp_count_label(scope$known_death_count)))
        )
      )
    ),
    shiny::tags$p(
      class = "rrp-scope-reconcile",
      "Assessed = eligible + ineligible. Eligible = accepted estimates + provider failures."
    )
  )
}

rrp_risk_summary_ui <- function(current) {
  accepted <- current$probability[current$disposition == "accepted"]
  if (!length(accepted)) return(shiny::tags$div(
    class = "rrp-risk-summary",
    shiny::tags$p(class = "rrp-risk-denominator",
                  "0 accepted current estimates"),
    empty_state(
      "No current numerical risk estimates available",
      "This snapshot has no accepted current predictions. Provider failures are not zero risk."
    )
  ))
  shiny::tags$div(
    class = "rrp-risk-summary",
    shiny::tags$p(
      class = "rrp-risk-denominator",
      sprintf("%s accepted current estimates among %s eligible episodes",
              rrp_count_label(length(accepted)), rrp_count_label(nrow(current)))
    ),
    shiny::tags$div(
      class = "rrp-risk-metrics",
      shiny::tags$div(class = "rrp-risk-metric",
                      shiny::tags$span("Minimum"),
                      shiny::tags$strong(rrp_percent_label(min(accepted)))),
      shiny::tags$div(class = "rrp-risk-metric rrp-risk-median",
                      shiny::tags$span("Median"),
                      shiny::tags$strong(rrp_percent_label(stats::median(accepted)))),
      shiny::tags$div(class = "rrp-risk-metric",
                      shiny::tags$span("Maximum"),
                      shiny::tags$strong(rrp_percent_label(max(accepted))))
    ),
    shiny::tags$p(
      class = "rrp-risk-summary-note",
      "Descriptive percentages from accepted current estimates only. Unavailable estimates and historical observations are excluded."
    )
  )
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
          bslib::card_body(shiny::uiOutput("rrp_episode_detail"))
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
          "A snapshot-level view of the assessed population and accepted ",
          "current remaining-risk estimates."
        )
      ),
      shiny::tags$div(class = "rrp-snapshot-bar rrp-overview-snapshot",
                      shiny::uiOutput("rrp_overview_snapshot")),
      bslib::layout_columns(
        col_widths = c(7, 5),
        class = "rrp-content-grid rrp-overview-grid",
        bslib::card(
          class = "rrp-panel rrp-overview-panel",
          bslib::card_header(shiny::tags$h2("Operational Scope")),
          bslib::card_body(shiny::uiOutput("rrp_overview_scope"))
        ),
        bslib::card(
          class = "rrp-panel rrp-overview-panel",
          bslib::card_header(shiny::tags$h2("Current Risk Distribution")),
          bslib::card_body(shiny::uiOutput("rrp_overview_risk"))
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
  snapshot_time <- shiny::reactive({
    data <- current()
    scope <- products()$scope
    if (!is.null(data) && nrow(data)) return(data$as_of_time[[1L]])
    if (scope$status == "ok") return(scope$data$as_of_time[[1L]])
    NULL
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
  history <- shiny::reactive({
    if (is.null(current()) || products()$trajectory$status != "ok") return(NULL)
    data <- products()$trajectory$data
    data[order(data$episode_id, data$as_of_time, data$created_at,
               data$run_id), , drop = FALSE]
  })
  history_by_episode <- shiny::reactive({
    data <- history()
    if (is.null(data)) return(NULL)
    split(data, data$episode_id)
  })
  selected_row <- shiny::reactive({
    data <- current()
    id <- selected_episode()
    if (is.null(data) || is.null(id)) return(NULL)
    data[data$episode_id == id, , drop = FALSE]
  })
  selected_history <- shiny::reactive({
    data <- history()
    id <- selected_episode()
    if (is.null(data) || is.null(id)) return(NULL)
    rows <- history_by_episode()[[id]]
    if (is.null(rows)) data[FALSE, , drop = FALSE] else rows
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
    rrp_snapshot_ui(snapshot_time())
  })
  output$rrp_overview_snapshot <- shiny::renderUI({
    rrp_snapshot_ui(snapshot_time())
  })
  output$rrp_overview_scope <- shiny::renderUI({
    product <- products()$scope
    if (no_products()) return(empty_state(
      "No analytical products yet",
      "Run an assessment, then refresh products outside the app to view operational scope."
    ))
    if (product$status != "ok") return(empty_state(
      "Operational scope unavailable",
      paste(product$message, "Refresh products outside the app if needed.")
    ))
    rrp_scope_ui(product$data)
  })
  output$rrp_overview_risk <- shiny::renderUI({
    product <- products()$current
    if (no_products()) return(empty_state(
      "No analytical products yet",
      "Run an assessment, then refresh products outside the app to view current risk."
    ))
    if (product$status != "ok") return(empty_state(
      "Current risk summary unavailable",
      paste(product$message, "Refresh products outside the app if needed.")
    ))
    rrp_risk_summary_ui(product$data)
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
      history = data$episode_id,
      disposition = ifelse(data$disposition == "accepted",
                           "Accepted", "Provider failure"),
      discharge_time = rrp_utc_label(data$discharge_time),
      followup_window_end = rrp_utc_label(data$followup_window_end)
    )
    selected <- match(shiny::isolate(selected_episode()), data$episode_id)
    histories <- history_by_episode()
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
        history = reactable::colDef(
          name = "Accepted history", minWidth = 125, sortable = FALSE,
          cell = function(value) {
            if (is.null(histories)) return(shiny::tags$span(
              class = "rrp-history-unavailable", "History unavailable"
            ))
            rrp_sparkline(histories[[value]])
          }
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
  output$rrp_episode_detail <- shiny::renderUI({
    episode <- selected_row()
    if (is.null(episode) || !nrow(episode)) return(empty_state(
      "Select an episode",
      "Choose a row in the Current Risk Pool to inspect its current estimate and recorded assessments."
    ))
    history_rows <- selected_history()
    shiny::tags$div(
      class = "rrp-episode-detail",
      shiny::tags$div(class = "rrp-detail-identity",
                      shiny::tags$span("SELECTED EPISODE"),
                      shiny::tags$strong(episode$episode_id[[1L]])),
      shiny::tags$div(
        class = "rrp-current-detail",
        shiny::tags$span("CURRENT REMAINING RISK"),
        shiny::tags$strong(if (is.na(episode$probability[[1L]]))
          "Unavailable" else rrp_percent_label(episode$probability[[1L]])),
        shiny::tags$small(if (episode$disposition[[1L]] == "provider_failure")
          "Provider failure in selected assessment" else
          "Accepted in selected assessment")
      ),
      if (is.null(history_rows)) empty_state(
        "History unavailable", products()$trajectory$message
      ) else if (!nrow(history_rows)) empty_state(
        "No accepted history",
        "No accepted risk assessments are recorded for this episode in the available trajectory product."
      ) else shiny::tags$div(
        class = "rrp-history-detail",
        shiny::tags$p(class = "rrp-history-caption",
                      "Recorded accepted estimates at their assessment times."),
        plotly::plotlyOutput("rrp_trajectory_plot", height = "270px"),
        rrp_observation_table(history_rows)
      )
    )
  })
  output$rrp_trajectory_plot <- plotly::renderPlotly({
    data <- selected_history()
    if (is.null(data) || !nrow(data)) return(NULL)
    hover <- sprintf(
      "Assessment: %s<br>Remaining risk: %s<br>Run ID: %s",
      rrp_utc_exact_label(data$as_of_time),
      rrp_percent_label(data$probability), data$run_id
    )
    plot <- plotly::plot_ly(
      x = format(data$as_of_time, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
      y = data$probability,
      type = "scatter", mode = "markers", text = hover,
      hoverinfo = "text", showlegend = FALSE,
      marker = list(size = 10, color = "#147789",
                    line = list(color = "#ffffff", width = 1.5))
    )
    plot <- plotly::layout(
      plot,
      xaxis = list(title = "Analytical assessment time (UTC)", type = "date",
                   tickformat = "%b %d<br>%H:%M", zeroline = FALSE,
                   gridcolor = "#e8eff2"),
      yaxis = list(title = "Remaining probability", range = c(0, 1),
                   tickformat = ".0%", dtick = 0.25, zeroline = FALSE,
                   gridcolor = "#e8eff2"),
      margin = list(l = 62, r = 14, t = 14, b = 72),
      plot_bgcolor = "#ffffff", paper_bgcolor = "#ffffff",
      font = list(family = "Arial, sans-serif", color = "#334956", size = 11)
    )
    plotly::config(plot, displayModeBar = FALSE, responsive = TRUE)
  })
}

shiny::shinyApp(ui, server)
