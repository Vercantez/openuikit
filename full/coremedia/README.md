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

## Depth pass 2026-09-15 (CMBlockBufferProtocol remainder / CMTime witnesses)

No declared Hashable/Equatable/OptionSet/NewtypeWrapper witnesses remain: the
prior passes already converted every one (verified by exact-match audit of all
257 declared rows). The remaining `CMBlockBufferProtocol` extension methods
that exist in the Apple surface (`makeContiguous(allocator:deallocator:flags:)`,
`makeContiguous(allocator:flags:)`, `withContiguousStorage(_:)`, pinned by
`reference/public-surface.tsv` and `reference/api-digester.json`) were missing
from the port, so they are now honest extension defaults: Linux storage is
always a single contiguous copy, so compacting copies the bytes (custom
allocator path copies in, then hands the scratch block back, mirroring
`CMBlockBufferCreateWithMemoryBlock`), and `withContiguousStorage` yields the
copied bytes. `CMBlockBufferContiguousTests.swift#testCMBlockBufferMakeContiguousAndContiguousStorage`
calls all three through the concrete buffer, `Slice`, and a generic
protocol-constrained helper. The eight remaining `CMTime` Comparable witnesses
are now cited: `>` / `>=` / `<=` were already called by
`testCMTimeComparableOperators`, and the five range-expression witnesses
(`..<`, `...`, `PartialRangeFrom/UpTo/Through`) are formed over `CMTime` by the
new `testCMTimeRangeExpressionOperators`. `DataProtocol.copyBytes`,
`sorted(using: SortComparator)`, `CMAudioFormatDescription*`, and image-buffer
sample APIs stay declared/deferred as instructed. Also fixed a latent
Apple-toolchain-only build break: `Calibration.init` used `CGSize.zero` in a
default argument, which Swift 6 rejects without a direct CoreGraphics import
(absent on Linux); the default now names a same-module constant.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2980 | 2997 |
| declared | 257 | 243 |
| deferred | 267 | 264 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +17 (9 block-buffer protocol rows: 3 deferred base + 6
declared host witnesses; 8 CMTime comparison/range witnesses).

Top test still
`CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (6.0%). No test owns more than 40% of implemented rows. The sealed gate
reaches `FRAMEWORK_FANOUT_DELIVERABLE_OK` and `FRAMEWORK_FANOUT_REFERENCE_OK`
on this Mac; its final stage is Linux-only (`import Glibc` in the generated
runner), so runtime proof here is a macOS runner over the same 181 cited
tests: the module and all test files compile warnings-clean and the three
tests behind the 17 promoted rows pass. (`testCMBlockBufferProtocolMethods`
traps on macOS identically with and without this change because the system
`libswiftCoreMedia.dylib` registers colliding classes; Linux has no system
CoreMedia.)

## Depth pass 2026-09-15 (equated host-type aliases)

This pass audits the 243 declared rows against the prompt's two convertible
categories. No declared Hashable/Equatable/OptionSet/NewtypeWrapper witnesses
remain (exact-match audit finds no `2eeoiy` / `4hash` / `9hashValue` /
`Newtype` / `rawValue` synthesized rows), and every `CMBlockBufferProtocol`
extension method plus its `CMBlockBuffer` / `Slice` host witnesses is already
implemented, so neither category has unconverted witnesses. The six remaining
conversions are the `c:@T@` host-type rows whose values a focused test both
names and equates — the same type-annotation-plus-use rule that already
carries `c:@T@CMBlockBufferRef` and friends: `CMAttachmentMode` (attachment
round-trip equates the mode), `CMAudioFormatDescriptionMask` (equality-mask
intersection and inequality), `CMVideoCodecType` (table-driven FourCC
equality), `CMTextDisplayFlags` / `CMTextJustificationValue` (text getters
equate the out-values), and `CMItemCount` (timing-array out-count equated with
the produced count). `CMAudioFormatDescription*`, image-buffer sample APIs,
Foundation `DataProtocol.copyBytes` / `sorted(using: SortComparator)`,
DispatchSource timer overloads, `CMSyncProtocol` / clock-extension overlays,
and custom-block-source fields stay declared/deferred as instructed.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2997 | 3003 |
| declared | 243 | 237 |
| deferred | 264 | 264 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +6. Top test still
`CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (6.0%). No test owns more than 40% of implemented rows. The sealed gate
reaches `FRAMEWORK_FANOUT_DELIVERABLE_OK` and `FRAMEWORK_FANOUT_REFERENCE_OK`
on this Mac; its final stage is Linux-only (`import Glibc` in the generated
runner). No product Swift or test files changed in this pass; the guest
sources manifest is unchanged.

