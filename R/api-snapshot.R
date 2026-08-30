#' Create a snapshot of a package's public API
#'
#' Statically parses the R sources of a package (no installation, no
#' dependency resolution required) and records every exported function
#' together with its formal arguments and their default values.
#'
#' @param path Path to the package source directory (must contain a
#'   `DESCRIPTION` file).
#' @return An object of class `api_snapshot`.
#' @export
#' @examples
#' \dontrun{
#' snap <- api_snapshot(".")
#' snap
#' }
api_snapshot <- function(path = ".") {
  desc <- file.path(path, "DESCRIPTION")
  if (!file.exists(desc)) {
    stop("No DESCRIPTION found at ", normalizePath(path, mustWork = FALSE),
         call. = FALSE)
  }
  dcf <- read.dcf(desc)
  pkg <- unname(dcf[1, "Package"])
  ver <- unname(dcf[1, "Version"])

  fns <- collect_functions(file.path(path, "R"))
  exports <- read_exports(path, fallback = names(fns))
  fns <- fns[intersect(exports, names(fns))]

  structure(
    list(package = pkg, version = ver, functions = fns),
    class = "api_snapshot"
  )
}

#' Snapshot a package at a given git ref
#'
#' Uses `git archive` to materialise the repository at `ref` (tag, branch or
#' commit SHA) into a temporary directory and snapshots it there. This lets
#' you compare the current working tree against your last release tag without
#' installing either version.
#'
#' @param ref A git ref, e.g. `"v1.0.0"` or `"HEAD~1"`.
#' @param repo Path to the git repository (default: current directory).
#' @return An object of class `api_snapshot`.
#' @export
api_snapshot_ref <- function(ref, repo = ".") {
  td <- tempfile("apiguard-")
  dir.create(td)
  tar <- tempfile(fileext = ".tar")
  status <- system2(
    "git",
    c("-C", shQuote(normalizePath(repo)), "archive", "-o", shQuote(tar), ref),
    stdout = FALSE, stderr = FALSE
  )
  if (status != 0 || !file.exists(tar)) {
    stop("git archive failed for ref '", ref,
         "'. Is this a git repo and does the ref exist?", call. = FALSE)
  }
  utils::untar(tar, exdir = td)
  api_snapshot(td)
}

# --- internals ---------------------------------------------------------------

collect_functions <- function(r_dir) {
  files <- list.files(r_dir, pattern = "\\.[rR]$", full.names = TRUE)
  out <- list()
  for (f in files) {
    exprs <- parse(f, keep.source = FALSE)
    for (e in exprs) {
      nm <- assigned_function_name(e)
      if (!is.null(nm)) out[[nm]] <- extract_signature(e)
    }
  }
  out[sort(names(out))]
}

# Detect top-level `name <- function(...)`, `name = function(...)` and
# `assign("name", function(...))`.
assigned_function_name <- function(e) {
  if (!is.call(e)) return(NULL)
  op <- as.character(e[[1]])[1]
  if (op %in% c("<-", "=") && length(e) >= 3) {
    lhs <- e[[2]]; rhs <- e[[3]]
    if (is.symbol(lhs) && is.call(rhs) &&
        identical(as.character(rhs[[1]])[1], "function")) {
      return(as.character(lhs))
    }
  }
  if (op == "assign" && length(e) >= 3 && is.character(e[[2]])) {
    rhs <- e[[3]]
    if (is.call(rhs) && identical(as.character(rhs[[1]])[1], "function")) {
      return(as.character(e[[2]]))
    }
  }
  NULL
}

extract_signature <- function(assign_call) {
  fn_call <- assign_call[[3]]
  fmls <- as.list(fn_call[[2]])
  args <- names(fmls)
  if (is.null(args)) args <- rep("", length(fmls))
  defaults <- vapply(fmls, function(d) {
    if (is.symbol(d) && identical(as.character(d), "")) {
      NA_character_ # required argument, no default
    } else {
      paste(deparse(d, width.cutoff = 500L), collapse = " ")
    }
  }, character(1))
  list(args = args, defaults = unname(defaults))
}

read_exports <- function(path, fallback) {
  ns_file <- file.path(path, "NAMESPACE")
  if (!file.exists(ns_file)) return(fallback)
  exprs <- parse(ns_file)
  exps <- character()
  for (e in exprs) {
    if (is.call(e) && identical(as.character(e[[1]])[1], "export")) {
      exps <- c(exps, vapply(as.list(e)[-1], as.character, character(1)))
    }
  }
  unique(exps)
}

#' @export
print.api_snapshot <- function(x, ...) {
  cat(sprintf("<api_snapshot> %s %s -- %d exported function(s)\n",
              x$package, x$version, length(x$functions)))
  invisible(x)
}
