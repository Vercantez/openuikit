# AVFoundation (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AVFoundation` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It is not wired into the shared guest package;
a passing isolated host gate is not integrated Linux success and is not Apple
media-pipeline behavior.

The isolated host compile is Foundation-only. CoreMedia, CoreVideo,
CoreGraphics, and CoreImage types used in signatures are host lookalikes behind
`canImport`, not public substitute modules.

## What is real

- `AVPlayer` stores item, rate, defaultRate, volume, mute, display-sleep, and
  background-playback policy. `play()` sets rate to 1, `pause()` sets rate to 0,
  `seek(to:)` keeps the last valid `CMTime`, and `replaceCurrentItem(with:)`
  clears rate and time. No frames are decoded or displayed.
- `AVURLAsset` / `AVPlayerItem` keep the caller URL. `AVFileType.mp4` / `.mov` /
  `.m4a` use the well-known UTIs already present in this lane.
- `AVAssetExportSession.init(asset:presetName:)` is nil for an empty preset.
  `export(to:as:)` is a portable fail-closed entry: without a host SPI handler it
  throws `AVFoundationPortableError.exportUnavailable` and sets `status` to
  `.failed`. `cancelExport()` sets `.cancelled`. Status raw values are 0...5.
- `AVAssetImageGenerator.generateCGImageAsynchronously` calls the completion
  handler with `frameGenerationUnavailable` when no host frame handler is
  installed. Delivery is synchronous on this host.
- `AVMakeRect(aspectRatio:insideRect:)` is an aspect-fit rectangle centered in
  the bounds; non-positive geometry returns `.zero`.
- `AVError.Code` raw values match the pinned `dotnet/macios` `AVError` enum.
  `AVFoundationErrorDomain` is the string `AVFoundationErrorDomain`.
- `AVCaptureDevice.devices()` is empty. `lockForConfiguration()` throws
  `mediaServiceUnavailable`.
- `AVPlayerAudiovisualBackgroundPlaybackPolicy` raw values are automatic=1,
  pauses=2, continuesIfPossible=3.
- IceCubes-facing `AVAudioSession` category/active state is process-local and
  does not talk to a session daemon. It is extra portable surface; iOS 26.1
  places `AVAudioSession` in AVFAudio, not this module's public census.

## Fail-closed / deferred

No camera, encoder, FairPlay, AirPlay, or export backend exists on this host.
Stubs compile so the graph can be reviewed; they do not invent hardware or
service success.

Deferred on this host:

- `AVPlayerLayer`, `AVCaptureVideoPreviewLayer`, `AVSynchronizedLayer`,
  `AVSampleBufferDisplayLayer` (must subclass `CALayer`)
- `AVAssetDownloadTask`, `AVAggregateAssetDownloadTask`,
  `AVAssetDownloadURLSession` (must subclass `URLSession` types)
- `UTType`-typed members (no UniformTypeIdentifiers on the isolated host)
- Metal / simd / UIKit / Core Image filter graphs that the host cannot name
- NSCoder / NSValue CoreMedia overlay helpers
- Opaque `some AsyncSequence` returns

String constants generated from the graph use the public identifier as a Linux
payload unless a focused test records a corroborated value. That is a
declaration, not Apple C-string ABI.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
