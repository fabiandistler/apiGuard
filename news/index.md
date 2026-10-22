# Changelog

## apiGuard 0.2.1.9000

### Bug fixes

- Removing a default value from an argument is now reported as
  `default_removed` / breaking: the argument becomes required, so every
  old call that omitted it now errors. It used to be graded
  `default_changed` / behaviour, which let
  [`check_api()`](https://fabiandistler.github.io/apiGuard/reference/check_api.md)
  pass and
  [`suggest_version_bump()`](https://fabiandistler.github.io/apiGuard/reference/suggest_version_bump.md)
  recommend only a minor bump
  ([\#8](https://github.com/fabiandistler/apiGuard/issues/8)).

## apiGuard 0.2.1

- [`api_snapshot()`](https://fabiandistler.github.io/apiGuard/reference/api_snapshot.md)
  no longer drops exports it cannot parse, so removing them is now
  reported as `function_removed` / breaking
  ([\#7](https://github.com/fabiandistler/apiGuard/issues/7)). In
  detail:
  - `exportPattern()` is matched against the package’s top-level
    definitions. A pattern that matches nothing raises a warning.
  - An alias (`f <- g`) gets the signature of `g`.
  - A function assigned to a string name (`"%+%" <- function(a, b)`) is
    parsed.
  - Re-exports and exported non-function objects are listed in the
    snapshot’s new `opaque` field and compared by name only.
  - The snapshot warns how many exports have no parsed signature.

## apiGuard 0.2.0

### Breaking changes

- [`check_api()`](https://fabiandistler.github.io/apiGuard/reference/check_api.md)
  gained a `strict` argument and `fail_on` now defaults to `"breaking"`
  alone. Behaviour-level changes (a changed default) no longer fail the
  CI gate, which makes the gate agree with
  [`suggest_version_bump()`](https://fabiandistler.github.io/apiGuard/reference/suggest_version_bump.md).
  Pass `strict = TRUE` for the previous behaviour. See
  `docs/adr/0001-behaviour-change-policy.md`.

### Bug fixes

- Adding an optional argument after `...`, or reordering arguments that
  all follow `...`, is no longer reported as breaking. Such arguments
  can only be matched by name, so an addition is `arg_added_optional` /
  feature and a reorder among them is not a change. Removing or renaming
  one stays breaking, and its message now says that named callers break
  ([\#6](https://github.com/fabiandistler/apiGuard/issues/6)).
- An optional argument inserted *before* an existing argument is now
  reported as `arg_inserted` / breaking. It used to be classified as a
  feature, even though it silently shifts every following argument and
  changes what positional calls mean
  ([\#4](https://github.com/fabiandistler/apiGuard/issues/4)).
- `...` is no longer mistaken for a required argument. Adding `...` is
  reported as `dots_added` / feature (it used to suggest a major bump);
  removing it is reported as `dots_removed` / breaking
  ([\#4](https://github.com/fabiandistler/apiGuard/issues/4)).
- `tests/smoke.R` no longer fails under `R CMD check`. It sourced `R/`
  relative to the working directory, which does not exist next to the
  installed tests
  ([\#4](https://github.com/fabiandistler/apiGuard/issues/4)).

### Documentation

- Added `CONTEXT.md` (glossary) and `docs/adr/`.
- Added an `R-CMD-check` GitHub Actions workflow.
- Replaced the author, licence, and installation placeholders.
