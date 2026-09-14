# CoreMedia Linux starting point

This directory is a clean-room Linux implementation of Apple's public
`CoreMedia` module seeded from the Xcode 26.1 iPhoneOS SDK graphs.

## What is real

- `CMTime` arithmetic matching Apple macOS 26.1 (2026-09-14 oracle) and
  `CMTime.h`: make, make-with-seconds (toward-zero; NaN → rounded zero),
  get-seconds, add/subtract (epoch 0 is a duration), multiply /
  multiplyByFloat64 / multiplyByRatio, compare/min/max/absoluteValue,
  convertScale for every `CMTimeRoundingMethod` including QuickTime
  (toward-zero when shrinking the scale, away-from-zero when growing it,
  never round a negative value to 0), flags, and `kCMTimeZero` /
  `Invalid` / `Indefinite` / `±Infinity` (inf/indefinite use timescale 0).
  Dictionary round-trip uses `epoch` / `flags` / `timescale` / `value`
  CFString keys.
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
- `CMTag` / `CMTypedTag` / sample-buffer `CMTaggedBuffer` with Linux
  category FourCC stand-ins, and `CMReadySampleBuffer` wrapping a
  data-ready `CMSampleBuffer` (data-buffer and marker inits).
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

- Invalid timescale, mixed infinities, different nonzero epochs on add,
  empty/malformed buffer offsets, and invalidated sample buffers fail closed.
  NaN seconds become a valid rounded-zero CMTime at the preferred timescale.
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

- Pixel-buffer `CMTaggedBuffer` groups and `CMReadySampleBuffer` specializations
  that need `CVPixelBuffer` / tagged-buffer groups until CoreVideo supplies them.
- `CMTag` C `__CMTag` layout and Apple category FourCC integers (Linux uses
  stand-in FourCCs `stvw`/`pack`/`pixf`/`mdia`/`msub`/`vlyr`/`proj`/`svi `/`trak`/`chnl`).
- Camera-calibration `intrinsicMatrix` (`simd_float3x3`) until `import simd` exists.
- APIs that require `AudioStreamBasicDescription` / `CVImageBuffer` /
  `AudioBufferList` until the central build supplies CoreAudioTypes and CoreVideo.
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
is a default-allocator wrapper (`CFAllocatorGetDefault()` / `kCFAllocatorSystemDefault`;
no slab cache). Endian sample-description bridges and bitstream parsers stay
fail-closed.

This run (depth pass 2026-09 wave 8, next pass on starting commit
`2de7152a`) keeps the earlier surface and adds honest Linux behavior for
`CMReadOnlyDataBlockBuffer` / `CMMutableDataBlockBuffer` (contiguous copy-in,
Collection/DataProtocol, custom `BlockSource`, `MemoryPool`), CMSampleBuffer
overlay (`ContentType`, `DataReadiness` state machine, per-sample attachments,
`SizePerSample` / `TimingPerSample`, `SamplePropertiesCollection`),
CMFormatDescription.Extensions collection/`init(base: CFDictionary?)`,
remaining video-codec FourCCs and MediaSubType table, CMTimebase overlay
rate/anchor/timer fail-closed paths, and CMTimeRange/CMTimeMapping algebra.

| status | before (this seed) | after |
| --- | ---: | ---: |
| implemented | 932 | 1573 |
| declared | 1508 | 1511 |
| deferred | 1064 | 420 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Top-5 `implemented` evidence distribution after this pass:

1. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (7.3%)
2. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (5.7%)
3. `CMDataBlockBufferTests.swift#testCMMutableDataBlockBufferReplaceAppendAndPointer` — 52 (3.3%)
4. `CMSampleBufferOverlayTests.swift#testCMSampleBufferSamplePropertiesAndAttachments` — 52 (3.3%)
5. `CMKeyStringTests.swift#testCMFormatDescriptionExtensionKeyStrings` — 46 (2.9%)

No non-constant test owns more than 40% of implemented rows. DispatchSourceTimer
overloads stay `declared` because constructing a live `DispatchSource` in this
Linux gate aborts libdispatch on release. `AudioBufferList` DataBlockBuffer
inits and `CVImageBuffer` sample-buffer entry points remain deferred. SwiftUI
cross-import overlay IDs are not in this module's public surface.

