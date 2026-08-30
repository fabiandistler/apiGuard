test_that("bump_version works", {
  expect_equal(bump_version("1.2.3", "major"), "2.0.0")
  expect_equal(bump_version("1.2.3", "minor"), "1.3.0")
  expect_equal(bump_version("1.2.3", "patch"), "1.2.4")
  expect_equal(bump_version("0.1", "minor"), "0.2.0")
})

test_that("suggested version is attached when current version given", {
  d_old <- make_pkg("f <- function(x) x", "f", version = "1.2.3")
  d_new <- make_pkg("f <- function(x, y = 0) x + y", "f", version = "1.2.3")
  bump <- suggest_version_bump(compare_api(d_old, d_new),
                               current_version = "1.2.3")
  expect_equal(bump$bump, "minor")
  expect_equal(bump$suggested_version, "1.3.0")
})

test_that("strict mode treats behaviour changes as breaking", {
  d_old <- make_pkg("f <- function(x = 1) x", "f")
  d_new <- make_pkg("f <- function(x = 2) x", "f")
  d <- compare_api(d_old, d_new)
  expect_equal(suggest_version_bump(d)$bump, "minor")
  expect_equal(suggest_version_bump(d, strict = TRUE)$bump, "major")
})

test_that("NEWS section contains grouped bullets", {
  d_old <- make_pkg("gone <- function() 1", "gone")
  d_new <- make_pkg("fresh <- function() 2", "fresh", version = "2.0.0")
  news <- generate_news_section(compare_api(d_old, d_new))
  expect_match(news, "# fakepkg 2.0.0", fixed = TRUE)
  expect_match(news, "Breaking changes", fixed = TRUE)
  expect_match(news, "New features", fixed = TRUE)
  expect_match(news, "`gone()`", fixed = TRUE)
})
