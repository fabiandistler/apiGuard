---
status: accepted
---

# Behaviour-level changes do not fail the CI gate by default

A changed default value is a Behaviour change: every existing call still runs and
still resolves to the same arguments, but its result may differ. `apiGuard` treats
this as a minor Bump rather than a major one, because the caller's code is still
correct — and the Gate (`check_api()`) now uses the same default, so a Behaviour
change no longer fails the build. Both sides accept `strict = TRUE` to treat
Behaviour as Breaking.

## Considered options

- **Gate strict, Bump lenient (the previous state).** `suggest_version_bump()`
  recommended a minor bump for a changed default while `check_api()` failed the
  build on the same Diff. The tool contradicted itself: it told maintainers which
  version to release and then blocked that release. Rejected as incoherent, not
  as a matter of taste.
- **Both strict.** Defensible — a changed default really can move results under
  users. Rejected because changing a default is routine in R package development,
  and a Gate that fails on it trains maintainers to disable the Gate.
- **Both lenient, with `strict = TRUE` as the opt-in (chosen).** `strict` already
  existed on `suggest_version_bump()` with default `FALSE`, so the package had
  already taken this position; the Gate was the outlier.

## Consequences

`check_api()`'s signature changed: `fail_on` now defaults to `"breaking"` alone
and a `strict` argument was added ahead of it. This is a Breaking change to
apiGuard's own Public API, made while the package is at `0.1.0.9000` with no
release tag, so no user can be affected. Maintainers who want the old strict
behaviour must pass `strict = TRUE` explicitly.
