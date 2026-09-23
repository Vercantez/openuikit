// `@main` on a UIApplicationDelegate, and Info.plist scene manifests.
//
// UIKit's `UIApplicationDelegate.main()` is what `@main final class
// AppDelegate: UIResponder, UIApplicationDelegate` calls (NetNewsWire
// iOS/AppDelegate.swift:23). It builds the delegate from its class, runs
// UIApplicationMain, and -- for an app whose Info.plist declares a
// UIApplicationSceneManifest -- connects the scene the manifest names:
// the scene delegate class by name, the storyboard's initial controller in a
// window UIKit creates and hands to the delegate, then the foreground
// transition. `main()` then runs the main thread's CFRunLoop, as
// UIApplicationMain does: the main dispatch queue, Foundation's Timers and
// RunLoop sources are all serviced by it. OpenUIKit's own host clock
// (animations, transitions, scroll physics, the host-clock timers) advances
// only through `UIWindow.tick(timestamp:)`, so the loop carries a display-rate
// ticker that feeds it (`_installHeadlessTicker`).
//
// MEASURED Tools/oracle2/scenelaunchprobe/transcript-ios26.1.txt (iPhone 16,
// iOS 26.1, the probe app has exactly NetNewsWire's manifest shape):
//   AppDelegate.init                       applicationState background (2)
//   willFinishLaunching / didFinishLaunching   no scenes yet
//   (a main-queue turn: e.g. the remote-notification registration failure)
//   configurationForConnecting             config already from the plist:
//                                          name, delegateClass, storyboard
//   SceneDelegate.init
//   initial controller init(coder:)        (the storyboard's)
//   sceneDelegate.window = window          not key, hidden, frame = screen,
//                                          no root yet
//   scene(_:willConnectTo:options:)        scene unattached (-1); window has
//                                          the root controller, not key, hidden
//   root viewDidLoad / viewWillAppear      (makeKeyAndVisible)
//   root viewSafeAreaInsetsDidChange
//   sceneWillEnterForeground               window key and visible
//   root viewDidAppear
//   sceneDidBecomeActive                   scene foregroundActive (0), a later turn
// The application delegate gets no applicationDidBecomeActive in a scene app.

#if canImport(Foundation)
import class Foundation.Bundle
import class Foundation.ProcessInfo
import struct Foundation.Data
import struct Foundation.URL
#if canImport(ObjectiveC)
import func Foundation.NSClassFromString
#endif
#endif
#if canImport(Foundation) && canImport(Dispatch)
import Dispatch
#endif
#if canImport(Foundation) && canImport(ObjectiveC)
import CoreFoundation
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// MARK: - The scene delegate's `window`

/// Writes a Swift scene delegate's own `var window: UIWindow?`. UIKit sets
/// that property through the ObjC-optional `window` requirement before it
/// calls `scene(_:willConnectTo:options:)` (MEASURED above; NetNewsWire's
/// SceneDelegate starts with `window!.tintColor`). A Swift delegate's plain
/// stored `window` is not the port's double-optional requirement. On an
/// Objective-C runtime the stored property is an ivar of the NSObject
/// subclass; the writer finds it by name, checks with Mirror that it really
/// holds `UIWindow?`, and assigns through a typed pointer (ordinary Swift
/// retain/release). Nothing else is ever written.
@MainActor
enum _UIDelegateWindowWriter {
    static func write(_ window: UIWindow?, into object: AnyObject) -> Bool {
#if canImport(ObjectiveC)
        var cls: AnyClass? = type(of: object)
        var mirror: Mirror? = Mirror(reflecting: object)
        while let current = cls, let m = mirror {
            if let child = m.children.first(where: { $0.label == "window" }) {
                guard type(of: child.value) == Optional<UIWindow>.self,
                      let ivar = class_getInstanceVariable(current, "window") else { return false }
                let base = Unmanaged.passUnretained(object).toOpaque()
                let slot = (base + ivar_getOffset(ivar)).assumingMemoryBound(to: Optional<UIWindow>.self)
                slot.pointee = window
                return true
            }
            cls = class_getSuperclass(current)
            mirror = m.superclassMirror
        }
#endif
        return false
    }
}

extension UIWindowSceneDelegate {
    /// Hands `window` to the delegate the way UIKit does (see
    /// `_UIDelegateWindowWriter`). Returns whether the delegate had one.
    @discardableResult
    func _setWindowLikeUIKit(_ window: UIWindow?) -> Bool {
        _UIDelegateWindowWriter.write(window, into: self)
    }
}

// MARK: - The Info.plist scene manifest

/// One `UISceneConfigurations` entry of `UIApplicationSceneManifest`.
public struct _UISceneManifestEntry: Equatable, Sendable {
    public var name: String?
    public var delegateClassName: String?
    public var storyboardName: String?
    public var sceneClassName: String?
}

