# AGENTS.md — readmit Development Guidelines

## Project context

`readmit` is an R package implementing the Readmission Risk Pool (RRP)
analytical platform. The package is intended for distribution through
CRAN and should follow conventional R package development practices.

This repository is being developed with an emphasis on delivering useful
analytical functionality through a simple, understandable, and
maintainable implementation.

## 1. Structure Before Sophistication

**Structure Before Sophistication** is the guiding development
philosophy.

Establish the overall structure and end-to-end workflows before deeply
implementing individual components.

Favor minimal working implementations that demonstrate the intended
functionality. Expand and refine those implementations incrementally as
requirements become clearer, users encounter issues, and practical needs
emerge.

Do not introduce sophistication simply to anticipate every possible
future requirement.

## 2. Prefer conventional R package practices

Use established R package conventions and tooling wherever possible.

- Treat CRAN as an intended distribution channel.
- Use `R CMD check` as the primary mechanism for validating package
  structure and compliance.
- Use conventional R documentation, dependency management, and testing
  practices.
- Prefer established R ecosystem solutions over custom infrastructure.

Do not create parallel systems for concerns already adequately addressed
by standard R package tooling.

## 3. Implement only necessary complexity

Focus development effort on the functionality required to make RRP work
as intended.

- Prefer straightforward implementations over elaborate abstractions.
- Build the minimum functionality necessary to support the current
  objective.
- Write focused tests that establish the correctness of meaningful
  behavior.
- Address real defects and demonstrated requirements rather than
  attempting to anticipate every possible edge case.
- Avoid enterprise-style software qualification, excessive defensive
  programming, and elaborate validation or lifecycle machinery unless
  specifically warranted.

Complexity is acceptable when it materially supports core functionality,
analytical correctness, or the user experience. It should not be
introduced merely as a precaution or engineering exercise.

## 4. Prioritize human maintainability

The package should remain understandable and maintainable by its human
maintainer.

Use clear organization, readable code, familiar R idioms, and
appropriately scoped functions.

Some complexity is inevitable, and understanding sophisticated
analytical functionality may require studying its implementation.
However, avoid unnecessary layers of indirection, fragmented
abstractions, or intricate dependencies that make the codebase difficult
to navigate.

When choosing between implementations, favor the simpler approach that
adequately satisfies the current requirements.

## 5. Develop iteratively and pragmatically

Favor a practical development cycle:

**Establish structure → Implement minimal functionality → Test → Use →
Refine**

Ship coherent, working functionality rather than delaying progress to
achieve exhaustive theoretical completeness.

Use conventional package checks and targeted tests to establish
reasonable confidence. Introduce additional safeguards when actual
behavior, defects, or requirements justify them.

Maintain essential correctness, particularly for analytical results and
persistent user data, without expanding validation into a separate
engineering objective.

## Guiding principle

**Build a rigorous analytical product, not an elaborate software system
surrounding it.**

Every additional abstraction, dependency, validation mechanism, or
operational process should have a clear purpose tied to RRP’s
functionality, correctness, usability, or maintainability.
