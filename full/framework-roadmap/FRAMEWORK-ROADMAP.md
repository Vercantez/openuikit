# Apple framework port roadmap

This is a source-unchanged inventory of direct imports in committed Git blobs at the 20 pinned app revisions. It is a roadmap input, not a claim that an Xcode project links or launches on Linux.

## Scope and evidence

- 20 pinned repositories; 31151 tracked shipping-source candidates; 80810 direct import declarations.
- Worktree source bytes are ignored. Git tree/blob objects at the pinned commits are the input.
- Tests, examples, demos, fixtures, docs, scripts, tools, and benchmark paths are excluded by the exact policy in the JSON. Committed vendored product source is included.
- The path policy is reproducible but is not a universal Xcode/Bazel target parser. Static imports do not prove transitive linkage or launch-time reachability.
- iPhoneOS/runtime port candidacy is an exact allowlist decision. Non-iOS Apple/developer modules and Swift-toolchain modules are explicit separate categories. App-local and third-party modules remain grouped because an import name cannot reliably distinguish them. Private-style/lowercase unknowns are flagged uncertain.

## iPhoneOS/runtime port candidates by app coverage

| Rank | Module | Apps / 20 | Files | Focus main target | Focus repository |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | `Foundation` | 20 | 13668 | 50 | 66 |
| 2 | `UIKit` | 20 | 8132 | 75 | 101 |
| 3 | `SwiftUI` | 19 | 3704 | 9 | 28 |
| 4 | `WebKit` | 19 | 383 | 6 | 6 |
| 5 | `Combine` | 17 | 805 | 15 | 18 |
| 6 | `SafariServices` | 17 | 133 | 2 | 2 |
| 7 | `UserNotifications` | 15 | 127 | 0 | 0 |
| 8 | `AVFoundation` | 14 | 302 | 0 | 0 |
| 9 | `WidgetKit` | 14 | 301 | 0 | 1 |
| 10 | `MobileCoreServices` | 14 | 90 | 0 | 2 |
| 11 | `StoreKit` | 14 | 45 | 1 | 1 |
| 12 | `os` | 13 | 219 | 1 | 1 |
| 13 | `UniformTypeIdentifiers` | 13 | 128 | 0 | 0 |
| 14 | `Intents` | 13 | 101 | 4 | 6 |
| 15 | `AVKit` | 13 | 54 | 0 | 0 |
| 16 | `AuthenticationServices` | 13 | 49 | 0 | 0 |
| 17 | `MessageUI` | 13 | 39 | 0 | 0 |
| 18 | `CoreGraphics` | 12 | 124 | 0 | 0 |
| 19 | `CryptoKit` | 12 | 65 | 0 | 0 |
| 20 | `PhotosUI` | 11 | 48 | 0 | 0 |
| 21 | `LocalAuthentication` | 11 | 43 | 2 | 2 |
| 22 | `BackgroundTasks` | 11 | 33 | 0 | 0 |
| 23 | `QuartzCore` | 10 | 123 | 0 | 0 |
| 24 | `CoreSpotlight` | 10 | 35 | 0 | 0 |
| 25 | `Network` | 10 | 30 | 1 | 1 |
| 26 | `SystemConfiguration` | 10 | 15 | 0 | 0 |
| 27 | `Photos` | 9 | 124 | 0 | 0 |
| 28 | `Accelerate` | 9 | 48 | 0 | 0 |
| 29 | `CoreImage` | 9 | 39 | 0 | 0 |
| 30 | `CoreServices` | 9 | 29 | 0 | 0 |
| 31 | `ImageIO` | 9 | 28 | 0 | 0 |
| 32 | `QuickLook` | 9 | 23 | 0 | 0 |
| 33 | `CoreLocation` | 8 | 103 | 0 | 0 |
| 34 | `CoreMedia` | 8 | 58 | 0 | 0 |
| 35 | `PassKit` | 8 | 53 | 1 | 1 |
| 36 | `CommonCrypto` | 8 | 36 | 0 | 0 |
| 37 | `Security` | 8 | 26 | 0 | 0 |
| 38 | `OSLog` | 8 | 22 | 0 | 0 |
| 39 | `AppIntents` | 7 | 160 | 0 | 0 |
| 40 | `objc` | 7 | 73 | 0 | 0 |

The table shows the top 40 of 131 observed iPhoneOS/runtime port candidates; the JSON contains the complete ranking. Apple-owned non-iOS/developer modules and Swift-toolchain modules remain inventoried but are excluded from this order.

## Focus launch/build relevance

This order puts direct imports in Focus launch anchors first, then imports in the exact 129-source Blockzilla target, then other Focus repository sources. It is build evidence, not a runtime call-graph claim.

