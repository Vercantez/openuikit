# CoreMedia Linux starting point

This directory is a clean-room Linux implementation of Apple's public
`CoreMedia` module seeded from the Xcode 26.1 iPhoneOS SDK graphs.

## What is real

- `CMTime` arithmetic exactly as documented in `CMTime.h`: make,
  make-with-seconds, get-seconds, add/subtract/multiply/multiplyByFloat64/
  multiplyByRatio, compare/min/max/absoluteValue, convertScale for every
  `CMTimeRoundingMethod` (QuickTime uses toward-+infinity as a labeled
  stand-in; see `oracle-questions.tsv`), flags, epoch mismatch → invalid,
  and `kCMTimeZero` / `Invalid` / `Indefinite` / `±Infinity`. Dictionary
  round-trip uses `value` / `timescale` / `epoch` / `flags` CFString keys.
- `CMTimeRange` (make, fromTimeToTime, contains, union/intersection, end,
  equal, dictionary) and `CMTimeMapping`.
- Host `CMClock` on `DispatchTime` nanoseconds (CMSync.h: "large integer
  timescale (eg, nanoseconds)") and `CMTimebase` rate/anchor interpolation
  `time = anchor + (sourceNow − sourceAnchor) * rate`. Audio clock create
  returns `kCMClockError_UnsupportedOperation`. Timers throw
  `kCMTimebaseError_TimerIntervalTooShort`.
- `CMBlockBuffer` owned-byte copy-in/copy-out, fill/replace/append,
  custom `AllocateBlock`/`FreeBlock` (copy-in then free),
  `AccessDataBytes` (prefers an interior cache pointer), and
  `GetDataPointer` into a contiguous cache invalidated on mutation.
- `CMSampleBuffer` create/ready/copy/timing/size/attachments/invalidate,
  per-sample attachment dictionaries, data-failed status,
  `MakeDataReady` callback invocation, and same-thread data-readiness
  tracking. Image-buffer and AudioBufferList entry points stay deferred
  until CoreVideo/CoreAudioTypes are present.
- `CMFormatDescription` media type/subtype, video dimensions, extensions,
  clean aperture / presentation dimensions, text/timecode getters,
  metadata identifier arrays, `CMAudioFormatDescriptionEqual` /
  `CreateSummary` / `GetMagicCookie` (cookie is nil until an ASBD create
  path supplies bytes). Audio `AudioStreamBasicDescription` bridging is
  compiled only when `CoreAudioTypes` is imported
  (`CMDependencyBridges.swift`); the isolated host does not claim it.
- `CMMemoryPool` wrapping `CFAllocatorGetDefault()` (AgeOutPeriod stored,
  no slab cache; `kCFAllocatorDefault` is NULL on this CoreFoundation).
  `CMPackingType` / `CMProjectionType` FourCCs and
  stereo-view option sets.
- `CMSimpleQueue` and `CMBufferQueue` (unsorted and PTS-sorted sample
  buffers, duration/size/PTS getters, end-of-data, validation, and
  rising-edge triggers). `CMBufferQueueCreateWithHandlers` fails closed:
  Linux has no ABI for Apple's internal handlers blob.
- Public `kCMTime*` / `kCMSampleAttachment*` / `kCMFormatDescription*`
  CFString keys (suffix payloads; color aliases match this repo's CoreVideo
  strings) and OSStatus integers from the public headers.
- C header macros (`CMITEMCOUNT_MAX`, `COREMEDIA_TRUE`/`FALSE`, and the
  `COREMEDIA_DECLARE_*` / alignment / visibility flags) as Swift overlay
  constants. `CMITEMCOUNT_MAX` is `Int.max`; Darwin visibility and
  `CMTIMEBASE_USE_SOURCE_TERMINOLOGY` are `0` on this Linux port.

`implemented` rows cite a focused test of that identifier. Enum/option-set
members may share one table-driven raw-value test. kCM* string payloads are
split into family tables (time/range/mapping, format-description extensions,
color/matrix, sample attachments, metadata key spaces).

## Fail-closed

- Invalid timescale, NaN seconds, mixed infinities, different epochs on add,
  empty/malformed buffer offsets, and invalidated sample buffers fail closed.
- Big-endian sample-description bridges, `CMSwap*` endian helpers, and
  H.264/HEVC parameter-set parsers return
  `kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor`
  / `kCMFormatDescriptionError_InvalidParameter`: there is no QuickTime
  decoder on this isolated Linux gate. SoundDescription CBR layout is never
  required (`CMDoesBigEndianSoundDescriptionRequireLegacyCBRSampleTableLayout`
  returns false).
- `CMBufferQueueCreateWithHandlers` returns
  `kCMBufferQueueError_InvalidCMBufferCallbacksStruct`.
- Timebase `Timer` / `DispatchSource` registration returns
  `kCMTimebaseError_TimerIntervalTooShort` (no run-loop scheduling).
- Arbitrary payload bytes are stored as opaque sample data; they are not
  treated as a decoded bitstream.

## Deferred

- `CMTag`, `CMReadySampleBuffer`, tagged-buffer groups, and packing
  attached to sample buffers (the packing/projection *enums* are implemented).
- APIs that require `AudioStreamBasicDescription` / `CVImageBuffer` until
  the central build supplies CoreAudioTypes and CoreVideo.
- Remaining Swift overlay Collection/camera-calibration helpers on
  `CMFormatDescription.Extensions.Value`.
- C-callable `@_cdecl` entry points are not emitted: Swift `CMTime` structs
  are not Clang-imported C types. Layout is reconstructed in
  `tests/agent/cm_value_layout.c`.

## Depth pass 2026-09 (wave 8)

Repair after `FW_MERGE REFUSED` at `08baa78a` (1130 `not-applicable` rows
were not SwiftUI cross-import overlay IDs). Counts are exact
`coverage.tsv` rows (3504 public precise IDs).

| status | before (`08baa78a`) | after |
| --- | ---: | ---: |
| implemented | 721 | 737 |
| declared | 1172 | 1600 |
| deferred | 481 | 1167 |
| unavailable | 0 | 0 |
| not-applicable | 1130 | 0 |

The 15 C preprocessor macros plus `CMTIMEBASE_USE_SOURCE_TERMINOLOGY` are
now Linux Swift overlay constants with
`CMMacroTests.swift#testCMCoreMediaMacroConstants`. The 1115
`::SYNTHESIZED::` stdlib/Foundation witnesses are `declared` when the host
type exists in this port and `deferred` when the overlay host is absent
(DataBlockBuffer collections, stereo/packing, MemoryPool/Tag, camera
calibration, CoreVideo pixel-buffer hosts).

Top-5 `implemented` evidence distribution after this repair:

1. `CMKeyStringTests.swift#testCMFormatDescriptionExtensionKeyStrings` — 46 (6.2%)
2. `CMKeyStringTests.swift#testCMSampleAttachmentKeyStrings` — 34 (4.6%)
3. `CMQueueTests.swift#testCMBufferQueueErrorAndTriggerConstants` — 33 (4.5%)
4. `CMKeyStringTests.swift#testCMFormatDescriptionColorMatrixKeyStrings` — 29 (3.9%)
5. `CMFormatDescriptionTests.swift#testCMFormatDescriptionOverlayKeys` — 26 (3.5%)

No non-constant test owns more than 40% of the remaining implemented rows.
SwiftUI cross-import overlay IDs are not in this module's public surface.

This run (third pass, starting commit `bff8535c`) keeps the wave-8 surface and adds
honest Linux behavior for attachments, memory pool, packing/projection/stereo
enums, audio format equal/summary/magic-cookie (nil until ASBD Create),
MakeDataReady callbacks, custom block allocators, and fail-closed endian /
H.264 / HEVC / timebase-dispatch / audio-clock APIs.

| status | before (this seed) | after |
| --- | ---: | ---: |
| implemented | 737 | 932 |
| declared | 1600 | 1508 |
| deferred | 1167 | 1064 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Top-5 `implemented` evidence distribution after this pass:

1. `CMKeyStringTests.swift#testCMFormatDescriptionExtensionKeyStrings` — 46 (4.9%)
2. `CMAudioFormatAndConstantTests.swift#testCMMPEG2VideoProfileFourCCConstants` — 37 (4.0%)
3. `CMKeyStringTests.swift#testCMSampleAttachmentKeyStrings` — 34 (3.6%)
4. `CMQueueTests.swift#testCMBufferQueueErrorAndTriggerConstants` — 33 (3.5%)
5. `CMAudioFormatAndConstantTests.swift#testCMSampleBufferAndFormatBridgeErrorConstants` — 33 (3.5%)

No non-constant test owns more than 40% of implemented rows. Audio
`AudioStreamBasicDescription` create/getters, `CVImageBuffer` sample-buffer
entry points, `CMTag`, and stereo-tagged buffer groups remain deferred. `CMMemoryPool`
is a default-allocator wrapper (no slab cache). Endian sample-description
bridges and bitstream parsers stay fail-closed.
