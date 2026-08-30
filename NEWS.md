# apiGuard 0.1.0.9000

## Breaking changes

* `check_api()` gained a `strict` argument and `fail_on` now defaults to
  `"breaking"` alone. Behaviour-level changes (a changed default) no longer fail
  the CI gate, which makes the gate agree with `suggest_version_bump()`. Pass
  `strict = TRUE` for the previous behaviour. See
  `docs/adr/0001-behaviour-change-policy.md`.

## Bug fixes

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
