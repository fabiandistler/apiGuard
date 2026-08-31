# Suggest a semantic version bump for a diff

Mapping: any `breaking` change -\> major; otherwise any `feature` -\>
minor; `behaviour` (changed defaults) counts as minor, unless
`strict = TRUE`, which treats it as breaking.

## Usage

``` r
suggest_version_bump(diff, current_version = NULL, strict = FALSE)
```

## Arguments

- diff:

  An `api_diff` object.

- current_version:

  Optional version string like `"1.2.3"`. If given, the suggested next
  version is computed.

- strict:

  Treat changed defaults as breaking?

## Value

An object of class `api_bump`.