extension UIApplication {
    /// The window-application entries of an Info.plist's
    /// UIApplicationSceneManifest, in plist order.
    public static func _sceneManifestEntries(infoDictionary info: [String: Any]?) -> [_UISceneManifestEntry] {
        guard let manifest = info?["UIApplicationSceneManifest"] as? [String: Any],
              let configurations = manifest["UISceneConfigurations"] as? [String: Any],
              let entries = configurations["UIWindowSceneSessionRoleApplication"] as? [[String: Any]]
        else { return [] }
        return entries.map {
            _UISceneManifestEntry(name: $0["UISceneConfigurationName"] as? String,
                                  delegateClassName: $0["UISceneDelegateClassName"] as? String,
                                  storyboardName: $0["UISceneStoryboardFile"] as? String,
                                  sceneClassName: $0["UISceneClassName"] as? String)
        }
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    /// Connects the manifest's scene in UIKit's measured order (file header).
    /// Returns the scene, or nil when the delegate class cannot be found.
    @discardableResult
    public func _hostConnectSceneFromManifest(_ entry: _UISceneManifestEntry,
                                              bundle: Bundle? = nil) -> UIWindowScene? {
        guard let appDelegate = delegate else {
            preconditionFailure("UIApplication must be launched before connecting a scene")
        }
        let session = UISceneSession()
        let planned = UISceneConfiguration(name: entry.name, sessionRole: session.role)
        if let className = entry.delegateClassName {
            planned.delegateClass = NSClassFromString(className)
        }
        if let storyboardName = entry.storyboardName {
            planned.storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        }
        session.configuration = planned
        let options = UIScene.ConnectionOptions()
        let configuration = appDelegate.application(self, configurationForConnecting: session,
                                                    options: options)
        session.configuration = configuration
        guard let delegateType = configuration.delegateClass as? NSObject.Type,
              let sceneDelegate = delegateType.init() as? UIWindowSceneDelegate else {
            return nil
        }
        let scene = UIWindowScene(session: session)
        scene.delegate = sceneDelegate
        _connect(scene: scene)
        scene.activationState = .unattached   // MEASURED -1 through willConnectTo

        var window: UIWindow?
        if let storyboard = configuration.storyboard {
            let root = storyboard.instantiateInitialViewController()
            let w = UIWindow(windowScene: scene)
            w._keyOnlyWhenMadeKey = true
            w.isHidden = true
            if let insets = UIApplication._headlessSafeArea { w._setSafeAreaInsets(insets) }
            sceneDelegate._setWindowLikeUIKit(w)
            w.rootViewController = root
            window = w
        }
        sceneDelegate.scene(scene, willConnectTo: session, options: options)
        if window == nil, case let .some(.some(created)) = sceneDelegate.window {
            window = created
        }
        // MEASURED order: viewDidLoad, viewWillAppear (view not yet in the
        // window), safe-area change as the view is installed, then
        // sceneWillEnterForeground (window key and visible), viewDidAppear.
        let root = window?.rootViewController
        root?.beginAppearanceTransition(true, animated: false)
        window?.makeKeyAndVisible()
        window?.layoutIfNeeded()
        sceneDelegate.sceneWillEnterForeground(scene)
        applicationState = .inactive
        scene.activationState = .foregroundInactive
        root?.endAppearanceTransition()
        return scene
    }

    /// The later turn in which UIKit activates the connected scene
    /// (MEASURED: sceneDidBecomeActive with the scene foregroundActive, and
    /// no applicationDidBecomeActive for a scene app).
    public func _hostActivateConnectedScenes() {
        applicationState = .active
        for s in connectedScenes {
            s.activationState = .foregroundActive
            s.delegate?.sceneDidBecomeActive(s)
        }
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: self)
    }
#endif
}

// MARK: - `@main`

extension UIApplicationDelegate {
    /// UIKit's entry point for `@main` on an application delegate. Never
    /// returns: it launches, connects the manifest's scene, and runs the
    /// headless main loop (see `UIApplication._runMain`).
    @MainActor
    public static func main() {
        UIApplication._runMain(delegateType: Self.self)
    }
}

