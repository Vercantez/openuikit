# iOS target for app source: route (b) and the Mach-O guest

**Date:** 2026-09-22. **Branch:** `agent/ios-target-route` (merges `agent/simplenote-objc-core`).
**Toolchains:** Xcode 26.1 / Swift 6.2.1 (route b); Linux Swift 6.2.4 + clang/lld-18 in `openuikit-guest-env:arm64` (guest).
**Oracle:** iOS 26.1 simulator (iPhone 16, 23B86), throwaway devices created and deleted per run.

## Status

App source can now be built for **`arm64-apple-ios26.1-simulator`** with `import UIKit`
resolving to OpenUIKit and **no Apple UIKit, SwiftUI or AppKit in the module graph**, so
`#if os(iOS)` / `canImport(UIKit)` / `targetEnvironment(simulator)` branches are the ones a
device takes. The ingest tools emit packages that build for either triple. Measured effect:
Simplenote's Swift half **489 → 425** unique errors (85 → 77 files) at the simplenote-objc-core
base, and **444 → 382** (81 → 73) after merging today's main. In both, the 42 `@IBAction`
arity errors, the AppKit class collisions and the `OUK_` renames gone; Kickstarter's real
Kingfisher 8.5.0 now compiles its **iOS** branch; ServerDrivenUI's AVAudioSession and
SwiftUICore rows are gone (20 → 3 own errors, the 3 being AVKit's `VideoPlayer`).
The same app source also builds for the iOS triple on the **Linux cross toolchain**
(`full/iostarget/ios_guest.sh`: `build_full.sh` with `TARGET=arm64-apple-ios26.0-simulator`).
The resulting platform-7 Mach-Os run under machorun in the arm64 Docker container.
The whole real-app verifier passes unchanged on that build (**Focus's real AppDelegate
launched, 14/14 byte-identical, `REAL-APP SCREEN VERIFIED ON LINUX`**). A probe with
`#if os(iOS)` + `import UIKit` prints the same 14 lines as the iOS 26.1 simulator,
including the `#available` answers. Getting there took five platform fixes (below).

## Design, and the measurement behind each choice

| question | answer | measured |
|---|---|---|
| triple | `arm64-apple-ios26.1-simulator` (Mach-O `LC_BUILD_VERSION` platform 7) | Goldens are captured on the iOS 26.1 **simulator**, so `targetEnvironment(simulator)` branches match the oracle. The route-(a) guest already had an `ios-simulator` link mode (`build_full.sh LINK_PLATFORM`, `retarget_macho_build_version.py`). A macOS binary "with iOS conditions" does not exist: `os()` is the triple; no `-D` changes it (eidolon/RxCocoa, Kingfisher both measured that). |
| deployment floor | `.iOS("26.0")` in `uikit/Package.swift` and every generated manifest | SwiftPM ignores the OS version in `--triple` and uses the package floor (default iOS 12): **1,183** availability errors against OpenUIKit's own UIKit-shaped `@available(iOS …)` annotations → **0**. SwiftPM refuses a client whose floor is below a dependency's, so generated packages carry the same floor. The Linux true-iOS build had the same problem at `ios18.0` (`'UIGlassEffect' is only available in iOS 26.0`, 6 errors in OpenUIKit); `ios26.0` builds. |
| SDK, route (b) | **curated iPhoneSimulator26.1 SDK** (`Tools/ingest/ios_target_sdk.py`): a symlink farm of Xcode's SDK without UIKit, SwiftUI and every framework/Swift module whose public headers or `.swiftinterface`s import them, transitively; kept frameworks whose cross-import overlays name a removed module get those overlay files pruned | Stock SDK: `import UIKit` already resolves to OpenUIKit (SwiftPM's `-I` precedes the SDK) and the UIKit target builds, but `import AVKit` / `import MessageUI` load **Apple's** UIKit silently: `let c: UIViewController = AVPlayerViewController()` → "cannot convert value of type 'AVPlayerViewController' to specified type 'UIViewController'". Curated: 107 of 277 modules removed → `no such module 'AVKit'` (an honest wall). Cross-import: Apple's kept `Intents` + a module named `UIKit` loaded `_AppIntents_UIKit` → "no such module"; 14 kept frameworks now have their UIKit/SwiftUI overlay files pruned. The SDK is never modified. |
| what stays Apple's on route (b) | Foundation, CoreFoundation, CoreGraphics, QuartzCore, AVFoundation/AVFAudio, CoreData, Combine, Dispatch, MobileCoreServices, UniformTypeIdentifiers, … (iOS declarations) | These are what the app's iOS source was written against; `AVAudioSession` is available again. Where the port also ships a same-named product and the iOS SDK copy is kept (MobileCoreServices), the port's shadowed Apple's `kUTType*` (8 errors in KsApi `MimeType.swift`), so generated manifests now link it on macOS/Linux only. |
| SDK, guest | the local guest sysroot plus the iPhoneSimulator stdlib interfaces/`.tbd`s (`full/xcodeplan/stage_true_ios_full_sdk.sh`); every framework is the port's | Linux Swift 6.2.4 consumes Apple's stable stdlib `.swiftinterface`s as `-I` modules. Two corrections were measured on the way. (a) `Observation` had to be staged (SwiftUI re-exports it: `no such module 'Observation'`). (b) Linking against **Apple's** iOS `libSystem.B.tbd` bound `Dispatch.DispatchQueue` metadata to libSystem (on iOS the Dispatch overlay lives in libdispatch), and machorun stopped at load: `undefined symbol '_$s8Dispatch0A5QueueC11OpenCombine9SchedulerAAMc'`. `ios_guest.sh` now links against machorun's own generated `libSystem`/`libobjc` `.tbd`s, retargeted to `arm64-ios-simulator`: what the guest really provides. |
| machorun and platform 7 | no change needed | machorun skips `LC_BUILD_VERSION` (`src/image.c:357`); it loaded platform-7 executables and dylibs unchanged. It does not consult the platform anywhere that mattered. `dyld_get_active_platform` still says macOS, and nothing on this path read it. |
| availability checks at run time | the guest answers iOS 26.1: `full/shims/ios_availability.c` is linked into iOS-triple executables. `-disable-availability-checking` is no longer passed to iOS-triple app code, because it folds every `#available` to true (Xcode 26.1 `-emit-ir`: 4 runtime-check references without the flag, 0 with it). Before: the guest said yes to 26.2 and 27.0 (the flag, then libswiftcompat's always-yes `__isPlatformVersionAtLeast`). | Oracle (simulator): 26.0 yes, 26.1 yes, 26.2 no, 27.0 no. |

## The smallest real case (route b), end to end

`uikit/Tools/iostarget/run_probe.sh` → **`IOS_TARGET_PROBE_VERIFIED`**:

1. the probe package (`#if !os(iOS) #error`, a zero-argument `@IBAction`, `import UIKit`,
   and the shared Objective-C `OUKObjCView : UIView` scenario) **fails** on the macOS triple
   with exactly those two diagnostics;
2. it builds for `arm64-apple-ios26.1-simulator` against the curated SDK; the executable is
   platform 7 and links no Apple UIKit/SwiftUI/AppKit (Foundation, CoreFoundation,
   CoreGraphics, libobjc, Swift runtime only);
3. run on the iOS 26.1 simulator it prints `UIView=OpenUIKit.UIView runtime-name=UIView`, and
   its Objective-C subclass trace (initializers, `-init`→`-initWithFrame:`, hierarchy
   callbacks, layout counts, `sizeToFit`, a leaf subclass) is **byte-identical, 52 lines**,
   to `Tools/oracle2/objcsubclassprobe/transcript-ios26.1.txt`, which the same `.m` produced
   against Apple's UIKit.

So an iOS-triple OpenUIKit process runs on Apple's own simulator runtime with Apple's
UIKit absent and gives UIKit's answers for the ObjC-subclass contract.

## The same case on Linux: the Mach-O guest built for iOS

`bash full/iostarget/ios_guest.sh` (host: stages the SDK variant; container
`openuikit-guest-env:arm64`: runs `build_full.sh` for `arm64-apple-ios26.0-simulator`,
then the checks). Output, verbatim tail:

```
POSIX_MADVISE_MATCHES_DARWIN
# iostarget-guest-probe os=iOS environment=simulator UIView=OpenUIKit.UIView
available iOS 26.0: yes
available iOS 26.1: yes
available iOS 26.2: no
available iOS 27.0: no
frame={{1, 2}, {30, 40}} bounds={{0, 0}, {30, 40}}
after first layoutIfNeeded layouts=1
…
IOS_TARGET_PROBE_MATCHES_IOS_26_1 lines=14
FOCUS_GUEST_BOUNDARY_OK sync=specific group=notify,reuse,timeout plist=bridge percent=utf8 archive=refused
FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController
rendered 15 screens; existing screens byte-identical 14/14 (including Ledger)
REAL-APP SCREEN VERIFIED ON LINUX
IOS_TARGET_GUEST_VERIFIED target=arm64-apple-ios26.0-simulator
```

`LC_BUILD_VERSION` of the probe is `platform 7, minos 26.0, sdk 26.1`. Every fix below
was found by this run failing first:

| failure (measured) | fix | where |
|---|---|---|
| `'UIGlassEffect' is only available in iOS 26.0 or newer` ×6 at `ios18.0` (the older true-iOS deployment) | deployment `ios26.0`, the same floor as SwiftPM | `ios_guest.sh` |
| `no such module 'Observation'` compiling SwiftUI | stage Observation's iOS interface and `.tbd` | `full/xcodeplan/stage_true_ios_full_sdk.sh` |
| `OpenCombine.o has platform macOS, which is different from target platform iOS Simulator` | compile the attested 103 pinned OpenCombine sources for the target when `LINK_PLATFORM=ios-simulator` | `build_full.sh` |
| `machorun: undefined symbol '_posix_madvise'` (wanted by `lib_FoundationICU.dylib`: ICU's iOS branch) | `posix_madvise` in the full/ libSystem umbrella, measured on macOS 26 **and** the iOS 26.1 simulator: −1/`EINVAL` for a bad advice (not POSIX's error-number return), unaligned address accepted, `DONTNEED` keeps contents, errno untouched on success. The fixture caught the errno detail on its first run. machorun itself is pinned, so the umbrella is the place | `full/shims/libsystem_posix_compat.c`, `full/iostarget/posix_madvise.{c,expected}` |
| Dispatch metadata bound to libSystem (above) | machorun's own `.tbd`s, retargeted | `ios_guest.sh` |
| `available iOS 26.2: yes`, `27.0: yes` (simulator: no, no) | real `#available` on the iOS triple | `build_full.sh`, `full/shims/ios_availability.c` |

Also seen, not fixed: the iOS-triple guest prints objc4 `Class … is implemented in both`
warnings for FoundationEssentials classes (stderr only; the probes and verifier pass).


## Before → after

Same generated package, same OpenUIKit tree, the only change is triple + SDK
(+ the manifest plumbing). Full data: `ios-target-route-measurements.json`.

### Simplenote Swift half (`swift build --target Simplenote`)

Both builds carry the simplenote-objc-core measurement shim (UIKit's `NSTextStorage`
declared in the generated `<UIKit/UIKit.h>` so the bridging-header PCH passes). The iOS
build additionally drops `import WidgetKit` from the two scratch copies that have it
(Apple's WidgetKit imports SwiftUI and is removed; the port's WidgetKit, `full/widgetkit`,
is not a route-(b) product): without that it stops at 1 fatal `no such module 'WidgetKit'`.
Their `WidgetCenter` uses are counted (2).

| | macOS triple (before) | iOS triple (after) |
|---|---:|---:|
| unique errors, simplenote-objc-core base | **489** | **425** |
| files, same base | 85 | 77 |
| unique errors, after merging main `d48096f4` | **444** | **382** |
| files, same | 81 | 73 |
| `@IBAction methods must have 1 argument` | 42 | **0** |
| `has different definitions in different modules` (AppKit/QuartzCore vs OpenUIKit-Swift.h) | 13 | **1** (`CALayer`, QuartzCore) |
| `OUK_NSLayoutConstraint` rename fallout (`isActive`, assignment) | 8 | 0 |
| `#selector` "not exposed to Objective-C" (IBAction fallout) | 6 | 0 |
| `SFSafariViewController` not found (macOS SafariServices) | 2 | 0 |
| `performBatchUpdates` / `performBatchChanges` (SimplenoteFoundation took `os(macOS)`) | 2 | 0 |

The row deltas below are the base pair. The after-merge pair has the same deltas row for row, except `performBatchUpdates`, which main already had.
| NEW: attributed-string rows (Foundation `NSAttributedString.Key.font/.foregroundColor/.paragraphStyle/.backgroundColor` 7, `String`→`NSAttributedString` 6, `foregroundColor:` / `string:` arguments 6, cross-universe conversion 1) | 0 | 20 |
| NEW: `WidgetCenter`, `INInteraction.intentResponse` | 0 | 3 |

The new rows are masking removed, not new faults: on macOS **AppKit** supplied UIKit's
`NSAttributedString.Key` additions on Foundation's type; on iOS only UIKit does, and the
port's keys live on OpenUIKit's own `NSAttributedString` (the "two universes" wall
simplenote-objc-core named, still open). SimplenoteFoundation now compiles its iOS branch
(`UITableView+ResultsController.swift`), which needed `UITableView.performBatchUpdates`
(added, measured, below).

### Kickstarter chain (`ios-oss-launch2-chain.json` of `agent/ios-oss-walls`, `chain_census.py`)

| target | macOS triple | iOS triple |
|---|---|---|
| **Kingfisher 8.5.0 real source** (`2015fda7`) | **69** errors, 12 files: the **AppKit** branch (`NSImage`, `CVDisplayLink` 27 in DisplayLink.swift, `RunLoop` ambiguous 9, `NSViewRepresentable`) — unfixable by the port | 1 fatal `no such module 'AVKit'` (Apple's removed; no route-(b) AVKit). With a measurement-only `AVKit` = `@_exported import AVFoundation`: **112** errors, 16 files, all in the **iOS** branch against OpenUIKit — `UIImage.imageOrientation/cgImage/withAlignmentRectInsets/imageFlippedForRightToLeftLayoutDirection`, `UIImageView.isAnimating/stopAnimating/isHighlighted`, `UIView.AnimationOptions.transitionFlip*`, `CADisplayLink`, `PHLivePhoto*` (the port's PhotosUI does not re-export Photos), SwiftUI `Image.ResizingMode/renderingMode/interpolation`, `UIApplication.beginBackgroundTask` — i.e. ordinary UIKit gaps |
| Kingfisher stand-in (their shim) | 0 | 0 |
| **ServerDrivenUI** (stand-in Kingfisher) | **20** own: 5 × `AVAudioSession … unavailable in macOS`, 12 × `AttributeContainer` font (AppKit pulled Apple's SwiftUICore, so the port's `SwiftUIAttributes` compiled out), `clipShape`/`Shape`, `accessibilityLabel`, `startsMediaSession` | 1 fatal `no such module 'AVKit'`; with the measurement AVKit: **3**, all AVKit `VideoPlayer` (`AudioVideoBlock.swift:68-72`). The AVAudioSession, SwiftUICore and AVKit→SwiftUI rows are **gone** |
| KsApi (dependency) | passes | passed after the MobileCoreServices fix (was 8 × `kUTType*` with the port's module shadowing Apple's) |

## Port fixes, each with a test that fails before

| change | evidence | test |
|---|---|---|
| `uikit/Package.swift` `.iOS("26.0")` | 1,183 → 0 availability errors on the iOS triple | `test_ios_target.py::test_platforms_include_ios_floor_matching_openuikit` |
| `UITableView.performBatchUpdates(_:completion:)` | `Tools/oracle2/tablebatchprobe` (iOS 26.1): updates run inside the call, rows visible on return, completion never synchronous — `true` after the 0.441 s row animation in a window, `false` next turn with no window, `true` next turn under `performWithoutAnimation` | `TableViewBatchUpdatesTests` (4): compile failure before, pass after |
| `posix_madvise` (guest libSystem umbrella) | macOS 26 + iOS 26.1 transcripts, above | `full/iostarget/posix_madvise.c` vs `.expected` under machorun (`POSIX_MADVISE_MATCHES_DARWIN`; failed first on the errno detail) |
| real `#available` on iOS-triple guests (`ios_availability.c`, no `-disable-availability-checking` for iOS app modules) | oracle: 26.2 no, 27.0 no | `IOSTargetGuestProbe` vs `full/iostarget/oracle-ios26.1.txt`: yes/yes before, no/no after |
| generated manifests: `-disable-availability-checking` only on macOS/Linux | emit-ir, above | `test_ios_target.py::test_availability_checking_is_not_disabled_on_ios` |
| `String.boundingRect(with:options:attributes:context:)` on the iOS triple (`NSStringDrawing.swift` gate `|| !canImport(AppKit)`) | AppKit's overlay supplied it on macOS; nothing does on iOS (NetNewsWire RSCore, 8 errors, reported by netnewswire-launch) | the probe package: `value of type 'String' has no member 'boundingRect'` before, builds after |

## Tooling (every app gets it)

* `Tools/ingest/ios_target_sdk.py` — build/reuse the curated SDK, `--report` (removed module → reason), `--flags`, `--build PKG [--target T]`.
* `xcodeproj_to_package.py` — manifests declare `.iOS("26.0")`; Darwin-source products condition on `[.macOS, .iOS]`; the port's SafariServices/PassKit/IntentsUI/MessageUI/LinkPresentation/PhotosUI link on `[.linux, .iOS]` (their SDK copies are removed); AppKit `-D` renames only on `.macOS`; SwiftPM's `arm64-apple-ios-simulator` generated-header dirs searched; MobileCoreServices off iOS.
* `spm_app_chain.py`: same floor and MobileCoreServices rule. `chain_census.py --ios-target`.
* `full/iostarget/ios_guest.sh`: the guest side, for any tree that ran `scripts/ops/local_guest_verify.sh`. `IOS_GUEST_REUSE_BUILD=1` reruns the checks only.
* `uikit/Tools/iostarget/run_probe.sh`: the route-(b) side, with the simulator oracle.
* `test_ios_target.py`, 18 tests. All ingest tests: **96 passed** with the corpus (fake-SDK unit tests; live-SDK tests that pin the removed/kept sets and that every removed framework the port supplies is linked on iOS; manifest and census plumbing).
* Usage: `python3 uikit/Tools/ingest/xcodeproj_to_package.py … --out PKG` then `python3 uikit/Tools/ingest/ios_target_sdk.py --out ~/.cache/ios-target-sdk --build PKG --target App`.

## Open (measured, not solved here)

1. **UIKit's umbrella re-exports; port CoreGraphics/QuartzCore types vs Apple's.** Measured
   (`Tools/oracle2/uikitreexportprobe_ios`, stock SDK): Apple's `import UIKit` brings in
   Foundation, CoreFoundation, CoreGraphics, QuartzCore, ImageIO, CoreImage, CoreText,
   CoreVideo, Dispatch, Darwin, ObjectiveC, Observation, Metal, IOSurface, Security,
   CFNetwork, FileProvider, UserNotifications and Accessibility. It does not bring in
   AVFoundation, Combine, CoreData, CoreLocation, CoreMedia, UniformTypeIdentifiers or os.
   The port's shim re-exports Foundation, ObjectiveC and OpenUIKit only. As an experiment,
   `@_exported import CoreGraphics, QuartzCore, ImageIO` in the shim on iOS took real
   Kingfisher from 112 → 109 errors (2 `CADisplayLink` rows and 1 `contents` row gone,
   1 new `'CALayer' is ambiguous`). It was not committed. With Apple's CoreGraphics or QuartzCore in scope next to the port, `CGColor` (OpenCoreGraphics' struct) and `CALayer` (OpenUIKit's class) are **ambiguous**; Simplenote's last `different definitions` is `CALayer`. Apple's `import UIKit` re-exports CoreGraphics, ImageIO and QuartzCore (measured by netnewswire-launch, 22 errors in RSCore); the port's shim cannot simply do the same until those types are unified. Same wall exists on the macOS triple; the iOS triple no longer hides it behind AppKit.
2. **UI-coupled Apple frameworks the port does not ship as route-(b) products:** AVKit (Kingfisher, ServerDrivenUI), WidgetKit (Simplenote; `full/widgetkit` exists for the guest but does not compile against the SwiftPM SwiftUI), and the rest of the 107 removed modules. Each is now an explicit `no such module`.
3. **Two NSAttributedString universes** (OpenUIKit's vs Foundation's) — 22 ambiguities + 20 attributed-string rows in Simplenote.
4. **Route-(b) Mach-O under machorun.** The route-(b) product runs on the iOS simulator, but links Apple's Foundation/CoreGraphics `.tbd`s, which the guest does not provide (it has the port's Foundation, statically linked, and loud-abort stubs at the framework paths). Running an Xcode-built binary under machorun needs either Xcode's swiftc compiling the whole port closure (FoundationEssentials, OpenCoreGraphics, CQuartz) against the guest SDK or ABI-compatible framework dylibs at Apple's install names. **Not reached.**
5. **ObjC subclassing inside the guest.** `build_full.sh` still compiles OpenUIKit without `OPENUIKIT_OBJC_SUBCLASSING` (the guest sysroot also has no ObjC Foundation headers for an app .m file). So the ObjC-subclass contract is proven on Apple's runtime (the simulator run above), not on objc4 under machorun. The guest probe uses a Swift UIView subclass. **Not attempted.**

