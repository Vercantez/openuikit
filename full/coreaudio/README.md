# CoreAudio Linux starting point

This directory is a clean-room Linux starting implementation of Apple's public
`CoreAudio` Swift overlay, seeded from the iPhoneOS 26.1 symbol graphs. It
builds module `CoreAudio` and `libCoreAudio.dylib` without copying Apple SDK
headers, module maps, or TBD bytes.

## What is real

- `UnsafeMutableAudioBufferListPointer` as a `RandomAccessCollection` /
  `MutableCollection` of `AudioBuffer`, including the nonmutating `count` and
  subscript setters expected by render callbacks.
- `AudioBufferList.sizeInBytes(maximumBuffers:)` and
  `AudioBufferList.allocate(maximumBuffers:)` (released with
  `UnsafeMutableRawPointer.deallocate()`; Apple overlay docs mention `free()`).
- Typed `AudioBuffer` / `UnsafeBufferPointer` / `UnsafeMutableBufferPointer`
  round-trips.
- `AudioChannelLayout` allocate/size helpers and
  `UnsafePointer` / `UnsafeMutablePointer` collection views of
  `AudioChannelDescription`.
- `ManagedAudioChannelLayout` copy-on-write storage, tag/bitmap accessors,
  description collection, `setAllToUnknown()`, equality, and
  `withUnsafePointer` / `withUnsafeMutablePointer`.
- `AudioChannelDescription.==`.
- Linux host-time helpers defined as nanosecond `DispatchTime` uptime, not as
  Darwin `mach_absolute_time`.

The isolated guest compile does not link `CoreAudioTypes`, so the C structs the
overlay extends (`AudioBuffer`, `AudioBufferList`, `AudioChannelLayout`,
`AudioChannelDescription`, and related typealiases) are defined in this module
with the field layouts recorded in the CoreAudioTypes public surface. Central
integration should replace those stand-ins with `import CoreAudioTypes`.

## Fail-closed boundaries

Linux has no Apple HAL, Core Audio server, or physical I/O device graph.

- `AudioObjectHasProperty` is always false.
- `AudioObjectGetPropertyData`, `AudioObjectGetPropertyDataSize`,
  `AudioObjectSetPropertyData`, `AudioObjectIsPropertySettable`, and property
  listener add/remove return `kAudioHardwareUnsupportedOperationError` and do
  not invent device lists, default devices, or property payloads.
- `CoreAudioHardware.isAvailable` is `false`.
- `AudioObjectExists` is always false.
- Realtime I/O procs, aggregate devices, tap descriptions, and driver plug-ins
  from the TBD export list are not implemented here.

## Still deferred / out of this overlay graph

The Swift public surface for this seed is the overlay (347 precise IDs). C HAL
symbols recorded only in `reference/tbd-exports.tsv` are extra fail-closed
entry points, not a claim of Apple HAL parity. Combine `publisher` members
are unavailable because Combine is not a declared dependency.

See `oracle-questions.tsv` for questions that need a central Apple-oracle probe.

## Depth pass 2026-09

Coverage of the 347 exact overlay IDs:

| status | depth start | depth pass | wave-4 | wave-6 | wave-10 | wave-11 |
| --- | --- | --- | --- | --- | --- |
| implemented | 102 | 317 | 335 | 335 | 335 | 335 |
| declared | 241 | 26 | 8 | 8 | 8 | 8 |
| unavailable | 4 | 4 | 4 | 4 | 4 |
| deferred | 0 | 0 | 0 | 0 | 0 |
| not-applicable | 0 | 0 | 0 | 0 | 0 |

Raised `implemented` first for the overlay types the Home Assistant corpus
reaches through `AudioBuffer` / channel-layout helpers, then for documented
Swift `Sequence` / `Collection` / `BidirectionalCollection` /
`MutableCollection` semantics on the four overlay collections. HAL C entry
points used by `HACoreAudioObjectSystem` remain fail-closed extras (not in the
347 overlay IDs). Foundation `sort(using:)` / `sorted(using:)` (single and
comparator-sequence overloads) and `formatted(_:)` are `implemented` via
test-only custom `SortComparator` types (`Compared == AudioBuffer` /
`AudioChannelDescription`) and custom `FormatStyle` types with the overlay
collection as `FormatInput`, following the Photos/TabularData/WeatherKit
precedent. `Sequence.compare(_:_:)` stays `declared` because its constraint
(`Comparator == Self.Element`) requires the element itself to be a
`SortComparator`, which the fixed C-struct stand-ins are not.
Optional-returning
`Sequence.flatMap` stays `declared` because Swift 6 deprecates that overload
under warnings-as-errors. Combine `publisher` stays `unavailable`.