## Depth pass 2026-09-15 (coremedia prompt: sync overlays / trampolines / recovered deferred)

No SwiftUI/View overlay rows exist in this module's public surface (verified:
zero `coverage.tsv` IDs mention SwiftUI or View), so the overlay-override clause
has nothing to convert here. This pass converts the remaining honestly
testable declared rows and recovers deferred rows that are pure in-process
values, constants, or callbacks:

- `CMSyncProtocol` (protocol + all 5 witnesses) exercised through a generic
  `S: CMSyncProtocol` probe over `CMClock` and `CMTimebase`; `CMSync` +
  `Error` statics; all 12 `CMClock` overlay members (`time`, `anchorTime()`,
  `invalidate()`, both `mightDrift` overloads, `convertTime`, `rate`,
  `rateAndAnchorTime`, `Error` + 3 statics); and the two Apple-labeled free
  functions `CMTimebaseSetAnchorTime(_:timebaseTime:immediateMasterTime:)` /
  `CMTimebaseSetRateAndAnchorTime(_:rate:anchorTime:immediateMasterTime:)`
  (new same-behavior overloads; the port's primary spelling keeps
  `immediateSourceTime:`). Synchronous, no run loop, no dispatch.
- Init trampolines: all 4 `CMTimebase` inits, `CMBufferQueue(capacity:handlers:)`,
  `CMSimpleQueue(capacity:)`, the 3 `init(referencing:)` C-bridged inits, and 8
  new throwing `CMBlockBuffer` overlay inits (`capacity`, `buffer:allocator:` /
  `buffer:deallocator:` over pointer and slice, `length:allocator:range:`,
  `length:allocator:deallocator:range:`, generic `bufferReference:`). Linux
  copies into one contiguous buffer; capacity only reserves; the custom
  deallocator runs after copy-in, mirroring the custom-block-source flow.
- `CMBlockBufferCustomBlockSource` fields + both inits, exercised through
  `CMBlockBufferCreateWithMemoryBlock` (copy-in then free).
- 24 remaining `c:@T@` host-type rows named, annotated, and equated;
  `CMBufferQueue.T` / `TriggerToken` / `CMSimpleQueue.T` aliases.
- `CMBufferQueue.Buffers` Sequence algorithms (31 witnesses: search, transform,
  fold, prefix/suffix/drop, sort/min/max, equality/prefix/lexicographic
  predicates, split, lazy, estimated count, contiguous-storage default,
  deterministic shuffle-shape checks). Foundation `sorted(using:)` / `compare` /
  `formatted`, Combine `publisher`, and the deprecated optional-`flatMap`
  (warning under `-warnings-as-errors`) stay declared.
- Deferred recoveries with Apple oracle values (Xcode macOS SDK 26.1 probe
  2026-09-15): `kCMMediaType_AuxiliaryPicture` (`'auxv'`), 8 image/sound
  description-flavor family statics, `kCMTagProjectionTypeHalfEquirectangular`
  (category `'proj'`, value `'hequ'`), `CMBufferValidationCallback/Handler`
  (accept/reject validator round-trip on a live queue), pure value type
  `CMSampleDataReference` (URL + byte offset, Hashable), and overlay
  `CMSampleBuffer.setDataBuffer(_:)` over the existing free function.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3003 | 3129 |