## Risks

* Deployment floor 26.0 folds every `#available(iOS ≤26.0)` to true at compile time; apps that ship lower floors lose their `else` branches in our build (a device at 26.1 takes the same branches, so behaviour matches the oracle).
* The curated SDK's removal rule is a textual import scan (conditional `#import`s count); it errs toward removing. `--report` prints each reason.
* SwiftPM leaves stale modules in `.build/<triple>/…/Modules`, which shadow SDK modules after a manifest change (measured with MobileCoreServices); clean `.build` when switching conditions.
* Touches outside `uikit/`: `full/scripts/build_full.sh` (every change is conditioned on `LINK_PLATFORM=ios-simulator`, except the `posix_madvise` umbrella object, which the macOS guest now carries too and verifies 14/14 with), `full/shims/{libsystem_posix_compat,ios_availability}.c`, `full/xcodeplan/stage_true_ios_full_sdk.sh`, `full/iostarget/`. The merge check needs `ALLOW_PATHS='^full/(iostarget/|scripts/build_full\.sh$|shims/(libsystem_posix_compat|ios_availability)\.c$|xcodeplan/stage_true_ios_full_sdk\.sh$)'`.
* `ios_availability.c` answers only for the executable's own checks; dylibs still bind libswiftcompat's always-yes.
* After main's `UIKitClangModule`, any Clang target that depends on the Swift `UIKit` product gets `redefinition of module 'UIKit'`. The probe was switched to the `OpenUIKit` product. Ingest-generated mixed packages do not depend on it from Clang.
* Incident: a scratchpad entry `ks` is another agent's symlink to `scratch/ladder-corpus/ios-oss`; for about a minute I extracted files into it by mistake. I deleted exactly the six new entries; no tracked corpus file was touched and the corpus root is back to its 25 upstream entries. iososs-walls was told.

## Validation

VALIDATION_PLACEHOLDER
