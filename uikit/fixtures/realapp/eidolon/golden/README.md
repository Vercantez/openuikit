# Eidolon (Kiosk) first screen: real-UIKit golden, iOS 26.1

The unmodified app sources and storyboards of artsy/eidolon `44486ed`, built
with Apple's UIKit and launched on a fresh simulator. This is the reference the
port's first screen is scored against.

| file | sha256 | what |
|---|---|---|
| `eidolon-window-render-1024x768@2x.png` | `a6731f7c3087ba8e8c4d88a4764c9416925de6553ad65900bb685f5d689e232e` | **the golden.** 2048×1536: the key window drawn with `drawHierarchy(in:afterScreenUpdates:false)` at scale 2, opaque (`recipe/render.lldb`), after the t=30 s shot |
| `eidolon-t2s.png` | `5921688b9d89a99d186630ea387f30e696c5c156ff16b9eda968711d14a4d295` | `simctl io screenshot` at t=2 s (1668×2420 portrait framebuffer, content letterboxed in landscape). The t=5, 15 and 30 s screenshots are byte-identical to it, so the screen is settled by 2 s |
| `logs/lldb-dump.txt` | | window, `_printHierarchy`, `recursiveDescription`, `_autolayoutTrace` of the live app (frames for masks and layout comparison) |
| `logs/lldb-orient.txt` | | scene geometry: 1024×768 pt, `landscapeRight (3)`, native 1536×2048, scale 2 |
| `recipe/` | | the complete capture recipe (below) |

## Device and toolchain

- Xcode 26.1 (17B55), SDK `iphonesimulator26.1` (23B77), Debug, `ARCHS=arm64`,
  `IPHONEOS_DEPLOYMENT_TARGET=12.0` (xcodebuild overrides; the pods' 8.0/9.0
  targets are refused by Xcode 26), `CODE_SIGNING_ALLOWED=NO`.
- Runtime iOS 26.1 (23B86), device type `iPad-Pro-11-inch-M4-8GB`, created fresh
  and deleted after capture (`eidolon-golden-throwaway`). Kiosk's Info.plist
  allows landscape only, so the window is 1024×768 pt landscapeRight.
- Captured 2026-09-22.

## What the screen shows, and why it is deterministic

`ListingsViewController`: the orange corner, the sale title `CLOSED`,
`REGISTER TO BID`, the six sort tabs (GRID selected), and the masonry grid of
lots (artist, title/date, dotted rule, bid, `BID`, `MORE INFO >`), plus the
`HELP` button.

The keys are the `fastlane oss_keys` values (`"-"`), so
`APIKeys.sharedKeys.stubResponses` is true (`APIKeys.swift:30`, key length
below the minimum) and Moya answers every request from the app's own bundled
`Kiosk/Stubbed Responses/*.json` (`Networking.swift:138`, `.immediate`
stubbing). **The listings are the app's bundled sample data, not network data
and not fabricated.** The artwork image URLs in that sample data
(`stagic*.artsy.net`) no longer resolve (`sim-kiosk` log: "server with the
specified hostname could not be found"), so every image view keeps its
placeholder background. Nothing on the screen depends on a live service; the
t=2/5/15/30 s screenshots are identical.

## Deviations from the app's own build (all in `recipe/`)

| lock entry | golden | why |
|---|---|---|
| `Keys` (cocoapods-keys plugin) | `KeysPod/gen_keys.sh`: same class/property names, every value `"-"` | the plugin needs secrets; `"-"` is the repo's own OSS setup |
| `CardFlight-v4` 4.3.1 (closed binary) | `CardFlightShim/`: call-site-derived, fail-closed (no reader, no token, no transaction) | the lock's repository is gone |
| `Stripe` 12.1.0 | `StripeShim/`: fail-closed (no network, no token, validator never valid) | payments must fail closed |
| `HockeySDK-Source`, `ARAnalytics/HockeyApp` | omitted | vendored CrashReporter has no arm64-simulator slice; with `"-"` keys HockeySDK disables itself |
| `Analytics` 3.6.9 | 4.1.8 (resolved by `pod install` against trunk once the Hockey subspec was removed; `Podfile.lock.golden`) | Segment analytics, inert with the `"-"` write key; no view code |
| RxCocoa 4.1.2 DataSources | the same overlay patches the port applies (`Sources/EidolonDependencies/overlays/`, `step_patch.sh`) | Swift 6.2.1 rejects a redundant `override init` (repro in `recipe/repro/`) |

No app source file is modified.

## Reproduce

```sh
export EIDOLON_SRC=/path/to/artsy/eidolon@44486ed   # read-only; copied
export EIDOLON_GOLDEN_WORK=$(mktemp -d)             # CocoaPods, DerivedData, shots, logs
bash uikit/fixtures/realapp/eidolon/golden/recipe/capture.sh
```

`capture.sh` takes `/tmp/conformance_sim.lock` (the conformance probe's
protocol) around boot → capture → shutdown and deletes the device on exit.
Requires CocoaPods (run with `CI=1`, which selects the lock's `Artsy+UIFonts`).
