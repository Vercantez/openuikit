# ios-oss (Kickstarter) launch pass 1: pin, census, oracle golden, chain compile to the first walls

**Date:** 2026-09-09. **Branch:** `agent/ios-oss-launch`, base `c7130364` (main).
**Route:** (b), Apple toolchain on this Mac (Xcode 26.1 / Swift 6.2.1) → Darwin SwiftPM against OpenUIKit.
**Corpus:** kickstarter/ios-oss `2f2dabb40b74dd1e7a7511a0dedb47d967ab08a0` (2026-08-27, "[DISC-149] Video Feed"), unpatched; `git status` clean before and after.
**Status:** first screen **not reached on OpenUIKit; score N/A**. The iOS 26.1 oracle golden of the real first screen exists (below). The first measured walls are in the three UIKit-bound modules at the bottom of the app's own dependency chain (`ReactiveExtensions`, `Prelude_UIKit`, `KDS`), one of them structural (accessibility on `NSObject`), plus Kingfisher compiling its AppKit branch. Six small members were measured on the oracle and added to the port with tests. No pin file, `Package.resolved`, `.app` or corpus file was touched. Machine-readable census: [ios-oss-launch-deps.json](ios-oss-launch-deps.json); chain spec: [ios-oss-launch-chain.json](ios-oss-launch-chain.json).

Prior context: `uicollectionviewcontroller.md` (2026-09-09) closed the last blocking UIKit *type* row for ios-oss and named the route-(b) `override`-in-extension shape as the open wall. This pass measures the app itself, not the type alphabet.

## (1) Corpus pin and census

The PBX application target is `Kickstarter-iOS` (product `Kickstarter`, debug bundle `com.kickstarter.kickstarter.debug`, scheme `Kickstarter iOS`). It holds **2 Swift files**: `AppDelegate.swift` (`@UIApplicationMain`) and a test file the target lists (`DataSources/SearchDataSourceTests.swift`). Everything else is in **seven local SwiftPM packages** the target links; `xcodeproj_to_package.py` sees them only as `spm_local` rows. `Main.storyboard`'s initial controller is `RootTabBarViewController` (Kickstarter-Framework); the app is Swift-only.

| module | Swift files (non-test) | files importing UIKit | role |
|---|---:|---:|---|
| Kickstarter-iOS (PBX target) | 2 | 1 | AppDelegate |
| Kickstarter-Framework | 353 | 284 | every feature (Discovery, RootTabBar, Onboarding, …) |
| Library | 372 | 127 | view models, `AppEnvironment`, services, strings |
| KsApi | 325 | 2 | GraphQL/REST models, `Secrets` |
| GraphAPI | 294 | 0 | Apollo codegen |
| KDS | 19 | 13 | design system (`KSRButton`, fonts, colours) |
| ServerDrivenUI | 13 | 1 | SwiftUI components |
| Experimentation | 10 | 0 | Statsig wrapper |
| **first-screen module set** | **1,388** | **428** | |

