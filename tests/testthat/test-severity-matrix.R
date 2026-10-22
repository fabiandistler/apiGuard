# Severity matrix (#13): one row per classification rule of the Public API.
# Each row pins an example pair of package sources plus the exact Change
# Records it must produce (compared order-insensitively, as sorted
# "type/severity" strings) and the derived Bump. Every classification bug
# so far (#4, #6, #8) was a drifted Severity; an intentional rule change
# updates its row here, an accidental one fails with the row's name.

rows <- list(
  # Breaking -----------------------------------------------------------------
  list(scenario = "exported function removed",
       old_code = "f <- function(a) a", old_exports = "f",
       new_code = "internal <- function() 1", new_exports = character(0),
       expect = "function_removed/breaking", bump = "major"),
  list(scenario = "opaque export removed",
       old_code = "x <- 1", old_exports = "x",
       new_code = "internal <- function() 1", new_exports = character(0),
       expect = "function_removed/breaking", bump = "major"),
  list(scenario = "argument removed",
       old_code = "f <- function(a, b = 1) a", old_exports = "f",
       new_code = "f <- function(a) a", new_exports = "f",
       expect = "arg_removed/breaking", bump = "major"),
  list(scenario = "dots removed",
       old_code = "f <- function(a, ...) a", old_exports = "f",
       new_code = "f <- function(a) a", new_exports = "f",
       expect = "dots_removed/breaking", bump = "major"),
  list(scenario = "required argument added",
       old_code = "f <- function(x) x", old_exports = "f",
       new_code = "f <- function(x, y) x + y", new_exports = "f",
       expect = "arg_added_required/breaking", bump = "major"),
  list(scenario = "optional argument inserted before an existing one",
       old_code = "f <- function(a, b = 1) a + b", old_exports = "f",
       new_code = "f <- function(a, extra = 10, b = 1) a + b", new_exports = "f",
       expect = "arg_inserted/breaking", bump = "major"),
  list(scenario = "positional argument order changed",
       old_code = "f <- function(a = 1, b = 2) a", old_exports = "f",
       new_code = "f <- function(b = 2, a = 1) a", new_exports = "f",
       expect = "arg_reordered/breaking", bump = "major"),
  list(scenario = "default removed (#8)",
       old_code = "f <- function(x, y = 1) x + y", old_exports = "f",
       new_code = "f <- function(x, y) y", new_exports = "f",
       expect = "default_removed/breaking", bump = "major"),
  # Behaviour stays minor only by default; under strict = TRUE it is a
  # major Bump (ADR 0001).
  list(scenario = "default value changed, strict",
       old_code = "f <- function(x, y = 1) x", old_exports = "f",
       new_code = "f <- function(x, y = 2) x", new_exports = "f",
       expect = "default_changed/behaviour", bump = "major",
       strict = TRUE),

  # Feature ------------------------------------------------------------------
  list(scenario = "exported function added",
       old_code = "gone <- function() 1", old_exports = character(0),
       new_code = "fresh <- function() 2", new_exports = "fresh",
       expect = "function_added/feature", bump = "minor"),
  list(scenario = "optional argument appended at the end",
       old_code = "f <- function(a, b = 1) a + b", old_exports = "f",
       new_code = "f <- function(a, b = 1, extra = 10) a + b", new_exports = "f",
       expect = "arg_added_optional/feature", bump = "minor"),
  list(scenario = "dots added",
       old_code = "f <- function(a) a", old_exports = "f",
       new_code = "f <- function(a, ...) a", new_exports = "f",
       expect = "dots_added/feature", bump = "minor"),
  list(scenario = "optional argument added after dots",
       old_code = "f <- function(x, ..., b = 1) x", old_exports = "f",
       new_code = "f <- function(x, ..., a = 2, b = 1) x", new_exports = "f",
       expect = "arg_added_optional/feature", bump = "minor"),

  # Behaviour ----------------------------------------------------------------
  list(scenario = "default value changed",
       old_code = "f <- function(x, y = 1) x", old_exports = "f",
       new_code = "f <- function(x, y = 2) x", new_exports = "f",
       expect = "default_changed/behaviour", bump = "minor"),
  list(scenario = "default added to a required argument",
       old_code = "f <- function(x, y) x + y", old_exports = "f",
       new_code = "f <- function(x, y = 2) x + y", new_exports = "f",
       expect = "default_changed/behaviour", bump = "minor"),

  # No change ----------------------------------------------------------------
  list(scenario = "identical sources",
       old_code = "f <- function(x = 1) x", old_exports = "f",
       new_code = "f <- function(x = 1) x", new_exports = "f",
       expect = character(0), bump = "patch"),
  list(scenario = "arguments after dots reordered",
       old_code = "f <- function(x, ..., a = 1, b = 1) x", old_exports = "f",
       new_code = "f <- function(x, ..., b = 1, a = 1) x", new_exports = "f",
       expect = character(0), bump = "patch")
)

for (row in rows) {
  test_that(sprintf("severity matrix: %s", row$scenario), {
    old <- api_snapshot(make_pkg(row$old_code, row$old_exports))
    new <- api_snapshot(make_pkg(row$new_code, row$new_exports))
    d <- compare_api(old, new)

    recs <- vapply(d$changes, function(r) sprintf("%s/%s", r$type, r$severity), "")
    expect_setequal(recs, row$expect)

    expected_bump <- suggest_version_bump(d, strict = isTRUE(row$strict))$bump
    expect_equal(expected_bump, row$bump)
  })
}
