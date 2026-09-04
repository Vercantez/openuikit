// openhost app-hosting mode (M7.5; rebuilt on the real app lifecycle in
// M12). Owner: host module.
//
// `openhost --app demo` now boots the way a real UIKit app boots:
//
//   UIScreen.main._hostConfigure(...)      // the surface SDL will open
//   UIApplicationMain(delegate: HostAppDelegate(...))
//     -> application(_:willFinishLaunchingWithOptions:)
//     -> application(_:didFinishLaunchingWithOptions:)
//          window = UIWindow(frame: UIScreen.main.bounds)
//          window.rootViewController = <the app's root VC>
//          window.makeKeyAndVisible()
//   ...first frame presented...
//   app._hostDidBecomeActive()             // applicationDidBecomeActive
//   ...run loop (HostCore.runLive)...
//   app._hostWillTerminate()               // applicationWillTerminate
//
// The delegate is a plain `UIResponder, UIApplicationDelegate` — the same
// class shape an app ships — so the window's responder chain really does
// end at ... -> UIWindow -> UIApplication -> HostAppDelegate.
//
// No Foundation here (same rule as HostCore.swift).
//
// Default scale is 2 (crisp): with M8 layer-contents caching a sustained
// scroll recomposites cached card/screen bitmaps instead of re-rasterizing,
// and a steady scroll frame renders in ~7ms at scale 2 (~2ms at scale 1) on
// the reference machine — comfortably 60fps either way (see
// docs/APP_FEEL.md "Performance").

import OpenUIKit
import DemoApp
import RealAppProbe
import ConformanceApps

/// Keeps the app delegate (and through it the window + root controller)
/// alive: UIApplication.delegate is weak, like UIKit's.
var _appDelegate: HostAppDelegate?

/// Default backing scale for `--app` mode (see header).
let appModeDefaultScale: CGFloat = 2

/// The apps `--app <name>` can boot: window size + root factory. The root is
/// a plain UIViewController: most apps hand back a UINavigationController,
/// `showcase` hands back a UITabBarController wrapping three of them.
// `@MainActor`: the factories build view controllers, which are main-actor
// isolated (as in real UIKit), so the stored closure type must say so too --
// otherwise the conversion silently drops the isolation.
@MainActor
let appRegistry: [String: (size: CGSize, makeRoot: @MainActor () -> UIViewController)] = [
    "demo": (DemoApp.windowSize, DemoApp.makeRootViewController),
    "tasks": (TasksApp.windowSize, TasksApp.makeRootViewController),
    "textdemo": (TextDemoApp.windowSize, TextDemoApp.makeRootViewController),
    "showcase": (ShowcaseApp.windowSize, ShowcaseApp.makeRootViewController),
    "selectors": (SelectorApp.windowSize, SelectorApp.makeRootViewController),
    // M14: NOT a DemoApp screen — UNMODIFIED source from Automattic/
    // pocket-casts-ios, compiled against OpenUIKit (Sources/RealAppProbe,
    // docs/REAL_APP_TEST.md). Live so the sheet's present animation, the
    // row tap highlight and the switch can be driven by hand.
    "pocketcasts": (RealAppScreen.windowSize, RealAppScreen.makeRootViewController),
    // CONFORMANCE APPS (docs/HILLCLIMB.md, Sources/ConformanceApps): the same
    // source the iOS simulator probe compiles against real UIKit. They boot
    // through this registry so the port's side of the comparison really is
    // the app lifecycle, not a scene builder — see ConformanceMode.swift for
    // the scripted replay and the recorder.
    "NavFlow": (NavFlowApp.windowSize, NavFlowApp.makeRoot),
    "Forms": (FormsApp.windowSize, FormsApp.makeRoot),
]

/// The host's app delegate: builds the key window in didFinishLaunching and
/// logs every lifecycle transition, so `--app` mode is also the manual test
/// for the lifecycle ordering the unit tests assert.
final class HostAppDelegate: UIResponder, UIApplicationDelegate {
    var name: String = ""
    var makeRoot: () -> UIViewController = {
        fatalError("HostAppDelegate launched with no root factory configured")
    }
    var window: UIWindow?
    var root: UIViewController?

    /// openhost owns this concrete delegate instance and supplies it directly
    /// to `UIApplicationMain(delegate:)`; no class-name construction is
    /// involved in the portable launch path.
    init(name: String, makeRoot: @escaping () -> UIViewController) {
        self.name = name
        self.makeRoot = makeRoot
        super.init()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        let vc = makeRoot()
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        root = vc
        print("lifecycle: didFinishLaunching  app=\(name) "
              + "window=\(fmt3(w.bounds.width))x\(fmt3(w.bounds.height)) "
              + "scale=\(fmt3(UIScreen.main.scale))")
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("lifecycle: didBecomeActive     state=\(application.applicationState)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("lifecycle: willResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("lifecycle: didEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("lifecycle: willEnterForeground")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("lifecycle: willTerminate")
    }
}

@MainActor
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
    // The screen an app reads (UIWindow(frame: UIScreen.main.bounds)) is the
    // surface this host is really going to open — see UIScreen.swift.
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size),
                                 scale: scale)

    let delegate = HostAppDelegate(name: appName, makeRoot: app.makeRoot)
    _appDelegate = delegate
    UIApplicationMain(delegate: delegate)

    guard let window = delegate.window, let root = delegate.root else {
        fatalError("app \"\(appName)\" did not create a window in didFinishLaunching")
    }
    window.setNeedsLayout()
    window.layoutIfNeeded()
    // M14 real-app screen: OpenUIKit's UIWindow does not run an appearance
    // transition when it becomes key (real UIKit does), so the app's
    // `viewDidAppear`-time presentation has to be kicked here. Recorded as a
    // gap in docs/REAL_APP_TEST.md.
    if let backdrop = root as? BackdropViewController {
        backdrop.presentPickerNow()
        window.layoutIfNeeded()
    }
    return HostScene(name: "\(appName)_app", sizePt: size, scale: scale,
                     window: window, container: root.view,
                     sceneAnimationDeadline: 0)
}
