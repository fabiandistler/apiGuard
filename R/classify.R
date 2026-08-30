#' Suggest a semantic version bump for a diff
#'
#' Mapping: any `breaking` change -> major; otherwise any `feature` ->
#' minor; `behaviour` (changed defaults) counts as minor, unless
#' `strict = TRUE`, which treats it as breaking.
#'
#' @param diff An `api_diff` object.
#' @param current_version Optional version string like `"1.2.3"`. If given,
#'   the suggested next version is computed.
#' @param strict Treat changed defaults as breaking?
#' @return An object of class `api_bump`.
#' @export
suggest_version_bump <- function(diff, current_version = NULL, strict = FALSE) {
  sev <- vapply(diff$changes, function(x) x$severity, character(1))
  bump <- if (!length(sev)) {
    "patch"
  } else if (any(sev == "breaking") || (strict && any(sev == "behaviour"))) {
    "major"
  } else if (any(sev %in% c("feature", "behaviour"))) {
    "minor"
  } else {
    "patch"
  }

  out <- list(
    bump = bump,
    counts = table(factor(sev, levels = c("breaking", "feature", "behaviour")))
  )
  if (!is.null(current_version)) {
    out$suggested_version <- bump_version(current_version, bump)
  }
  class(out) <- "api_bump"
  out
}

#' Bump a version string semantically
#' @param version Version string, e.g. `"1.2.3"`.
#' @param bump One of `"major"`, `"minor"`, `"patch"`.
#' @export
bump_version <- function(version, bump) {
  parts <- suppressWarnings(as.integer(strsplit(version, ".", fixed = TRUE)[[1]]))
  parts <- c(parts, rep(0L, max(0L, 3L - length(parts))))[1:3]
  switch(bump,
    major = sprintf("%d.0.0", parts[1] + 1L),
    minor = sprintf("%d.%d.0", parts[1], parts[2] + 1L),
    patch = sprintf("%d.%d.%d", parts[1], parts[2], parts[3] + 1L),
    stop("Unknown bump type: ", bump, call. = FALSE)
  )
}

#' @export
print.api_bump <- function(x, ...) {
  cat(sprintf("Suggested bump: %s", x$bump))
  if (!is.null(x$suggested_version)) {
    cat(sprintf(" -> %s", x$suggested_version))
  }
  cat("\n")
  print(x$counts)
  invisible(x)
}