extension UIApplication {
    /// Headless launch for `@main` apps. The screen comes from the host
    /// environment (`OPENUIKIT_SCREEN=393x852@3`, safe area
    /// `OPENUIKIT_SAFE_AREA=59,0,34,0`: the iPhone 16 portrait values measured
    /// for the real-app screens); `OPENUIKIT_SNAPSHOT_PNG=<path>` renders the
    /// key window after `OPENUIKIT_SNAPSHOT_DELAY` seconds (default 2) and
    /// exits 0. Without a snapshot path the loop runs until the process ends.
#if canImport(ObjectiveC)
    /// The synchronous half of `main()`: the delegate built from its class,
    /// then the launch callbacks, all while the application reports
    /// `.background` (MEASURED 2 at init, willFinish and didFinish).
    @MainActor
    public static func _mainLaunch(delegateType: UIApplicationDelegate.Type) -> UIApplication {
        let app = UIApplication.shared
        app.applicationState = .background
        guard let cls = delegateType as? NSObject.Type,
              let appDelegate = cls.init() as? UIApplicationDelegate else {
            fatalError("UIApplicationDelegate.main(): \(delegateType) is not an NSObject subclass")
        }
        _ = app._hostLaunch(delegate: appDelegate, launchOptions: nil, launchState: .background)
        return app
    }
#endif

    @MainActor
    public static func _runMain(delegateType: UIApplicationDelegate.Type) -> Never {
#if canImport(Foundation) && canImport(ObjectiveC) && canImport(Dispatch)
        let env = ProcessInfo.processInfo.environment
        if let resources = Bundle.main.resourcePath {
            _ = _adoptBundledOpenUIKitResources(bundleResourcePath: resources)
        }
        _configureHeadlessScreen(env)
        let app = _mainLaunch(delegateType: delegateType)
        let entries = UIApplication._sceneManifestEntries(infoDictionary: Bundle.main.infoDictionary)
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let entry = entries.first {
                    app._hostConnectSceneFromManifest(entry)
                    DispatchQueue.main.async {
                        MainActor.assumeIsolated { app._hostActivateConnectedScenes() }
                    }
                } else {
                    app._hostDidBecomeActive()
                }
            }
        }
        if let path = env["OPENUIKIT_SNAPSHOT_PNG"] {
            let delay = Double(env["OPENUIKIT_SNAPSHOT_DELAY"] ?? "") ?? 2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                MainActor.assumeIsolated {
                    _writeKeyWindowSnapshot(to: path)
                    exit(0)
                }
            }
        }
        _installHeadlessTicker()
        CFRunLoopRun()
        exit(0)
#else
        fatalError("UIApplicationDelegate.main() needs Foundation, Dispatch and the ObjC runtime")
#endif
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    /// Adds a 60 Hz CFRunLoop timer (common modes) to the main run loop. Each
    /// fire sets `OpenUIKitRuntime.animationTime` to the seconds since the
    /// ticker started and ticks the key window (or the first window): the
    /// host-clock steppers are process-wide, so one tick per frame advances
    /// all of them. Returns the timer so a host (or test) can invalidate it.
    @MainActor
    @discardableResult
    public static func _installHeadlessTicker(interval: CFTimeInterval = 1.0 / 60) -> CFRunLoopTimer {
        let start = CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(nil, start + interval, interval, 0, 0) { _ in
            MainActor.assumeIsolated {
                let now = CFAbsoluteTimeGetCurrent() - start
                OpenUIKitRuntime.animationTime = now
                let app = UIApplication.shared
                (app.keyWindow ?? app.windows.first)?.tick(timestamp: now)
            }
        }!
        CFRunLoopAddTimer(CFRunLoopGetMain(), timer, .commonModes)
        return timer
    }
#endif

