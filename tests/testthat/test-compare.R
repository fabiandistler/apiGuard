test_that("snapshot extracts only exported functions", {
  d <- make_pkg(
    c("pub <- function(x, y = 1) x + y",
      "priv <- function() 42"),
    exports = "pub"
  )
  s <- api_snapshot(d)
  expect_named(s$functions, "pub")
  expect_equal(s$functions$pub$args, c("x", "y"))
  expect_true(is.na(s$functions$pub$defaults[1]))   # x required
  expect_equal(s$functions$pub$defaults[2], "1")    # y has default
})

test_that("removed and added functions are classified", {
  d_old <- make_pkg("gone <- function() 1", "gone")
  d_new <- make_pkg("fresh <- function() 2", "fresh")
  d <- compare_api(api_snapshot(d_old), api_snapshot(d_new))
  types <- vapply(d$changes, `[[`, "", "type")
  expect_true("function_removed" %in% types)
  expect_true("function_added" %in% types)
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("signature changes are classified correctly", {
  d_old <- make_pkg(
    c("stable <- function(x) x",
      "ch <- function(a, b = 1, z = FALSE) a + b"),
    exports = c("stable", "ch")
  )
  d_new <- make_pkg(
    c("stable <- function(x) x",
      "ch <- function(b = 2, a, z = FALSE, extra = 10) a + b"),
    exports = c("stable", "ch")
  )
  d <- compare_api(d_old, d_new)
  types <- vapply(d$changes, `[[`, "", "type")
  expect_true("default_changed" %in% types)     # b: 1 -> 2
  expect_true("arg_added_optional" %in% types)  # extra = 10
  expect_true("arg_reordered" %in% types)       # (a,b,z) -> (b,a,z,...)
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("required new argument is breaking, optional is feature", {
  d_old <- make_pkg("f <- function(x) x", "f")
  d_req <- make_pkg("f <- function(x, y) x + y", "f")
  d_opt <- make_pkg("f <- function(x, y = 0) x + y", "f")

  d1 <- compare_api(d_old, d_req)
  d2 <- compare_api(d_old, d_opt)
  expect_equal(vapply(d1$changes, `[[`, "", "type"), "arg_added_required")
  expect_equal(vapply(d1$changes, `[[`, "", "severity"), "breaking")
  expect_equal(vapply(d2$changes, `[[`, "", "type"), "arg_added_optional")
  expect_equal(vapply(d2$changes, `[[`, "", "severity"), "feature")
  expect_equal(suggest_version_bump(d2)$bump, "minor")
})

test_that("no changes -> patch", {
  code <- "f <- function(x = 1) x"
  d <- compare_api(make_pkg(code, "f"), make_pkg(code, "f"))
  expect_length(d$changes, 0)
  expect_equal(suggest_version_bump(d)$bump, "patch")
})

test_that("an optional argument inserted before an existing one is breaking", {
  d_old <- make_pkg("f <- function(a, b = 1) a + b", "f")
  d_new <- make_pkg("f <- function(a, extra = 10, b = 1) a + b", "f")
  d <- compare_api(d_old, d_new)
  expect_equal(vapply(d$changes, `[[`, "", "type"), "arg_inserted")
  expect_equal(vapply(d$changes, `[[`, "", "severity"), "breaking")
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("an optional argument appended at the end stays a feature", {
  d_old <- make_pkg("f <- function(a, b = 1) a + b", "f")
  d_new <- make_pkg("f <- function(a, b = 1, extra = 10) a + b", "f")
  d <- compare_api(d_old, d_new)
  expect_equal(vapply(d$changes, `[[`, "", "type"), "arg_added_optional")
  expect_equal(suggest_version_bump(d)$bump, "minor")
})

test_that("adding dots is a feature, removing them is breaking", {
  d_none <- make_pkg("f <- function(a) a", "f")
  d_dots <- make_pkg("f <- function(a, ...) a", "f")

  added <- compare_api(d_none, d_dots)
  expect_equal(vapply(added$changes, `[[`, "", "type"), "dots_added")
  expect_equal(vapply(added$changes, `[[`, "", "severity"), "feature")
  expect_equal(suggest_version_bump(added)$bump, "minor")

  removed <- compare_api(d_dots, d_none)
  expect_equal(vapply(removed$changes, `[[`, "", "type"), "dots_removed")
  expect_equal(vapply(removed$changes, `[[`, "", "severity"), "breaking")
  expect_equal(suggest_version_bump(removed)$bump, "major")
})

test_that("moving dots relative to named arguments is breaking", {
  d_old <- make_pkg("f <- function(a, ..., b = 1) a", "f")
  d_new <- make_pkg("f <- function(a, b = 1, ...) a", "f")
  d <- compare_api(d_old, d_new)
  expect_true("arg_reordered" %in% vapply(d$changes, `[[`, "", "type"))
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("an argument inserted before dots shifts positional callers", {
  d_old <- make_pkg("f <- function(a, ...) a", "f")
  d_new <- make_pkg("f <- function(a, b = 1, ...) a", "f")
  d <- compare_api(d_old, d_new)
  expect_equal(vapply(d$changes, `[[`, "", "type"), "arg_inserted")
  expect_equal(suggest_version_bump(d)$bump, "major")
})
