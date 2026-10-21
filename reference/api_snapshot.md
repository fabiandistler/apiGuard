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

An object of class `api_snapshot`: `functions` holds the parsed
signatures, `opaque` the names of exports without one.

## Details

Exports are read from `NAMESPACE`, including `exportPattern()`, which is
matched against the package's top-level definitions. An alias (`f <- g`)
gets the signature of its target. An export without a parsed signature
(a re-export, a non-function object, a function built by a factory) is
kept by name in `opaque`, so its removal is still reported; the snapshot
warns how many such exports there are.

## Examples

``` r
if (FALSE) { # \dontrun{
snap <- api_snapshot(".")
snap
} # }
```
