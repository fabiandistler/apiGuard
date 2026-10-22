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
  # Exports without a parsed signature are compared by name only.
  old_names <- union(names(old_f), old$opaque)
  new_names <- union(names(new_f), new$opaque)
  changes <- list()

  for (fn in setdiff(old_names, new_names)) {
    changes[[length(changes) + 1]] <- record(
      "function_removed", fn,
      if (fn %in% names(old_f)) {
        sprintf("exported function `%s()` was removed", fn)
      } else {
        sprintf("export `%s` was removed", fn)
      },
      "breaking"
    )
  }
  for (fn in setdiff(new_names, old_names)) {
    changes[[length(changes) + 1]] <- record(
      "function_added", fn,
      if (fn %in% names(new_f)) {
        sprintf("new exported function `%s()`", fn)
      } else {
        sprintf("new export `%s`", fn)
      },
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

# The Change Kind vocabulary (CONTEXT.md): every value the classifier can
# emit, enumerated once beside the constructor that stamps it.
change_kinds <- c(
  "function_added", "function_removed",
  "arg_added_required", "arg_inserted", "arg_added_optional", "arg_removed",
  "arg_reordered",
  "dots_added", "dots_removed",
  "default_changed", "default_removed"
)

change_severities <- c("breaking", "feature", "behaviour")

record <- function(type, fn, detail, severity) {
  stopifnot(
    "`type` is not a known Change Kind" = type %in% change_kinds,
    "`severity` is not a known Severity" = severity %in% change_severities
  )
  list(type = type, fn = fn, detail = detail, severity = severity)
}

compare_signature <- function(fn, old, new) {
  out <- list()
  o_args <- old$args; n_args <- new$args
  o_def  <- old$defaults; n_def <- new$defaults

  # Arguments after `...` can only be matched by name, so their position does
  # not matter: they form a named set, not part of the positional sequence.
  o_named <- named_only_args(o_args)
  n_named <- named_only_args(n_args)

  # Removed arguments: always breaking.
  for (a in setdiff(o_args, n_args)) {
    out[[length(out) + 1]] <- if (identical(a, "...")) {
      record(
        "dots_removed", fn,
        "`...` was removed (callers passing extra arguments break)",
        "breaking"
      )
    } else {
      callers <- if (a %in% o_named) "named callers" else "positional callers"
      record(
        "arg_removed", fn,
        sprintf("argument `%s` was removed (%s break)", a, callers),
        "breaking"
      )
    }
  }

  # Added arguments: an optional argument is only backwards compatible when it
  # is appended behind every pre-existing positional argument, or placed after
  # `...`. Inserting it earlier shifts the arguments that follow, which breaks
  # positional callers silently.
  positions <- which(n_args %in% o_args & !n_args %in% n_named)
  last_common <- if (length(positions)) max(positions) else 0L
  for (a in setdiff(n_args, o_args)) {
    i <- match(a, n_args)
    if (identical(a, "...")) {
      out[[length(out) + 1]] <- record(
        "dots_added", fn, "`...` added", "feature"
      )
      next
    }
    required <- is.na(n_def[i])
    if (required) {
      out[[length(out) + 1]] <- record(
        "arg_added_required", fn,
        sprintf("argument `%s` added (no default)", a),
        "breaking"
      )
    } else if (i < last_common && !a %in% n_named) {
      out[[length(out) + 1]] <- record(
        "arg_inserted", fn,
        sprintf(paste0("argument `%s` inserted at position %d (default: %s); ",
                       "later arguments shift, positional callers ",
                       "break silently"),
                a, i, n_def[i]),
        "breaking"
      )
    } else {
      out[[length(out) + 1]] <- record(
        "arg_added_optional", fn,
        sprintf("argument `%s` added (default: %s)", a, n_def[i]),
        "feature"
      )
    }
  }

  # Changed defaults on common arguments. Removing a default turns the argument
  # into a required one: every old call that omitted it now errors, which is
  # breaking (#8). A changed value, or a default added where there was none,
  # keeps every existing call running — behaviour.
  for (a in intersect(o_args, n_args)) {
    od <- o_def[match(a, o_args)]
    nd <- n_def[match(a, n_args)]
    default_removed <- !is.na(od) && is.na(nd)
    if (default_removed) {
      out[[length(out) + 1]] <- record(
        "default_removed", fn,
        sprintf("default of `%s` removed (was %s); argument is now required",
                a, na_to_missing(od)),
        "breaking"
      )
    } else if (!identical(od, nd) && !(is.na(od) && is.na(nd))) {
      out[[length(out) + 1]] <- record(
        "default_changed", fn,
        sprintf("default of `%s` changed: %s -> %s",
                a, na_to_missing(od), na_to_missing(nd)),
        "behaviour"
      )
    }
  }

  # Reordered common arguments: positional calls break. `...` takes part in
  # this check, so moving it relative to named arguments is caught here.
  # Arguments that are named-only in both versions are compared as a set.
  common <- intersect(o_args, n_args)
  if (length(common) > 1L) {
    stay_named <- intersect(o_named, n_named)
    in_old <- positional_order(o_args[o_args %in% n_args], stay_named)
    in_new <- positional_order(n_args[n_args %in% o_args], stay_named)
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

# Arguments after `...`: callers can only supply them by name.
named_only_args <- function(args) {
  dots <- match("...", args)
  if (is.na(dots)) character() else args[-seq_len(dots)]
}

# Order that matters to callers: arguments named-only in both versions are
# sorted, so a reorder among them is ignored.
positional_order <- function(args, stay_named) {
  c(args[!args %in% stay_named], sort(args[args %in% stay_named]))
}
