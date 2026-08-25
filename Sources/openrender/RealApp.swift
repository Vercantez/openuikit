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
}

@MainActor
let realAppVariants: [RealAppVariant] = [
    RealAppVariant(name: "realapp_history_light", style: .light, makeRoot: {
        RealAppScreen.makeRoot(variant: .listeningHistory, theme: .light)
    }),
    RealAppVariant(name: "realapp_settings_light", style: .light, makeRoot: {
        RealAppScreen.makeRoot(variant: .settings, theme: .light)
    }),
    RealAppVariant(name: "realapp_settings_dark", style: .dark, makeRoot: {
        RealAppScreen.makeRoot(variant: .settings, theme: .dark)
    }),
]

@MainActor
func runRealApp(_ variant: RealAppVariant, assets: String) -> SceneResult {
    let size = RealAppScreen.windowSize
    let scale: CGFloat = 2
    Timer._reset()
    GlyphInkTable.windowCompositing = false
    OpenUIKitRuntime.systemFontCut = .iOS
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: variant.style,
                                                  displayScale: scale)
    RealAppScreen.configureAssets(directory: assets)
    OpenUIKitRuntime.imageScreenScale = scale
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size), scale: scale)

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.overrideUserInterfaceStyle = variant.style
    let root = variant.makeRoot()
    window.rootViewController = root
    window.makeKeyAndVisible()
    // openrender has no run loop, so viewDidAppear never fires on its own.
    (root as? BackdropViewController)?.presentPickerNow()
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
    let layout = JSONValue.object(["name": .string(variant.name),
                                   "views": .array(views)])
    let bmp = UIRenderer.render(window, scale: scale)
    OpenUIKitRuntime.animationTime = 0
    realAppRetained.append(window)
    realAppRetained.append(root)
    return SceneResult(name: variant.name,
                       pngs: [("\(variant.name).png", bmp.pngData())],
                       layout: layout)
}

/// Presentations are held by the presenter; the window and root are held here
/// so nothing is torn down before the render completes.
var realAppRetained: [AnyObject] = []