| declared | 237 | 131 |
| deferred | 264 | 244 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +126 (106 declared, 20 deferred). Top test still
`CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (5.8%). No test owns more than 40% of implemented rows. New tests own
26 + 36 + 31 + 13 + 20 rows respectively. Verified on this Mac:
`FRAMEWORK_FANOUT_DELIVERABLE_OK` via the shared validator, product plus all
30 test files compile warnings-clean, and a macOS runner over the 5 new tests
prints marker-only stdout (`COREMEDIA_MACOS_PROBE_OK`, ObjC duplicate-class
notes on stderr from the system `libswiftCoreMedia.dylib`, as in prior passes).
The sealed gate's final stage remains Linux-only (`import Glibc` in the
generated runner). Leftover deferred rows still need CoreAudioTypes/CoreVideo
(audio/image sample paths, tagged-dynamic pixel content, parameter-set and
single-sample collections), `simd`, DispatchSource timers (aborts libdispatch
in the sealed gate), or hardware/daemons. No Apple service or hardware success
was invented.

## Depth pass 2026-09-15 (coremedia prompt: witnesses / block-buffer / keep-list)

Audit result: no declared Hashable/Equatable/OptionSet/NewtypeWrapper witnesses
remain (exact-match audit finds no `2eeoiy` / `4hash` / `9hashValue` / `Newtype` /
`rawValue` synthesized rows and no `c:@E` declared rows), so that category has
nothing left to convert. The keep-list stays untouched: `CMAudioFormatDescription*`
and image-buffer sample APIs remain deferred, and Foundation
`DataProtocol.copyBytes` / `sorted(using: SortComparator)` (plus `compare`,
`formatted`, `lastRange`/`firstRange`) remain declared. DispatchSource timer
overloads, `CMSyncProtocol` / clock-extension overlays, and custom-block-source
fields stay declared/deferred as instructed.

This pass repairs three latent breaks instead of reclassifying rows:

1. `testCMTimeRangeExpressionOperators` was cited by 5 implemented rows
   (the `..<` / `...` / `PartialRangeFrom/UpTo/Through` witnesses over `CMTime`)
   but the function did not exist, so the deliverable validator rejected the
   framework (5 errors). The focused synchronous test is now defined in
   `CMTimeTests.swift` and forms/asserts all five range expressions.
2. `CMBlockBufferProtocol.makeContiguous(allocator:deallocator:flags:)`,
   `makeContiguous(allocator:flags:)`, and `withContiguousStorage(_:)` were
   cited as implemented (9 rows via
   `testCMBlockBufferMakeContiguousAndContiguousStorage`) but missing from the
   product, so no test binary could compile. They are now honest extension
   defaults in `CMBlockBuffer.swift`: Linux storage is always one contiguous
   copy, so compacting copies the bytes (the custom-allocator path allocates
   scratch, copies in, builds the buffer, then hands the scratch block back;
   empty input returns an empty buffer without touching the allocator).
3. `Calibration.init` used `CGSize.zero` in a default argument, which Swift 6
   rejects without a direct CoreGraphics import (absent on Linux). The default
   now names a same-module `@usableFromInline` constant.
4. One test typo fixed: slice fill `source[1..<4]` with `0` yields
   `[1, 0, 0, 0, 5]`, not `[1, 0, 0, 4, 5]` (the author replaced two `7`s and
   forgot the fill covers all three slice bytes).

| status | before | after |
| --- | ---: | ---: |
| implemented | 3003 | 3003 |
| declared | 237 | 237 |
| deferred | 264 | 264 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +0 rows reclassified (claims repaired, not relabeled). Top test
still `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (6.0%). No test owns more than 40% of implemented rows. Verified on this Mac:
`FRAMEWORK_FANOUT_DELIVERABLE_OK` (was 5 errors before fix 1), product plus all
27 test files compile warnings-clean, and a macOS runner over all 181 cited tests
prints marker-only stdout (`COREMEDIA_MACOS_PROBE_OK`, debug lines on stderr).
The sealed gate's final stage remains Linux-only (`import Glibc` in the generated
runner). No new product files; the guest sources manifest is unchanged.

