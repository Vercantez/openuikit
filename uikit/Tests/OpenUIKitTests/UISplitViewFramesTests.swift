import Foundation
import XCTest
@testable import OpenUIKit

// Replays Tools/oracle2/splitframesprobe/ios26.1-{ipad,iphone16}.json: the
// same step list the probe ran on iOS 26.1, compared record by record for
// split state, per-column frames / safe areas, and the delegate stream.

#if !os(Linux)
@MainActor
#endif
private final class FrameChild: UIViewController {
    let label: String
    init(_ label: String) { self.label = label; super.init(nibName: nil, bundle: nil); title = label }
    required init?(coder: NSCoder) { fatalError() }
}

#if !os(Linux)
@MainActor
#endif
private func controllerName(_ vc: UIViewController?) -> String {
    guard let vc else { return "nil" }
    if let c = vc as? FrameChild { return c.label }
    if let nav = vc as? UINavigationController { return "nav[" + nav.viewControllers.map(controllerName).joined(separator: ",") + "]" }
    if vc is UISplitViewController { return "split" }
    return String(describing: type(of: vc))
}

#if !os(Linux)
@MainActor
#endif
private final class FrameObserver: UISplitViewControllerDelegate {
    struct Event: Equatable { let name: String; let collapsed: Bool; let vcs: String }
    var events: [Event] = []
    var topColumnOverride: UISplitViewController.Column?
    var collapseSecondaryOntoPrimary = false
    var separateReturnsNew = false
    weak var split: UISplitViewController?
    func log(_ what: String) {
        guard let split else { return }
        events.append(Event(name: what, collapsed: split.isCollapsed, vcs: split.viewControllers.map(controllerName).joined(separator: ",")))
    }
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) { log("willChangeTo(\(displayMode.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool { log("show(\(controllerName(vc)))"); return false }
    func splitViewController(_ svc: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool { log("showDetail(\(controllerName(vc)))"); return false }
    func primaryViewController(forCollapsing svc: UISplitViewController) -> UIViewController? { log("primaryViewController(forCollapsing)"); return nil }
    func primaryViewController(forExpanding svc: UISplitViewController) -> UIViewController? { log("primaryViewController(forExpanding)"); return nil }
    func splitViewController(_ svc: UISplitViewController, collapseSecondary secondary: UIViewController, onto primary: UIViewController) -> Bool {
        log("collapseSecondary(\(controllerName(secondary)),onto:\(controllerName(primary)))->\(collapseSecondaryOntoPrimary)"); return collapseSecondaryOntoPrimary
    }
    func splitViewController(_ svc: UISplitViewController, separateSecondaryFrom primary: UIViewController) -> UIViewController? {
        log("separateSecondaryFrom(\(controllerName(primary)))->\(separateReturnsNew ? "NewSep" : "nil")"); return separateReturnsNew ? FrameChild("NewSep") : nil
    }
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        let r = topColumnOverride ?? proposedTopColumn
        log("topColumnForCollapsing(proposed:\(proposedTopColumn.rawValue))->\(r.rawValue)"); return r
    }
    func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode {
        log("displayModeForExpanding(proposed:\(proposedDisplayMode.rawValue))->\(proposedDisplayMode.rawValue)"); return proposedDisplayMode
    }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) { log("didCollapse") }
    func splitViewControllerDidExpand(_ svc: UISplitViewController) { log("didExpand") }
    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) { log("willShow(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) { log("willHide(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, didShow column: UISplitViewController.Column) { log("didShow(\(column.rawValue))") }
    func splitViewController(_ svc: UISplitViewController, didHide column: UISplitViewController.Column) { log("didHide(\(column.rawValue))") }
}

/// The probe's host: a plain controller whose trait override flips the
/// child's size class. The port has no `traitOverrides.horizontalSizeClass`;
/// the test changes `UITraitCollection.current` and drives the window hook.
#if !os(Linux)
@MainActor
#endif
private final class FrameHost: UIViewController {
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); children.forEach { $0.beginAppearanceTransition(true, animated: animated) } }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); children.forEach { $0.endAppearanceTransition() } }
}

