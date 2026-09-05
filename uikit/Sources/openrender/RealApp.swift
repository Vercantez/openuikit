// `openrender realapp <outdir>` — headless render of the REAL-APP screen
// (Sources/RealAppProbe: unmodified pocket-casts source compiled against
// OpenUIKit). Owner: rendercli module.
//
// This is not a scene JSON: the screen is built by the app's own Swift, so
// there is nothing to describe in a fixture. It boots the same way
// `openhost --app` does — UIScreen configured, window, root controller,
// present — and then renders the window, which is what puts the presented
// sheet in the picture.
//
// Like SceneBuilder.swift this file must NOT import Foundation.

import OpenUIKit
import RealAppProbe

struct RealAppVariant {
    let name: String
    let style: UIUserInterfaceStyle
    let makeRoot: () -> UIViewController
    /// The picker variants render a sheet presented over a backdrop; the
    /// storage screen is a plain pushed controller, so there is no
    /// presentation to drive and no 0.4 s transition to run past.
    var presentsSheet = true
    /// Dynamic Type override applied to `UITraitCollection.current` (and
    /// therefore the window) before the screen is built. Default `.large`
    /// is a device's shipped category — identity for every UIFontMetrics
    /// factor, so the original four screens do not move.
    var contentSizeCategory: UIContentSizeCategory = .large
    var idiom: UIUserInterfaceIdiom = .phone
    var windowSize: CGSize = CGSize(width: 393, height: 852)
    var nativeScale: CGFloat = 3
    var safeAreaInsets: UIEdgeInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
}

@MainActor
let realAppVariants: [RealAppVariant] = RealAppScreen.screens.map { screen in
    RealAppVariant(
        name: screen.name,
        style: screen.style,
        makeRoot: { RealAppScreen.makeRoot(variant: screen.variant, theme: screen.theme) },
        presentsSheet: screen.presentsSheet,
        contentSizeCategory: screen.contentSizeCategory,
        idiom: screen.idiom,
        windowSize: screen.windowSize,
        nativeScale: screen.nativeScale,
        safeAreaInsets: screen.safeAreaInsets)
}

/// Render scale; main.swift sets it from OPENUIKIT_REALAPP_SCALE.
nonisolated(unsafe) var realAppScale: CGFloat = 2

