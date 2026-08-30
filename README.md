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
| `...` removed | **breaking** | callers passing extra arguments break |
| Required argument added | **breaking** | old calls error |
| Optional argument *inserted* before an existing one | **breaking** | later arguments shift, positional calls break silently |
| Arguments reordered | **breaking** | positional calls break silently |
| Optional argument *appended* at the end | feature | backwards compatible |
| `...` added | feature | backwards compatible |
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

Fails the build on breaking changes. Behaviour-level changes (a changed
default) only recommend a minor bump and do not fail the gate — pass
`strict = TRUE` to `check_api()` to treat them as breaking too. The default
deliberately matches `suggest_version_bump()`, so the gate never blocks a bump
the tool itself recommends (see `docs/adr/0001-behaviour-change-policy.md`).

## Installation

```r
# Not on CRAN (yet).
remotes::install_github("fabiandistler/apiGuard")
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
