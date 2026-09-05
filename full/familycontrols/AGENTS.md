# FamilyControls framework fan-out rules

This directory is an isolated clean-room starting point for the Linux `FamilyControls`
port. Work only inside `full/familycontrols/`. Do not edit application
sources, another framework, package-wide manifests, shared integration/build
files, or anything under `reference/` or `tests/acceptance/`.

## Immutable evidence

`reference/immutable-files.sha256` seals this file, `FANOUT_TASK.md`, every
reference input, and `tests/acceptance/test_host.sh`. Never rewrite, regenerate,
or reseal those files. SDK headers, module maps, Swift interfaces, and TBD files
are proprietary inputs: their paths and hashes are recorded, but their bytes
must not be copied into this repository.

All extractor-emitted graph files are preserved byte-for-byte. Apple graphs can
legitimately repeat a precise identifier. `reference/public-surface.tsv` contains
one canonical row per exact ID under the fixed `canonicalSurfacePolicy` recorded
in `reference/symbol-graphs.json`; duplicate occurrence and full-payload conflict
counts remain explicit there. Never treat canonical compaction as evidence that
the other raw occurrences did not exist.

`reference/api-digester.json` is a location-free compiler dump from the same
pinned Xcode SDK. Reconcile it with the symbol graph before writing declarations:
use it for imported ObjC USRs, superclass/protocol identity, selectors, type
optionality, declaration attributes, and ordered enum children. The graph remains
the canonical exact-ID census. `reference/external-evidence.json` pins independent
binding sources available in the prepared cloud environment. They are a
read-only secondary cross-check, never authority over the Apple-derived files and
never runtime evidence. If sources conflict, defer the declaration and add an
oracle question. Do not guess.

## Required output

- Implement a real Linux module named `FamilyControls` and a loadable
  `libFamilyControls.dylib`. Put implementation Swift files in this framework
  directory, outside `tests/`, and list each one as a repo-relative path in
  `familycontrols_guest_sources.txt`.
- Create `coverage.tsv` with the exact header
  `precise	status	evidence	notes`. Include every precise identifier from
  `reference/public-surface.tsv` exactly once. Allowed statuses are
  `implemented`, `declared`, `deferred`, `unavailable`, and `not-applicable`.
  At least 1926 rows must be `implemented` or `declared` for the `leaf-full`
  lane. A declaration that does not compile is not `declared`; behavior that was
  not exercised is not `implemented`. Every `implemented` row must cite
  `test:full/familycontrols/tests/agent/*Tests.swift#testName`; define that exact `test*`
  function for the sealed runner to call. Every `declared` row must cite
  `source:full/familycontrols/<product-source>.swift#Symbol`; the source must be listed in
  `familycontrols_guest_sources.txt` and contain the exact identifier anchor. Deferred,
  unavailable, and not-applicable rows require explanatory notes.
- Create `oracle-questions.tsv` with the exact header
  `precise	question	risk	reason`. Use an exact graph precise ID, or `module`
  for a cross-cutting question. Include at least one concrete question; do not
  guess behavior missing from public inputs.
- Create a nonempty `README.md` describing what is real, fail-closed, and still
  deferred. The primary implementation file must be `FamilyControls.swift`.
- Put focused behavioral checks in `tests/agent/*Tests.swift` as top-level,
  synchronous, no-argument functions named `test*`. Create
  `tests/agent/FamilyControlsLoadSmoke.swift` with exactly these three logical lines
  (including the blank line): `import FamilyControls`, a blank line, and
  `let frameworkLoadSmokeMarker = "FAMILYCONTROLS_AGENT_RUNTIME_OK"`. The sealed gate generates the
  executable runner from `implemented` coverage rows, imports and explicitly
  loads the dylib, invokes every cited test exactly once, and emits the marker
  as its sole stdout. Loading and printing are acceptance plumbing, not
  behavioral evidence by themselves.
- When dependencies are listed below, create
  `tests/agent/FamilyControlsDependencyIdentity.swift`. Import `FamilyControls` and every
  declared dependency and pass genuine dependency values through public
  `FamilyControls` APIs. This probe is for the clean EC2 integration build; the isolated
  host gate is not permission to create same-named stand-ins. Never declare a
  public framework-local substitute for a dependency-owned type.
- Preserve unavailable, entitlement-gated, hardware-only, and Apple-service
  behavior honestly. Prefer deterministic fail-closed errors or inert behavior
  over fabricated success. Do not add or prioritize `#Preview` support.

Before implementation, make a declaration-facts pass: exact graph ID and
signature, matching API-digester node/USR, dependency owner, and any corroborating
binding source location. Static sources do not establish defaults, callback
timing, queues, retention, coding round trips, hardware behavior, or service
success. Such behavior is `implemented` only with focused behavioral test
evidence; the load-smoke marker alone proves none of it.

## Build discipline

Run `bash tests/acceptance/test_host.sh` from this framework directory before
committing. It validates evidence, coverage, the source manifest, warnings-as-
errors compilation, dylib creation, import, linking, focused tests, and the exact
load-smoke marker.
Keep all generated products in temporary directories; remove `.build`, `build`,
and `scratch` before reporting completion. Do not weaken or bypass the gate.

Dependencies expected by this seed:

- `Foundation`

Risk labels:

- `privacy`
- `authorization`
- `fail-closed`
