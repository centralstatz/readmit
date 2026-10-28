# readmit v1.0.0 — Architecture Specification

- **Target release:** `readmit` v1.0.0
- **Status:** Draft — under active development
- **Document type:** Living architectural specification
- **Scope:** Intended architecture for the v1.0.0 release

This document is the current source of truth for the planned `readmit` v1.0.0 architecture. It describes the intended release, rather than the present implementation or a hypothetical final system. Decisions will be added and refined here as they are made; Git will track the document's evolution. Future releases may revise this same document.

## Architectural foundation

### Package identity

`readmit` is the R package that implements the Readmission Risk Pool (RRP) analytical platform. It provides reusable functionality to create, configure, execute, and operate RRP projects. The package is the platform implementation, not merely an interface to a separately installed platform.

### Distribution and development

`readmit` is developed as a conventional R package, with CRAN as an intended distribution channel. Standard R package tooling handles installation, dependencies, documentation, testing, and software checks. The custom installation, software-realization, qualification, and distribution infrastructure of the previous RRP implementation is not part of this architecture.

### RRP projects

An RRP project is a user-owned directory created and operated through `readmit` functions. It contains the configuration, source integration, risk-provider implementation, persistent analytical state, generated analytical products, and Shiny application needed for that implementation. The package can create and operate multiple independent projects.

### Reference implementation

The package includes a reference RRP project using synthetic data and a reference risk provider. Users can initialize a working copy through the package's public R interface. Resources in the installed package remain separate from the user's initialized project.

### Shiny application

The Shiny application belongs to the RRP project. It is a conventional Shiny application that can be run and deployed with established R and Shiny tooling. It has no separate platform installation, external deployment artifact, or independent software lifecycle.

### Analytical purpose

RRP integrates clinical source data and risk predictions into a longitudinal analytical system for understanding patient readmission risk, maintaining historical assessments, generating analytical products, and presenting results through an interactive application. Specific data contracts, analytical methods, persistence behavior, and products are **To be defined**.

## Public R API and project operations

This section will define the user-facing operations for initializing, validating, executing, refreshing, inspecting, and operating RRP projects. Function names, arguments, return values, and exact responsibilities are **To be defined**.

## RRP project structure

This section will define the project directory layout and ownership of configuration, adapters, providers, state, products, and application files. The precise directory contract is **To be defined**.

## Configuration and extensibility

This section will define how users configure projects, connect source data, supply risk providers, and customize their implementations. The configuration and extension contracts are **To be defined**.

## Canonical data model

This section will define the common analytical data structure used to standardize source information for RRP operations. Its fields and contracts are **To be defined**.

## Analytical execution lifecycle

This section will define the workflow connecting source integration, risk prediction, longitudinal history, and product generation. Its sequence and operational behavior are **To be defined**.

## Historical state and persistence

This section will define how risk assessments and related analytical state are retained across executions. The persistence mechanism and update behavior are **To be defined**.

## Analytical products

This section will define the outputs generated from risk assessments and historical data for analytical and application use. The specific products and their contracts are **To be defined**.

## Shiny application architecture

This section will define the project's interactive application, including its major views, data consumption, and relationship to the project. Those details are **To be defined**.

## Reference project

This section will define the synthetic reference implementation, its included resources, and how a working copy is initialized and operated. Those details are **To be defined**.

## Testing and validation

This section will define conventional R package checks and focused functional tests appropriate for v1.0.0. The specific tests are **To be defined**. Testing should establish meaningful behavior and analytical correctness without an elaborate qualification or upfront validation framework.

## Architectural boundaries and non-goals

The v1.0.0 architecture does not require:

- Custom software installation or package-management systems.
- Software-realization registries.
- Formal qualification authorities or elaborate evidence frameworks.
- A mandatory custom CLI.
- Separate application export or deployment lifecycle machinery.
- Infrastructure abstractions unnecessary to operate RRP.
- Speculative functionality solely for hypothetical future releases.

These boundaries allow functionality and safeguards when actual RRP requirements justify them.
