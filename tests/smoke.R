# Base-R smoke test (no testthat needed):
#   Rscript tests/smoke.R
# Exercises the full pipeline against two fake packages.

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

make_pkg <- function(code, exports, version = "1.0.0") {
  dir <- tempfile("pkg-")
  dir.create(file.path(dir, "R"), recursive = TRUE)
  writeLines(c("Package: fakepkg", paste("Version:", version)),
             file.path(dir, "DESCRIPTION"))
  writeLines(code, file.path(dir, "R", "code.R"))
  writeLines(sprintf("export(%s)", exports), file.path(dir, "NAMESPACE"))
  dir
}

old <- make_pkg(
  c("stable <- function(x) x",
    "gone   <- function(y) y",
    "ch     <- function(a, b = 1) a + b"),
  c("stable", "gone", "ch")
)
new <- make_pkg(
  c("stable <- function(x) x",
    "ch     <- function(a, b = 2, extra = 10) a + b + extra",
    "fresh  <- function() 42"),
  c("stable", "ch", "fresh"),
  version = "1.0.0"
)

diff <- compare_api(api_snapshot(old), api_snapshot(new))
print(diff)

types <- vapply(diff$changes, `[[`, "", "type")
stopifnot(
  "function_removed"   %in% types,
  "function_added"     %in% types,
  "default_changed"    %in% types,
  "arg_added_optional" %in% types,
  suggest_version_bump(diff)$bump == "major",
  bump_version("1.2.3", "major") == "2.0.0",
  bump_version("1.2.3", "minor") == "1.3.0"
)

news <- generate_news_section(diff, version = "2.0.0")
stopifnot(grepl("Breaking changes", news, fixed = TRUE))
cat(news)

cat("\nSMOKE TEST PASSED\n")