## Depth pass 2026-09-15 (coremedia prompt: concrete witnesses / family aliases / timing arrays)

No SwiftUI/View overlay rows exist in this module's public surface (zero
`coverage.tsv` IDs mention SwiftUI or View), so the overlay-override clause
has nothing to convert. This pass converts honestly exercisable declared
witnesses with concrete (non-generic) calls plus a small set of deferred
family members:

- `CMWitnessDepthTests.swift#testCMDataBlockBufferConcreteWitnesses` (34 rows)
  and `#testCMDataBlockBufferRegionWitnesses` (52 rows) call `difference`
  (both overloads), `max` / `min` / `sorted` / `contains`,
  `index(offsetBy:limitedBy:)`, `removingSubranges`, `drop(while:)`, both
  `split` forms, `shuffled` / `randomElement` (shape-only assertions),
  `_StringProcessing` `firstRange` / `ranges` / `trimmingPrefix` (both forms),
  Foundation `DataProtocol` `firstRange` / `lastRange` (both arities), and —
  on the read-only host only — `count`, `subscript(...)`,
  `removeFirst` / `removeLast` / `popFirst` / `popLast` (value semantics
  preserved: mutation replaces the shared storage), and mutating
  `trimPrefix` (both forms) on all three byte projections.
- `#testCMOptionSetArrayLiteralWitnesses` forms `EqualityMask`,
  `TimeCode.Flag`, and `FontFace` through array literals (3 rows).
- `#testCMTagAndSampleReferenceInequality` asserts `!=` on `CMTag`,
  `CMTag.Value`, and `CMSampleDataReference` (3 rows; hosts exist in this
  port — prior "host absent" notes were stale).
- `#testCMSampleBufferFamilyWitnesses` names the four `T` typealiases
  (`CMTimebase.T`, `CMBlockBuffer.T`, `CMSampleBuffer.T`,
  `CMFormatDescription.T` — already present in product, previously uncited),
  plus new product members `sampleTimingInfos()` /
  `outputSampleTimingInfos()` (uniform single entry expands across all
  samples, mirroring `sampleTimingInfo(at:)`; output equals sample timings
  — the port stores no trim/derive state) and `taggedBuffers` (always `nil`:
  the port never constructs tagged content). Existing
  `testCMSampleBufferContentTypeAndNotificationKey` and
  `testCMSampleBufferDataReadinessStateMachine` now also cite the matching
  `contentType` / `dataReadiness` property rows (2 rows; members already
  existed and were already exercised).

Kept out (stay declared/deferred as recorded): Foundation
`DataProtocol.copyBytes` / `ContiguousBytes.copy` (keep-list), Combine
`publisher`, Foundation `sorted(using:)` / `compare` / `formatted` (no
`SortComparator` / `FormatStyle` exists for these hosts), the deprecated
optional-`flatMap` on `Buffers` (warns under `-warnings-as-errors`),
DispatchSource timer overloads (live `DispatchSource` aborts libdispatch in
the sealed gate), `CVBufferRef` attachment members (host absent on Linux),
audio/image/pixel/tagged-dynamic APIs (need CoreAudioTypes/CoreVideo),
`simd` calibration matrix, and notification-name string values (unobserved;
guessing is fabrication). `indices(where:)` / `indices(of:)` on
`CMReadOnlyDataBlockBuffer` itself stay declared: the port's
`subscript(range:)` copies into a fresh buffer rebased to zero, so slicing
breaks index stability — verified 2026-09-15 (match at index 1 yields
`1..<1`; trailing matches trap with `Range requires lowerBound <=
upperBound`). The `BlockRegion` projections slice via `Slice` and are exact
(their 4 rows convert). Recorded as a new `oracle-questions.tsv` row; the
fix (view-based slicing) would redesign Collection semantics without an
Apple oracle, so it stays untouched.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3129 | 3230 |
| declared | 131 | 45 |
| deferred | 244 | 229 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +101 (86 declared, 15 deferred).