| Rank | Module | Launch anchors | Main-target files | Focus files | Corpus apps |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | `UIKit` | 1 | 75 | 101 | 20 |
| 2 | `Combine` | 1 | 15 | 18 | 17 |
| 3 | `Foundation` | 0 | 50 | 66 | 20 |
| 4 | `SwiftUI` | 0 | 9 | 28 | 19 |
| 5 | `WebKit` | 0 | 6 | 6 | 19 |
| 6 | `Intents` | 0 | 4 | 6 | 13 |
| 7 | `IntentsUI` | 0 | 3 | 3 | 4 |
| 8 | `SafariServices` | 0 | 2 | 2 | 17 |
| 9 | `LocalAuthentication` | 0 | 2 | 2 | 11 |
| 10 | `StoreKit` | 0 | 1 | 1 | 14 |
| 11 | `os` | 0 | 1 | 1 | 13 |
| 12 | `Network` | 0 | 1 | 1 | 10 |
| 13 | `PassKit` | 0 | 1 | 1 | 8 |
| 14 | `AudioToolbox` | 0 | 1 | 1 | 7 |
| 15 | `CoreHaptics` | 0 | 1 | 1 | 4 |
| 16 | `MobileCoreServices` | 0 | 0 | 2 | 14 |
| 17 | `WidgetKit` | 0 | 0 | 1 | 14 |
| 18 | `Social` | 0 | 0 | 1 | 6 |

## Requested baseline families

| Family | Import modules | Apps / 20 | Files | Focus main target | Focus repository |
| --- | --- | ---: | ---: | ---: | ---: |
| Foundation | `Foundation` | 20 | 13668 | 50 | 66 |
| UIKit | `UIKit` | 20 | 8132 | 75 | 101 |
| SwiftUI | `SwiftUI` | 19 | 3704 | 9 | 28 |
| Combine | `Combine` | 17 | 805 | 15 | 18 |
| WebKit | `WebKit` | 19 | 383 | 6 | 6 |
| Intents / IntentsUI | `Intents`, `IntentsUI` | 13 | 117 | 7 | 9 |
| UserNotifications | `UserNotifications`, `UserNotificationsUI` | 15 | 137 | 0 | 0 |
| CoreSpotlight | `CoreSpotlight` | 10 | 35 | 0 | 0 |
| MobileCoreServices / UTType | `MobileCoreServices`, `UniformTypeIdentifiers` | 17 | 218 | 0 | 2 |
| WidgetKit | `WidgetKit` | 14 | 301 | 0 | 1 |
| SafariServices | `SafariServices` | 17 | 133 | 2 | 2 |
| StoreKit | `StoreKit` | 14 | 45 | 1 | 1 |
| AuthenticationServices | `AuthenticationServices` | 13 | 49 | 0 | 0 |
| CoreGraphics | `CoreGraphics` | 12 | 124 | 0 | 0 |
| QuartzCore | `QuartzCore` | 10 | 123 | 0 | 0 |

## Classification boundary

Observed categories: {"apple_first_party": 131, "apple_non_ios_or_developer": 4, "non_apple_system": 9, "project_or_third_party": 1206, "swift_toolchain": 8, "uncertain": 43}.

Apple-owned non-iOS/developer modules (inventoried, not ranked as iPhoneOS runtime ports): `AppKit`, `Cocoa`, `WatchKit`, `XCTest`.

Swift-toolchain modules (inventoried, not framework ports): `FoundationEssentials`, `FoundationNetworking`, `FoundationXML`, `Observation`, `PackageDescription`, `RegexBuilder`, `Swift`, `swift`.

Uncertain module names requiring ownership review: `Watchkit`, `_types`, `absl`, `alsa`, `android`, `aom`, `asm`, `blurhash`, `boost`, `brotli`, `emscripten`, `ffnvcodec`, `gtest`, `hwy`, `jxl`, `libPhoneNumber_iOS`, `libcmark`, `libgimp`, `libphonenumber`, `libprisma`, `libxml`, `libyasm`, `linux`, `machine`, `mbedtls`, `mozjpeg`, `ogg`, `openssl`, `opus`, `opusfile`, `proton_app_uniffi`, `pulse`, `sanitizer`, `sqlcipher`, `td`, `va`, `valgrind`, `vdpau`, `vk_video`, `vulkan`, `webp`, `wpxmlrpc`, `zxcvbn_ios`.

`MobileCoreServices` is the legacy module; modern `UTType` lives in `UniformTypeIdentifiers` and is not itself an importable module. Full per-app evidence counts, samples, source/blob digests, policy, and both complete rankings are in `framework-roadmap.json`.

## Reproduce

```sh
cd full/framework-roadmap
python3 framework_roadmap.py --check
python3 -m unittest -v test_framework_roadmap.py
```