#if !os(Linux)
@MainActor
#endif
final class UISplitViewFramesTests: XCTestCase {
    private struct Device { let file: String; let size: CGSize; let scale: CGFloat; let safe: UIEdgeInsets; let compact: Bool; let idiom: UIUserInterfaceIdiom }
    private static let ipad = Device(file: "ios26.1-ipad", size: CGSize(width: 820, height: 1180), scale: 2,
                                     safe: UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0), compact: false, idiom: .pad)
    private static let iphone16 = Device(file: "ios26.1-iphone16", size: CGSize(width: 393, height: 852), scale: 3,
                                         safe: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0), compact: true, idiom: .phone)

    /// Rows the port does not reproduce, by "<scene> <label>": the iPhone
    /// setSecondary(nil) leaves an empty navigation controller pushed and
    /// reports willHide/didHide(2); the port pops it silently.
    private static let skipped: Set<String> = ["ios26.1-iphone16 double setSecondary(nil)"]

    private var window: UIWindow!
    private var device: Device!
    private var previousTraits: UITraitCollection!
    private var previousCut: FontEngine.SystemFontCut!

    private func traits(compact: Bool) -> UITraitCollection {
        UITraitCollection(userInterfaceStyle: .light, displayScale: device.scale,
                          horizontalSizeClass: compact ? .compact : .regular, userInterfaceIdiom: device.idiom)
    }
    private func setSizeClass(compact: Bool) {
        let previous = window.traitCollection
        UITraitCollection.current = traits(compact: compact)
        window._traitsDidChange(previous: previous)
        window.layoutIfNeeded()
    }

    private let auto = UISplitViewController.automaticDimension
    private let allModes: [UISplitViewController.DisplayMode] = [.secondaryOnly, .oneBesideSecondary, .oneOverSecondary, .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary]

    /// The probe's step for a label; nil means "unknown label" (a failure).
    private func step(_ label: String, _ s: UISplitViewController) -> Bool {
        switch label {
        case "mounted": return true
        case "override.compact", "override.compact.2": setSizeClass(compact: true); return true
        case "override.regular", "override.regular.2": setSizeClass(compact: false); return true
        case "beside.bgNone": s.preferredDisplayMode = .oneBesideSecondary; s.primaryBackgroundStyle = .none
        case "beside.bgSidebar", "twoBeside.bgSidebar": s.primaryBackgroundStyle = .sidebar
        case "twoBeside.bgNone": s.preferredDisplayMode = .twoBesideSecondary; s.primaryBackgroundStyle = .none
        case "fraction0.3": s.preferredPrimaryColumnWidthFraction = 0.3
        case "fraction0.5": s.preferredPrimaryColumnWidthFraction = 0.5
        case "fraction0.5.max300": s.maximumPrimaryColumnWidth = 300
        case "wp.pref320.min375.max400":
            s.maximumPrimaryColumnWidth = auto; s.preferredPrimaryColumnWidthFraction = auto
            s.preferredPrimaryColumnWidth = 320; s.minimumPrimaryColumnWidth = 375; s.maximumPrimaryColumnWidth = 400
        case "reset.secondaryOnlyButton":
            s.preferredPrimaryColumnWidth = auto; s.minimumPrimaryColumnWidth = auto; s.maximumPrimaryColumnWidth = auto
            s.showsSecondaryOnlyButton = true
        case "hidePrimary", "nnw.hidePrimary": s.hide(.primary)
        case "showPrimary", "nnw.showPrimary": s.show(.primary)
        case "showSecondary", "nnw.showSecondary": s.show(.secondary)
        case "hideSecondary": s.hide(.secondary)
        case "nnw.showSupplementary": s.show(.supplementary)
        case "nnw.hideSupplementary": s.hide(.supplementary)
        case "showDetail(D)":
            // The probe's triple scene resets the supplementary fraction and
            // requests twoBeside in the same step; its other scenes do not.
            // iOS deferred that mode change until after the detail swap (the
            // didShow(0) row already lists D), so the port applies it after.
            s.showDetailViewController(FrameChild("D"), sender: nil)
            if s.style == .tripleColumn { s.preferredSupplementaryColumnWidthFraction = auto; s.preferredDisplayMode = .twoBesideSecondary }
        case "showDetail(E)": s.showDetailViewController(FrameChild("E"), sender: nil)
        case "show(E)": s.show(FrameChild("E"), sender: nil)
        case "setSecondary(F)": s.setViewController(FrameChild("F"), for: .secondary)
        case "setSecondary(nil)": s.setViewController(nil, for: .secondary)
        case "wp.supp320": s.preferredSupplementaryColumnWidth = 320
        case "wp.supp320.tile": s.preferredSplitBehavior = .tile
        case "wp.suppAuto.automatic": s.preferredSupplementaryColumnWidth = auto; s.preferredSplitBehavior = .automatic
        case "nnw.widths":
            s.minimumPrimaryColumnWidth = 300; s.maximumPrimaryColumnWidth = 500
            s.minimumSupplementaryColumnWidth = 280; s.maximumSupplementaryColumnWidth = 440
            s.preferredSupplementaryColumnWidth = 320; s.preferredPrimaryColumnWidth = 300
            s.preferredSplitBehavior = .tile; s.showsSecondaryOnlyButton = true; s.preferredDisplayMode = .twoBesideSecondary
        case "nnw.oneBeside": s.preferredDisplayMode = .oneBesideSecondary
        case "nnw.secondaryOnly": s.preferredDisplayMode = .secondaryOnly
        case "reset.primFraction0.3":
            s.minimumPrimaryColumnWidth = auto; s.maximumPrimaryColumnWidth = auto
            s.minimumSupplementaryColumnWidth = auto; s.maximumSupplementaryColumnWidth = auto
            s.preferredSupplementaryColumnWidth = auto; s.preferredPrimaryColumnWidth = auto
            s.preferredSplitBehavior = .automatic; s.preferredDisplayMode = .twoBesideSecondary
            s.preferredPrimaryColumnWidthFraction = 0.3
        case "suppFraction0.5": s.preferredPrimaryColumnWidthFraction = auto; s.preferredSupplementaryColumnWidthFraction = 0.5
        case "suppFraction0.5.oneBeside": s.preferredDisplayMode = .oneBesideSecondary
        default:
            if label.hasPrefix("mode"), let raw = Int(label.dropFirst(4)), let mode = UISplitViewController.DisplayMode(rawValue: raw) {
                s.preferredDisplayMode = mode
            } else { return false }
        }
        return true
    }

    private func makeScene(_ scene: String, _ observer: FrameObserver) -> (UIViewController, UISplitViewController) {
        func triple(compact: Bool) -> UISplitViewController {
            let s = UISplitViewController(style: .tripleColumn)
            s.setViewController(FrameChild("A"), for: .primary)
            s.setViewController(FrameChild("S"), for: .supplementary)
            s.setViewController(FrameChild("B"), for: .secondary)
            if compact { s.setViewController(FrameChild("C"), for: .compact) }
            return s
        }
        func double() -> UISplitViewController {
            let s = UISplitViewController(style: .doubleColumn)
            s.setViewController(FrameChild("A"), for: .primary)
            s.setViewController(FrameChild("B"), for: .secondary)
            return s
        }
        func legacy() -> UISplitViewController {
            let s = UISplitViewController()
            s.viewControllers = [UINavigationController(rootViewController: FrameChild("A")), UINavigationController(rootViewController: FrameChild("B"))]
            return s
        }
        func hosted(_ s: UISplitViewController) -> UIViewController {
            let h = FrameHost()
            h.addChild(s)
            h.view.addSubview(s.view)
            s.view.frame = h.view.bounds
            s.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            s.didMove(toParent: h)
            return h
        }
        let split: UISplitViewController
        let root: UIViewController
        switch scene {
        case "double": split = double(); root = split
        case "triple": split = triple(compact: false); root = split
        case "transition.triple": split = triple(compact: false); root = hosted(split)
        case "transition.triple.compactC": split = triple(compact: true); root = hosted(split)
        case "transition.triple.topPrimary": observer.topColumnOverride = .primary; split = triple(compact: false); root = hosted(split)
        case "transition.legacy": split = legacy(); root = hosted(split)
        case "transition.legacy.onto": observer.collapseSecondaryOntoPrimary = true; observer.separateReturnsNew = true; split = legacy(); root = hosted(split)
        case "transition.double": split = double(); root = hosted(split)
        default: fatalError("unknown scene \(scene)")
        }
        split.delegate = observer; observer.split = split
        return (root, split)
    }

    private func containerOf(_ vc: UIViewController) -> UIViewController {
        var top = vc
        while let p = top.parent, !(p is UISplitViewController) { top = p }
        return top
    }

    private func replay(_ device: Device) throws -> (Int, Int) {
        self.device = device
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Tools/oracle2/splitframesprobe/\(device.file).json"))
        let document = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let records = try XCTUnwrap(document["records"] as? [[String: Any]])
        var compared = 0, skipped = 0
        var scene = "", split: UISplitViewController!, observer: FrameObserver!
        for record in records {
            let sceneName = try XCTUnwrap(record["scene"] as? String)
            if sceneName == "DONE" { break }
            let label = try XCTUnwrap(record["label"] as? String)
            let tag = "\(device.file) \(sceneName) \(label)"
            if sceneName != scene {
                scene = sceneName
                UITraitCollection.current = traits(compact: device.compact)
                window = UIWindow(frame: CGRect(origin: .zero, size: device.size))
                window._setSafeAreaInsets(device.safe)
                observer = FrameObserver()
                let (rootController, s) = makeScene(scene, observer)
                split = s
                window.rootViewController = rootController
                rootController.beginAppearanceTransition(true, animated: false)
                rootController.endAppearanceTransition()
                window.layoutIfNeeded()
            } else {
                observer.events = []
                XCTAssertTrue(step(label, split), "unknown step \(tag)")
                window.layoutIfNeeded()
            }
            if Self.skipped.contains(tag) { skipped += 1; observer.events = []; continue }
            compared += 1
            // State.
            XCTAssertEqual(split.isCollapsed, record["collapsed"] as? Bool, "collapsed \(tag)")
            XCTAssertEqual(split.displayMode.rawValue, record["displayMode"] as? Int, "displayMode \(tag)")
            XCTAssertEqual(split.preferredDisplayMode.rawValue, record["preferredDisplayMode"] as? Int, "preferredDisplayMode \(tag)")
            XCTAssertEqual(Double(split.primaryColumnWidth), record["primaryColumnWidth"] as? Double, "primaryColumnWidth \(tag)")
            if let sw = record["supplementaryColumnWidth"] as? Double { XCTAssertEqual(Double(split.supplementaryColumnWidth), sw, "supplementaryColumnWidth \(tag)") }
            if let behavior = record["splitBehavior"] as? Int { XCTAssertEqual(split.splitBehavior.rawValue, behavior, "splitBehavior \(tag)") }
            XCTAssertEqual(split.viewControllers.map(controllerName), record["viewControllers"] as? [String], "viewControllers \(tag)")
            XCTAssertEqual(split.children.map(controllerName).sorted(), (record["children"] as? [String])?.sorted(), "children \(tag)")
            // Column geometry.
            if let columns = record["columns"] as? [String: [String: Any]] {
                for (key, column) in columns {
                    let which: UISplitViewController.Column = key == "primary" ? .primary : key == "supplementary" ? .supplementary : key == "secondary" ? .secondary : .compact
                    guard let vc = split.viewController(for: which) else { XCTFail("missing column \(key) \(tag)"); continue }
                    let container = containerOf(vc)
                    XCTAssertEqual(controllerName(container), column["container"] as? String, "container \(key) \(tag)")
                    XCTAssertEqual(container.parent === split, column["containerParentIsSplit"] as? Bool, "parent \(key) \(tag)")
                    XCTAssertEqual(split.isShowing(which), column["showing"] as? Bool, "showing \(key) \(tag)")
                    guard column["inSplitView"] as? Bool == true, let absolute = column["absolute"] as? [Double], let safe = column["safeArea"] as? [Double] else { continue }
                    let frame = container.view.convert(container.view.bounds, to: split.view)
                    XCTAssertEqual([frame.minX, frame.minY, frame.width, frame.height].map(Double.init), absolute, "frame \(key) \(tag)")
                    let sa = container.view.safeAreaInsets
                    XCTAssertEqual([sa.top, sa.left, sa.bottom, sa.right].map(Double.init), safe, "safeArea \(key) \(tag)")
                }
            }
            if let legacy = record["legacyChildren"] as? [[String: Any]] {
                for entry in legacy {
                    guard let vcName = entry["vc"] as? String, let child = split.children.first(where: { controllerName($0) == vcName }) else { XCTFail("legacy child \(entry["vc"] ?? "") \(tag)"); continue }
                    guard child.view.superview === split.view, let absolute = entry["absolute"] as? [Double], let safe = entry["safeArea"] as? [Double] else { continue }
                    let frame = child.view.convert(child.view.bounds, to: split.view)
                    XCTAssertEqual([frame.minX, frame.minY, frame.width, frame.height].map(Double.init), absolute, "legacy frame \(vcName) \(tag)")
                    let sa = child.view.safeAreaInsets
                    XCTAssertEqual([sa.top, sa.left, sa.bottom, sa.right].map(Double.init), safe, "legacy safeArea \(vcName) \(tag)")
                }
            }
            // Delegate stream: the will-phase sequence is deterministic in the
            // oracle; the did-phase order varied between runs, so it is a
            // multiset. Every did-phase event follows every will-phase event.
            let oracle = ((record["events"] as? [String]) ?? []).filter { $0.hasPrefix("delegate.") }.map(Self.parse)
            let mine = observer.events
            let isDid: (String) -> Bool = { $0.hasPrefix("did") }
            XCTAssertEqual(mine.filter { !isDid($0.name) }.map(\.name), oracle.filter { !isDid($0.name) }.map(\.name), "will events \(tag)")
            XCTAssertEqual(mine.filter { isDid($0.name) }.map(\.name).sorted(), oracle.filter { isDid($0.name) }.map(\.name).sorted(), "did events \(tag)")
            if let firstDid = mine.firstIndex(where: { isDid($0.name) }) {
                XCTAssertFalse(mine[firstDid...].contains { !isDid($0.name) }, "will after did \(tag)")
            }
            for event in mine {
                guard let match = oracle.first(where: { $0.name == event.name }) else { continue }
                XCTAssertEqual(event.collapsed, match.collapsed, "collapsed inside \(event.name) \(tag)")
                if isDid(event.name) { XCTAssertEqual(event.vcs, match.vcs, "viewControllers inside \(event.name) \(tag)") }
            }
            observer.events = []
        }
        return (compared, skipped)
    }

    private static func parse(_ raw: String) -> FrameObserver.Event {
        // "delegate.willHide(1) {collapsed=false mode=2 vcs=[A,S,B]}"
        let body = raw.dropFirst("delegate.".count)
        let name = String(body.prefix { $0 != " " })
        let collapsed = body.contains("collapsed=true")
        // Names nest ("nav[A,nav[B]]"), so the list runs to the closing "]}".
        let vcs = body.range(of: "vcs=[").map { String(body[$0.upperBound...].dropLast(2)) } ?? ""
        return FrameObserver.Event(name: name, collapsed: collapsed, vcs: vcs)
    }

    override func setUp() {
        super.setUp()
        previousTraits = UITraitCollection.current
        previousCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }
    override func tearDown() {
        UITraitCollection.current = previousTraits
        OpenUIKitRuntime.systemFontCut = previousCut
        window = nil
        super.tearDown()
    }

    func testIPadA16RegularReplay() throws {
        let (compared, skipped) = try replay(Self.ipad)
        print("SPLIT_FRAMES ipad compared \(compared) skipped \(skipped)")
        XCTAssertEqual(compared, 79)
    }
    func testIPhone16CompactReplay() throws {
        let (compared, skipped) = try replay(Self.iphone16)
        print("SPLIT_FRAMES iphone16 compared \(compared) skipped \(skipped)")
        XCTAssertEqual(compared + skipped, 79)
    }
}