Top-5 `implemented` evidence distribution after this pass:

1. `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` — 180 (5.6%)
2. `CMCollectionDepthTests.swift#testCMDataBlockBufferCollectionAlgorithms` — 149 (4.6%)
3. `CMFormatDescriptionSurfaceTests.swift#testCMFormatDescriptionMediaSubTypeTable` — 115 (3.6%)
4. `CMCollectionDepthTests.swift#testCMSampleAttachmentsArrayCollectionAlgorithms` — 110 (3.4%)
5. `CMTimebaseAndAlgebraTests.swift#testCMOptionSetAlgebra` — 89 (2.8%)

No test owns more than 40% of implemented rows (`testCMDataBlockBufferRegionWitnesses`
is the largest new citation at 52 rows, 1.6%). Verified on this Mac:
`FRAMEWORK_FANOUT_DELIVERABLE_OK` via the shared validator, product plus all
31 test files compile warnings-clean, and a macOS runner over all 191 cited
tests prints `COREMEDIA_ALL_CITED_MACOS_PROBE_OK` (ObjC duplicate-class notes
on stderr from the system `libswiftCoreMedia.dylib`, as in prior passes). The
sealed gate's final stage remains Linux-only (`import Glibc` in the generated
runner). No new product files; the guest sources manifest is unchanged.

## Depth pass 2026-09-15 (coremedia prompt: copyBytes overloads / notification names)

No SwiftUI/View overlay rows exist in this module's public surface (zero
`coverage.tsv` IDs mention SwiftUI or View), so the overlay-override clause
has nothing to convert here. This pass converts the honestly exercisable
remainder of the declared keep-list plus two deferred pure constants:

- `CMCopyBytesDepthTests.swift#testCMDataBlockBufferCopyBytesOverloads`
  (16 rows) calls all seven `DataProtocol` / `ContiguousBytes` `copyBytes`
  spellings the Apple surface synthesizes (demangled via `swift-demangle` to
  confirm the exact signatures, including the Void-returning
  `ContiguousBytes`-constrained `copyBytes(to:from:)`), on each host that
  carries no custom shadowing overload: `CMReadOnlyDataBlockBuffer` (6 rows),
  its `BlockRegion` (5 rows), and `CMMutableDataBlockBuffer.BlockRegion`
  (5 rows). Every call checks byte fidelity against a known source.
- `CMSampleBufferOverlayTests.swift#testCMSampleBufferDataNotificationNames`
  (2 deferred rows) asserts the Apple-oracle-pinned raw values
  `CMSampleBufferDataFailed` and `FigSampleBufferDataBecameReady` (Xcode macOS
  SDK 26.1 probe 2026-09-15; the `Fig` prefix is unguessable without the
  oracle). New `public static let` members on the existing `CMSampleBuffer`
  overlay; posting and delivery timing stay unobserved.

Kept out (stay declared/deferred as recorded): Foundation
`sorted(using:)` / `compare` / `formatted` (no concrete `SortComparator` /
`FormatStyle` exists for these byte hosts; a throwaway test-only comparator
would exercise nothing Apple-meaningful), Combine `publisher` (no Combine on
Linux), the deprecated optional-`flatMap` on `Buffers` (warns under
`-warnings-as-errors`), `indices(where:)` / `indices(of:)` on
`CMReadOnlyDataBlockBuffer` (slicing breaks index stability; traps),
`CVBufferRef` attachment members (host absent), DispatchSource timer
overloads (live `DispatchSource` aborts libdispatch in the sealed gate),
audio/image/pixel/tagged-dynamic APIs (need CoreAudioTypes/CoreVideo),
`simd` calibration matrix, and notification posting semantics.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3230 | 3248 |
| declared | 45 | 29 |
| deferred | 229 | 227 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +18 (16 declared, 2 deferred).

