# CoreAudioTypes (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreAudioTypes` module. It produces one nominal Swift identity,
`CoreAudioTypes`, and a loadable `libCoreAudioTypes.dylib`. Downstream
CoreAudio, AudioToolbox, AVFAudio, AudioUnit, CoreMedia, and unchanged apps
are expected to import this module rather than redefining these types.

## What is real

- `@frozen` value layouts for `AudioBuffer`, `AudioBufferList`,
  `AudioStreamBasicDescription`, `AudioStreamPacketDescription`,
  `AudioStreamPacketDependencyDescription`, `AudioTimeStamp`, `SMPTETime`,
  `AudioChannelDescription`, `AudioChannelLayout`, `AudioClassDescription`,
  `AudioFormatListItem`, `AudioValueRange`, and `AudioValueTranslation`.
  Field types and order follow the sealed symbol graph. Swift
  `MemoryLayout` size/alignment/stride and every exposable field offset are
  asserted in `tests/agent/CoreAudioTypesRuntime.swift`.
- Flexible-array convention: `AudioBufferList.mBuffers` and
  `AudioChannelLayout.mChannelDescriptions` are one embedded element.
  Additional elements use `leadingOffset + n * stride`. Negative counts and
  checked-integer overflow fail closed and do not allocate undersized memory.
- Graph-owned option sets (`AudioChannelBitmap`, `AudioChannelFlags`,
  `AudioTimeStampFlags`, `SMPTETimeFlags`) with `UInt32` raw values,
  Equatable, and Sendable. Synthesized SetAlgebra/OptionSet API is exercised.
  `sampleHostTimeValid` is the union of sample and host validity, not a
  sixth independent bit.
- Graph typealiases (`AudioFormatID`, `AudioFormatFlags`,
  `AudioChannelLabel`, `AudioChannelLayoutTag`, sample types,
  `AVAudioInteger`/`AVAudioUInteger`, `AudioSessionID`).
- `AudioChannelLayoutTag_GetNumberOfChannels` as the low-16-bit packing
  convention (`tag & 0xFFFF`).
- Pointer walking across four `AudioBuffer` elements and four
  `AudioChannelDescription` elements, plus zero/one/many and maximal-safe
  arithmetic. `AudioValueTranslation` is constructed only from non-nil
  pointers; nil is never dereferenced.
- A test-only reconstructed C fixture under `tests/agent/` for
  sizeof/alignof/offsetof comparison. It is not Apple header text. Its full
  70-line output was also compared with the real Xcode 26.1 macOS ARM64
  headers; every observed size, alignment, offset, and trailing-array formula
  matched.
- All 398 graph-present globals and all 65 CoreAudioTypes-owned enum
  cases/static members are pinned to Xcode 26.1 iPhoneOS observations. The
  ordinary-import oracle runtime asserts all 463 raw values, including
  `COREAUDIOTYPES_VERSION == 20211130`.

`OSType` and `OSStatus` are Darwin MacTypes names required by seeded
signatures. They are not CoreAudioTypes graph IDs and not CoreFoundation
lookalikes.

## Fail-closed / not invented

- No device, codec, session, or host audio service. There is no hardware
  success path.
- No `CoreAudioTypes.CFString` / `CFURL` / `CFDictionary`. The product
  module does not import CoreFoundation because no CF-owned type crosses a
  seeded public signature.
- Source-defined Swift enums cannot reproduce the storage model of
  Clang-imported C enums exactly. Alignment/stride are forced to the observed
  Apple widths (4 bytes for `AudioChannelCoordinateIndex`/`SMPTETimeType` and
  8 for `MPEG4ObjectID`), but Swift reports `MemoryLayout.size == 1` instead
  of 4/8. Containing `SMPTETime`/`AudioTimeStamp` fields still match the
  Apple C layout.
- `AudioFormatListItem` and `AudioValueTranslation` Swift
  `MemoryLayout.size` omit tail padding (`44`/`28`) while C `sizeof` and
  Swift `stride` are `48`/`32` on this host.

## Still deferred / blocked

- Exact Clang-imported enum `MemoryLayout.size`/binary identity. This requires
  an underlying C module or equivalent importer support; it is not solved by
  inventing extra public cases.
- The 20 graph rows under `AVAudioSession.ErrorCode` require the canonical
  AVAudioSession class owned by AVFAudio/AVFoundation. They are deliberately
  deferred: defining an empty `AVAudioSession` namespace here collides with
  the repository's real class and does not match Apple ordinary-import
  behavior.
- Linked CoreFoundation runtime in the central guest package. The portable
  gate typechecks a client importing both `CoreAudioTypes` and
  `CoreFoundation`; it does not turn an overlay typecheck into link proof.
- Integration with downstream CoreAudio, AudioToolbox, AVFAudio, AudioUnit,
  and CoreMedia builds.

## Tests

- Sealed host gate: `bash tests/acceptance/test_host.sh`
- Full portable integration gate (sealed gate, emitted-surface comparison,
  ordinary-import runtime, 463 Apple-oracle values, internal flexible-array
  arithmetic, reconstructed C fixture, and CoreFoundation coexistence
  typecheck): `bash tests/agent/test_integration.sh`
- Focused Swift layouts/runtime: `tests/agent/CoreAudioTypesRuntime.swift`
  marker `COREAUDIOTYPES_AGENT_RUNTIME_OK`
- Internal overflow/negative-count helper:
  `COREAUDIOTYPES_FLEXIBLE_ARRAY_OK`
- Reconstructed C fixture: `COREAUDIOTYPES_C_LAYOUT_OK`
- Apple-oracle values: `COREAUDIOTYPES_APPLE_ORACLE_VALUES_OK`
- Full integration marker: `COREAUDIOTYPES_AGENT_INTEGRATION_OK`
