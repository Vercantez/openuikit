# VideoToolbox Linux lane

This directory is a Linux starting implementation of Apple's public
`VideoToolbox` C API, reconstructed after the fan-out branch
`cursor/port-videotoolbox-to-linux-6878` (legacy PR #52) could not be
fetched (the GitHub App token cannot read `openuikit-linux-platform`)
and `origin/main` had no `full/videotoolbox/` seed (wave-3 seeds were
never merged into the monorepo).

## What is real

- Named `OSStatus` constants from the pinned `dotnet/macios` `VTDefs.cs`
  mapping of `VTErrors.h`.
- Decode/encode info and frame option-set flags with the documented bit
  positions.
- Fail-closed compression and decompression session creation
  (`kVTCouldNotFindVideoEncoderErr` / `kVTCouldNotFindVideoDecoderErr`).
- Software pixel-transfer and pixel-rotation sessions that accept
  property get/set in process memory. `TransferImage` / `RotateImage`
  return not-supported; they do not convert pixels.
- `VTCopyVideoEncoderList` returns an empty list.
- Hardware-decode and MV-HEVC queries are false.
- Multipass storage, frame silos, RAW processing, motion estimation, and
  HDR per-frame metadata creation fail closed.

## What is fail-closed / deferred

- No encoder, decoder, or pixel-format converter runs on this host.
- CoreMedia / CoreVideo sample-buffer and pixel-buffer identities are
  not imported in the isolated gate; public functions take
  `OpaquePointer?` instead of inventing `CMSampleBuffer` / `CVPixelBuffer`
  types.
- Property-key `String` payloads are the public C identifiers. Darwin
  `CFSTR` bytes were not observed and are not claimed.
- `GetTypeID` returns `0`. Darwin `CFTypeID` values are unobserved.
- macios numeric codes at `-12907` / `-12908` disagree with some public
  header copies of `kVTCouldNotFindVideoEncoderErr`; an oracle question
  records that conflict.

Sources listed in `videotoolbox_guest_sources.txt` compile to
`libVideoToolbox.dylib`.
