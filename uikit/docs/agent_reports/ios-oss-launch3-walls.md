# ios-oss (Kickstarter) launch pass 3: Apple Pay, ServerDrivenUI, into Library

**Date:** 2026-09-22. **Branch:** `agent/ios-oss-walls` (continues [ios-oss-launch2-walls.md](ios-oss-launch2-walls.md)); commits `f582062d`, `e9ca7c76`, `9d35ff3e`, `b5496afe` and this report.
**Route:** (b), Apple toolchain on the macOS target, the same chain spec and checkouts as pass 2.
**Status:** first screen **not reached**. Apple Pay is closed. ServerDrivenUI is down to one family of errors, and that family is the macOS AppKit leak, which the `ios-target` pass now owns. Library has been type-checked once, as an uncommitted experiment with the leak removed: its own errors then fell to **1**, an `NSAttributedString` identity wall in the port. Kickstarter-Framework is **not reached**.

## Census

Machine-readable file: [ios-oss-launch3-census.json](ios-oss-launch3-census.json). It covers the committed state and the experiment.

| target | pass 2 end | committed now | behind the leak (experiment E, not committed) |
|---|---:|---:|---:|
| StripeApplePay / Stripe / StripePaymentSheet | 3 / blocked / blocked | **0 / 0 / 0** | — |
| all other shims, Prelude…Lottie (30 targets) | 0 | 0 | — |
| ServerDrivenUI | 24 own | **12 own** (all TextBlock.swift:41-58, leak) | **0** |
| Library (372 files) | blocked | blocked by ServerDrivenUI | 16, then 1 after the member fixes below (with a generated alias, see (4)) |
| Kickstarter-Framework / App | blocked | blocked | blocked by Library |

Experiment E dropped `import AppKit` from OpenUIKit and removed the `!canImport(SwiftUICore)` guard in SwiftUI's TextAttributes. In the working tree only, it:
- declared IndexPath `item` / `section` / `init(item:section:)` as `@_disfavoredOverload`;
- made UIResponder's `awakeFromNib` a fresh declaration.

It is not committed, because two things broke inside the package:
- Blockzilla's TooltipView relies on AppKit's `NSString.boundingRect` reaching it through that import (3 errors).
- A UINib test override became ambiguous.

The coordinator also assigned macOS-leak plumbing to `ios-target`. The patch was used only to measure what lies behind the leak.

## macOS-branch leaks measured and left to `ios-target`