Top-5 `implemented` evidence distribution after this pass is unchanged (the
new tests cite 16 and 2 rows, 0.5% and 0.1%). No test owns more than 40% of
implemented rows. Leftover deferred rows still need CoreAudioTypes/CoreVideo
(audio/image sample paths, tagged-dynamic pixel content, parameter-set and
single-sample collections), `simd`, DispatchSource timers, hardware/daemons,
or unobserved family-overlay shapes. No Apple service or hardware success was
invented.

## Wave 9 pass 2026-09-15 (color-volume / lens `!=` witnesses)

No SwiftUI/View overlay rows exist in this module's public surface (zero
`coverage.tsv` IDs mention SwiftUI; the 47 `view` matches are the already
implemented `CMStereoView` media constants), so the overlay-override clause
has nothing to convert here. This pass converts the 7 deferred `!=`
witnesses whose hosts exist in this port (prior "host absent" notes were
stale): `ContentColorVolume`, `ColorPrimaries`, `ColorVolume`,
`LensRole` (Apple `Role`), `LensDomain` (Apple `Domain`), `AlgorithmKind`,
and `ExtrinsicOriginSource`, all exercised by the new
`CMWitnessDepthTests.swift#testCMColorVolumeAndLensInequality`. It also
corrects the notes on the 10 `RawRepresentable`-constrained hash defaults
for those hosts (kept deferred): the host exists, but the conditional
default is shadowed by the concrete `Hashable` synthesis, so no focused
test can distinctly exercise that default implementation.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3248 | 3255 |
| declared | 29 | 29 |
| deferred | 227 | 220 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +7 deferred. The new test owns 7 rows (0.2%); no test
owns more than 40% of implemented rows. Leftover declared rows are the
standing keep-list (Foundation `sorted(using:)` / `compare` / `formatted`
with no concrete `SortComparator` / `FormatStyle`, Combine `publisher`,
deprecated optional-`flatMap`, trapping `indices` on the read-only host,
`CVBufferRef` members with no host, DispatchSource timer overloads that
abort libdispatch in the sealed gate). Leftover deferred rows need
CoreAudioTypes/CoreVideo (audio/image sample paths, tagged-dynamic pixel
content, parameter-set and single-sample collections), `simd`, DispatchSource
timers, hardware/daemons, or unobserved family-overlay shapes. No Apple
service or hardware success was invented.

## Wave 10 pass 2026-09-15 (leftover audit: ceiling reached)

No SwiftUI/View overlay rows exist in this module's public surface (zero
`coverage.tsv` IDs mention SwiftUI; the `view` matches are the already
implemented `CMStereoView` media constants), so the overlay-override clause
has nothing to convert here. This pass audits every one of the 29 declared
and 220 deferred rows against the convertibility rules and finds the module
at its honest ceiling:

- The 20 `sorted(using:)` / `compare` / `formatted` / `publisher` witnesses
  need a concrete `SortComparator` / `FormatStyle` / Combine, none of which
exists for these byte hosts on Linux; a throwaway test-only comparator
would exercise nothing Apple-meaningful.
- The deprecated optional-`flatMap` on `Buffers` warns under
  `-warnings-as-errors`, so no cited test may call it.
- `indices(where:)` / `indices(of:)` on `CMReadOnlyDataBlockBuffer` trap
  (slicing rebases indices; verified 2026-09-15).
- `CVBufferRef` attachment members have no host on Linux.
- The 4 DispatchSource timer overloads abort libdispatch when a live
  `DispatchSource` is constructed in the sealed gate.
- All 220 deferred rows need CoreAudioTypes/CoreVideo (audio/image sample
  paths, tagged-dynamic pixel content, parameter-set and single-sample
  collections), `simd`, DispatchSource timers, hardware/daemons, or
  unobserved family-overlay shapes.

