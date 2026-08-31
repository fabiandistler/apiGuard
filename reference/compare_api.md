# Compare two API snapshots (or package paths)

Compare two API snapshots (or package paths)

## Usage

``` r
compare_api(old, new)
```

## Arguments

- old, new:

  Objects of class `api_snapshot`, or paths to package source
  directories (snapshotted on the fly).

## Value

An object of class `api_diff`: a list of change records, each with
`type`, `fn`, `detail` and `severity` (`breaking`, `feature`,
`behaviour`).

## Examples

``` r
if (FALSE) { # \dontrun{
diff <- compare_api(api_snapshot_ref("v1.0.0"), api_snapshot("."))
diff
} # }
```
