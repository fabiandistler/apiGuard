test_that("check_api fails on breaking changes", {
  d_old <- make_pkg("f <- function(a, b = 1) a", "f")
  d_new <- make_pkg("f <- function(a) a", "f")
  expect_output(
    expect_error(check_api(d_old, d_new), "forbidden change"),
    "BREAKING"
  )
})

test_that("check_api tolerates behaviour changes by default", {
  d_old <- make_pkg("f <- function(a, b = 1) a", "f")
  d_new <- make_pkg("f <- function(a, b = 2) a", "f")
  expect_output(diff <- check_api(d_old, d_new), "BEHAVIOUR")
  expect_s3_class(diff, "api_diff")
})

test_that("check_api agrees with suggest_version_bump on behaviour changes", {
  d_old <- make_pkg("f <- function(a, b = 1) a", "f")
  d_new <- make_pkg("f <- function(a, b = 2) a", "f")
  diff <- compare_api(d_old, d_new)

  expect_equal(suggest_version_bump(diff)$bump, "minor")
  expect_output(lenient <- check_api(d_old, d_new))
  expect_s3_class(lenient, "api_diff")

  expect_equal(suggest_version_bump(diff, strict = TRUE)$bump, "major")
  expect_output(
    expect_error(check_api(d_old, d_new, strict = TRUE), "behaviour")
  )
})

test_that("check_api passes when nothing changed", {
  code <- "f <- function(x = 1) x"
  expect_output(check_api(make_pkg(code, "f"), make_pkg(code, "f")),
                "No public API changes")
})