No product Swift or test files changed; the guest sources manifest is
unchanged. Structural audit of `coverage.tsv` (3504 rows): every
implemented row cites a well-formed
`test:full/coremedia/tests/agent/*Tests.swift#test*` target that exists as
a top-level synchronous no-argument function, and every declared row cites
an existing `source:` anchor. The sealed gate's deliverable phase cannot
complete in this isolated worktree for reasons outside `full/coremedia/`:
the shared validator resolves `reference/corpus-summary.json`'s source path
to `full/framework-roadmap/framework-roadmap.json`, which is absent from
this worktree (only `coremedia`, `familycontrols`, and `framework-fanout`
ship here); `reference/` is immutable to this lane so the gap cannot be
repaired from inside the framework directory.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3255 | 3255 |
| declared | 29 | 29 |
| deferred | 220 | 220 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +0 (ceiling; 3255/3504 = 92.9% implemented). Top test
still `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (5.5%). No test owns more than 40% of implemented rows. No Apple
service or hardware success was invented.

## Wave 11 pass 2026-09-15 (declared sweep: +4)

No SwiftUI/View overlay rows exist in this module's public surface, so the
overlay-override clause has nothing to convert here. This pass re-audited
all 29 declared rows and converted the 4 generic `CMTimebase`
`DispatchSourceTimer` overloads (`addTimer`, `removeTimer`,
`setTimerNextFireTime`, `setTimerToFireImmediately`) from declared to
implemented. Each now cites a focused synchronous test in the new
`CMDispatchTimerMethodTests.swift` that passes a real (resumed, then
cancelled before release) timer source through the generic method — the
same arm/disarm discipline as the long-passing
`testCMTimebaseDispatchSourceTimersFailClosed` C-entry test — and asserts
the fail-closed `kCMTimebaseError_TimerIntervalTooShort` throw. The throw
path is genuine product behavior (`CMClock.swift` never registers the
source), so this is behavioral evidence, not witness theater. The new file
was compiled with `-warnings-as-errors` and executed 5/5 clean on
aarch64 Linux (Swift 6.2.4) before the coverage flip.

The remaining 25 declared rows stay declared, concurring with the wave-10
audit: 4 two-comparator `sorted(using:)` witnesses name an overload that
does not exist on Linux corelibs; 4 `compare` witnesses need an
`Element: SortComparator` conformance (retroactive `UInt8` or impossible
`AnyObject`) under Linux's signature; 4 `publisher` witnesses need
Combine, absent on Linux; 4 single-comparator `sorted(using:)` / 4
`formatted` witnesses would need throwaway test-only comparators/styles
that exercise no product behavior beyond already-covered iteration; 2
`indices` witnesses on `CMReadOnlyDataBlockBuffer` trap per the oracle
note; 2 `CVBufferRef` attachment members have no host type; 1 deprecated
optional-`flatMap` warns under `-warnings-as-errors`. All 220 deferred
rows still need CoreAudioTypes/CoreVideo, `simd`, hardware/daemons, or
unobserved overlay shapes. No Apple service or hardware success invented.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3255 | 3259 |
| declared | 29 | 25 |
| deferred | 220 | 220 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +4 (3259/3504 = 93.0% implemented). The new test file
owns 4 rows (0.1%). Top test still
`CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (5.5%). No test owns more than 40% of implemented rows.

## Wave 12 pass 2026-09-15 (leftover audit: ceiling re-affirmed)

No SwiftUI/View overlay rows exist in this module's public surface, so the
overlay-override clause has nothing to convert here. This pass re-audited
all 25 declared and 220 deferred rows against the convertibility rules
and re-affirms the honest ceiling: no declared row compiles into an
honestly exercisable synchronous test, and no deferred row can be
implemented in-process without hardware/daemon or the absent
CoreAudioTypes/CoreVideo/`simd`/Combine dependencies.

- 8 `sorted(using:)` witnesses (4 two-comparator + 4 single-comparator)
  need a concrete `SortComparator`; none exists for these byte hosts on
  Linux, and a throwaway test-only comparator would exercise no product
  behavior.
- 4 `compare` witnesses need an `Element: SortComparator` conformance
  (retroactive `UInt8` or impossible `AnyObject`) under Linux's signature.
