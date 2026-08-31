# Snapshot a package at a given git ref

Uses `git archive` to materialise the repository at `ref` (tag, branch
or commit SHA) into a temporary directory and snapshots it there. This
lets you compare the current working tree against your last release tag
without installing either version.

## Usage

``` r
api_snapshot_ref(ref, repo = ".")
```

## Arguments

- ref:

  A git ref, e.g. `"v1.0.0"` or `"HEAD~1"`.

- repo:

  Path to the git repository (default: current directory).

## Value

An object of class `api_snapshot`.