#if canImport(Foundation)
    @MainActor
    static func _configureHeadlessScreen(_ env: [String: String]) {
        var size = CGSize(width: 393, height: 852)
        var scale: CGFloat = 3
        if let spec = env["OPENUIKIT_SCREEN"] {
            let parts = spec.split(separator: "@")
            let dims = parts.first?.split(separator: "x").compactMap { Double($0) } ?? []
            if dims.count == 2 { size = CGSize(width: dims[0], height: dims[1]) }
            if parts.count == 2, let s = Double(parts[1]) { scale = CGFloat(s) }
        }
        OpenUIKitRuntime.imageScreenScale = scale
        // An `@main` UIApplicationDelegate is an iOS app: iOS's SF cut and the
        // iOS-harvested symbol ink, as every other iOS host sets
        // (openrender RealApp.swift, openhost, host_full).
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size), scale: scale)
        // The process-wide trait environment an iPhone app launches into: the
        // device idiom, the screen's scale, light style, the default Large
        // content size. NetNewsWire keys its large title on the idiom
        // (MainFeedCollectionViewController.swift:127 `if
        // traitCollection.userInterfaceIdiom == .phone`); with the
        // unspecified idiom the headless host left, the feed list never got
        // its large "Feeds" title. OPENUIKIT_IDIOM=pad / OPENUIKIT_STYLE=dark
        // select the iPad idiom and dark appearance.
        let idiom: UIUserInterfaceIdiom = env["OPENUIKIT_IDIOM"] == "pad" ? .pad : .phone
        UIDevice.current.userInterfaceIdiom = idiom
        OpenUIKitRuntime.assetCatalogIdiom = idiom
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: env["OPENUIKIT_STYLE"] == "dark" ? .dark : .light,
            displayScale: scale,
            preferredContentSizeCategory: .large,
            userInterfaceIdiom: idiom)
        let insets = (env["OPENUIKIT_SAFE_AREA"] ?? "59,0,34,0")
            .split(separator: ",").compactMap { Double($0) }
        if insets.count == 4 {
            _headlessSafeArea = UIEdgeInsets(top: insets[0], left: insets[1],
                                             bottom: insets[2], right: insets[3])
        }
    }

    /// An app bundle that carries OpenUIKit's measured tables (metrics, glyph
    /// and symbol ink, system colours) in `<resources>/OpenUIKit/` -- the way
    /// a framework's resource bundle ships inside an iOS app -- uses them;
    /// otherwise the configured `resourceRoot` stays. Returns whether the
    /// bundled tables were adopted. Fonts are not required here (the glyph
    /// rasterizer's own lookup applies), unlike the SwiftUI packaged-app
    /// contract (`configureApplicationBundleResources`).
    @MainActor
    @discardableResult
    static func _adoptBundledOpenUIKitResources(bundleResourcePath: String) -> Bool {
        let root = bundleResourcePath + "/OpenUIKit"
        guard ResourceIO.readFile(root + "/font_metrics.json") != nil else { return false }
        OpenUIKitRuntime.resourceRoot = root
        UIImage.clearNamedCache()
        return true
    }

    /// The key window's view tree in the shape Tools/oracle2/nnwgolden's
    /// LayoutDump.m writes for the iOS golden: path, class, frame in the
    /// superview, window frame, hidden, label text. A measurement aid for
    /// comparing the port's hierarchy with the real one.
    @MainActor
    static func _layoutJSON(of window: UIWindow) -> String {
        func esc(_ s: String) -> String {
            var out = ""
            for u in s.unicodeScalars {
                switch u {
                case "\"": out += "\\\""
                case "\\": out += "\\\\"
                case "\n": out += "\\n"
                default:
                    if u.value < 0x20 { out += String(format: "\\u%04x", u.value) } else { out.unicodeScalars.append(u) }
                }
            }
            return out
        }
        func nums(_ r: CGRect) -> String { "[\(r.origin.x), \(r.origin.y), \(r.size.width), \(r.size.height)]" }
        var rows: [String] = []
        func walk(_ v: UIView, _ path: String) {
            let wf = v.convert(v.bounds, to: window)
            var row = "{\"path\": \"\(path)\", \"class\": \"\(esc(String(describing: type(of: v))))\", "
                + "\"frame\": \(nums(v.frame)), \"window_frame\": \(nums(wf)), "
                + "\"hidden\": \(v.isHidden || v.alpha < 0.01)"
            if let label = v as? UILabel, let text = label.text { row += ", \"text\": \"\(esc(text))\", \"font\": \(label.font.pointSize)" }
            rows.append(row + "}")
            for (i, sub) in v.subviews.enumerated() {
                walk(sub, path.isEmpty ? "\(i)" : "\(path).\(i)")
            }
        }
        walk(window, "")
        let b = window.bounds
        return "{\"screen\": {\"scale\": \(UIScreen.main.scale), \"size\": [\(b.width), \(b.height)]}, \"views\": [\n"
            + rows.joined(separator: ",\n") + "\n]}\n"
    }

    /// Applied to every window the headless host creates (UIWindow's
    /// registration hook reads it).
    @MainActor static var _headlessSafeArea: UIEdgeInsets?

    @MainActor
    static func _writeKeyWindowSnapshot(to path: String) {
        guard let window = UIApplication.shared.keyWindow else {
            print("OPENUIKIT_SNAPSHOT: no key window")
            return
        }
        window.layoutIfNeeded()
        let scale = UIScreen.main.scale
        let bitmap = UIRenderer.render(window, scale: scale)
        let png = bitmap.pngData()
        do {
            try Data(png).write(to: URL(fileURLWithPath: path))
            print("OPENUIKIT_SNAPSHOT_WRITTEN \(path) \(bitmap.width)x\(bitmap.height)")
            if let layoutPath = ProcessInfo.processInfo.environment["OPENUIKIT_SNAPSHOT_LAYOUT_JSON"] {
                try Data(_layoutJSON(of: window).utf8).write(to: URL(fileURLWithPath: layoutPath))
                print("OPENUIKIT_LAYOUT_WRITTEN \(layoutPath)")
            }
        } catch {
            print("OPENUIKIT_SNAPSHOT: write failed \(error)")
        }
    }
#endif
}