Wave-4 (2026-09-14): converted 18 `declared` rows (6 `sort(using:)`,
8 `sorted(using:)`, 4 `formatted(_:)`) with five focused tests in
`tests/agent/FoundationComparatorTests.swift`, each citing at most 4 rows.
Leftover `declared`: 4 `compare(_:_:)` (unsatisfiable without inventing a
`SortComparator` conformance on Apple's C structs) and 4 `flatMap`
(deprecated overload, `compactMap` covers the documented replacement).

Wave-6 (2026-09-15): recounted 335 implemented / 8 declared /
4 unavailable / 0 deferred / 0 not-applicable of 347 — no change.
This slug has no SwiftUI View types, so the pi-wave6 overlay-override
playbook does not apply. Re-probed both leftover groups against the
local Xcode 26.1 toolchain instead of converting them: a test-only
`extension AudioBuffer: SortComparator` fails under warnings-as-errors
(retroactive conformance of an imported type, plus a `Sendable`
violation on the raw-pointer `mData` field), so `compare(_:_:)` would
need an invented product-level conformance Apple does not declare;
the optional-returning `flatMap` closure is a hard
`#DeprecatedDeclaration` error under warnings-as-errors on both
platforms, and citing the sequence-overload `flatMap` test for the
optional-overload precise IDs would miscite the overload. Both groups
stay honestly `declared`. Also fixed a pre-existing gate breakage:
Xcode 26.1's `Darwin` module now exposes `DarwinBoolean`, which made
bare `DarwinBoolean(true)` ambiguous in `tests/agent/CoreAudioRuntime.swift`
and `tests/agent/HardwareFailClosedTests.swift`; both call sites now
use `CoreAudio.DarwinBoolean`. `bash tests/acceptance/test_host.sh`
is green (`FRAMEWORK_FANOUT_HOST_OK`).

Wave-10 (2026-09-15): recounted 335 implemented / 8 declared /
4 unavailable / 0 deferred / 0 not-applicable of 347 — no change.
Re-verified both leftover groups against Apple Swift 6.2.1 (Xcode 26.1
toolchain): `Sequence.compare(_:_:)` requires `Comparator == Element`,
so calling it on the four overlay collections would need an invented
`SortComparator` conformance on the `AudioBuffer` / `AudioChannelDescription`
C-struct stand-ins, and the optional-returning `flatMap` closure is a hard
`#DeprecatedDeclaration` error under warnings-as-errors (verified with a
minimal `swiftc -typecheck` probe). Both groups stay honestly `declared`.
This slug has no SwiftUI View types, so the overlay-override playbook does
not apply. `bash tests/acceptance/test_host.sh` is green
(`FRAMEWORK_FANOUT_HOST_OK`).

Wave-11 (2026-09-15): recounted 335 implemented / 8 declared /
4 unavailable / 0 deferred / 0 not-applicable of 347 — no change.
Re-verified both leftover groups against Apple Swift 6.2.1 (Xcode 26.1
toolchain) with a minimal `swiftc -typecheck -warnings-as-errors` probe:
the optional-returning `flatMap` closure is a hard `#DeprecatedDeclaration`
error, and `Sequence.compare(_:_:)` requires `Comparator == Element`, so
calling it on the four overlay collections would need an invented
`SortComparator` conformance on the `AudioBuffer` /
`AudioChannelDescription` C-struct stand-ins that Apple does not declare.
Both groups stay honestly `declared`. This slug has no SwiftUI View types,
so the overlay-override playbook does not apply.

Top-5 implemented evidence distribution (of 335 implemented rows; no test
exceeds 4%):

1. `testLayoutPointerTypealiases` — 12
2. `testCollectionMap` — 8
3. `testBufferListPointerTypealiases` — 6
4. `testMutablePartition` — 6
5. `testLayoutUnsafePointerInitAndCollection` — 6

