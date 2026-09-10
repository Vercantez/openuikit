import UIKit
// UIToolbar height oracle (agent/toolbar-intrinsic-height, 2026-09-10).
//
// Measures, per device and orientation, everything that decides how tall a
// UIToolbar is: intrinsicContentSize, sizeThatFits, systemLayoutSizeFitting,
// sizeToFit, the frame Auto Layout gives an unconstrained-height bar pinned
// to the bottom of a view controller's view (to view.bottom and to the
// safe-area bottom), and the frame UIKit itself gives the bar it manages
// inside a UINavigationController with isToolbarHidden = false — in window
// points, including the safe-area bottom — with and without items and for
// UIBarStyle .default / .black. Each phase rewrites the JSON so a late
// crash keeps the earlier rows; a DONE marker ends the run.
//
// Recipe: scripts/toolbar_height_probe_sim.sh <outdir> (iPhone 16, iPhone SE
// 3rd gen, iPad A16 — all iOS 26.1). Landscape is requested from inside the
// app with UIWindowScene.requestGeometryUpdate (confprobe's recipe).

var rows: [String: Any] = [:]
var phase: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func size(_ s: CGSize) -> [Double] { [Double(s.width), Double(s.height)] }
func insets(_ i: UIEdgeInsets) -> [Double] { [i.top, i.left, i.bottom, i.right].map(Double.init) }
let docs = NSHomeDirectory() + "/Documents"
func save() {
    let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
    try! data.write(to: URL(fileURLWithPath: docs + "/toolbarheight.json"))
}
func tree(_ v: UIView, depth: Int = 0) -> [[String: Any]] {
    var out: [[String: Any]] = []
    for s in v.subviews {
        out.append(["class": String(describing: type(of: s)), "frame": rect(s.frame), "depth": depth,
                    "hidden": s.isHidden])
        if depth < 3 { out.append(contentsOf: tree(s, depth: depth + 1)) }
    }
    return out
}
func traits(_ tc: UITraitCollection) -> [String: Any] {
    ["horizontal": tc.horizontalSizeClass.rawValue, "vertical": tc.verticalSizeClass.rawValue,
     "idiom": tc.userInterfaceIdiom.rawValue, "scale": Double(tc.displayScale)]
}
func styleName(_ s: UIBarStyle) -> String { s == .black ? "black" : "default" }
func threeItems() -> [UIBarButtonItem] {
    [UIBarButtonItem(systemItem: .add), UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(systemItem: .done)]
}

/// Every size-reporting API on one bar, read where it stands (detached or in a host).
func sizes(_ tb: UIToolbar, width w: CGFloat) -> [String: Any] {
    [
        "intrinsic": size(tb.intrinsicContentSize),
        "sizeThatFits.w0": size(tb.sizeThatFits(CGSize(width: w, height: 0))),
        "sizeThatFits.w100": size(tb.sizeThatFits(CGSize(width: w, height: 100))),
        "sizeThatFits.zero": size(tb.sizeThatFits(.zero)),
        "systemLayout.compressed": size(tb.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)),
        "systemLayout.expanded": size(tb.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)),
        "systemLayout.wRequired": size(tb.systemLayoutSizeFitting(CGSize(width: w, height: 0),
                                                                  withHorizontalFittingPriority: .required,
                                                                  verticalFittingPriority: .fittingSizeLevel)),
        "frame": rect(tb.frame),
        "traits": traits(tb.traitCollection),
    ]
}

/// Detached and then hosted (frame-based, 44 high as firefoxrowsprobe did),
/// plus a zero-frame bar after sizeToFit.
func frameCases(in host: UIView, items: Bool, style: UIBarStyle) -> [String: Any] {
    let w = host.bounds.width
    var r: [String: Any] = [:]
    let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: w, height: 44))
    tb.barStyle = style
    if items { tb.items = threeItems() }
    r["detached"] = sizes(tb, width: w)
    host.addSubview(tb)
    tb.layoutIfNeeded()
    r["hosted44"] = sizes(tb, width: w)
    r["hosted44.tree"] = tree(tb)
    for h in [54, 64] as [CGFloat] {
        tb.frame = CGRect(x: 0, y: 100, width: w, height: h)
        tb.setNeedsLayout(); tb.layoutIfNeeded()
        r["hosted\(Int(h))"] = sizes(tb, width: w)
        r["hosted\(Int(h)).tree"] = tree(tb)
    }
    tb.removeFromSuperview()

    let z = UIToolbar()
    z.barStyle = style
    if items { z.items = threeItems() }
    host.addSubview(z)
    z.sizeToFit()
    z.layoutIfNeeded()
    r["zeroFrame.sizeToFit"] = sizes(z, width: w)
    z.removeFromSuperview()
    return r
}