| where | condition | errors |
|---|---|---:|
| ServerDrivenUI TextBlock.swift:41, 48, 50, 52, 54, 56, 58 | OpenUIKit `import AppKit` (FoundationTypes.swift:63-73) loads AppKit, and through it Apple's **SwiftUICore**, into every client module (`-Rmodule-loading` on ServerDrivenUI lists AppKit, SwiftUICore, CoreTransferable, Accessibility, DataDetection). Also, SwiftUI TextAttributes.swift:37 `!canImport(SwiftUICore)` is true on the macOS 26 SDK, so the port's `AttributeScopes.SwiftUIAttributes` is never declared and `attributes.font` resolves to Apple's `Font`. | 12 |
| ServerDrivenUI AudioVideoBlock.swift:54 | `import AVFoundation` resolves to Apple's macOS AVFoundation: `AVAudioSession` is unavailable on macOS | 5 |
| ServerDrivenUI AudioVideoBlock.swift:70-72 | `import AVKit` (Apple's macOS AVKit) re-exports Apple's SwiftUI: `Shape`, `accessibilityLabel` and `startsMediaSession` resolve against Apple's types | 3 |
| Kingfisher (pass 2) | `#if os(macOS)` ×56 selects AppKit; `RunLoop` is ambiguous because of the same AppKit import | 69 |

I wrote fail-closed AVFoundation / AVKit / MediaPlayer ports that routed those imports, measured them, and tested them. I then **withdrew** them on the coordinator's instruction. Their iOS 26.1 measurements are committed for whoever ports media: [ios-oss-launch3-avmedia-oracle-ios26.1.json](ios-oss-launch3-avmedia-oracle-ios26.1.json), `Tools/oracle2/avmediaprobe`. The transcript covers:
- AVAudioSession defaults and raw strings;
- AVPlayer's rate after `play()` with and without an item;
- an unreachable item going to `failed` / `NSURLErrorDomain -1003`;
- seeks and periodic observers that never fire;
- AVPlayerLayer, AVAssetImageGenerator, AVPlayerViewController and MPVolumeView defaults.

## (1) Apple Pay, fail closed (`f582062d`)

`Tools/oracle2/applepayprobe` ran on a private iPhone 16 / iOS 26.1; transcript in [ios-oss-launch3-applepay-oracle-ios26.1.json](ios-oss-launch3-applepay-oracle-ios26.1.json). It measured:
- PKPaymentNetwork raw strings;
- raw values for capabilities, shipping, summary-item type, authorization status, and button type and style;
- PKPaymentRequest and PKPaymentSummaryItem defaults;
- PKPaymentAuthorizationResult (`errors: nil` reads `[]`);
- a bare PKPayment;
- PKPaymentButton: class chain via UIButton, frame 140×30, intrinsic size 100×30 for `.plain` and 140×30 for `.buy`, corner radius 4.

Two divergences are deliberate and stated:
- `canMakePayments(...)` returns **false**. The simulator returns true because it ships a simulated card.
- `PKPaymentAuthorizationViewController(paymentRequest:)` is **always nil**. The simulator returns a controller for a complete request.

No payment is ever authorised, and the Apple Pay mark is not drawn. Tests: `PassKitTests` 5/5; each fails if the port claims it can pay.

## (2) UIKit submodules (`e9ca7c76`)

`import UIKit.UIStackView` (Library UIStackView.swift:2) failed with "no such module". Across the ladder corpus, apps also import these UIKit submodules:
- `UIKit.UIGestureRecognizerSubclass` (10 files)
- `UIActivity` (5)
- `UIFont` (2)
- `UIContextMenuConfiguration` (2)

The fix is a C target, `UIKitClangModule`. Its module map declares `module UIKit` with those submodules as empty headers; the shape is copied from the iOS 26.1 SDK's UIKit module map. Swift loads the Swift `UIKit` shim as its overlay, so every declaration is still OpenUIKit's. The target applies to the Apple toolchain only. `UIKitSubmoduleImportTests` compiles only with it.

## (3) Library members (`9d35ff3e`) and SwiftUI surface (`b5496afe`)

Measured by the new probes `swiftuia11yprobe` and `iososslibraryprobe` (transcripts committed).

**UIKit:**
- **`UIAccessibilityTraits` raw values were wrong** for all but button and link. The port used 1<<n in declaration order; iOS gives image 4, staticText 64, searchField 1024, startsMediaSession 2048, header 65536, and so on. All 19 are fixed; supportsZoom and toggleButton are added.
- `UILabel.drawText(in:)` is now the drawing hook. iOS calls it once with the bounds, and PaddingLabel's inset moves the text.
- `UIView.minimum/maximumContentSizeCategory` (stored only).
- `shouldAutomaticallyForwardAppearanceMethods` (true).
- `UIActivityItemProvider` methods are now `open`.
- The UIKit shim re-exports UserNotifications on the Apple host (`import UIKit` names `UNAuthorizationStatus` on iOS 26.1).

**SwiftUI:**
- `Font(uiFont)` no longer flattens a registered face (KDS Inter) into the system font.
- New: `Font.italic()`, `Color(Color)`, `Text.TruncationMode`, and `List(selection:)`. `List(selection:)` never writes the selection, and says so.
- New: `.isStaticText` / `.startsMediaSession`, mapped by name. The hosted accessibility tree cannot be measured without an assistive technology; the probe records 0 elements.
- New pass-throughs: `accessibilityHeading(_:)` and `backgroundStyle(_:)`.

Tests: `IosOssLibraryMembersTests` 6/6, `IosOssServerDrivenUITests` 6/6.

## (4) The wall inside Library: two NSAttributedStrings

OpenUIKit declares its own `NSAttributedString`, and the UIKit shim aliases it. A file that imports **both** Foundation and UIKit therefore sees both types, and Swift reports them as ambiguous. This happens in 12 Library files; for example, String+Attributed.swift:4 has 4 errors.

A generated module-local alias, the device Focus's `OpenUIKitGenerated.swift` uses, clears that. It then breaks NumberFormatter.swift:14 instead: `override func attributedString(for:withDefaultAttributes:)` must override Foundation's `Formatter` method, which uses Foundation's type ("method does not override").

Neither spelling compiles all of Library. The fix belongs in the port: on the Apple host, NSAttributedString should be Foundation's, or bridge to it. **Not done.** The alias template is not committed.

Also noted and not changed: `UIContentSizeCategory` raw values in the port are `"extraSmall"`-style, while iOS 26.1 reports `UICTContentSizeCategoryM` for `.medium`.

## Validation

| check | result |
|---|---|
| `swift build`, `--build-tests` | complete |
| new tests | PassKitTests 5/5, IosOssLibraryMembersTests 6/6, IosOssServerDrivenUITests 6/6, UIKitSubmoduleImportTests 1/1 |
| broad filter (IosOss / SwiftUI / buttons / labels / text / fonts / navigation / accessibility) | only the base-commit failures remain: TextFieldDelegateTests, IOSNavigationBarTransitionTests, UIScrollEdgeEffectTests |
| simulators | the 4 probe devices were created and deleted |
| corpus / pins | untouched |
| gate / guest | recorded in the hand-off message |
