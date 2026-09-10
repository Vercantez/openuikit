// UISplitViewController column geometry + collapse/expand delegate-order oracle.
// Built by scripts/splitframes_probe_sim.sh for iOS 26.1 on iPad (A16) 820×1180
// @2x (regular width: expanded) and iPhone 16 393×852 @3x (compact: collapsed).
// Every step mutates one split, waits 0.7 s, and appends a settled snapshot to
// Documents/splitframes.json: state, per-column frames (own + absolute), safe
// areas, and every delegate / child-lifecycle event in the order it fired.
import UIKit

var records: [[String: Any]] = []
var events: [String] = []
let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
func flush() {
    let doc: [String: Any] = [
        "ios": UIDevice.current.systemVersion, "model": UIDevice.current.model,
        "screen": rect(UIScreen.main.bounds), "scale": UIScreen.main.scale,
        "records": records]
    let data = try! JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted, .sortedKeys])
    try! data.write(to: docs.appendingPathComponent("splitframes.json"))
}
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.size.width, r.size.height].map { Double($0) } }
func insets(_ i: UIEdgeInsets) -> [Double] { [i.top, i.left, i.bottom, i.right].map { Double($0) } }
func name(_ vc: UIViewController?) -> String {
    guard let vc else { return "nil" }
    if let c = vc as? Child { return c.label }
    if let nav = vc as? UINavigationController { return "nav[" + nav.viewControllers.map(name).joined(separator: ",") + "]" }
    if let tab = vc as? UITabBarController { return "tab[" + (tab.viewControllers ?? []).map(name).joined(separator: ",") + "]" }
    if vc is UISplitViewController { return "split" }
    return String(describing: type(of: vc))
}

final class Child: UIViewController {
    let label: String
    init(_ label: String) { self.label = label; super.init(nibName: nil, bundle: nil); title = label }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = .white; events.append("\(label).viewDidLoad") }
    override func viewWillAppear(_ a: Bool) { super.viewWillAppear(a); events.append("\(label).viewWillAppear") }
    override func viewDidAppear(_ a: Bool) { super.viewDidAppear(a); events.append("\(label).viewDidAppear") }
    override func viewWillDisappear(_ a: Bool) { super.viewWillDisappear(a); events.append("\(label).viewWillDisappear") }
    override func viewDidDisappear(_ a: Bool) { super.viewDidDisappear(a); events.append("\(label).viewDidDisappear") }
    override func willMove(toParent p: UIViewController?) { super.willMove(toParent: p); events.append("\(label).willMove(\(name(p)))") }
    override func didMove(toParent p: UIViewController?) { super.didMove(toParent: p); events.append("\(label).didMove(\(name(p)))") }
}

func state(_ s: UISplitViewController) -> String {
    "collapsed=\(s.isCollapsed) mode=\(s.displayMode.rawValue) vcs=[\(s.viewControllers.map(name).joined(separator: ","))]"
}

