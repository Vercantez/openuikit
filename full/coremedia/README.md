# CoreMedia Linux starting point

This directory is a clean-room Linux implementation of Apple's public
`CoreMedia` module seeded from the Xcode 26.1 iPhoneOS SDK graphs.

## What is real

- `CMTime` and `CMTimeFlags` / `CMTimeRoundingMethod` with make, seconds,
  convert-scale, add/subtract/multiply, compare, min/max, absolute value,
  clamp/map, and dictionary round-trip through real `CFDictionary` values.
- `CMTimeRange`, `CMTimeMapping`, `CMSampleTimingInfo`, `CMVideoDimensions`
  with the C field layouts (`24 / 48 / 96 / 72 / 8` bytes on LP64).
- Media type and codec/pixel-format FourCC constants, plus
  `CMFormatDescription` identity (`mediaType`, `mediaSubType`, dimensions).
- `CMBlockBuffer` owned-byte copy-in/copy-out (no interior pointers into
  temporaries). `CMSampleBuffer` timing and data-read surfaces, invalidate
  exactly-once, not-ready/make-ready, and fail-closed invalidation.
- Attachment propagate vs not-propagate, and `NSError` contracts on
  `NSOSStatusErrorDomain`.
- C-callable `@_cdecl` entry points are not emitted on this isolated Linux
  Swift 6.2 gate: Swift `CMTime` / `CMTimeRange` structs are not Clang-imported
  C types, so they cannot be passed through a C calling convention. The
  functions exist as Swift overlay (`public func CMTimeMake` and siblings).
  Layout is independently reconstructed in `tests/agent/cm_value_layout.c`.
  Central ARM64 integration must import the real C structs before claiming
  TBD C ABI. Everything else is Swift-only overlay.

## Fail-closed

- Invalid timescale, NaN seconds, mixed infinities, different epochs on add,
  empty/malformed buffer offsets, and invalidated sample buffers fail closed.
- Arbitrary payload bytes are stored as opaque sample data; they are not
  treated as a decoded or validated bitstream.
- Apple clocks, timebases, buffer queues, tagged buffers, hardware, and
  daemon-backed services are not implemented. Those identifiers are deferred
  or unavailable.

## Deferred

- `OSStatus`-typed C APIs wait for Darwin in the central ARM64 build.
- `AudioStreamBasicDescription` / `AudioBuffer` / `CVImageBuffer` APIs are
  compiled only when the real `CoreAudioTypes` and `CoreVideo` modules exist.
- Unobserved rounding details (`quickTime`), CFString pointer identity versus
  Apple's interned keys, and process-local `CFTypeID` values are queued in
  `oracle-questions.tsv`.
