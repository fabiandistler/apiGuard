# apiGuard 0.1.0.9000

## Breaking changes

* `check_api()` gained a `strict` argument and `fail_on` now defaults to
  `"breaking"` alone. Behaviour-level changes (a changed default) no longer fail
  the CI gate, which makes the gate agree with `suggest_version_bump()`. Pass
  `strict = TRUE` for the previous behaviour. See
  `docs/adr/0001-behaviour-change-policy.md`.

## Bug fixes

* `api_snapshot()` no longer drops exports it cannot parse, so removing them is
  now reported as `function_removed` / breaking (#7). In detail:
  * `exportPattern()` is matched against the package's top-level definitions.
    A pattern that matches nothing raises a warning.
  * An alias (`f <- g`) gets the signature of `g`.
  * A function assigned to a string name (`"%+%" <- function(a, b)`) is parsed.
  * Re-exports and exported non-function objects are listed in the
    snapshot's new `opaque` field and compared by name only.
  * The snapshot warns how many exports have no parsed signature.
* An optional argument inserted *before* an existing argument is now reported as
  `arg_inserted` / breaking. It used to be classified as a feature, even though
  it silently shifts every following argument and changes what positional calls
  mean.
* `...` is no longer mistaken for a required argument. Adding `...` is reported
  as `dots_added` / feature (it used to suggest a major bump); removing it is
  reported as `dots_removed` / breaking.
* `tests/smoke.R` no longer fails under `R CMD check`. It sourced `R/` relative
  to the working directory, which does not exist next to the installed tests.

## Documentation

* Added `CONTEXT.md` (glossary) and `docs/adr/`.
* Added an `R-CMD-check` GitHub Actions workflow.
* Replaced the author, licence, and installation placeholders.