final class Observer: NSObject, UISplitViewControllerDelegate {
    var topColumnOverride: UISplitViewController.Column?
    var expandModeOverride: UISplitViewController.DisplayMode?
    var collapseSecondaryOntoPrimary = false
    var separateReturnsNew = false
    weak var split: UISplitViewController?
    func log(_ what: String) { events.append("delegate." + what + " {" + (split.map(state) ?? "") + "}") }
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) { log("willChangeTo(\(displayMode.rawValue))") }
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode { log("targetDisplayModeForAction"); return .automatic }
    func splitViewController(_ svc: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool { log("show(\(name(vc)))"); return false }
    func splitViewController(_ svc: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool { log("showDetail(\(name(vc)))"); return false }
    func primaryViewController(forCollapsing svc: UISplitViewController) -> UIViewController? { log("primaryViewController(forCollapsing)"); return nil }
    func primaryViewController(forExpanding svc: UISplitViewController) -> UIViewController? { log("primaryViewController(forExpanding)"); return nil }
    func splitViewController(_ svc: UISplitViewController, collapseSecondary secondary: UIViewController, onto primary: UIViewController) -> Bool {
        log("collapseSecondary(\(name(secondary)),onto:\(name(primary)))->\(collapseSecondaryOntoPrimary)"); return collapseSecondaryOntoPrimary
    }
    func splitViewController(_ svc: UISplitViewController, separateSecondaryFrom primary: UIViewController) -> UIViewController? {
        log("separateSecondaryFrom(\(name(primary)))->\(separateReturnsNew ? "NewSep" : "nil")"); return separateReturnsNew ? Child("NewSep") : nil
    }
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        let r = topColumnOverride ?? proposedTopColumn
        log("topColumnForCollapsing(proposed:\(proposedTopColumn.rawValue))->\(r.rawValue)"); return r
    }
    func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode {
        let r = expandModeOverride ?? proposedDisplayMode
        log("displayModeForExpanding(proposed:\(proposedDisplayMode.rawValue))->\(r.rawValue)"); return r
    }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) { log("didCollapse") }
    func splitViewControllerDidExpand(_ svc: UISplitViewController) { log("didExpand") }
    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) { log("willShow(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) { log("willHide(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, didShow column: UISplitViewController.Column) { log("didShow(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, didHide column: UISplitViewController.Column) { log("didHide(\(column.rawValue))") }
}

func columnInfo(_ s: UISplitViewController, _ column: UISplitViewController.Column) -> [String: Any]? {
    guard s.style != .unspecified, let vc = s.viewController(for: column) else { return nil }
    var info: [String: Any] = ["vc": name(vc), "showing": s.isShowing(column)]
    var top: UIViewController = vc
    while let p = top.parent, !(p is UISplitViewController) { top = p }
    info["container"] = name(top)
    info["containerParentIsSplit"] = top.parent === s
    if let v = top.viewIfLoaded {
        info["frame"] = rect(v.frame)
        info["absolute"] = rect(v.convert(v.bounds, to: nil))
        info["safeArea"] = insets(v.safeAreaInsets)
        info["inSplitView"] = v.isDescendant(of: s.view)
        info["hidden"] = v.isHidden
        info["alpha"] = Double(v.alpha)
    }
    if let v = vc.viewIfLoaded, v !== top.viewIfLoaded {
        info["vcFrame"] = rect(v.frame)
        info["vcAbsolute"] = rect(v.convert(v.bounds, to: nil))
        info["vcSafeArea"] = insets(v.safeAreaInsets)
    }
    return info
}

func snapshot(_ scene: String, _ label: String, _ s: UISplitViewController) {
    s.view.layoutIfNeeded()
    var r: [String: Any] = [
        "scene": scene, "label": label, "style": s.style.rawValue,
        "collapsed": s.isCollapsed, "displayMode": s.displayMode.rawValue,
        "preferredDisplayMode": s.preferredDisplayMode.rawValue,
        "primaryColumnWidth": Double(s.primaryColumnWidth),
        "viewControllers": s.viewControllers.map(name),
        "children": s.children.map(name),
        "splitFrame": rect(s.view.frame), "splitAbsolute": rect(s.view.convert(s.view.bounds, to: nil)),
        "splitSafeArea": insets(s.view.safeAreaInsets),
        "horizontalSizeClass": s.traitCollection.horizontalSizeClass.rawValue,
        "subviews": s.view.subviews.map { String(describing: type(of: $0)) + rect($0.frame).description },
        "events": events,
    ]
    if s.style != .unspecified {
        // MEASURED: the legacy split raises NSInvalidArgumentException for
        // splitBehavior and preferredSplitBehavior ("requires -initWithStyle:").
        r["splitBehavior"] = s.splitBehavior.rawValue
        r["preferredSplitBehavior"] = s.preferredSplitBehavior.rawValue
        r["primaryBackgroundStyle"] = s.primaryBackgroundStyle.rawValue
        if s.style == .tripleColumn { r["supplementaryColumnWidth"] = Double(s.supplementaryColumnWidth) }
        var cols: [String: Any] = [:]
        for (k, c) in [("primary", UISplitViewController.Column.primary), ("supplementary", .supplementary), ("secondary", .secondary), ("compact", .compact)] {
            if let i = columnInfo(s, c) { cols[k] = i }
        }
        r["columns"] = cols
    } else {
        var legacy: [[String: Any]] = []
        for vc in s.children {
            var i: [String: Any] = ["vc": name(vc)]
            if let v = vc.viewIfLoaded { i["frame"] = rect(v.frame); i["absolute"] = rect(v.convert(v.bounds, to: nil)); i["safeArea"] = insets(v.safeAreaInsets) }
            legacy.append(i)
        }
        r["legacyChildren"] = legacy
    }
    events = []
    records.append(r)
    flush()
}

struct Scene {
    let name: String
    let make: () -> (UIViewController, UISplitViewController)
    let steps: [(String, (UISplitViewController, UIViewController) -> Void)]
}

func triple(_ obs: Observer, compact: Bool = false) -> UISplitViewController {
    let s = UISplitViewController(style: .tripleColumn)
    s.setViewController(Child("A"), for: .primary)
    s.setViewController(Child("S"), for: .supplementary)
    s.setViewController(Child("B"), for: .secondary)
    if compact { s.setViewController(Child("C"), for: .compact) }
    s.delegate = obs; obs.split = s
    return s
}
func double(_ obs: Observer) -> UISplitViewController {
    let s = UISplitViewController(style: .doubleColumn)
    s.setViewController(Child("A"), for: .primary)
    s.setViewController(Child("B"), for: .secondary)
    s.delegate = obs; obs.split = s
    return s
}
func legacy(_ obs: Observer) -> UISplitViewController {
    let s = UISplitViewController()
    s.viewControllers = [UINavigationController(rootViewController: Child("A")), UINavigationController(rootViewController: Child("B"))]
    s.delegate = obs; obs.split = s
    return s
}
/// A host whose trait override flips the child's size class (iOS 17 API).
final class Host: UIViewController {
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = .black }
}
func hosted(_ s: UISplitViewController) -> UIViewController {
    let h = Host()
    h.addChild(s)
    h.view.addSubview(s.view)
    s.view.frame = h.view.bounds
    s.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    s.didMove(toParent: h)
    return h
}

let auto = UISplitViewController.automaticDimension
let allModes: [UISplitViewController.DisplayMode] = [.secondaryOnly, .oneBesideSecondary, .oneOverSecondary, .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary]

func scenes() -> [Scene] {
    var list: [Scene] = []
    // 1. Double-column geometry.
    do {
        let obs = Observer()
        var steps: [(String, (UISplitViewController, UIViewController) -> Void)] = [("mounted", { _, _ in })]
        for m in [UISplitViewController.DisplayMode.secondaryOnly, .oneBesideSecondary, .oneOverSecondary] {
            steps.append(("mode\(m.rawValue)", { s, _ in s.preferredDisplayMode = m }))
        }
        steps += [
            ("beside.bgNone", { s, _ in s.preferredDisplayMode = .oneBesideSecondary; s.primaryBackgroundStyle = .none }),
            ("beside.bgSidebar", { s, _ in s.primaryBackgroundStyle = .sidebar }),
            ("fraction0.3", { s, _ in s.preferredPrimaryColumnWidthFraction = 0.3 }),
            ("fraction0.5", { s, _ in s.preferredPrimaryColumnWidthFraction = 0.5 }),
            ("fraction0.5.max300", { s, _ in s.maximumPrimaryColumnWidth = 300 }),
            ("wp.pref320.min375.max400", { s, _ in s.maximumPrimaryColumnWidth = auto; s.preferredPrimaryColumnWidthFraction = auto; s.preferredPrimaryColumnWidth = 320; s.minimumPrimaryColumnWidth = 375; s.maximumPrimaryColumnWidth = 400 }),
            ("reset.secondaryOnlyButton", { s, _ in s.preferredPrimaryColumnWidth = auto; s.minimumPrimaryColumnWidth = auto; s.maximumPrimaryColumnWidth = auto; s.showsSecondaryOnlyButton = true }),
            ("hidePrimary", { s, _ in s.hide(.primary) }),
            ("showPrimary", { s, _ in s.show(.primary) }),
            ("showSecondary", { s, _ in s.show(.secondary) }),
            ("hideSecondary", { s, _ in s.hide(.secondary) }),
            ("showDetail(D)", { s, _ in s.showDetailViewController(Child("D"), sender: nil) }),
            ("show(E)", { s, _ in s.show(Child("E"), sender: nil) }),
            ("setSecondary(F)", { s, _ in s.setViewController(Child("F"), for: .secondary) }),
            ("setSecondary(nil)", { s, _ in s.setViewController(nil, for: .secondary) }),
        ]
        list.append(Scene(name: "double", make: { let s = double(obs); return (s, s) }, steps: steps))
    }
    // 2. Triple-column geometry.
    do {
        let obs = Observer()
        var steps: [(String, (UISplitViewController, UIViewController) -> Void)] = [("mounted", { _, _ in })]
        for m in allModes { steps.append(("mode\(m.rawValue)", { s, _ in s.preferredDisplayMode = m })) }
        steps += [
            ("twoBeside.bgNone", { s, _ in s.preferredDisplayMode = .twoBesideSecondary; s.primaryBackgroundStyle = .none }),
            ("twoBeside.bgSidebar", { s, _ in s.primaryBackgroundStyle = .sidebar }),
            ("wp.supp320", { s, _ in s.preferredSupplementaryColumnWidth = 320 }),
            ("wp.supp320.tile", { s, _ in s.preferredSplitBehavior = .tile }),
            ("wp.suppAuto.automatic", { s, _ in s.preferredSupplementaryColumnWidth = auto; s.preferredSplitBehavior = .automatic }),
            ("nnw.widths", { s, _ in s.minimumPrimaryColumnWidth = 300; s.maximumPrimaryColumnWidth = 500; s.minimumSupplementaryColumnWidth = 280; s.maximumSupplementaryColumnWidth = 440; s.preferredSupplementaryColumnWidth = 320; s.preferredPrimaryColumnWidth = 300; s.preferredSplitBehavior = .tile; s.showsSecondaryOnlyButton = true; s.preferredDisplayMode = .twoBesideSecondary }),
            ("nnw.oneBeside", { s, _ in s.preferredDisplayMode = .oneBesideSecondary }),
            ("nnw.secondaryOnly", { s, _ in s.preferredDisplayMode = .secondaryOnly }),
            ("nnw.showSupplementary", { s, _ in s.show(.supplementary) }),
            ("nnw.showPrimary", { s, _ in s.show(.primary) }),
            ("nnw.hidePrimary", { s, _ in s.hide(.primary) }),
            ("nnw.hideSupplementary", { s, _ in s.hide(.supplementary) }),
            ("nnw.showSecondary", { s, _ in s.show(.secondary) }),
            ("reset.primFraction0.3", { s, _ in s.minimumPrimaryColumnWidth = auto; s.maximumPrimaryColumnWidth = auto; s.minimumSupplementaryColumnWidth = auto; s.maximumSupplementaryColumnWidth = auto; s.preferredSupplementaryColumnWidth = auto; s.preferredPrimaryColumnWidth = auto; s.preferredSplitBehavior = .automatic; s.preferredDisplayMode = .twoBesideSecondary; s.preferredPrimaryColumnWidthFraction = 0.3 }),
            ("suppFraction0.5", { s, _ in s.preferredPrimaryColumnWidthFraction = auto; s.preferredSupplementaryColumnWidthFraction = 0.5 }),
            ("suppFraction0.5.oneBeside", { s, _ in s.preferredDisplayMode = .oneBesideSecondary }),
            ("showDetail(D)", { s, _ in s.preferredSupplementaryColumnWidthFraction = auto; s.preferredDisplayMode = .twoBesideSecondary; s.showDetailViewController(Child("D"), sender: nil) }),
            ("show(E)", { s, _ in s.show(Child("E"), sender: nil) }),
        ]
        list.append(Scene(name: "triple", make: { let s = triple(obs); return (s, s) }, steps: steps))
    }
    // 3. Collapse/expand order: triple, hosted, trait override flips the size class.
    for (variant, compact, topOverride) in [("triple", false, nil), ("triple.compactC", true, nil), ("triple.topPrimary", false, UISplitViewController.Column.primary)] {
        let obs = Observer(); obs.topColumnOverride = topOverride
        let toCompact: (UISplitViewController, UIViewController) -> Void = { _, h in h.traitOverrides.horizontalSizeClass = .compact }
        let toRegular: (UISplitViewController, UIViewController) -> Void = { _, h in h.traitOverrides.horizontalSizeClass = .regular }
        list.append(Scene(name: "transition." + variant, make: { let s = triple(obs, compact: compact); return (hosted(s), s) }, steps: [
            ("mounted", { _, _ in }),
            ("override.compact", toCompact),
            ("override.regular", toRegular),
            ("showSecondary", { s, _ in s.show(.secondary) }),
            ("override.compact.2", toCompact),
            ("override.regular.2", toRegular),
        ]))
    }
    // 4. Legacy collapse/expand and showDetail routing.
    for (variant, onto, sep) in [("legacy", false, false), ("legacy.onto", true, true)] {
        let obs = Observer(); obs.collapseSecondaryOntoPrimary = onto; obs.separateReturnsNew = sep
        list.append(Scene(name: "transition." + variant, make: { let s = legacy(obs); return (hosted(s), s) }, steps: [
            ("mounted", { _, _ in }),
            ("override.compact", { _, h in h.traitOverrides.horizontalSizeClass = .compact }),
            ("showDetail(D)", { s, _ in s.showDetailViewController(Child("D"), sender: nil) }),
            ("override.regular", { _, h in h.traitOverrides.horizontalSizeClass = .regular }),
            ("showDetail(E)", { s, _ in s.showDetailViewController(Child("E"), sender: nil) }),
        ]))
    }
    // 5. Double hosted transitions with column show / detail in the collapsed state.
    do {
        let obs = Observer()
        list.append(Scene(name: "transition.double", make: { let s = double(obs); return (hosted(s), s) }, steps: [
            ("mounted", { _, _ in }),
            ("override.compact", { _, h in h.traitOverrides.horizontalSizeClass = .compact }),
            ("showSecondary", { s, _ in s.show(.secondary) }),
            ("showDetail(D)", { s, _ in s.showDetailViewController(Child("D"), sender: nil) }),
            ("show(E)", { s, _ in s.show(Child("E"), sender: nil) }),
            ("showPrimary", { s, _ in s.show(.primary) }),
            ("override.regular", { _, h in h.traitOverrides.horizontalSizeClass = .regular }),
        ]))
    }
    return list
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var queue = scenes()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        runNext()
        return true
    }
    func runNext() {
        guard !queue.isEmpty else { records.append(["scene": "DONE"]); flush(); exit(0) }
        let scene = queue.removeFirst()
        events = []
        let (root, split) = scene.make()
        window!.rootViewController = root
        var steps = scene.steps
        func step() {
            guard !steps.isEmpty else { self.window!.rootViewController = UIViewController(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.runNext() }; return }
            let (label, action) = steps.removeFirst()
            action(split, root)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                snapshot(scene.name, label, split)
                step()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { step() }
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