@MainActor
func runRealApp(_ variant: RealAppVariant, assets: String) -> SceneResult {
    let size = variant.windowSize
    // Phone goldens are the iPhone 16 at 3x (`OPENUIKIT_REALAPP_SCALE=3`);
    // the Linux byte-identity fixture stays at 2. Pad goldens are the
    // iPad (A16) at native 2x — never resampled up to 3.
    let scale = variant.idiom == .pad ? variant.nativeScale : realAppScale
    Timer._reset()
    GlyphInkTable.windowCompositing = false
    OpenUIKitRuntime.systemFontCut = .iOS
    let savedIdiom = UIDevice.current.userInterfaceIdiom
    let savedAssetIdiom = OpenUIKitRuntime.assetCatalogIdiom
    let savedTraits = UITraitCollection.current
    UIDevice.current.userInterfaceIdiom = variant.idiom
    OpenUIKitRuntime.assetCatalogIdiom = variant.idiom
    // Same override the iOS oracle applies on the window
    // (`UITraitCollection(preferredContentSizeCategory:)` via
    // `traitOverrides`) before capture. Set on `current` *before*
    // `makeRoot` so `UIFont.font(ofSize:weight:scalingWith:)` — which
    // reads `UIFontMetrics.scaledFont` → `UITraitCollection.current` —
    // sees the category at construction. `updateSize()` uses
    // `scaledValue(for:)` *without* `compatibleWith:` which, on the iOS
    // cut, tracks `UIApplication.shared.preferredContentSizeCategory`
    // (always `.large` here) — MEASURED dtmetrics probe, iPhone 16 /
    // iOS 26.1: icons stay 24×24 at every window override.
    //
    // `userInterfaceIdiom: .pad` is the iPad (A16) row
    // (realapp_settings_light_ipad): form-sheet geometry, nav/table
    // chrome and readable-width margins all key off this trait.
    UITraitCollection.current = UITraitCollection(
        userInterfaceStyle: variant.style,
        displayScale: scale,
        preferredContentSizeCategory: variant.contentSizeCategory,
        userInterfaceIdiom: variant.idiom)
    RealAppScreen.configureAssets(directory: assets)
    RealAppScreen.configureNibs(directory: RealAppScreen.defaultNibsDirectory)
    OpenUIKitRuntime.imageScreenScale = scale
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size), scale: scale)

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    // MEASURED (realappprobe, iPhone 16 / iOS 26.1): the window's safe area
    // is [59, 0, 34, 0]; the sheet's detent height gets the 34 added
    // (343 + 34 = 377), which the port could not reproduce with zero insets.
    // iPad (A16) uses `RealAppScreen.padSafeArea`, filled from that
    // capture's window dump — not the phone 59/34.
    window._setSafeAreaInsets(variant.safeAreaInsets)
    window.overrideUserInterfaceStyle = variant.style
    let root = variant.makeRoot()
    window.rootViewController = root
    window.makeKeyAndVisible()
    // openrender has no run loop, so viewDidAppear never fires on its own.
    if variant.presentsSheet {
        (root as? BackdropViewController)?.presentPickerNow()
    } else {
        // A pushed screen's own lifecycle instead: viewWillAppear is where
        // StorageAndDataUseViewController reloads its table.
        root.beginAppearanceTransition(true, animated: false)
        root.endAppearanceTransition()
    }
    window.setNeedsLayout()
    window.layoutIfNeeded()

    // The app presents with `animated: true` (its own source, unmodified), so
    // at t = 0 the sheet is still below the screen and the dim is at alpha 0.
    // Run the shared animation clock past the 0.4 s present transition, the
    // same way an animation fixture captures a later frame.
    OpenUIKitRuntime.animationTime = 1.0
    window.layoutIfNeeded()

    var views: [JSONValue] = []
    dumpLayout(window, path: "", into: &views)
    let layout = JSONValue.object([
        "name": .string(variant.name),
        "views": .array(views),
        "screen": .object([
            "scale": .number(Double(scale)),
            "bounds": .array([.number(Double(size.width)), .number(Double(size.height))]),
        ]),
        "userInterfaceIdiom": .string(variant.idiom == .pad ? "pad" : "phone"),
    ])
    // The nib parser's own honesty log: anything the archive carried that
    // UINib did not model. Printed with the render so a fidelity gap in a
    // nib-loaded variant shows up as a key name, not just as pixels.
    if !UINib.unhandledKeys.isEmpty {
        print("  nib keys not modelled: "
              + UINib.unhandledKeys.sorted().joined(separator: " "))
        UINib.unhandledKeys = []
    }
    let bmp = UIRenderer.render(window, scale: scale)
    // MEASURED realapp_focus_settings_light / realappprobe, iPhone 16 /
    // iOS 26.1: `UIGraphicsImageRendererFormat.opaque = true`, so unpainted
    // window pixels (nil UILayoutContainerView behind a `UIImage()` nav bar)
    // land as (0,0,0,255). The port's Bitmap starts transparent-zero;
    // compare composites that over white. Fill zero-alpha here to match
    // the probe; fully painted screens (Pocket Casts) are unchanged.
    var i = 0
    while i < bmp.pixels.count {
        if bmp.pixels[i + 3] == 0 {
            bmp.pixels[i + 3] = 255
        }
        i += 4
    }
    OpenUIKitRuntime.animationTime = 0
    UIDevice.current.userInterfaceIdiom = savedIdiom
    OpenUIKitRuntime.assetCatalogIdiom = savedAssetIdiom
    UITraitCollection.current = savedTraits
    realAppRetained.append(window)
    realAppRetained.append(root)
    return SceneResult(name: variant.name,
                       pngs: [("\(variant.name).png", bmp.pngData())],
                       layout: layout)
}

/// Presentations are held by the presenter; the window and root are held here
/// so nothing is torn down before the render completes.
var realAppRetained: [AnyObject] = []
