git_available <- function() !identical(unname(Sys.which("git")), "")

git_run <- function(repo, ...) {
  system2(
    "git",
    c("-C", shQuote(repo),
      "-c", "user.name=apiGuardTest",
      "-c", "user.email=test@example.com",
      ...),
    stdout = FALSE, stderr = FALSE
  )
}

commit_all <- function(repo, message) {
  git_run(repo, "add", "-A")
  git_run(repo, "commit", "-q", "-m", message)
}

test_that("api_snapshot_ref snapshots a package at an earlier commit", {
  skip_if_not(git_available(), "git is not available")

  repo <- make_pkg("f <- function(a, b = 1) a + b", "f")
  git_run(repo, "init", "-q")
  commit_all(repo, "first")

  writeLines("f <- function(a, extra = 10, b = 1) a + b",
             file.path(repo, "R", "code.R"))
  commit_all(repo, "second")

  old <- api_snapshot_ref("HEAD~1", repo = repo)
  expect_s3_class(old, "api_snapshot")
  expect_equal(old$package, "fakepkg")
  expect_equal(old$functions$f$args, c("a", "b"))

  d <- compare_api(old, api_snapshot(repo))
  expect_equal(vapply(d$changes, `[[`, "", "type"), "arg_inserted")
  expect_equal(suggest_version_bump(d)$bump, "major")
})

test_that("api_snapshot_ref errors on an unknown ref", {
  skip_if_not(git_available(), "git is not available")

  repo <- make_pkg("f <- function(a) a", "f")
  git_run(repo, "init", "-q")
  commit_all(repo, "first")

  expect_error(api_snapshot_ref("no-such-ref", repo = repo), "git archive failed")
})
