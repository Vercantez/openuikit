# Cinematic

Linux starting point for Apple's public `Cinematic` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and the
read-only `dotnet/macios` Cinematic bindings. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success with guest AVFoundation, CoreMedia, Metal, or Apple cinematic video.

## Depth pass 2026-09

This is a fresh seed: 237 exact public identifiers, floor 119 nondeferred,
lane `medium-full`.

Coverage after this pass: **231 implemented / 6 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 evidence distribution (share of the 231 implemented rows):

1. `CNEnumTests.swift#testCNDetectionTypeRawValues` — 13 (5.6%, enum members)
2. `CNEnumTests.swift#testCNSpatialAudioRenderingStyleRawValues` — 11 (4.8%, enum members)
3. `CNCinematicErrorTests.swift#testCNCinematicErrorCodeRawValues` — 9 (3.9%, enum members plus `init(rawValue:)`)
4. `CNCinematicErrorTests.swift#testCNCinematicErrorInitUserInfoAndCustomNSError` — 8 (3.5%)
5. `CNAssetInfoTests.swift#testCNAssetInfoHostUnparsedTrackLayout` — 8 (3.5%)

Tied at 8 citations: `testCNScriptFrameAtTime`. No non-enum test is cited by
more than 40% of the remaining implemented rows.

## What is real

- `CNCinematicError.Code` raw values match pinned macios (`unknown = 1` …
  `cancelled = 7`). `CNCinematicErrorDomain` is the token
  `CNCinematicErrorDomain`. Stored `userInfo` is preserved; hashing uses the
  code only; `Code ~= error` matches `CNCinematicError` instances.
- `CNDetectionType`, `CNRenderingQuality`, `CNSpatialAudioContentType`, and
  `CNSpatialAudioRenderingStyle` use the macios integers, including detection
  gaps (`catHead = 9`, `autoFocus = 100`).
- `CNDetectionID` / `CNDetectionGroupID` are `Int64` newtypes with both
  `init(rawValue:)` and `init(_:)`.
- `CNDetection` stores time, type, normalized rect, and disparity. Public init
  leaves identifiers nil. `disparity(in:…)` returns the prior or `0`.
- `CNDecision` records strong/user flags and `FocusDetectionID` (`.single` /
  `.group`). Constructed decisions are not user decisions until a script adds
  them.
- `CNCustomDetectionTrack` assigns identifiers, queries `atOrBefore` /
  `nearest` / `in`, and optionally inserts one linear midpoint when `smooth`
  is true. `CNFixedDetectionTrack` is constant-disparity (`.fixedFocus` or the
  original detection's type).
- In-memory `CNScript` edits user decisions and added tracks, answers
  decision/frame queries, and round-trips a Linux-local
  `openuikit.cinematic.script-changes.v1` JSON. That codec is not Apple's
  `dataRepresentation`.
- `CNRenderingSession.encodeRender` returns `false`. Pixel-format lists are
  empty. Frame attributes from sample buffers / timed metadata are `nil`.
- `CNObjectTracker.isSupported` is `false`; find/start/continue fail closed.
- `CNAssetSpatialAudioInfo.isSupported` is `false`; the completion-handler
  check reports `false` synchronously.

## Fail-closed boundaries

Linux has no cinematic asset parser, Metal cinematic shaders, object-tracker
ML, or spatial-audio mix daemon.

- `CNAssetInfo.init(asset:)`, `CNScript.init(asset:changes:progress:)`,
  `CNRenderingSession.Attributes.init(asset:)`, and
  `CNAssetSpatialAudioInfo.init(asset:)` throw `.unsupported`.
- `CNAssetInfo.isCinematic(asset:)` and
  `assetContainsSpatialAudio(asset:)` are async `false`.
- `CNCompositionInfo.insertTimeRange` throws `.unsupported`.
- `AVMutableComposition.addTracks` returns a host placeholder and does not
  mutate cinematic tracks.
- Isolated-host `CMTime` / `AVAsset` / `CVPixelBuffer` / `MTLCommandQueue`
  lookalikes live behind `canImport` so the sealed gate can compile. They are
  not ports of those modules.

The six async-only loaders are `declared` because the sealed runner cannot
`await`. Their fail-closed bodies still throw or return false.

## Still open

See `oracle-questions.tsv` for Darwin error-domain bytes, VoiceOver labels,
disparity sampling, cinematic load error codes, Metal pixel formats, tracker
availability, spatial-audio defaults, `isUserDecision` on init, and transition
ramp timing.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```
