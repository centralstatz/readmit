# Understand how remaining readmission risk changes after discharge.

READMISSION RISK POOL · ANALYTICAL PLATFORM

![Readmission Risk Pool platform
logo](reference/figures/rrp-platform-dark.svg)

Readmission Risk Pool (RRP) connects an organization’s data and risk
provider to repeated, point-in-time assessments. The `readmit` R package
supplies the shared analytical workflow, retained history, and a
project-owned application.

[Get started
→](https://readmit.centralstatz.com/articles/getting-started.md)
[Explore the implementation
guide](https://readmit.centralstatz.com/articles/implementing-rrp.md)

A REPEATABLE WORKFLOW

01**Map**organization-owned sources

02**Assess**risk at chosen times

03**Retain**outcomes across runs

04**Explore**products in the app

THE ANALYTICAL QUESTION

## One prediction at discharge cannot describe a changing risk pool.

As follow-up time passes and new information becomes available, the set
of eligible discharge episodes can change. A later assessment asks about
the **remaining probability of a first hospital readmission strictly
after that time and through 30 elapsed days after the original
discharge**. Each assessment keeps the original endpoint; it does not
restart the 30-day window.

RRP applies shared eligibility rules to the episodes an organization
supplies, records accepted estimates and other dispositions at each
chosen time, and derives current-risk, trajectory, and
operational-summary products. Its trajectories are recorded assessments,
not continuous predictions between runs.

WHAT THE PLATFORM ENABLES

## From local inputs to an inspectable risk pool.

The organization controls clinical sources, mapping, the risk provider,
and how results are evaluated and used. `readmit` provides the shared
structure around those choices.

01 / CONNECT

### Own the implementation

Start with an ordinary project directory containing editable
source-mapping and risk-provider scripts, configuration, branding, and
its own Shiny app.

02 / ASSESS

### Reassess at chosen times

Apply discharge-anchored eligibility and point-in-time event
availability before requesting risk for eligible episodes.

03 / RETAIN

### Keep the full history

Retain completed runs, including accepted estimates, provider failures,
and ineligible episodes, so earlier results remain inspectable.

04 / EXPLORE

### See the pool and its trajectories

Refresh CSV products from history and explore current remaining risk,
recorded episode trajectories, and operational scope in the project app.

THE PROJECT-OWNED APPLICATION

## A working view of the current pool and recorded risk.

The existing application lists eligible discharge episodes and their
current estimates. Selecting an episode reveals its accepted assessments
across runs.

[![Simulated RRP project application showing eligible discharge episodes
with current-risk bars, one selected episode, and its recorded risk
trajectory](rrp-app-preview.jpg)](https://readmit.centralstatz.com/rrp-app-preview.jpg)

Actual RRP Shiny application with simulated data. The risk values and
episode IDs are illustrative; no patient records are shown. Open the
image for a full-size view.

START WITH READMIT

## Build an RRP project around your data and model.

Install `readmit` 1.0.0 from CRAN, then use the short walkthrough or the
complete simulated-hospital guide.

CRAN RELEASE 1.0.0

    install.packages("readmit")

Project authors supply source mapping and a risk provider. RRP does not
include a clinically validated model.

[**Getting started**A short, installed vignette for the project
workflow.](https://readmit.centralstatz.com/articles/getting-started.md)
[**Implementation guide**A full simulated-hospital walkthrough with
source mapping and a demonstration
model.](https://readmit.centralstatz.com/articles/implementing-rrp.md)
[**Function reference**Package operations, arguments, and
examples.](https://readmit.centralstatz.com/reference/index.md)
[**GitHub repository**Source code, issues, and the current development
version.](https://github.com/centralstatz/readmit)

**Current status: `readmit` 1.0.0 is available on
[CRAN](https://CRAN.R-project.org/package=readmit).** The corresponding
[GitHub v1.0.0
release](https://github.com/centralstatz/readmit/releases/tag/v1.0.0) is
also available.
