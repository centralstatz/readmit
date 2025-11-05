# Package Development Notes

Contains daily notes with details about how things were developed. Primarily following https://r-pkgs.org/.

# 11/5/2025

* Initialized package by creating repo here: https://github.com/centralstatz/readmit
* Then created _New Folder from Git_ in Positron, cloning that repo
* Then used `usethis::create_package(getwd())` to initialize package template
* Added this file `DEVNOTES.md` to `.Rbuildignore`
* Ran `usethis::use_r("hsr_extract_coefficients")` to create the packages first function, which extracts the list of model coefficients from a CMS Hospital Specific Report (HSR) for a specified cohort.