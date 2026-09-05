# AVKit corpus surface — isolated Linux starting point

Worktree `agent/fw-avkit`. Isolated host module under `full/avkit/` (not
wired into the shared guest package). No scene pixel rule: AVKit is not
imported by `openrender` scenes.

## Before / after

| gate | before | after |
|---|---|---|
| `full/avkit` coverage | 99 implemented / 912 declared (1011 IDs) | **990 implemented / 21 declared** |
| Host gate (`test_host.sh`) | seed only | **FRAMEWORK_FANOUT_HOST_OK** (`swift:6.2-noble`) |
| Catalyst | 124/124 | **124/124** (this branch; no render rule) |
| iOS suite | 112/113 (`corner_radius`) | 112/113 (not recaptured; no UIKit source change) |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393 | **unchanged** (this branch) |
| Linux `swift:6.2-noble` openrender | — | **green** (197.88 s) |

The 21 remaining `declared` rows are synthesized `Hashable` / `OptionSet` /
`SetAlgebra` witnesses citing `AVKitSurface.swift`. `AVPlayerViewController`,
`AVPictureInPictureController`, and `AVPlaybackSpeed` are nondeferred.

## Probe

Private simulator `OpenUIKit-Chrome-fw-avkit` (iPhone 16 / iOS 26.1,
locale `en_US`). Apple AVKit on-device, not the Linux module.

## Measured rules (now in the Linux module)

`AVPlaybackSpeed.systemDefaultSpeeds` is one stable array of five entries:

| i | rate | localizedName | localizedNumericName |
|---|------|---------------|----------------------|
| 0 | 2.0 | Double | `2×` (U+00D7) |
| 1 | 1.5 | Faster | `1.5×` |
| 2 | 1.25 | Fast | `1.25×` |
| 3 | 1.0 | Normal | `1×` |
| 4 | 0.5 | Half | `0.5×` |

Custom `localizedNumericName`: whole numbers drop `.0`; suffix U+00D7.
`AVPlayerViewController.speeds === systemDefaultSpeeds`. A fresh controller's
`selectedSpeed === systemDefaultSpeeds[3]`. `selectSpeed` is object identity;
selecting a list member writes `player.defaultRate`. Assigning a player with
`defaultRate` 1.5 selects the 1.5 entry.

PVC defaults match the probe (and the iPhoneOS 26.1 header where it names
one): `showsPlaybackControls` true, `showsTimecodes` false,
`videoGravity` `.resizeAspect`, `isReadyForDisplay` false, `videoBounds`
zero, `contentOverlayView` non-nil, `allowsPictureInPicturePlayback` true,
`allowsVideoFrameAnalysis` true, `videoFrameAnalysisTypes.default` (raw 1),
`canStartPictureInPictureAutomaticallyFromInline` false,
`updatesNowPlayingInfoCenter` true, `entersFullScreenWhenPlaybackBegins`
false, `exitsFullScreenWhenPlaybackEnds` false, `requiresLinearPlayback`
false, `preferredDisplayDynamicRange.automatic`.

PiP: `isPictureInPictureSupported() == false`; `init(playerLayer:)`
returns nil; `init(contentSource:)` still constructs; `start` / `stop`
stay inactive and **do not** call the delegate (no `failedToStart`). Linux
matches that path.

`AVPlayerView` is macOS-only (`AVKit.h` `#if TARGET_OS_OSX`) and is not in
this iPhoneOS public surface. No coverage row.

Isolated host has Foundation only. `AVPlayer.defaultRate` (Apple default
1.0) is a module-local lookalike under `#if !canImport(AVFoundation)` so
`selectSpeed` can write it. Real AVFoundation owns the property on a later
EC2 integration build.

`AVInterstitialTimeRange` is `NSCopying` + `NSSecureCoding`. Linux keeps
`init(timeRange:)` (tvOS-designated / `API_UNAVAILABLE(ios)` on Apple).
Archive keys are a host overlay, not Apple-dumped.

## Fail-closed (unchanged policy)

No AirPlay picker, PiP window, capture hardware, or AVKitCore. Route
selection completes once after return with `(false, .none)`. Custom
capture-sound URLs throw `AVKitError.unknown`. Input picker `present` /
`dismiss` keep `isPresented` false. `VideoPlayer` labels the selected URL
and rate; it does not decode frames.

SwiftUI `View` members on `VideoPlayer` are identity no-ops. Focused tests
plus `testVideoPlayerViewSurfaceNoops` type-check the overlay.

## OPEN

See `full/avkit/oracle-questions.tsv`: Apple interstitial archive keys;
`selectSpeed` then assign player / KVO of `defaultRate`; full-screen
delegate order; `systemDefaultSpeeds` names off `en_US`; route-selection
queue; capture-sound error code; input-picker presentation sequencing;
`VideoPlayer.body` update / z-order; `AVKitError` hash payload.
