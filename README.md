# apiGuard

> Detect breaking API changes between two versions of your R package —
> statically, in seconds, pre-release.

## Why?

R has `revdepcheck` (runs your reverse dependencies — powerful but slow,
runtime-based) and `pkgdiff` (compares CRAN versions). **apiGuard** fills the
gap *before* release:

- **Static**: parses sources, no install, no dependency resolution
- **Git-native**: compare working tree vs. your last release tag
- **Actionable**: SemVer bump suggestion + ready-to-paste NEWS.md section
- **CI-ready**: one-liner gate that fails the build on breaking changes

## What it detects

| Change | Severity | Why |
|---|---|---|
| Exported function removed | **breaking** | existing code breaks |
| Argument removed | **breaking** | named & positional calls break |
| Required argument added | **breaking** | old calls error |
| Arguments reordered | **breaking** | positional calls break silently |
| Optional argument added | feature | backwards compatible |
| Function added | feature | backwards compatible |
| Default value changed | behaviour | silent behaviour change (configurable: `strict = TRUE` -> breaking) |

## Usage

```r
library(apiGuard)

# Compare working tree against last release tag
diff <- compare_api(api_snapshot_ref("v1.0.0"), api_snapshot("."))
diff

# SemVer recommendation
suggest_version_bump(diff, current_version = "1.0.0")
#> Suggested bump: major -> 2.0.0

# NEWS.md section
cat(generate_news_section(diff, version = "2.0.0"))
```

## CI gate (GitHub Actions)

```yaml
- name: API breaking-change check
  run: |
    Rscript -e 'apiGuard::check_api(apiGuard::api_snapshot_ref("v1.0.0"), ".")'
  shell: bash
```

Fails the build if breaking (or, by default, behaviour-level) changes are
present without a major version bump decision.

## Installation

```r
# Not on CRAN (yet). PLACEHOLDER: replace with your GitHub org/user
remotes::install_github("YOURUSER/apiGuard")
```

## Roadmap / known limitations

- [ ] S3 method table tracking (`exportMethods`, generic/method drift)
- [ ] S4/R6 class signature comparison
- [ ] Return-class heuristics via `roxygen2` `@return` tags
- [ ] Reverse-dependency impact hint (query CRAN db for dependents of changed fns)
- [ ] Published GitHub Action (`youruser/apiguard-action@v1`)
- Only **exported** functions are compared (by design); internal helpers are free to change
- Static parsing does not evaluate code — functions created by factories/metaprogramming are not seen
- After cloning, run `devtools::document()` to regenerate `NAMESPACE`/`man` from roxygen comments

## Contributing

Change records are plain lists — adding a new detector means adding one
`record()` call in `R/compare-api.R` plus a test in `tests/testthat/`.
PRs welcome.
