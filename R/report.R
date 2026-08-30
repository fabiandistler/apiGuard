#' @export
as.data.frame.api_diff <- function(x, ...) {
  if (!length(x$changes)) {
    return(data.frame(
      type = character(), fn = character(),
      severity = character(), detail = character(),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    type     = vapply(x$changes, `[[`, "", "type"),
    fn       = vapply(x$changes, `[[`, "", "fn"),
    severity = vapply(x$changes, `[[`, "", "severity"),
    detail   = vapply(x$changes, `[[`, "", "detail"),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

#' @export
print.api_diff <- function(x, ...) {
  cat(sprintf("API diff: %s %s -> %s\n",
              x$old["package"], x$old["version"], x$new["version"]))
  df <- as.data.frame(x)
  if (!nrow(df)) {
    cat("No public API changes detected.\n")
    return(invisible(x))
  }
  labels <- c(breaking = "BREAKING", feature = "FEATURE", behaviour = "BEHAVIOUR")
  for (sev in names(labels)) {
    sub <- df[df$severity == sev, , drop = FALSE]
    if (nrow(sub)) {
      cat(sprintf("\n[%s] (%d)\n", labels[[sev]], nrow(sub)))
      for (i in seq_len(nrow(sub))) {
        cat(sprintf("  * %s(): %s\n", sub$fn[i], sub$detail[i]))
      }
    }
  }
  cat(sprintf("\nSuggested version bump: %s\n", suggest_version_bump(x)$bump))
  invisible(x)
}