This run (depth pass 2026-09 wave 8, next pass on starting commit
`6bf18072`) keeps the earlier surface and adds honest Linux behavior for
`CMTag` / `CMTypedTag` / `CMTaggedBuffer` (sample-buffer only),
`CMReadySampleBuffer` over `CMReadOnlyDataBlockBuffer`, format-description
`Extensions` as a `BidirectionalCollection`, camera-calibration lens overlay
(without `simd_float3x3`), font-name / local-key / presentation-dimension
getters, remaining format-type FourCCs, HEVC temporal-level keys, metadata
format-description keys, and timebase notification strings.

| status | before (this seed) | after |
| --- | ---: | ---: |
| implemented | 1573 | 2111 |
| declared | 1511 | 1126 |
| deferred | 420 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Top-5 `implemented` evidence distribution after this pass:

1. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (5.4%)
2. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (4.2%)
3. `CMFormatDescriptionExtensionOverlayTests.swift#testCMFormatDescriptionExtensionKeyRawValues` — 59 (2.8%)
4. `CMDataBlockBufferTests.swift#testCMMutableDataBlockBufferReplaceAppendAndPointer` — 52 (2.5%)
5. `CMSampleBufferOverlayTests.swift#testCMSampleBufferSamplePropertiesAndAttachments` — 52 (2.5%)

No non-constant test owns more than 40% of implemented rows. DispatchSourceTimer
overloads stay `declared` because constructing a live `DispatchSource` in this
Linux gate aborts libdispatch on release. `AudioBufferList` / `CVImageBuffer`
sample-buffer entry points remain deferred. SwiftUI cross-import overlay IDs
are not in this module's public surface.

Sealed gate `bash full/coremedia/tests/acceptance/test_host.sh` (this snapshot):

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreMedia lane=large-partitioned symbols=3504
FRAMEWORK_FANOUT_REFERENCE_OK
COREMEDIA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreMedia dylib=libCoreMedia.dylib
```

This pass re-ran that sealed gate in the Linux environment until
`FRAMEWORK_FANOUT_HOST_OK`. Guest stdout is marker-only; `CMTimeShow` /
`CMTimeRangeShow` / `CMTimeMappingShow` write debug lines to stderr.

## Depth pass 2026-09 (wave 8)

This continuation converts previously declared collection and value semantics
into exercised Linux behavior. Focused synchronous tests now cover the
`CMFormatDescription.Extensions`, `CMSampleBuffer.SamplePropertiesCollection`,
and `CMSampleBuffer.SampleAttachmentsArray` standard-library algorithms,
CoreMedia option-set mutation/algebra, raw-value wrapper equality and hashing,
and the complete sample-buffer attachment-key identity table. No Apple service,
hardware, callback-scheduling, or image/audio dependency behavior was inferred;
those boundaries remain declared or deferred as recorded in `coverage.tsv`.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2111 | 2311 |
| declared | 1126 | 926 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Top-5 `implemented` evidence distribution after this pass:

1. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (5.0%)
2. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (3.9%)
3. `CMFormatDescriptionExtensionOverlayTests.swift#testCMFormatDescriptionExtensionKeyRawValues` — 59 (2.6%)
4. `CMDataBlockBufferTests.swift#testCMMutableDataBlockBufferReplaceAppendAndPointer` — 52 (2.3%)
5. `CMSampleBufferOverlayTests.swift#testCMSampleBufferSamplePropertiesAndAttachments` — 52 (2.3%)

The environment verifier emitted the required campaign marker:
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
The sealed host gate was then run from a clean temporary build and reached all
deliverable, reference, runtime, and dylib host markers.

### Wave 8 continuation from campaign commit `5a351db2`

This continuation adds focused runtime evidence for the standard-library
collection behavior inherited by `CMReadOnlyDataBlockBuffer`, its `BlockRegion`,
and `CMMutableDataBlockBuffer.BlockRegion`. The synchronous test specializes the
algorithms for all three concrete byte projections and checks searching,
transforms, folds, ordering, slicing, index movement, iteration, and boundary
behavior. It does not reclassify Foundation comparator/formatting, Combine, or
String Processing overloads that the test does not exercise.

| status | before (`5a351db2`) | after |
| --- | ---: | ---: |
| implemented | 2311 | 2460 |
| declared | 926 | 777 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

The campaign ledger baseline was 2111 implemented rows, so wave 8 now has a
cumulative gain of 349 implemented rows; this continuation itself contributes
149 focused rows.

