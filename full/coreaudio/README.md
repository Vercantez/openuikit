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

| status | before | after |
| --- | --- | --- |
| implemented | 102 | 317 |
| declared | 241 | 26 |
| unavailable | 4 | 4 |
| deferred | 0 | 0 |
| not-applicable | 0 | 0 |

Raised `implemented` first for the overlay types the Home Assistant corpus
reaches through `AudioBuffer` / channel-layout helpers, then for documented
Swift `Sequence` / `Collection` / `BidirectionalCollection` /
`MutableCollection` semantics on the four overlay collections. HAL C entry
points used by `HACoreAudioObjectSystem` remain fail-closed extras (not in the
347 overlay IDs). Foundation `SortComparator` / `FormatStyle` members stay
`declared` because `AudioBuffer` / `AudioChannelDescription` are not a
documented `Compared` / `FormatInput` match. Optional-returning
`Sequence.flatMap` stays `declared` because Swift 6 deprecates that overload
under warnings-as-errors. Combine `publisher` stays `unavailable`.

Top-5 implemented evidence distribution (of 317 implemented rows; no test
exceeds 4%):

1. `testLayoutPointerTypealiases` — 12
2. `testCollectionMap` — 8
3. `testBufferListPointerTypealiases` — 6
4. `testMutablePartition` — 6
5. `testLayoutUnsafePointerInitAndCollection` — 6