/// Auto Layout: leading/trailing/bottom pinned, no height constraint.
func autoLayoutCases(in vc: UIViewController, items: Bool, style: UIBarStyle, prefix: String) -> [String: Any] {
    var r: [String: Any] = [:]
    for (name, toSafeArea) in [("viewBottom", false), ("safeAreaBottom", true)] {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.barStyle = style
        if items { tb.items = threeItems() }
        vc.view.addSubview(tb)
        let bottom = toSafeArea ? vc.view.safeAreaLayoutGuide.bottomAnchor : vc.view.bottomAnchor
        NSLayoutConstraint.activate([
            tb.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            tb.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            tb.bottomAnchor.constraint(equalTo: bottom),
        ])
        vc.view.layoutIfNeeded()
        tb.layoutIfNeeded()
        var c = sizes(tb, width: vc.view.bounds.width)
        c["frameInWindow"] = rect(tb.convert(tb.bounds, to: nil))
        c["tree"] = tree(tb)
        c["viewBounds"] = rect(vc.view.bounds)
        c["viewSafeArea"] = insets(vc.view.safeAreaInsets)
        r[name] = c
        pendingAutoLayout.append((prefix + "." + name, tb))
    }
    return r
}
/// Auto Layout bars kept alive for one run-loop turn, then re-read: the
/// first read happens in the turn that added them, before UIKit has had a
/// chance to invalidate the intrinsic size for the host's traits.
var pendingAutoLayout: [(String, UIToolbar)] = []

/// Every view under `root` (any depth) whose window-space frame reaches into
/// the bottom `band` points of the window: the bar UIKit really shows.
func bottomViews(_ root: UIView, band: CGFloat, depth: Int = 0) -> [[String: Any]] {
    var out: [[String: Any]] = []
    guard let win = root.window else { return out }
    for s in root.subviews {
        let f = s.convert(s.bounds, to: nil)
        if f.maxY > win.bounds.height - band && f.height < win.bounds.height && f.height > 0 {
            out.append(["class": String(describing: type(of: s)), "frameInWindow": rect(f), "depth": depth,
                        "hidden": s.isHidden, "alpha": Double(s.alpha)])
        }
        if depth < 8 { out.append(contentsOf: bottomViews(s, band: band, depth: depth + 1)) }
    }
    return out
}

