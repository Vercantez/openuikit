# ReplayKit framework fan-out rules

This directory is an isolated clean-room starting point for the Linux `ReplayKit`
port. Work only inside `full/replaykit/`. Do not edit application
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

## Required output

- Implement a real Linux module named `ReplayKit` and a loadable
  `libReplayKit.dylib`. Put implementation Swift files in this framework
  directory, outside `tests/`, and list each one as a repo-relative path in
  `replaykit_guest_sources.txt`.
- Create `coverage.tsv` with the exact header
  `precise	status	evidence	notes`. Include every precise identifier from
  `reference/public-surface.tsv` exactly once. Allowed statuses are
  `implemented`, `declared`, `deferred`, `unavailable`, and `not-applicable`.
  At least 108 rows must be `implemented` or `declared` for the `leaf-full`
  lane. A declaration that does not compile is not `declared`; behavior that was
  not exercised is not `implemented`.
- Create `oracle-questions.tsv` with the exact header
  `precise	question	risk	reason`. Use an exact graph precise ID, or `module`
  for a cross-cutting question. Include at least one concrete question; do not
  guess behavior missing from public inputs.
- Create a nonempty `README.md` describing what is real, fail-closed, and still
  deferred. The primary implementation file must be `ReplayKit.swift`.
- Create `tests/agent/ReplayKitRuntime.swift`. It must import `ReplayKit`, exercise
  meaningful implemented behavior, and print exactly `REPLAYKIT_AGENT_RUNTIME_OK` on success.
- Preserve unavailable, entitlement-gated, hardware-only, and Apple-service
  behavior honestly. Prefer deterministic fail-closed errors or inert behavior
  over fabricated success. Do not add or prioritize `#Preview` support.

## Build discipline

Run `bash tests/acceptance/test_host.sh` from this framework directory before
committing. It validates evidence, coverage, the source manifest, warnings-as-
errors compilation, dylib creation, import, linking, and the runtime marker.
Keep all generated products in temporary directories; remove `.build`, `build`,
and `scratch` before reporting completion. Do not weaken or bypass the gate.

Dependencies expected by this seed:

- `AVFoundation`
- `Foundation`
- `UIKit`

Risk labels:

- `capture`
- `privacy`
- `host-service`