- 4 `formatted` witnesses need a concrete `FormatStyle`; none exists.
- 4 `publisher` witnesses need Combine, absent on Linux.
- 2 `indices(where:)` / `indices(of:)` witnesses on
  `CMReadOnlyDataBlockBuffer` trap (slicing rebases indices; verified
  2026-09-15).
- 2 `CVBufferRef` attachment members have no host type on Linux.
- 1 deprecated optional-`flatMap` on `Buffers` warns under
  `-warnings-as-errors`, so no cited test may call it.
- All 220 deferred rows need CoreAudioTypes/CoreVideo (20 audio/image
  C APIs, AudioBufferList/packet-description paths, tagged-dynamic pixel
  content, parameter-set and single-sample collections), `simd`,
  DispatchSource timers, hardware/daemons, or unobserved overlay shapes.

No product Swift, test, manifest, or coverage rows changed in this pass.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3259 | 3259 |
| declared | 25 | 25 |
| deferred | 220 | 220 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +0 (ceiling; 3259/3504 = 93.0% implemented). Top test
still `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (5.5%). No test owns more than 40% of implemented rows. No Apple
service or hardware success invented.

## Wave 13 pass 2026-09-18 (async leftover audit: ceiling re-affirmed)

No SwiftUI/View overlay rows exist in this module's public surface (zero
`coverage.tsv` IDs mention SwiftUI; the `view` matches are the already
implemented `CMStereoView` media constants), so the overlay-override clause
has nothing to convert here. This pass answers the wave-13 prompt directly:
the sealed runner now awaits top-level `func test*() async`, so every one
of the 25 declared and 220 deferred rows was audited for async-shaped
leftover that completes in-process (empty AsyncSequence, immediate throw).
Result: `coverage.tsv` contains zero async identifiers (no `async`,
`AsyncSequence`, `AsyncStream`, continuation, or actor rows), so there is
no async-shaped leftover to convert — the prompt's "~0" estimate is
exactly 0.

- The 25 declared rows are all synchronous stdlib witnesses already ruled
  unconvertible in waves 10/12: 8 `sorted(using:)` (no concrete
  `SortComparator` on Linux), 4 `compare` (needs `Element:
  SortComparator`), 4 `formatted` (no concrete `FormatStyle`), 4
  `publisher` (no Combine on Linux), 2 trapping `indices` on
  `CMReadOnlyDataBlockBuffer`, 2 `CVBufferRef` members with no host type,
  1 deprecated optional-`flatMap` (warns under `-warnings-as-errors`).
  None has an async spelling; none completes in-process as async.
- The 220 deferred rows need CoreAudioTypes/CoreVideo (20 audio/image C
  APIs whose signatures cannot even be spelled without
  `AudioStreamBasicDescription` / `AudioBufferList` / `CVImageBuffer`),
  `simd`, DispatchSource timers, hardware/daemons, or unobserved overlay
  shapes. None is an in-process empty-sequence or immediate-throw
  candidate; hardware/daemon success stays fail-closed per contract.
- Structural audit re-run: all 3259 implemented rows cite well-formed
  `test:full/coremedia/tests/agent/*Tests.swift#test*` targets that exist
  as top-level `func test*()` functions (0 missing, 0 bad-format); all 25
  declared rows cite existing `source:` anchors. Product sources typecheck
  clean under `swiftc -typecheck -warnings-as-errors` (Apple Swift 6.2.1).

No product Swift, test, manifest, or coverage rows changed in this pass.

| status | before | after |
| --- | ---: | ---: |
| implemented | 3259 | 3259 |
| declared | 25 | 25 |
| deferred | 220 | 220 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: +0 (ceiling; 3259/3504 = 93.0% implemented). Top test
still `CMCollectionDepthTests.swift#testCMFormatDescriptionExtensionsCollectionAlgorithms` —
180 (5.5%). No test owns more than 40% of implemented rows. No Apple
service or hardware success invented.
