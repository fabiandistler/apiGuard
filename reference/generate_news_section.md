# Generate a NEWS.md section from an API diff

Generate a NEWS.md section from an API diff

## Usage

``` r
generate_news_section(diff, version = NULL)
```

## Arguments

- diff:

  An `api_diff` object.

- version:

  Version string for the heading; defaults to the version in the `new`
  snapshot.

## Value

A single markdown string (also printed via
[`cat()`](https://rdrr.io/r/base/cat.html) for piping into
[`writeLines()`](https://rdrr.io/r/base/writeLines.html) / `clipr`).

## Examples

``` r
if (FALSE) { # \dontrun{
d <- compare_api(api_snapshot_ref("v1.0.0"), api_snapshot("."))
cat(generate_news_section(d, version = "2.0.0"))
} # }
```
