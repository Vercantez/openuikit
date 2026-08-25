// openhost app-hosting mode (M7.5). Owner: host module.
//
// `openhost --app demo` boots a UIApplication-lite: a live UIWindow whose
// root is the DemoApp's UINavigationController, driven by the same event /
// animation-clock / render loop as scene mode (runLive / runScripted in
// HostCore.swift). No Foundation here (same rule as HostCore.swift).
//
// Default scale is 2 (crisp): with M8 layer-contents caching a sustained
// scroll recomposites cached card/screen bitmaps instead of re-rasterizing,
// and a steady scroll frame renders in ~7ms at scale 2 (~2ms at scale 1) on
// the reference machine — comfortably 60fps either way (see
// docs/APP_FEEL.md "Performance").

import OpenUIKit
import DemoApp

/// Keeps the root navigation controller alive (HostScene only holds views).
var _appRootNav: UINavigationController?

/// Default backing scale for `--app` mode (see header).
let appModeDefaultScale: CGFloat = 2

func buildAppScene(_ appName: String, scaleOverride: CGFloat?) -> HostScene {
    guard appName == "demo" else {
        fatalError("unknown app \"\(appName)\" (available: demo)")
    }
    let scale = scaleOverride ?? appModeDefaultScale
    let size = DemoApp.windowSize
    GlyphInkTable.windowCompositing = false
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                  displayScale: scale)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    let nav = DemoApp.makeRootViewController()
    _appRootNav = nav
    nav.view.frame = window.bounds
    window.addSubview(nav.view)
    window.setNeedsLayout()
    window.layoutIfNeeded()
    return HostScene(name: "demo_app", sizePt: size, scale: scale,
                     window: window, container: nav.view,
                     sceneAnimationDeadline: 0)
}