Repository-wide: 2,072 Swift files, of which 508 sit in test directories (the ladder's 2,053/2,055 count is the same repository at drift). Objective-C: **0** `.m`/`.mm`, 1 header (GraphAPI). Nibs: **43** = 40 storyboards/XIBs under `Kickstarter-Framework/Resources`, 1 XIB under Discovery, 2 storyboards in the app target (Launch + Main). Generated inputs: `KsApi/Sources/KsApi/Secrets.swift` is absent in the clone (the Makefile clones a private repo or copies `Configs/Secrets.swift.example`).

**Dependencies.** The corpus `Package.resolved` pins 41 packages; `xcodebuild -resolvePackageDependencies` resolved all 41 identities to the same revisions (workspace-state compared, 0 mismatches). Load-bearing, per `full/ladder/dep-classes-2026-09-16.json` (ios-oss: 6 measured deps, `worst_load_bearing_class` Foundation-heavy, 176 selector sites of which 163 are the app's own):

| dep | pin | ladder class | measured here |
|---|---|---|---|
| Apollo / ApolloAPI (apollo-ios 1.9.3) | `eedde215` | Foundation-heavy | **compiles** as-is against the host |
| ReactiveSwift 7.1.1 | `40c465af` | Foundation-heavy | **compiles** as-is |
| Kickstarter-Prelude 1.0.0 (`Prelude`, `Prelude_UIKit`) | `f3a2dc43` | unmeasured (app-owned) | `Prelude` compiles; `Prelude_UIKit` **49 errors** (below) |
| Kickstarter-ReactiveExtensions 2.0.0 | `36984ccb` | unmeasured (app-owned) | **12 errors**, all one structural gap |
| SwiftSoup 2.6.0 | `0e96a20f` | Foundation-heavy | compiles as-is |
| Kingfisher 8.5.0 | `2015fda7` | SwiftUI/Combine-bound | **69 errors**: selects its macOS/AppKit branch |
| Lottie 4.5.1 | `047aa81b` | SwiftUI/Combine-bound | not attempted (first screen needs it: the onboarding is a Lottie loop) |
| AlamofireImage 4.3.0 | `1eaf3b6c` | UIKit-bound | not attempted |
| Firebase 11.15.0, Stripe 23.32.0, Facebook 12.3.2, Braze 12.1.0, Segment 1.8.0, Statsig 1.61.0 | (see JSON) | services, binary xcframeworks | no port; Statsig has a fail-closed shim (below) |

Import census of the first-screen set (Library + Kickstarter-Framework + AppDelegate; test file excluded): 49 distinct modules. 15 resolve from the macOS SDK/toolchain (Foundation, Combine, AVFoundation, WebKit, PassKit, UserNotifications, … — not guest credit), 7 are OpenUIKit products (UIKit, SwiftUI, SafariServices, MessageUI, …), 13 are chain targets, and **14 have no port**: AlamofireImage, BrazeKit, BrazeUI, FacebookCore, FacebookLogin, Firebase, FirebaseCrashlytics, FirebaseRemoteConfig, KingfisherWebP, Lottie, Segment, SegmentBrazeUI, Stripe, StripePaymentSheet.

## (2) iOS 26.1 oracle: the real first screen

The corpus was copied (without `.git`) to the session scratchpad; the only file added to the copy is `KsApi/Sources/KsApi/Secrets.swift`, generated from the public `Configs/Secrets.swift.example` with `isOSS = true`, the value the README documents for "a mock version that serves up hard-coded data" (the `Makefile`'s `secrets` target copies the same example when the private repo is unreachable). No other credential, config or source was changed; the corpus clone was not written to. Build:

```sh
xcodebuild build -project Kickstarter.xcodeproj -scheme "Kickstarter iOS" -configuration Debug \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=26.1,name=iPhone 16' \
  -derivedDataPath … -clonedSourcePackagesDirPath … -skipPackageUpdates \
  -onlyUsePackageVersionsFromResolvedFile CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
```

`** BUILD SUCCEEDED **` in one 10-minute slice (478 compile steps; the Firebase Crashlytics run-script warning is upstream). Private device `OpenUIKit-Launch-ios-oss-launch` (iPhone 16, iOS 26.1 23B86, 393×852 @3x, light, status bar overridden to 9:41 / charged / 3 wifi / 4 cellular), installed `KickDebug.app`, launched detached. Console: Facebook's "client token must be embedded" (demo `FacebookAppID`), `Statsig reload error: … StatsigClientError error 1` (demo key), one `Unbalanced calls to begin/end appearance transitions for RootTabBarViewController` — no crash.

**First screen after launch: `OnboardingView`**, a SwiftUI view in a `UIHostingController` presented `.fullScreen` from `AppDelegate` (`triggerOnboardingFlow`, `hasSeenOnboarding` unset) over the storyboard's `RootTabBarViewController`. Golden: [ios-oss-launch-first-screen-ios26.1.png](ios-oss-launch-first-screen-ios26.1.png) (1179×2556). Measured on the PNG (pt = px/3):

| element | frame (pt) | note |
|---|---|---|
| background | full window | `rgb(6,229,132)` Kickstarter green |
| progress track / fill | x 20–334, y 106.7–114.7 / fill x 20–83 | 8 pt tall; fill `rgb(3,113,65)` = page 1 of 5 |
| close × | x 350–365, y 103–118 | black glyph |
| "Welcome to Kickstarter" | ink x 73.7–319.7, y 142.7–159.7 | bold, black |
| body (4 lines) | ink x 28.7–364.7, y 180.3–253.3 | "Use our app to discover and support creative projects. …" |
| Lottie illustration | animated band px x 27–1152, y 992–1953 | **loops**: three captures 5 s apart differ by 19.6–28.8 % of pixels, all inside this band; every other pixel is identical |
| **Next** button | x 40–353, y 708.3–760 | fill `rgb(30,30,30)`, white label ink x 179.7–214.3 |

Because the band animates, the golden is one frame; a comparison must mask that band (`compare_realapp.py` has no mask flag yet — recorded as the next need for this screen).

**Behind it:** with `com.kickstarter.KeyValueStoreType.hasSeenOnboarding` set true and a relaunch, the root is the Explore tab (`Discovery`, "Magic / Popular / Newest / Ending Soon", "Bring creative projects to life", a mock project card, floating tab bar Explore/Activity/Search/Profile) under the system App Tracking Transparency alert; two captures 5 s apart are byte-identical: [ios-oss-launch-explore-att-ios26.1.png](ios-oss-launch-explore-att-ios26.1.png). That is the UIKit screen the next rung would score once the alert is dismissed (a `simctl` tap is not available; the alert is `AppTrackingTransparency`'s, requested by `AppDelegateViewModel`).

## (3) Ingest and chain compile census

`xcodeproj_to_package.py --target Kickstarter-iOS --library` exits 0 with 1 Swift source, 2 nibs, 1 xcassets, 5 `.strings`, and 13 no-port rows — the local packages are `spm_local` rows it copies "next to the generated package, not linked". The app is those packages, so this pass adds a second tool:

- `Tools/ingest/spm_app_chain.py SPEC --out DIR --corpus … --checkouts …` emits a SwiftPM package (tools 6.0, `defaultLocalization`) whose targets **symlink the unchanged upstream directories** — corpus modules, the app's `Package.resolved` checkouts (the ones Xcode resolved above), and shims under `uikit/Sources` — and depend on OpenUIKit products instead of the Apple SDK. `--copy` materialises with a `PROVENANCE.json` of SHA-256s the way Eidolon's ingest did. 3 fixture tests (`test_spm_app_chain.py`), no corpus needed; the existing 47 ingest tests still pass (24 skipped without the corpus).
- `Tools/ingest/chain_census.py` builds target by target (`swift build --target`), parses diagnostics, splits **own** errors (files under the target) from **dependency** errors, keeps `protocol requires …` notes, groups messages, and marks dependents "blocked by dependency" rather than failed.
- `Sources/KickstarterServiceShims/Statsig`: fail-closed `StatsigClient` / `StatsigUser` / `StatsigOptions` / `StatsigEnvironment` / `DynamicConfig` / `Layer` covering exactly the surface `Experimentation/StatsigClient.swift` uses; `isInitialized()` false, gates false, values nil, completion called once with an error (the oracle console printed the same "Statsig reload error" with the demo key). Not in the main manifest; the chain package links it.

Chain result (debug, `-j 4`, OpenUIKit at this branch):

| target | source | status | own errors | files | first lines of the grouped census |
|---|---|---|---:|---:|---|
| Statsig (shim) | uikit | passed | 0 | | |
| Prelude | checkout | passed | 0 | | 24 files |
| ReactiveSwift | checkout | passed | 0 | | 51 files, as-is |
| SwiftSoup | checkout | passed | 0 | | 58 files, as-is |
| ApolloAPI / Apollo | checkout | passed | 0 | | 28 + 87 files, as-is |
| GraphAPI | corpus | passed | 0 | | 294 files |
| Experimentation | corpus | passed | 0 | | against the shim |
| **ReactiveExtensions** | checkout | **failed** | 13 → **12** | 1 | `Rac where Object: NSObject` sets `accessibilityLabel/Hint/Value/Traits/ElementsHidden/isAccessibilityElement` on **NSObject** (6 members × 2 sites); the port declares them on `UIResponder` |
| **Prelude_UIKit** | checkout | **failed** | 57 → **49** | 23 | 9 × `CALayer.lens` and 5 × "cannot declare conformance to NSObjectProtocol" (`CALayer`, `NSMutableParagraphStyle`, `UIBarButtonItem`, `UINavigationItem`, `UITabBarItem` are not `NSObject`-derived here — the class-ABI family simplenote-launch3 named); `UIBarItem` type absent (2); 16 `does not conform to <X>Protocol` whose unmet requirements the notes name: `imageInsets`, `isEnabled`, `isSecureTextEntry`, `accessibilityElements`, `accessibilityElementsHidden`, two read-only candidates (`UINavigationController.viewControllers` setter non-public); `UIButton.setBackgroundImage`, `UIGraphicsBeginImageContext`, `Canvas.setFillColor` |
| **KDS** | corpus | **failed** | **65** | 7 | `UIButton.Configuration` family 28 (`background` 10, `baseForegroundColor` 4, `contentInsets` 2, `imagePlacement`, `titleLineBreakMode`, `titleAlignment`, `titleTextAttributesTransformer`, `imageColorTransformer`, `.borderless()`, `configurationUpdateHandler`, `setNeedsUpdateConfiguration` 4, `UIConfigurationTextAttributesTransformer`); `UIFontDescriptor` 15 (`addingAttributes` 3, `FeatureKey` 8, `AttributeName` 2, `TraitKey`, `.traits`); CoreText constants 10 (`kNumberSpacingType`, `kMonospacedNumbersSelector`, `kStylisticAlternativesType`, `kStylisticAlt{One,Two}OnSelector`, `CTFontManagerRegisterFontsForURL`); `UIFont(name:size:)` 1 (the port's `UIFont` is a system-font struct with no PostScript registry); `UIAccessibility.isBoldTextEnabled` 1; `CGColor.components` 1; SwiftUI `Color.white` 1, `#Preview` availability 1 |
| KsApi | corpus | blocked | 0 (12 dep) | | not reached: ReactiveExtensions |
| **Kingfisher** | checkout | **failed** | **69** | 12 | `#if os(macOS)` selects AppKit: `KFCrossPlatformImage` = `NSImage` (4 conversions), `NSView`/`NSViewRepresentable`/`NSImageScaling`, `CVDisplayLink` (11), `RunLoop` ambiguous (9, AppKit vs the port's), `Image.ResizingMode/TemplateRenderingMode/Interpolation`, `UIImage.Orientation`, `UIBarItem`, `UIActivityIndicatorView` missing on the macOS branch |
| ServerDrivenUI, Library, Kickstarter_Framework, KickstarterApp | corpus | blocked | 0 own | | their own files never reach semantic checking |

Same-name-different-ABI note: `KDS` compiled with `-swift-version 5` under a tools-6.0 manifest; the `#Preview` and `_OpenView.white` rows are the port's SwiftUI on macOS 13 deployment, not app errors.

### Port fixes (small, generic, oracle-measured, each with a test)

Probe: a `swiftc -target arm64-apple-ios26.1-simulator` command-line binary run with `simctl spawn` on the same device (`oracle_probe_lines` in the JSON, verbatim). Tests: `Tests/OpenUIKitTests/IosOssLaunchMembersTests.swift`, **5/5**, with the neighbouring `TextInputTraitsTests` 14/14 and `ScrollPhysicsTests` 6/6.

| member | oracle | port before | port after |
|---|---|---|---|
| `UIScrollView.DecelerationRate` | `.normal.rawValue` 0.998, `.fast` 0.99, fresh view `.normal` | `decelerationRate: CGFloat` (no typed enum) | struct with the two constants; property typed; physics constant untouched |
| `UITextField.BorderStyle` | raws 0…3, default `.none` | top-level `UITextFieldBorderStyle` without raw values | `Int` raws + nested `typealias` |
| `UITextSpellCheckingType` / `spellCheckingType` | raws 0…2, default `.default` | absent | enum + property on `UITextField` and `UITextView` |
| `UIAccessibilityNavigationStyle` / `accessibilityNavigationStyle` | raws 0…2, fresh view `.automatic` | absent | enum + stored property on `UIResponder` |
| `UITextField.textColor` | `UIColor?`; fresh field `labelColor`; after `= nil` reads `labelColor` | non-optional `UIColor` | nullable; nil resets to `.label` |
| `UILabel.textColor` | `UIColor!` (null_resettable); fresh label `labelColor`; after `= nil` reads `labelColor` | non-optional | `UIColor!`; nil resets to `.label`. Needed because unpatched Focus (`AutocompleteTextField.swift:247`) assigns a field's optional colour to a label, which Apple's types accept |

Effect on the census: ReactiveExtensions 13 → 12, Prelude_UIKit 57 → 49 (`DecelerationRate` ×2, `BorderStyle` ×2, `UITextSpellCheckingType` ×2, `UIAccessibilityNavigationStyle` ×2). KDS unchanged (its rows are the configuration/font-descriptor families).

### Measured but NOT applied (documented for the next rung)

- **`CGColor.components`** — oracle: sRGB colours give 4 components in extended sRGB, but `UIColor.white/.black/.clear/(white:alpha:)/.label/.systemBackground` give **2** (extended gray). The port's `CGColor` is an RGBA struct with no colour model, so a faithful `components` needs a gray model first; a 4-always implementation would be wrong on the exact colours the app's `hexString` reads.
- **`UIFont(name:size:)`** — oracle: `Helvetica`, `Helvetica-Bold`, `HelveticaNeue-Light`, `Courier` resolve to themselves; `NoSuchFont`, `Inter`, `SFProText-Regular` → nil; `.SFUI-Regular` maps to `TimesNewRomanPSMT` (CoreText note); system font `fontName` `.SFUI-Regular`, `familyName` `.AppleSystemUIFont`. The port's `UIFont` is a system-font value type; a PostScript-name registry is a text-module change.
- **Accessibility properties on `NSObject`** — oracle: `NSObject()` reads label/hint/value nil, `isAccessibilityElement` false, traits 0, `elementsHidden` false. The port stores them on `UIResponder`; moving them to `NSObject` on Darwin collides with AppKit's `NSAccessibility` method family (`accessibilityLabel()`), the same umbrella that forced the six renames in simplenote-launch3. This is the whole ReactiveExtensions wall and one Prelude row.

## Walls, in order met

1. **`NSObject` accessibility (structural).** 12 of ReactiveExtensions' 12 errors; blocks KsApi and everything above.
2. **Non-`NSObject` classes / `NSObjectProtocol` conformance** in Prelude's lens protocols: `CALayer`, `NSMutableParagraphStyle`, `UIBarButtonItem`, `UINavigationItem`, `UITabBarItem` (the class-ABI family; the `@objc @implementation` spike of 2026-09-09 is the recommended route), plus `UIBarItem` and a handful of lens members.
3. **`UIButton.Configuration` + `UIFontDescriptor`/CoreText** families in KDS (48 of 65).
4. **Kingfisher's platform branch.** Compiled on the macOS target it is the AppKit library; the app's `UIImageView.kf` and `KFImage` need the iOS branch against OpenUIKit — a `-D`/target-condition problem of the same shape as RxCocoa's `NSButton` in eidolon-launch.
5. **14 no-port service modules** for Library/Framework (Firebase, Stripe, Facebook, Braze, Segment, AlamofireImage, KingfisherWebP, Lottie) — fail-closed shims of the eidolon/focus kind; not started.
6. The first screen itself is SwiftUI + Lottie; the UIKit screen behind it needs the ATT alert path.

## (4) Score

N/A — nothing rendered on OpenUIKit. Not added to the real-app set; the golden and its measured frames are carried for whoever renders it.

## Validation

| check | result |
|---|---|
| `swift build` (every Darwin target, debug) | complete, 0 errors after the `UILabel.textColor` change (the intermediate state broke Blockzilla at one line, fixed by the IUO) |
| `swift test --filter 'IosOssLaunchMembersTests\|TextInputTraitsTests\|ScrollPhysicsTests'` | **25/25** |
| ingest tests | `test_spm_app_chain` **3/3**; `test_xcodeproj_to_package` **47 ran, 0 failures** (24 skipped: no corpus in the default run) |
| chain census | 17 targets, reproducible from the spec + corpus + checkouts; JSON carried |
| corpus | `git status --short` empty before and after; the Xcode build ran on a scratch copy |
| simulator | created with `SIM_DEVICE_SUFFIX=-ios-oss-launch`, deleted at the end (0 devices match) |
| merge check | recorded below |

### Merge check

`CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/ios-oss-launch` from the
monorepo root, detached with `nohup` and polled in foreground loops. The first
two attempts printed `MERGE CONFLICT with main` on the `REAL_APP_TEST.md` table
row (main advanced twice while the branch waited for the shared lock); each
time `origin/main` was merged into the branch with both rows kept. The third
run, on merge commit `076490a5`, printed **`checks passed (CHECK_ONLY)`** and
**0 `REFUSED` lines** (the script's documented exit 128 in cleanup applies).

| stage | printed |
|---|---|
| macOS release `openrender` | complete, 168.19 s |
| Catalyst gate | **124/124 scenes pass** |
| real-app floors | history_light 99.137, settings_light 98.535, settings_dark 98.548, storage_light 99.74, settings_light_xs 98.72, settings_light_xxxl 98.334, settings_light_ax1 97.549, settings_light_ipad 99.65, focus_settings_light 98.823, focus_home_light 98.558, history_light_ipad 99.86, storage_light_ipad 99.734, hackers_feed_light 98.235, ledger_light 99.61 |
| guest library route (Foundation hidden) | `GUEST_ROUTE_COMPILE_OK openuikit=148 opencoregraphics=12`, `GUEST_ROUTE_CHECK_OK elapsed=61s` |
| conformance apps (SKIP_CAPTURE re-render) | all rows at their board values (no `lower` line) |
| Linux build (`swift:6.2-noble`) | `openrender` complete, 163.96 s |
