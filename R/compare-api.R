#' Compare two API snapshots (or package paths)
#'
#' @param old,new Objects of class `api_snapshot`, or paths to package source
#'   directories (snapshotted on the fly).
#' @return An object of class `api_diff`: a list of change records, each with
#'   `type`, `fn`, `detail` and `severity` (`breaking`, `feature`,
#'   `behaviour`).
#' @export
#' @examples
#' \dontrun{
#' diff <- compare_api(api_snapshot_ref("v1.0.0"), api_snapshot("."))
#' diff
#' }
compare_api <- function(old, new) {
  old <- as_snapshot(old)
  new <- as_snapshot(new)

  old_f <- old$functions
  new_f <- new$functions
  changes <- list()

  for (fn in setdiff(names(old_f), names(new_f))) {
    changes[[length(changes) + 1]] <- record(
      "function_removed", fn,
      sprintf("exported function `%s()` was removed", fn),
      "breaking"
    )
  }
  for (fn in setdiff(names(new_f), names(old_f))) {
    changes[[length(changes) + 1]] <- record(
      "function_added", fn,
      sprintf("new exported function `%s()`", fn),
      "feature"
    )
  }
  for (fn in intersect(names(old_f), names(new_f))) {
    changes <- c(changes, compare_signature(fn, old_f[[fn]], new_f[[fn]]))
  }

  structure(
    list(old = c(package = old$package, version = old$version),
         new = c(package = new$package, version = new$version),
         changes = changes),
    class = "api_diff"
  )
}

as_snapshot <- function(x) {
  if (inherits(x, "api_snapshot")) return(x)
  if (is.character(x) && length(x) == 1) return(api_snapshot(x))
  stop("`old`/`new` must be an api_snapshot or a path.", call. = FALSE)
}

record <- function(type, fn, detail, severity) {
  list(type = type, fn = fn, detail = detail, severity = severity)
}

compare_signature <- function(fn, old, new) {
  out <- list()
  o_args <- old$args; n_args <- new$args
  o_def  <- old$defaults; n_def <- new$defaults

  # Removed arguments: always breaking.
  for (a in setdiff(o_args, n_args)) {
    out[[length(out) + 1]] <- record(
      "arg_removed", fn,
      sprintf("argument `%s` was removed (positional callers break)", a),
      "breaking"
    )
  }

  # Added arguments: breaking only when they have no default.
  for (a in setdiff(n_args, o_args)) {
    i <- match(a, n_args)
    required <- is.na(n_def[i])
    out[[length(out) + 1]] <- record(
      if (required) "arg_added_required" else "arg_added_optional", fn,
      sprintf("argument `%s` added (%s)", a,
              if (required) "no default" else paste0("default: ", n_def[i])),
      if (required) "breaking" else "feature"
    )
  }

  # Changed defaults on common arguments: behaviour change.
  for (a in intersect(o_args, n_args)) {
    od <- o_def[match(a, o_args)]
    nd <- n_def[match(a, n_args)]
    if (!identical(od, nd) && !(is.na(od) && is.na(nd))) {
      out[[length(out) + 1]] <- record(
        "default_changed", fn,
        sprintf("default of `%s` changed: %s -> %s",
                a, na_to_missing(od), na_to_missing(nd)),
        "behaviour"
      )
    }
  }

  # Reordered common arguments: positional calls break.
  common <- intersect(o_args, n_args)
  if (length(common) > 1L) {
    in_old <- o_args[o_args %in% n_args]
    in_new <- n_args[n_args %in% o_args]
    if (!identical(in_old, in_new)) {
      out[[length(out) + 1]] <- record(
        "arg_reordered", fn,
        "positional argument order changed; calls without names may break",
        "breaking"
      )
    }
  }

  out
}
