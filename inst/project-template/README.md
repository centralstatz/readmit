# RRP project

This directory is your RRP project. You own its configuration, clinical source
integration, risk model, branding, and any application code. Edit and version
these files with your usual R tools.

- `R/produce-canonical.R` is where you read your clinical sources, choose the
  discharge population, and map discharge episodes and terminal events into the
  canonical data expected by `readmit`.
- `R/calculate-risk.R` is where you use your own predictors and model to estimate
  remaining readmission risk for an eligible episode.
- `rrp-project.dcf` identifies the project. `rrp-authoring.dcf` points to the two
  authoring scripts.
- `_brand.yml` and `assets/project-logo.png` provide editable project branding.

`readmit` owns the shared analytical target, eligibility rules, history, and
products. You supply the source mapping and prediction engine for your project.
The Shiny application lives under `app/`; its source and styling belong to you.
You can launch it with `shiny::runApp("app")`, even before analytical products
exist. It will show empty views until products are available.
