## Submission context

This update advances `readmit` from 1.0.0 to 1.1.0 within the Readmission Risk
Pool (RRP) platform. Canonical discharge episodes after the assessment time are
now rejected. Terminal events require four fields, and eligibility uses event
occurrence time without a separate event-availability timestamp.

## Test environments

Local macOS Tahoe 26.5.2 (Apple Silicon), R 4.6.2.

## R CMD check results

`R CMD check --as-cran` on `readmit_1.1.0.tar.gz`: 0 errors, 0 warnings,
1 NOTE. The CRAN incoming feasibility NOTE reports five days since the last
update. This release addresses the assessment-time discharge boundary and
terminal-event contract after the recent 1.0.0 release.

## Reverse dependencies

The current CRAN source index lists no reverse Depends, Imports, LinkingTo,
Suggests, or Enhances for `readmit` (reviewed 2026-11-09). No reverse-dependency
checks were applicable.
