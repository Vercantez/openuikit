# ios-oss (Kickstarter) launch pass 2: the measured walls

**Date:** 2026-09-22. **Branch:** `agent/ios-oss-walls`, base `9cd38125` (main). Merges `agent/uibutton-configuration` (4 commits, 2026-09-10, not previously on main).
**Route:** (b), Apple toolchain (Xcode 26.1 / Swift 6.2.1) → Darwin SwiftPM against OpenUIKit.
**Corpus:** kickstarter/ios-oss `2f2dabb4`, read-only, unpatched. Checkouts: `swift package resolve` of the app's pins (Prelude 1.0.0 `f3a2dc43`, ReactiveExtensions 2.0.0 `36984ccb`, ReactiveSwift 7.1.1 `40c465af`, SwiftSoup 2.6.0, apollo-ios 1.9.3, Kingfisher 8.5.0 `2015fda7`, lottie-ios 4.5.1 `047aa81b`, AlamofireImage 4.3.0, Alamofire 5.10.2, KingfisherWebP 1.7.0 — revisions equal to `Package.resolved`).
**Status:** first screen **not reached; score N/A**. Walls 1–3 are closed at compile level with oracle-measured behaviour; wall 4 (Kingfisher's platform branch) is **open** and replaced by a fail-closed stand-in; wall 5 is covered by fail-closed shims; wall 6 is **not reached**. The next wall is a compile wall in the dependency layer under Library: OpenUIKit's PassKit has no Apple Pay types (3 errors), and ServerDrivenUI has 24 own errors.

## Walls, before → after

Census: `Tools/ingest/chain_census.py` over `ios-oss-launch2-chain.json`, target by target, `--continue`. Machine-readable: [ios-oss-launch2-walls-census.json](ios-oss-launch2-walls-census.json). "Before" is `9cd38125` with the pass-1 spec plus the two spec fixes below (without them KsApi cannot be checked at all).

| module | before (own errors) | after | what closed it |
|---|---:|---:|---|
| ReactiveExtensions | 0 | 0 | wall 1 was already closed on main by `nsobject-value-classes` (aa6d9847: accessibility as an NSObject-conformed protocol) — verified, not redone |
| Prelude_UIKit | 20 | **0** | lens members, §2 |
| KsApi | 1 (reported as 0: see tooling) | **0** | `UIDevice.identifierForVendor`; generated `Secrets.swift`; `MobileCoreServices` product |
| KDS | 65 | **0** | `UIButton.Configuration`, `UIFontDescriptor`, CoreText registry, CGColor model, §3 |
| Kingfisher | 69 (AppKit branch) | 0 — **stand-in** | wall stays open, §4 |
| KingfisherWebP | not built | 0 — shim | |
| Lottie | not built | 0 — **stand-in** (real 4.5.1: **169** errors, 24 files) | §5 |
| 17 service shims | — | 14 pass, StripeApplePay **3**, Stripe / StripePaymentSheet blocked | §5 |
| ServerDrivenUI | blocked | **24** own | next wall |
| Library / Kickstarter_Framework / KickstarterApp | blocked | blocked (StripeApplePay, ServerDrivenUI) | not reached |

Wall 2 (Prelude's `NSObjectProtocol` conformances on CALayer, NSMutableParagraphStyle, UIBarButtonItem, UINavigationItem, UITabBarItem, UIBarItem) was also already closed on main by `5a9299a5`; the 20 errors left in Prelude_UIKit were lens members, below. UIResponder / UIView / UIViewController declarations were not touched.

## (1) Oracle

`Tools/oracle2/iososswallsprobe` (runner `scripts/iososs_walls_probe_sim.sh`): a command-line binary run with `simctl spawn` on a private iPhone 16 / iOS 26.1 (23B86), reading the Prelude / KDS surface, with the app's own Inter font files for the CoreText part. 519 lines, committed verbatim: [ios-oss-launch2-walls-oracle-ios26.1.json](ios-oss-launch2-walls-oracle-ios26.1.json). The simulator device was created by the runner and deleted afterwards.

## (2) Prelude_UIKit and KsApi (commit `204e07ad`)

| member | iOS 26.1 | port |
|---|---|---|
| `UIControl.allTargets` / `actions(forTarget:forControlEvent:)` | `["tap:"]`, then `["tap:", "other"]`; nil target counts once, as NSNull; nil for unregistered | implemented; nil-target registrations are no longer pruned as dead weak targets |
| `UIButton.setBackgroundImage` / `backgroundImage(for:)` / `currentBackgroundImage` | a normal image is also what highlighted/disabled/selected read | same; drawn by a bounds-filling image view created on first use |
| `adjustsImageWhenHighlighted/Disabled` | custom true, system false | stored |
| `UILabel.font` `UIFont!`, `UITextField.font` `UIFont?` | nil → `.SFUI-Regular` 17 | same |
| `UITextView.textColor` `UIColor?`, `font`, `textAlignment`, `isSecureTextEntry` | textColor nil after `= nil`; font nil by default; natural; false | same (alignment / secure entry stored) |
| `UIScrollView.scrollIndicatorInsets` | sets both axes; reads back only while they agree, else `.zero` | same |
| `UIActivityIndicatorView.style` / `color` | raws 100 / 101; getter reads secondaryLabel; nil resets | settable style; `UIColor!` colour (painted default unchanged) |
| `UIProgressView.Style`, `UIStackView.isBaselineRelativeArrangement`, `UITabBar.barTintColor`, `UITableViewController.tableView` setter, `UINavigationController.viewControllers` setter | raws 0/1; false; nil; setter sets `view` | stored / implemented (`setViewControllers(_:animated:)` added) |
| `UIGraphicsBeginImageContext`, canvas `setFillColor` / `fill(_:)` | 1×1 @1, transparent; default fill black | same |
| `UIDevice.identifierForVendor` | simulator: a UUID | **nil** — no identity is minted; KsApi coalesces with `UUID()` |

## (3) KDS (commits `00894128` merge, `204e07ad`, `0370ae05`)

- **UIButton.Configuration**: taken from `agent/uibutton-configuration` (its own 40,755-line iOS 26.1 oracle, 916-line tests), merged cleanly. Two corrections from this pass's measurement: a direct `updateConfiguration()` does not run the handler (2 → 2), the layout-time update does; and factory `background.backgroundColor` / `strokeColor` read back **clear, not nil** (both oracles agree) — now shared sentinel objects so an app-assigned colour is still drawn verbatim. Its 916-line test suite passes with both changes.
- **UIFontDescriptor**: `AttributeName` / `FeatureKey` / `TraitKey` with the measured raw strings, `fontAttributes`, `addingAttributes` (weight → `.SFUI-Bold` / `.SFUI-Semibold` 17, equal to `systemFont(ofSize:weight:)`), `UIFont.Weight.rawValue`. `withSymbolicTraits(.traitBold)` on regular now gives **Semibold** (measured); three AttributedStringTests expectations that encoded Bold were corrected.
- **CoreText**: `CTFontManagerRegisterFontsForURL`, `CTFontManagerScope`, the SFNT feature constants (6/0/1/35/2/4), `UIFont(name:size:)`, `fontName`, `familyName`, `familyNames`, `fontNames(forFamilyName:)`. All 18 Inter names, errors 101/105, and Inter-Regular 16 pt metrics (15.5 / −3.859375 / 19.359375 / cap 11.640625 / x 8.6796875 — the x-height is the "x" glyph at opsz 16, not OS/2) match the oracle (`testInterFromCorpusMatchesOracleNames`, runs with `OPENUIKIT_IOSOSS_CORPUS`). Registered faces render from their file at the named instance with opsz = point size.
- **CGColor gray model**: `numberOfComponents` / `components` — 2 for `white/black/clear/gray`, `UIColor(white:)`, `CGColor(gray:)` and the semantic colours measured gray per style; 4 otherwise. Applied now (it was "measured but not applied" in pass 1).
- `UIAccessibility.isBoldTextEnabled` (false); SwiftUI `background(_:ignoresSafeAreaEdges:)`.
- Found on the way: `GlyphFont.init?(path:)` freed its buffer and returned nil, so `deinit` freed it again (SIGABRT on any font file stb_truetype rejects). Fixed.

## (4) Kingfisher: the platform branch stays open

Kingfisher 8.5.0 selects its platform with `#if os(macOS)` (56 sites): on the macOS target the Apple toolchain builds, `KFCrossPlatformImage` is `NSImage`, `KFImage` is an `NSViewRepresentable`, and the `UIImageView.kf` / `UIButton.kf` extensions the app calls sit in the other branch. Unlike RxCocoa in eidolon (an extra file in the module plus the unchanged AppKit branch), the iOS branch is not reachable by adding a file: no `-D` flag changes `os()`, and compiling Kingfisher alone for an iOS triple cannot link into the macOS executable. **Not solved.** To measure what lies past it, `Sources/KickstarterServiceShims/Kingfisher` is a fail-closed stand-in with exactly the app's surface (`Source`, `KFImage`, `KFAnimatedImage`, `AnimatedImageView`, `ImagePrefetcher`, `ImageCache`, `ImageDownloader`, processor/serializer protocols): every prefetch fails, the cache is empty, `KFImage` shows its placeholder. Options for a real fix, not attempted: a Mac Catalyst build of the whole chain against OpenUIKit (module-name collision with Apple's UIKit), or an OpenUIKit-side Kingfisher adapter reimplementing the iOS branch.

## (5) Service shims and Lottie (commit `34fc4d0d`)

Written by a helper agent from the call sites, reviewed and integrated here; 28/28 tests in the standalone package (`swift test --package-path uikit/Sources/KickstarterServiceShims`), each failing if a shim reports success: Firebase (+Core/Analytics/Crashlytics/RemoteConfig), FacebookCore/Login, StripePayments/ApplePay/PaymentSheet + umbrella, BrazeKit/UI, Segment, SegmentBrazeUI, AlamofireImage, KingfisherWebP, Kingfisher, Lottie. A few SDK constants were written from the pinned SDKs' documentation rather than read from their sources (Remote Config error codes 8001–8003, `STPErrorCode` values, Braze defaults) — flagged in the file headers.

Lottie 4.5.1 itself compiles its `canImport(UIKit)` branch against OpenUIKit and stops at **169 errors / 24 files** (32 × `cannot find 'bounds'` in its layer extensions, `CALayerContentsGravity`, `CAAnimation` overrides, `contentMode`, `CGImage`). The stand-in's `LottieAnimationView` is an empty view that never plays; the onboarding illustration band is empty — the band the iOS golden must mask anyway because it animates.

Tooling: SwiftPM target names are unique across a graph, and OpenUIKit's manifest declares Eidolon's `Stripe` shim, so Kickstarter's `Stripe` could not load. Module aliasing does not avoid it (measured). The chain now depends on a filtered symlink view of the OpenUIKit manifest without that one target (`openuikit_manifest_filter`); OpenUIKit's manifest is unchanged.

## (6) The next wall (exact)

1. `StripeApplePay` (and so Stripe, StripePaymentSheet, Library, Framework, App): `cannot find type 'PKPayment' in scope` ×2, `'PKPaymentRequest'` ×1 — OpenUIKit's `PassKit` is Wallet-only; the app also uses `PKPaymentAuthorizationViewController`, `PKPaymentNetwork`, `PKPaymentSummaryItem`, `PKPaymentAuthorizationStatus/Result`, `PKPaymentButton`. Needs a measured, fail-closed Apple Pay surface.
2. `ServerDrivenUI` 24 own: SwiftUI `AttributeContainer` font attribute (10), `AccessibilityHeadingLevel`, `AVAudioSession` unavailable on macOS (5 — Apple's AVFoundation), `Color` → `UIColor`, `clipShape(_:style:)`, `backgroundStyle`, `OEmbedWebView: UIViewRepresentable`, `WKWebView.scrollView / backgroundColor`.
3. Library (372 files) and Kickstarter-Framework (353) have still never been semantically checked; the first screen (SwiftUI `OnboardingView` in a `UIHostingController`) sits in Framework.

## Tooling changes

`spm_app_chain.py`: `generated` (Secrets.swift from the public example, `isOSS = true`, as the oracle build did), `macos_deployment` (15.0 for the app's iOS 18), `openuikit_manifest_filter`, extra packages / aliased products. `chain_census.py`: attributes errors behind per-entry symlinks to the target (KsApi's own error was reported as a dependency error). 8 + 1 fixture tests.

## Validation

| check | result |
|---|---|
| `swift build` (all Darwin targets) | complete, 0 errors |
| `IosOssWallsTests` (29) + `UIButtonConfigurationTests` + `AttributedStringTests` + `UIButtonTests` | all pass |
| broad filter (controls / text / fonts / colours / navigation: 678 tests) | 12 failures, all pre-existing: `TextFieldDelegateTests` (2 tests), `KeyboardChromeTests`, `IOSNavigationBarTransitionTests`, `UIScrollEdgeEffectTests` fail the same way on the base commit run with the same filters in a detached base worktree |
| shim package | 28/28 |
| ingest tests | spm_app_chain 8/8, chain_census 1/1 |
| corpus | never written; Secrets.swift exists only in the generated chain directory |
| pins | no `Package.resolved`, `.app` or vendored file changed |
| push | `git push` of the branch was denied by the permission system; commits are local |
| merge check / guest verify | GATE_AND_GUEST_PLACEHOLDER |
