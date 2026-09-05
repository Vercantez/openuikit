# AVFoundation SDK depth (`agent/fw-avfoundation`)

Isolated Linux `AVFoundation` in `full/avfoundation/`. No scene pixels. No
vendor-pin edit.

## Before / after (coverage.tsv)

| status | before | after |
|---|---|---|
| implemented | 156 | **1113** |
| declared | 5164 | 4246 |
| deferred | 312 | 273 |
| total | 5632 | 5632 |

Named families are nondeferred: `AVPlayer`, `AVPlayerItem`, `AVQueuePlayer`,
`AVPlayerLayer` (was 9 deferred), `AVAsset`, `AVURLAsset`. `AVAudioSession` /
`AVAudioPlayer` are extra portable surface (iOS 26.1 places them in AVFAudio,
not this module's census).

## What was measured (`docker exec uikit-linux`, Swift 6.2.4)

- `AVPlayer.play()` applies `defaultRate` (1 → rate 1). `timeControlStatus` is
  `.playing` iff `rate != 0`. Empty player `status` is `.unknown`; a URL item
  is `.readyToPlay` (state-only, no decode).
- Paused `seek(to: CMTime(value: 1, timescale: 2))` round-trips the same
  `CMTime`. Invalid seeks are ignored. Date seeks return false (no decoder).
- Periodic / boundary observers fire from a 20 ms `DispatchTime` pulse.
  `AVPlayerItemDidPlayToEndTimeNotification` posts when injected duration
  elapses.
- `AVAsset.load(.duration, .tracks, .isPlayable)` returns `.invalid`, `[]`,
  `false`. `isPlayable` stays false. Host SPI may inject duration; that is
  not Apple decode.
- `AVPlayerLayer` default `videoGravity` is `AVLayerVideoGravityResizeAspect`.
  `isReadyForDisplay` is false. `copyDisplayedPixelBuffer()` is nil.
- `AVCaptureDevice.authorizationStatus(for:)` is `.denied`.
  `requestAccess(for:)` is false. `devices()` is empty.
  `AVCaptureSession.startRunning()` leaves `isRunning` false.
- `AVAudioSession.currentRoute` is empty and `outputVolume` is 0 after
  `setCategory(.playAndRecord, mode: .voiceChat)`. `AVAudioPlayer` runs a
  silent clock. `AVSpeechSynthesizer.speak` returns false.

## Open (oracle-questions.tsv)

Seek completion-handler queue, `allowsExternalPlayback` default vs no-hardware
false, remaining `AVFileType` UTIs, and whether Darwin notification overlays
share the C-string ABI. No parameter search against comparison scores.

## Gate

`docker exec uikit-linux` Swift 6.2.4: 34 focused tests printed
`AVFOUNDATION_AGENT_RUNTIME_OK`. Isolated host gate:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

Provenance check used the generator blob sealed in
`reference/framework.json` (`6fc0f17b`, SHA-256 `e44f6bde…`). Current
`scripts/framework-fanout/generate_seed_v2.py` on main is a later hash and
was not modified.
