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
  `AccessDataBytes` copying into the caller temporary. Interior
  `GetDataPointer` fails closed (`kCMBlockBufferUnallocatedBlockErr`).
- `CMSampleBuffer` create/ready/copy/timing/size/attachments/invalidate.
  Image-buffer and AudioBufferList entry points stay deferred until
  CoreVideo/CoreAudioTypes are present.
- `CMFormatDescription` media type/subtype, video dimensions, extensions,
  equality, and the Swift overlay CFString wrappers (`FieldDetail`,
  `YCbCrMatrix`, `ColorPrimaries`, `TransferFunction`, `AttachmentKey`,
  MPEG-2 profile FourCCs from `CMFormatDescription.h` char literals).
- `CMMetadata` identifier split (`keyspace/key`) and data-type registry.
- Public `kCMTime*` / `kCMSampleAttachment*` / `kCMFormatDescription*`
  CFString keys (suffix payloads; color aliases match this repo's CoreVideo
  strings) and OSStatus integers from the public headers.

## Fail-closed

- Invalid timescale, NaN seconds, mixed infinities, different epochs on add,
  empty/malformed buffer offsets, and invalidated sample buffers fail closed.
- Big-endian sample-description bridges and H.264/HEVC parameter-set
  parsers return `kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor`
  / `kCMFormatDescriptionError_InvalidParameter`: there is no QuickTime
  decoder on this isolated Linux gate.
- Arbitrary payload bytes are stored as opaque sample data; they are not
  treated as a decoded bitstream.

## Deferred

- `CMBufferQueue`, `CMSimpleQueue`, `CMMemoryPool`, `CMTag`,
  `CMReadySampleBuffer`, stereo/packing, and tagged-buffer types.
- APIs that require `AudioStreamBasicDescription` / `CVImageBuffer` until
  the central build supplies CoreAudioTypes and CoreVideo.
- Remaining Swift overlay Collection/camera-calibration helpers on
  `CMFormatDescription.Extensions.Value`.
- C-callable `@_cdecl` entry points are not emitted: Swift `CMTime` structs
  are not Clang-imported C types. Layout is reconstructed in
  `tests/agent/cm_value_layout.c`.
