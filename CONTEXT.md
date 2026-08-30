# apiGuard

Compares the public API of two versions of an R package and tells the maintainer
what the difference means for their users: which changes break existing code,
which version number the release deserves, and whether CI should stop the build.

## Language

**Public API**:
The set of a package's exported functions together with their formal arguments,
argument order, and default values. Nothing else is compared — internal helpers
are outside the API by definition.
_Avoid_: interface, surface, exports

**Snapshot**:
The Public API of one version of one package, captured by statically parsing its
sources. A Snapshot is a fact about a version, never about a change.
_Avoid_: scan, dump, state

**Diff**:
The comparison of two Snapshots, expressed as an ordered set of Change Records.
_Avoid_: delta, comparison, report

**Change Record**:
One difference between two Snapshots, carrying its kind, the function it belongs
to, a human-readable detail, and exactly one Severity.
_Avoid_: finding, issue, violation

**Severity**:
The consequence a Change Record has for existing calling code. Exactly three
values exist — Breaking, Feature, Behaviour — and every Change Record has one.
_Avoid_: level, priority, class

**Breaking**:
Existing calling code stops working or silently changes meaning. Covers loud
failures (a removed function, a new required argument) and silent ones (a
positional argument shifting to a different meaning). Both are Breaking; the
silent case is the one the tool exists to catch.
_Avoid_: major, incompatible

**Feature**:
New capability that no existing call can observe. All existing calls keep
working and keep meaning the same thing.
_Avoid_: minor, addition, enhancement

**Behaviour**:
Every existing call still runs and still resolves to the same arguments, but the
value a default supplies has changed, so the result may differ. Distinct from
Breaking because the caller's code is still correct; distinct from Feature
because the caller's results may move under them.
_Avoid_: behavioural, semantic change, soft break

**Bump**:
The SemVer step a Diff recommends: major, minor, or patch. Derived from the
Severities present in the Diff, never asserted directly.
_Avoid_: increment, version change

**Gate**:
The CI check that turns a Diff into a build outcome. The Gate consumes the same
Severities as the Bump and must never block a release the Bump recommends.
_Avoid_: guard, barrier, check
