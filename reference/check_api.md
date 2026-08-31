# CI gate: fail if the API changed in a forbidden way

Designed to be called in CI right after a release tag is created (or in
a PR against the last release tag):

## Usage

``` r
check_api(old, new, strict = FALSE, fail_on = "breaking")
```

## Arguments

- old, new:

  Snapshots or paths, as for
  [`compare_api()`](https://fabiandistler.github.io/apiGuard/reference/compare_api.md).

- strict:

  Treat behaviour-level changes (changed defaults) as breaking?

- fail_on:

  Severities that should fail the check.

## Value

Invisibly, the `api_diff` (when the check passes).

## Details

    Rscript -e 'apiGuard::check_api(apiGuard::api_snapshot_ref("v1.0.0"), ".")'

Exits non-zero (via [`stop()`](https://rdrr.io/r/base/stop.html)) when
any change of a severity listed in `fail_on` is detected. The default
matches
[`suggest_version_bump()`](https://fabiandistler.github.io/apiGuard/reference/suggest_version_bump.md):
behaviour-level changes (a changed default) recommend a minor bump and
do not fail the gate. Pass `strict = TRUE` to treat them as breaking in
both places.