Top-5 `implemented` evidence distribution after this continuation:

1. `CMCollectionDepthTests.swift#testCMDataBlockBufferCollectionAlgorithms` — 149 (6.1%)
2. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (4.7%)
3. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (3.6%)
4. `CMFormatDescriptionExtensionOverlayTests.swift#testCMFormatDescriptionExtensionKeyRawValues` — 59 (2.4%)
5. `CMDataBlockBufferTests.swift#testCMMutableDataBlockBufferReplaceAppendAndPointer` — 52 (2.1%)

The sealed gate completed with the required environment, deliverable, reference,
runtime, and dylib markers. Existing fail-closed image/audio dependency,
bitstream parser, handler-blob, and timer-scheduling boundaries remain unchanged.

### Depth pass 2026-09 (wave 8 continuation from `08da4b01`)

This continuation audits the already-present format-description and sample-buffer
implementations against their concrete synchronous behavioral tests. It promotes
358 formerly declared identifiers whose synthesized value/collection operations,
format presentation, sample timing/range copying, readiness transitions, and
attachment semantics are directly exercised on Linux. No Apple callback queue,
hardware codec, image-buffer, audio-packet, daemon, or entitlement behavior was
inferred; those boundaries remain deferred or declared in `coverage.tsv`.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2460 | 2818 |
| declared | 777 | 419 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Top-5 `implemented` evidence distribution after this continuation:

1. `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` — 180 (6.4%)
2. `CMCollectionDepthTests.swift#testCMDataBlockBufferCollectionAlgorithms` — 149 (5.3%)
3. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (4.1%)
4. `CMCollectionDepthTests.swift#testCMSampleAttachmentsArrayCollectionAlgorithms` — 110 (3.9%)
5. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (3.2%)

The sealed Linux host gate completed with all deliverable, reference, runtime,
and dylib markers. The environment verifier separately confirmed Swift 6.2.4,
the Linux target, scratch corpus, and dotnet-macios evidence marker.

## Depth pass 2026-09-14 (Apple CMTime oracle)

