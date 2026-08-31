# Create a snapshot of a package's public API

Statically parses the R sources of a package (no installation, no
dependency resolution required) and records every exported function
together with its formal arguments and their default values.

## Usage

``` r
api_snapshot(path = ".")
```

## Arguments

- path:

  Path to the package source directory (must contain a `DESCRIPTION`
  file).

## Value

An object of class `api_snapshot`.

## Examples

``` r
if (FALSE) { # \dontrun{
snap <- api_snapshot(".")
snap
} # }
```
