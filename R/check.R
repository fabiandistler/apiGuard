#' CI gate: fail if the API changed in a forbidden way
#'
#' Designed to be called in CI right after a release tag is created (or in a
#' PR against the last release tag):
#'
#' ```sh
#' Rscript -e 'apiGuard::check_api(apiGuard::api_snapshot_ref("v1.0.0"), ".")'
#' ```
#'
#' Exits non-zero (via `stop()`) when any change of a severity listed in
#' `fail_on` is detected.
#'
#' @param old,new Snapshots or paths, as for [compare_api()].
#' @param fail_on Severities that should fail the check.
#' @return Invisibly, the `api_diff` (when the check passes).
#' @export
check_api <- function(old, new,
                      fail_on = c("breaking", "behaviour")) {
  diff <- compare_api(old, new)
  print(diff)
  sev <- vapply(diff$changes, function(x) x$severity, character(1))
  bad <- sev %in% fail_on
  if (any(bad)) {
    stop(sprintf(
      "check_api: %d forbidden change(s) detected (%s). Bump the major version or revert.",
      sum(bad), paste(unique(sev[bad]), collapse = ", ")
    ), call. = FALSE)
  }
  invisible(diff)
}
