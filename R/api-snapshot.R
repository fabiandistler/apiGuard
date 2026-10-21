#' Create a snapshot of a package's public API
#'
#' Statically parses the R sources of a package (no installation, no
#' dependency resolution required) and records every exported function
#' together with its formal arguments and their default values.
#'
#' Exports are read from `NAMESPACE`, including `exportPattern()`, which is
#' matched against the package's top-level definitions. An alias (`f <- g`)
#' gets the signature of its target. An export without a parsed signature
#' (a re-export, a non-function object, a function built by a factory) is
#' kept by name in `opaque`, so its removal is still reported; the snapshot
#' warns how many such exports there are.
#'
#' @param path Path to the package source directory (must contain a
#'   `DESCRIPTION` file).
#' @return An object of class `api_snapshot`: `functions` holds the parsed
#'   signatures, `opaque` the names of exports without one.
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

  defs <- collect_definitions(file.path(path, "R"))
  exports <- resolve_exports(path, defs)
  sigs <- lapply(exports, resolve_signature, defs = defs)
  names(sigs) <- exports
  has_sig <- !vapply(sigs, is.null, logical(1))
  opaque <- sort(exports[!has_sig])
  if (length(opaque)) {
    warning(sprintf(
      paste0("%d export(s) have no parsed signature and are compared by ",
             "name only: %s"),
      length(opaque), paste0("`", opaque, "`", collapse = ", ")
    ), call. = FALSE)
  }
  fns <- sigs[has_sig]

  structure(
    list(package = pkg, version = ver,
         functions = fns[sort(names(fns))], opaque = opaque),
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

# Every top-level assignment in R/, keyed by name; a later file or line
# overrides an earlier one. Each value is the signature of a function, the
# name an alias points to, or NULL for any other object.
collect_definitions <- function(r_dir) {
  files <- list.files(r_dir, pattern = "\\.[rR]$", full.names = TRUE)
  defs <- list()
  for (f in files) {
    for (e in parse(f, keep.source = FALSE)) {
      def <- top_level_assignment(e)
      if (is.null(def)) next
      value <- def$value
      defs[def$name] <- list(
        if (is_function_call(value)) {
          extract_signature(value)
        } else if (is.symbol(value)) {
          list(alias_of = as.character(value))
        }
      )
    }
  }
  defs
}

# Detect top-level `name <- value`, `"name" <- value`, `name = value` and
# `assign("name", value)`.
top_level_assignment <- function(e) {
  if (!is.call(e) || length(e) < 3) return(NULL)
  op <- as.character(e[[1]])[1]
  target <- e[[2]]
  if (op %in% c("<-", "=") && is.symbol(target)) target <- as.character(target)
  if (op %in% c("<-", "=", "assign") &&
      is.character(target) && length(target) == 1) {
    return(list(name = target, value = e[[3]]))
  }
  NULL
}

is_function_call <- function(x) {
  is.call(x) && identical(as.character(x[[1]])[1], "function")
}

extract_signature <- function(fn_call) {
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

# Signature of `name`, following aliases; NULL when none can be parsed.
resolve_signature <- function(name, defs, seen = character()) {
  def <- defs[[name]]
  if (is.null(def$alias_of)) return(def)
  if (def$alias_of %in% seen) return(NULL)
  resolve_signature(def$alias_of, defs, c(seen, name))
}

# Exported names: explicit exports plus every top-level definition matching
# an exportPattern. Without a NAMESPACE every function definition counts.
resolve_exports <- function(path, defs) {
  path <- normalizePath(path)
  if (!file.exists(file.path(path, "NAMESPACE"))) {
    return(names(defs)[!vapply(defs, is.null, logical(1))])
  }
  ns <- parseNamespaceFile(basename(path), dirname(path))
  matched <- lapply(ns$exportPatterns, grep, x = names(defs), value = TRUE)
  empty <- ns$exportPatterns[lengths(matched) == 0L]
  if (length(empty)) {
    warning(sprintf(
      "exportPattern(%s) matches no top-level definition in R/",
      paste0('"', empty, '"', collapse = ", ")
    ), call. = FALSE)
  }
  unique(c(ns$exports, unlist(matched)))
}

#' @export
print.api_snapshot <- function(x, ...) {
  cat(sprintf("<api_snapshot> %s %s -- %d exported function(s)",
              x$package, x$version, length(x$functions)))
  if (length(x$opaque)) {
    cat(sprintf(", %d export(s) without a parsed signature", length(x$opaque)))
  }
  cat("\n")
  invisible(x)
}
