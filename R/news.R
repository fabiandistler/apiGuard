#' Generate a NEWS.md section from an API diff
#'
#' @param diff An `api_diff` object.
#' @param version Version string for the heading; defaults to the version in
#'   the `new` snapshot.
#' @return A single markdown string (also printed via `cat()` for piping into
#'   `writeLines()` / `clipr`).
#' @export
#' @examples
#' \dontrun{
#' d <- compare_api(api_snapshot_ref("v1.0.0"), api_snapshot("."))
#' cat(generate_news_section(d, version = "2.0.0"))
#' }
generate_news_section <- function(diff, version = NULL) {
  version <- version %||% unname(diff$new["version"])
  pkg <- unname(diff$new["package"])

  df <- as.data.frame(diff)
  section <- function(title, rows) {
    if (is.null(rows) || !nrow(rows)) return(NULL)
    bullets <- sprintf("* `%s()`: %s", rows$fn, rows$detail)
    paste0("## ", title, "\n\n", paste(bullets, collapse = "\n"), "\n")
  }

  parts <- c(
    sprintf("# %s %s\n", pkg, version),
    section("Breaking changes", df[df$severity == "breaking", , drop = FALSE]),
    section("New features", df[df$severity == "feature", , drop = FALSE]),
    section("Behaviour changes", df[df$severity == "behaviour", , drop = FALSE])
  )
  paste0(paste(parts[!vapply(parts, is.null, logical(1))], collapse = "\n"), "\n")
}