This pass matches the Linux `CMTime` / `CMTimeRange` port to a live Apple
CoreMedia transcript captured on this Mac (`scratch/oracle-2026-09-14/`,
Xcode 26.1 / macOS 26.1). Guest sources typecheck as `CoreMediaPort`.
A host runner compiled `CMTime.swift` + `CMTimeRange.swift` against the
same assertions as the Apple transcript: every measured key matched except
`CMTimeMultiplyByFloat64` timescale (seconds 0.75 and flags valid match;
Darwin used 1e9, Linux follows the public header's 65536 doubling).

| status | before | after |
| --- | ---: | ---: |
| implemented | 2818 | 2851 |
| declared | 419 | 386 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Apple mismatches fixed:

1. Rounding raw values: default=1, halfAway=1, towardZero=2, away=3, quickTime=4, pinf=5, ninf=6.
2. QuickTime is not toward-+infinity. Convert 1/2→ts 1 is 0; 1/2→ts 3 is 2; −1/2→ts 1 is −1; 5/3→ts 2 is 3. Rule: toward-zero when shrinking the timescale, away-from-zero when growing it, and never round a negative value down to 0.
3. Special constants: invalid 0/0/fl=0; zero 0/1/fl=1; indefinite 0/0/fl=17; +inf 0/0/fl=5; −inf 0/0/fl=9 (timescale 0 for inf/indefinite).
4. `CMTimeMakeWithSeconds`: 1.5@ts=2 is exact 3/2; 0.5@ts=1 is toward-zero 0 with hasBeenRounded; NaN@ts=600 is valid+rounded zero, not invalid; ±inf map to the inf constants; ts≤0 is invalid.
5. Epoch: adding (1/1, epoch 1) + (1/1, epoch 0) yields (2/1, epoch 1), not invalid. Epoch 0 is a duration; compare orders the later epoch first.
6. Dictionary keys are exactly `epoch,flags,timescale,value`.
7. Range: start 1/2 + duration 1/3 → end 5/6; contains 1/2 true, 1.0 false; fromTimeToTime(.zero, 1/2).duration = 1/2; union duration 5/6; intersection duration 0.
8. `CMTimeMultiplyByFloat64(1/2, 1.5)` matches seconds 0.75 and valid flags. Darwin's 1e9 timescale is recorded in `oracle-questions.tsv`.
9. `CMTimeMultiplyByRatio(1/2, 2, 3)` is the exact rational 2/6.
10. `CMTimeCompare` total order is now `-inf < finite < indefinite < +inf < invalid` as documented in `CMTime.h`.

Remaining deferred rows are still audio/image-buffer C APIs that need
CoreAudioTypes/CoreVideo, DispatchSource timer overloads that abort
libdispatch in the sealed Linux gate, and overlay hosts that this port
does not implement. No Apple service or hardware success was invented.

## Depth pass 2026-09-14 (Hashable / Equatable / OptionSet)

This continuation converts previously declared stdlib Hashable, Equatable,
and OptionSet witnesses only where a focused test hashes, equals, or uses
OptionSet algebra on that host type. Identity `Hashable` on `CMClock`,
`CMTimebase`, `CMBlockBuffer`, `CMBufferQueue`, and `CMSimpleQueue` matches
the existing `CMMemoryPool` / `CMFormatDescription` pattern. Packing and
projection enums, stereo-view option sets, attachment-mode, and timebase
notification keys are exercised directly. Flavor `CFString` typealiases keep
their `_SwiftNewtypeWrapper` witnesses declared: Linux does not wrap those
C strings. `DataProtocol.copyBytes`, `sorted(using: SortComparator)`,
un-called `CMBlockBufferProtocol` methods, and CoreAudioTypes/CoreVideo
sample APIs stay declared or deferred.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2851 | 2904 |
| declared | 386 | 333 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +53.

Top-5 `implemented` evidence distribution after this pass:

1. `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` — 180 (6.2%)
2. `CMCollectionDepthTests.swift#testCMDataBlockBufferCollectionAlgorithms` — 149 (5.1%)
3. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (4.0%)
4. `CMCollectionDepthTests.swift#testCMSampleAttachmentsArrayCollectionAlgorithms` — 110 (3.8%)
5. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (3.1%)

No test owns more than 40% of implemented rows. Leftover deferred C APIs are
still the CoreAudioTypes/CoreVideo family (`CMAudioFormatDescriptionCreate`
and ASBD/channel-layout/format-list getters, audio packet-description sample
buffers, `AudioBufferList` copy/set, image-buffer sample-buffer create/get,
and `CMVideoFormatDescriptionCreateForImageBuffer` / `MatchesImageBuffer`).

## Depth pass 2026-09-14 (CMBlockBufferProtocol / flavor Hashable)

This continuation wraps the six description-flavor CFString typealiases as
`RawRepresentable` structs so `==` / `!=`, `hash(into:)`, `hashValue`, and
`init(rawValue:)` / `init(_:)` can be hashed and equated by a focused test.
Public `CMBlockBufferProtocol` now matches Apple's requirements (`owner`,
`startIndex`, `endIndex`) with extension defaults for `dataLength`,
`isContiguous`, `copyDataBytes(to:)`, `dataBytes()`, `fillDataBytes(with:)`,
`replaceDataBytes(with:)`, and the six slice subscripts. `CMBlockBuffer.Slice`
conforms and those methods are called through the protocol and the concrete
buffer. `makeContiguous` / `withContiguousStorage`, Foundation
`DataProtocol.copyBytes`, `sorted(using: SortComparator)`, and
CoreAudioTypes/CoreVideo sample APIs stay declared or deferred.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2904 | 2980 |
| declared | 333 | 257 |
| deferred | 267 | 267 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +76.

Top-5 `implemented` evidence distribution after this pass:

1. `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` — 180 (6.0%)
2. `CMCollectionDepthTests.swift#testCMDataBlockBufferCollectionAlgorithms` — 149 (5.0%)
3. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (3.9%)
4. `CMCollectionDepthTests.swift#testCMSampleAttachmentsArrayCollectionAlgorithms` — 110 (3.7%)
5. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (3.0%)

No test owns more than 40% of implemented rows. Leftover deferred C APIs are
still the CoreAudioTypes/CoreVideo family (`CMAudioFormatDescriptionCreate`
and ASBD/channel-layout/format-list getters, audio packet-description sample
buffers, `AudioBufferList` copy/set, image-buffer sample-buffer create/get,
and `CMVideoFormatDescriptionCreateForImageBuffer` / `MatchesImageBuffer`).
