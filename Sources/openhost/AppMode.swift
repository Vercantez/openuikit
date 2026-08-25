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

/// Keeps the root view controller alive (HostScene only holds views).
var _appRoot: UIViewController?

/// Default backing scale for `--app` mode (see header).
let appModeDefaultScale: CGFloat = 2

/// The apps `--app <name>` can boot: window size + root factory. The root is
/// a plain UIViewController: most apps hand back a UINavigationController,
/// `showcase` hands back a UITabBarController wrapping three of them.
let appRegistry: [String: (size: CGSize, makeRoot: () -> UIViewController)] = [
    "demo": (DemoApp.windowSize, DemoApp.makeRootViewController),
    "tasks": (TasksApp.windowSize, TasksApp.makeRootViewController),
    "textdemo": (TextDemoApp.windowSize, TextDemoApp.makeRootViewController),
    "showcase": (ShowcaseApp.windowSize, ShowcaseApp.makeRootViewController),
]

func buildAppScene(_ appName: String, scaleOverride: CGFloat?,
                   style: UIUserInterfaceStyle = .light) -> HostScene {
    guard let app = appRegistry[appName] else {
        let names = appRegistry.keys.sorted().joined(separator: ", ")
        fatalError("unknown app \"\(appName)\" (available: \(names))")
    }
    let scale = scaleOverride ?? appModeDefaultScale
    let size = app.size
    GlyphInkTable.windowCompositing = false
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: style,
                                                  displayScale: scale)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    let root = app.makeRoot()
    _appRoot = root
    root.view.frame = window.bounds
    window.addSubview(root.view)
    window.setNeedsLayout()
    window.layoutIfNeeded()
    return HostScene(name: "\(appName)_app", sizePt: size, scale: scale,
                     window: window, container: root.view,
                     sceneAnimationDeadline: 0)
}
