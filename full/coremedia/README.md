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
  `AccessDataBytes` (prefers an interior cache pointer), and
  `GetDataPointer` into a contiguous cache invalidated on mutation.
- `CMSampleBuffer` create/ready/copy/timing/size/attachments/invalidate,
  per-sample attachment dictionaries, data-failed status, and
  same-thread data-readiness tracking. Image-buffer and AudioBufferList
  entry points stay deferred until CoreVideo/CoreAudioTypes are present.
- `CMFormatDescription` media type/subtype, video dimensions, extensions,
  clean aperture / presentation dimensions, text/timecode getters, and
  metadata identifier arrays. Audio `AudioStreamBasicDescription`
  bridging is compiled only when `CoreAudioTypes` is imported
  (`CMDependencyBridges.swift`); the isolated host does not claim it.
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
- Big-endian sample-description bridges and H.264/HEVC parameter-set
  parsers return `kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor`
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

- `CMMemoryPool`, `CMTag`, `CMReadySampleBuffer`, stereo/packing, and
  tagged-buffer types.
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
Audio ASBD / CVImageBuffer / MemoryPool / Tag / packing remain deferred.
