# Export resolution: every NAMESPACE export ends up in the snapshot (#7).

change_types <- function(d) vapply(d$changes, `[[`, "", "type")

pattern_ns <- 'exportPattern("^[^\\\\.]")'

test_that("exportPattern resolves against top-level definitions", {
  d <- make_pkg(
    c("f <- function(x) x", "g <- function(y = 1) y", ".hidden <- function() 1"),
    namespace = pattern_ns
  )
  s <- api_snapshot(d)
  expect_named(s$functions, c("f", "g"))
  expect_equal(s$functions$g$args, "y")
})

test_that("a function removed under exportPattern is breaking", {
  d_old <- make_pkg(c("f <- function(x) x", "g <- function(x) x"),
                    namespace = pattern_ns)
  d_new <- make_pkg("f <- function(x) x", namespace = pattern_ns)
  d <- compare_api(d_old, d_new)
  expect_equal(change_types(d), "function_removed")
  expect_output(expect_error(check_api(d_old, d_new), "forbidden"))
})

test_that("an exportPattern that matches nothing warns", {
  d <- make_pkg("f <- function(x) x", namespace = 'exportPattern("^zzz")')
  expect_warning(api_snapshot(d), "exportPattern")
})

test_that("an alias resolves to the signature of its target", {
  d <- make_pkg(c("g <- function(x, y = 1) x", "f <- g"), c("f", "g"))
  s <- api_snapshot(d)
  expect_named(s$functions, c("f", "g"))
  expect_equal(s$functions$f, s$functions$g)
})

test_that("a removed alias is breaking", {
  d_old <- make_pkg(c("g <- function(x) x", "f <- g"), c("f", "g"))
  d_new <- make_pkg("g <- function(x) x", "g")
  d <- compare_api(d_old, d_new)
  expect_equal(change_types(d), "function_removed")
  expect_equal(d$changes[[1]]$fn, "f")
  expect_output(expect_error(check_api(d_old, d_new), "forbidden"))
})

test_that("a removed re-export is breaking and reported as not analysed", {
  ns_old <- c("export(f)", "export('%>%')", "importFrom(magrittr,'%>%')")
  d_old <- make_pkg("f <- function() NULL", namespace = ns_old)
  d_new <- make_pkg("f <- function() NULL", "f")

  expect_warning(s_old <- api_snapshot(d_old), "1 export")
  expect_equal(s_old$opaque, "%>%")

  d <- compare_api(s_old, api_snapshot(d_new))
  expect_equal(change_types(d), "function_removed")
  expect_equal(d$changes[[1]]$fn, "%>%")
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("a removed exported non-function object is breaking", {
  d_old <- make_pkg(c("K <- 1", "f <- function() NULL"), c("K", "f"))
  d_new <- make_pkg("f <- function() NULL", "f")
  s_old <- suppressWarnings(api_snapshot(d_old))
  d <- compare_api(s_old, api_snapshot(d_new))
  expect_equal(change_types(d), "function_removed")
  expect_equal(d$changes[[1]]$fn, "K")
})

test_that("a function assigned to a string name is parsed", {
  d_old <- make_pkg('"%+%" <- function(a, b, c) NULL', "'%+%'")
  d_new <- make_pkg('"%+%" <- function(a, b) NULL', "'%+%'")
  expect_equal(api_snapshot(d_old)$functions[["%+%"]]$args, c("a", "b", "c"))
  d <- compare_api(d_old, d_new)
  expect_equal(change_types(d), "arg_removed")
})
