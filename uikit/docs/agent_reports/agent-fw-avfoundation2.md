# AVFoundation SDK depth, second pass (`agent/fw-avfoundation2`)

Base: `origin/agent/fw-avfoundation` (first pass, refused for coverage honesty).
Scope: `full/avfoundation/` plus this report. No uikit sources, no `reference/`
or `tests/acceptance/` edits, no pin files.

## What was refused

`coverage.tsv` marked **1113** identifiers `implemented`, but **434** of **915**
non-enum implemented rows cited one test
(`tests/agent/AVPlaybackTests.swift#testAVCaptureDeviceDeclaredSurface`) — a
bulk relabel of the capture surface as "declared-surface implemented". Three
other `*DeclaredSurface` tests plus `testAVCaptureSessionFailClosed` cited
another 362 non-enum rows the same way.

Invented success is worse than a marked gap. `implemented` evidence must be a
focused test of that identifier's behaviour. Enum/option-set members may share
one table-driven raw-value test; nothing else may. The merge path refuses any
single test cited by more than 150 non-enum rows or more than 40% of them.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| main (seed) | 156 | 5164 | 312 | 5320 |
| first pass (refused) | 1113 | 4246 | 273 | 5359 |
| this pass | **277** | **5086** | 269 | 5363 |

Public surface is still 5632 precise IDs. The medium-full floor is 2816
nondeferred; 5363 remains well above it.

Every row whose only evidence was a bulk/surface test is `declared` again with
`source:full/avfoundation/<file>.swift#Symbol` (or stays `deferred` when the
isolated host still cannot name the type). The four `*DeclaredSurface`
functions are deleted.

### Evidence distribution (top 5 tests by row count)

1. `testAVErrorCodeMaciosRawValues` — 89 (85 enum cases of `AVError.Code` plus
   domain/errorCode; table-driven raw values from pinned `dotnet/macios`)
2. `testAVPlayerStatusAndTimeControl` — 21
3. `testAVAssetLoadFailClosed` — 21
4. `testAVPlayerItemStateMachine` — 17
5. `testAVCaptureAuthorizationDenied` — 14

26 distinct cited tests. 277 implemented rows. Non-enum implemented: 151.
Largest non-enum citation is `testAVAssetLoadFailClosed` at **18 / 151 = 11.9%**.
No test exceeds 150 non-enum rows or 40%.

First-pass top 5 (for the refusal): `testAVCaptureDeviceDeclaredSurface` 493,
`testAVPlayerDeclaredSurface` 110, `testAVPlayerItemDeclaredSurface` 105,
`testAVCaptureSessionFailClosed` 97, `testAVErrorCodeMaciosRawValues` 89.

## Behaviour this pass actually tests

Cited Apple documentation, not a comparison-score search.

1. **AVPlayer transport.** Apple `AVPlayer.play()` begins playback at
   `defaultRate` (initial 1.0)
   (https://developer.apple.com/documentation/avfoundation/avplayer/play()).
   Measured `testPlayerVolumeMuteAndPolicy`: `defaultRate` 1.5 → `play()` rate
   1.5. `timeControlStatus` is `.playing` iff `rate != 0`
   (https://developer.apple.com/documentation/avfoundation/avplayer/timecontrolstatus-swift.property).
   Empty player `status` is `.unknown`; a URL item is `.readyToPlay`
   (state-only, no decode). Paused `seek(to:)` keeps `CMTime` identity;
   completion-handler / async / tolerance seeks finish; date seeks return false
   without a decoder.
2. **Observers and item end.** Periodic / boundary observers fire from a 20 ms
   `DispatchTime` pulse. `AVPlayerItem.didPlayToEndTimeNotification` posts when
   injected duration elapses. `AVQueuePlayer` insert/advance/remove ordering is
   process-local.
3. **AVAsset.load.** `AVAsset.load(.duration, .tracks, .isPlayable)` returns
   `.invalid`, `[]`, `false`. `status(of:)` is `.notYetLoaded` until
   `load` / `loadValuesAsynchronously`. Host SPI may inject duration; that is
   not Apple decode.
4. **AVPlayerLayer.** Default `videoGravity` is
   `AVLayerVideoGravityResizeAspect` (Apple `AVLayerVideoGravity` C-string).
   `isReadyForDisplay` is false. `copyDisplayedPixelBuffer()` is nil.
5. **Capture authorization.** Apple `AVAuthorizationStatus` NS_ENUM:
   notDetermined=0, restricted=1, denied=2, authorized=3. Linux has no prompt:
   `authorizationStatus(for:)` is `.denied`, `requestAccess(for:)` is false,
   `devices()` / `DiscoverySession.devices` / `default(for:)` are empty
   (https://developer.apple.com/documentation/avfoundation/avcapturedevice/authorizationstatus(for:)).
   `AVCaptureSession.startRunning()` leaves `isRunning` false.
6. **AVAudioSession (extra portable; iOS 26.1 places it in AVFAudio).**
   Category/mode/options/`setActive` are process-local. No hardware:
   `currentRoute` inputs/outputs empty, `outputVolume` 0. Changing category
   posts `routeChangeNotification` with documented keys
   `AVAudioSessionRouteChangeReasonKey` (`.categoryChange` = 3) and
   `AVAudioSessionRouteChangePreviousRouteKey`
   (https://developer.apple.com/documentation/avfaudio/avaudiosession/routechangenotification).
   Interruptions are not invented; host SPI posts
   `AVAudioSessionInterruptionTypeKey` / `AVAudioSessionInterruptionOptionKey`
   (https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionnotification).
   `AVAudioPlayer` runs a silent clock.

`avfoundation_guest_sources.txt` is unchanged (23 sorted product sources).

## Open (oracle-questions.tsv)

Seek completion-handler queue, `allowsExternalPlayback` default vs no-hardware
false, remaining `AVFileType` UTIs, Darwin notification C-string ABI, and
whether Darwin `setCategory` posts `routeChangeNotification` on the calling
thread when only options/mode change. No parameter search against comparison
scores.

## Gate

Isolated Linux `swiftc -warnings-as-errors` of `libAVFoundation.dylib` plus 26
cited tests in `docker exec uikit-linux` (Swift 6.2.4). Main's
`validate_seed.py` plus `generator-lineage.json` (not committed; this
worktree's validator still lacks lineage) accepted the sealed generator
digest `e44f6bde…` against checked-in `e56ee6e7…`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```
