# This app belongs to the project. Run it with shiny::runApp("app") from the
# project root, or pass the app directory to shiny::runApp().

project_root <- normalizePath("..", winslash = "/", mustWork = TRUE)
brand <- yaml::read_yaml(file.path(project_root, "_brand.yml"))
project_name <- brand$meta$name$full
primary_color <- brand$color$primary
logo_file <- file.path(project_root, brand$logo$medium$path)

shiny::addResourcePath("rrp-project-brand", dirname(logo_file))
logo_url <- paste0("rrp-project-brand/", basename(logo_file))

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
          "Accepted remaining readmission-risk estimates and each episode's ",
          "observed risk trajectory."
        )
      ),
      bslib::layout_columns(
        col_widths = c(7, 5),
        class = "rrp-content-grid",
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Current accepted estimates")),
          bslib::card_body(empty_state(
            "No current risk estimates",
            paste(
              "Accepted episode estimates will appear here after your project",
              "has generated analytical products."
            )
          ))
        ),
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Episode Risk Trajectory")),
          bslib::card_body(empty_state(
            "No episode trajectory",
            paste(
              "Once estimates are available, this view will show an episode's",
              "actual recorded assessments."
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
            "No risk summary available",
            "A summary of accepted current estimates will appear here when products are available."
          ))
        ),
        bslib::card(
          class = "rrp-panel",
          bslib::card_header(shiny::tags$h2("Operational scope")),
          bslib::card_body(empty_state(
            "No assessment summary available",
            "The assessed population and its outcomes will appear here when products are available."
          ))
        )
      )
    )
  )
)

server <- function(input, output, session) {}

shiny::shinyApp(ui, server)