final class ToolbarVC: UIViewController {
    let bar = UIToolbar()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.items = threeItems()
        view.addSubview(bar)
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     bar.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var keep: [Any] = []
    var wantLandscape = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        rows["os"] = UIDevice.current.systemVersion
        rows["device"] = UIDevice.current.model
        rows["idiom"] = UIDevice.current.userInterfaceIdiom.rawValue
        rows["screen"] = rect(UIScreen.main.bounds)
        rows["scale"] = Double(UIScreen.main.scale)
        // Cold, detached, before any window exists: what a unit test would see.
        let cold = UIToolbar()
        rows["cold.intrinsic"] = size(cold.intrinsicContentSize)
        rows["cold.sizeThatFits.393x0"] = size(cold.sizeThatFits(CGSize(width: 393, height: 0)))
        cold.items = threeItems()
        rows["cold.items.intrinsic"] = size(cold.intrinsicContentSize)
        rows["cold.items.sizeThatFits.393x0"] = size(cold.sizeThatFits(CGSize(width: 393, height: 0)))
        save()
        let root = UIViewController(); root.view.backgroundColor = .white
        let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root
        w.makeKeyAndVisible(); window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.run(orientation: "portrait") }
        return true
    }

    func run(orientation: String) {
        guard let w = window else { return }
        phase = [:]
        phase["window"] = rect(w.bounds)
        phase["windowSafeArea"] = insets(w.safeAreaInsets)
        phase["traits"] = traits(w.traitCollection)
        phase["interfaceOrientation"] = w.windowScene?.interfaceOrientation.rawValue ?? -1
        rows[orientation] = phase; save()

        let host = UIViewController(); host.view.backgroundColor = .white
        w.rootViewController = host
        w.layoutIfNeeded()
        var frames: [String: Any] = [:]
        var auto: [String: Any] = [:]
        for style in [UIBarStyle.default, .black] {
            for items in [false, true] {
                let key = "\(styleName(style)).\(items ? "items" : "noItems")"
                frames[key] = frameCases(in: host.view, items: items, style: style)
                auto[key] = autoLayoutCases(in: host, items: items, style: style, prefix: key)
            }
        }
        phase["frame"] = frames
        phase["autoLayout"] = auto
        phase["hostSafeArea"] = insets(host.view.safeAreaInsets)
        rows[orientation] = phase; save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            host.view.layoutIfNeeded()
            var later: [String: Any] = [:]
            for (name, tb) in pendingAutoLayout {
                var c = sizes(tb, width: host.view.bounds.width)
                c["frameInWindow"] = rect(tb.convert(tb.bounds, to: nil))
                c["tree"] = tree(tb)
                later[name] = c
                tb.removeFromSuperview()
            }
            pendingAutoLayout = []
            phase["autoLayout.later"] = later
            rows[orientation] = phase; save()
            self.runNavigation(orientation: orientation, w: w)
        }
    }

    func runNavigation(orientation: String, w: UIWindow) {
        // App-like Auto Layout paths, read one turn later with no synchronous
        // layout in the adding turn: (a) added to the root view of the live
        // host and left to the next layout pass; (b) added in a fresh
        // controller's viewDidLoad, that controller then made the window root.
        let hostA = UIViewController(); hostA.view.backgroundColor = .white
        w.rootViewController = hostA
        let a = UIToolbar(); a.translatesAutoresizingMaskIntoConstraints = false; a.items = threeItems()
        hostA.view.addSubview(a)
        NSLayoutConstraint.activate([a.leadingAnchor.constraint(equalTo: hostA.view.leadingAnchor),
                                     a.trailingAnchor.constraint(equalTo: hostA.view.trailingAnchor),
                                     a.bottomAnchor.constraint(equalTo: hostA.view.bottomAnchor)])
        let b = UIToolbar(); b.translatesAutoresizingMaskIntoConstraints = false
        b.items = threeItems(); b.invalidateIntrinsicContentSize()
        hostA.view.addSubview(b)
        NSLayoutConstraint.activate([b.leadingAnchor.constraint(equalTo: hostA.view.leadingAnchor),
                                     b.trailingAnchor.constraint(equalTo: hostA.view.trailingAnchor),
                                     b.bottomAnchor.constraint(equalTo: hostA.view.safeAreaLayoutGuide.bottomAnchor)])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var deferred: [String: Any] = [:]
            deferred["addedThenWaited.viewBottom"] = ["frame": rect(a.frame), "intrinsic": size(a.intrinsicContentSize),
                                                       "tree": tree(a)]
            deferred["addedThenWaited.safeAreaBottom"] = ["frame": rect(b.frame), "intrinsic": size(b.intrinsicContentSize)]
            let vc = ToolbarVC()
            w.rootViewController = vc
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                deferred["viewDidLoad.viewBottom"] = ["frame": rect(vc.bar.frame), "intrinsic": size(vc.bar.intrinsicContentSize),
                                                      "frameInWindow": rect(vc.bar.convert(vc.bar.bounds, to: nil)),
                                                      "tree": tree(vc.bar), "viewBounds": rect(vc.view.bounds),
                                                      "traits": traits(vc.bar.traitCollection)]
                vc.bar.invalidateIntrinsicContentSize(); vc.view.setNeedsLayout(); vc.view.layoutIfNeeded()
                deferred["viewDidLoad.afterInvalidate"] = ["frame": rect(vc.bar.frame), "intrinsic": size(vc.bar.intrinsicContentSize)]
                phase["autoLayout.deferred"] = deferred
                rows[orientation] = phase; save()
                self.keep.append(hostA); self.keep.append(vc)
                self.runNavigationCases(orientation: orientation, w: w)
            }
        }
    }

    func runNavigationCases(orientation: String, w: UIWindow) {

        // UINavigationController-managed toolbar. One controller per case;
        // the nav becomes the window's root so UIKit lays it out for real.
        var navs: [String: Any] = [:]
        let cases: [(String, Bool, UIBarStyle)] = [
            ("default.noItems", false, .default), ("default.items", true, .default),
            ("black.noItems", false, .black), ("black.items", true, .black),
        ]
        var i = 0
        func next() {
            guard i < cases.count else {
                phase["navigation"] = navs
                rows[orientation] = phase; save()
                self.finish(orientation: orientation)
                return
            }
            let (name, items, style) = cases[i]; i += 1
            let root = UIViewController(); root.view.backgroundColor = .white; root.title = "Root"
            if items { root.toolbarItems = threeItems() }
            let nav = UINavigationController(rootViewController: root)
            nav.toolbar.barStyle = style
            nav.isToolbarHidden = false
            w.rootViewController = nav
            w.layoutIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                nav.view.layoutIfNeeded()
                let tb: UIToolbar = nav.toolbar
                var c: [String: Any] = [:]
                c["toolbarFrame"] = rect(tb.frame)
                c["toolbarFrameInWindow"] = rect(tb.convert(tb.bounds, to: nil))
                c["toolbarSuperview"] = tb.superview.map { String(describing: type(of: $0)) } ?? "nil"
                c["toolbarSuperviewFrame"] = tb.superview.map { rect($0.frame) } ?? []
                c["sizes"] = sizes(tb, width: nav.view.bounds.width)
                c["tree"] = tree(tb)
                c["navViewBounds"] = rect(nav.view.bounds)
                c["navSafeArea"] = insets(nav.view.safeAreaInsets)
                c["rootViewFrame"] = rect(root.view.frame)
                c["rootViewFrameInWindow"] = rect(root.view.convert(root.view.bounds, to: nil))
                c["rootSafeArea"] = insets(root.view.safeAreaInsets)
                c["navBarFrame"] = rect(nav.navigationBar.frame)
                c["items"] = tb.items?.count ?? -1
                c["rootSafeAreaLayoutFrame"] = rect(root.view.safeAreaLayoutGuide.layoutFrame)
                c["bottomViews"] = bottomViews(nav.view, band: 140)
                c["toolbarItemsOnRoot"] = root.toolbarItems?.count ?? -1
                c["isToolbarHidden"] = nav.isToolbarHidden
                c["toolbarHidden"] = tb.isHidden
                navs[name] = c
                phase["navigation"] = navs
                rows[orientation] = phase; save()
                self.keep.append(nav)
                next()
            }
        }
        next()
    }

    func finish(orientation: String) {
        guard let w = window else { return }
        if orientation == "portrait" {
            let blank = UIViewController(); blank.view.backgroundColor = .white
            w.rootViewController = blank
            wantLandscape = true
            requestLandscape(attempts: 0)
        } else {
            save()
            FileManager.default.createFile(atPath: docs + "/DONE", contents: nil)
            print("toolbarheightprobe: DONE")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        }
    }

    func requestLandscape(attempts: Int) {
        guard let w = window else { return }
        let s = w.bounds.size
        if s.width > s.height {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.run(orientation: "landscape") }
            return
        }
        if attempts >= 40 {
            rows["landscape"] = ["error": "never rotated after \(attempts) attempts", "window": rect(w.bounds),
                                 "orientation": w.windowScene?.interfaceOrientation.rawValue ?? -1]
            save()
            FileManager.default.createFile(atPath: docs + "/DONE", contents: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
            return
        }
        w.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        w.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeLeft)) { error in
            print("toolbarheightprobe: requestGeometryUpdate \(error)")
            rows["landscape.requestError"] = String(describing: error)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.requestLandscape(attempts: attempts + 1) }
    }

}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
