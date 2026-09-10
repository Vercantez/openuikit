// UIScrollEdgeEffect oracle (iOS 26): the default top/bottom edge effects a
// UIScrollView / UITableView / UICollectionView gets under a navigation bar
// and a tab bar (or toolbar), when they engage as the content offset moves,
// the pixel profile per style (.automatic / .soft / .hard), what
// `isHidden = true` removes, the effect's relation to a
// UIScrollEdgeElementContainerInteraction on the same scroll view, and the
// `style` read-back defaults. Each phase leaves the app idle so the driving
// script (scripts/scroll_edge_effect_probe_sim.sh) can take a render-server
// screenshot (drawHierarchy never shows the effect).
import UIKit

var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func insets(_ i: UIEdgeInsets) -> [Double] { [i.top, i.left, i.bottom, i.right].map(Double.init) }
func marker(_ name: String) { FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data()) }
func waitAck(_ name: String, then: @escaping () -> Void) {
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(name).ack") { then(); return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { waitAck(name, then: then) }
}
func ptr(_ o: AnyObject) -> String { String(UInt(bitPattern: ObjectIdentifier(o).hashValue), radix: 16) }
func styleName(_ s: UIScrollEdgeEffect.Style) -> String {
    if s === UIScrollEdgeEffect.Style.automatic { return "automatic" }
    if s === UIScrollEdgeEffect.Style.soft { return "soft" }
    if s === UIScrollEdgeEffect.Style.hard { return "hard" }
    return "other:" + String(describing: s)
}
func effectRow(_ e: UIScrollEdgeEffect) -> [String: Any] {
    ["style": styleName(e.style), "styleDescription": String(describing: e.style), "hidden": e.isHidden,
     "ptr": ptr(e), "class": NSStringFromClass(type(of: e)), "isNSObject": e.isKind(of: NSObject.self)]
}
func effectsRow(_ s: UIScrollView) -> [String: Any] {
    ["top": effectRow(s.topEdgeEffect), "bottom": effectRow(s.bottomEdgeEffect),
     "left": effectRow(s.leftEdgeEffect), "right": effectRow(s.rightEdgeEffect),
     "topStable": s.topEdgeEffect === s.topEdgeEffect,
     "distinct": Set([ptr(s.topEdgeEffect), ptr(s.bottomEdgeEffect), ptr(s.leftEdgeEffect), ptr(s.rightEdgeEffect)]).count]
}
func tree(_ v: UIView, depth: Int, into out: inout [[String: Any]], limit: Int) {
    guard out.count < limit else { return }
    let cls = NSStringFromClass(type(of: v))
    out.append(["d": depth, "class": cls, "frame": rect(v.frame), "alpha": Double(v.alpha), "hidden": v.isHidden,
                "opaque": v.isOpaque, "bg": v.backgroundColor.map { String(describing: $0) } ?? "nil",
                "sublayers": (v.layer.sublayers ?? []).map { NSStringFromClass(type(of: $0)) }.filter { !$0.hasSuffix("CALayer") },
                "filters": (v.layer.filters ?? []).map { String(describing: $0) }])
    for s in v.subviews { tree(s, depth: depth + 1, into: &out, limit: limit) }
}
func windowTree(_ w: UIWindow) -> [[String: Any]] {
    var out: [[String: Any]] = []
    tree(w, depth: 0, into: &out, limit: 400)
    return out
}

/// Fills a scrolling view with 40 pt black/red bands so a 1 pt column
/// profile reads the effect's alpha directly.
let bandCount = 75
let bandHeight: CGFloat = 40
func bandColor(_ i: Int) -> UIColor { i % 2 == 0 ? .black : .red }

final class ScrollVC: UIViewController {
    let scroll = UIScrollView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scroll.frame = view.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: view.bounds.width, height: CGFloat(bandCount) * bandHeight)
        for i in 0..<bandCount {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * bandHeight, width: view.bounds.width, height: bandHeight))
            band.autoresizingMask = [.flexibleWidth]
            band.backgroundColor = bandColor(i)
            scroll.addSubview(band)
        }
        view.addSubview(scroll)
    }
}

final class TableVC: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = bandHeight
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { bandCount }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
        c.backgroundColor = bandColor(indexPath.row)
        c.contentView.backgroundColor = bandColor(indexPath.row)
        c.selectionStyle = .none
        return c
    }
}

final class CollectionVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    init() {
        let l = UICollectionViewFlowLayout()
        l.minimumLineSpacing = 0; l.minimumInteritemSpacing = 0
        super.init(collectionViewLayout: l)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { bandCount }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath)
        c.backgroundColor = bandColor(indexPath.item)
        return c
    }
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: bandHeight)
    }
}

/// Navigation bar + a 100 pt header container (with a label) sitting below
/// the bar, holding a UIScrollEdgeElementContainerInteraction on the same
/// scroll view that the navigation bar already gives a top edge effect.
final class InteractionVC: UIViewController {
    let scroll = UIScrollView()
    let header = UIView()
    var top: UIScrollEdgeElementContainerInteraction!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scroll.frame = view.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: view.bounds.width, height: CGFloat(bandCount) * bandHeight)
        for i in 0..<bandCount {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * bandHeight, width: view.bounds.width, height: bandHeight))
            band.autoresizingMask = [.flexibleWidth]
            band.backgroundColor = bandColor(i)
            scroll.addSubview(band)
        }
        view.addSubview(scroll)
        header.autoresizingMask = [.flexibleWidth]
        let label = UILabel(frame: CGRect(x: 20, y: 30, width: 200, height: 40))
        label.text = "Header"; label.textColor = .white; label.font = .boldSystemFont(ofSize: 28)
        header.addSubview(label)
        view.addSubview(header)
        top = UIScrollEdgeElementContainerInteraction(); top.edge = .top; top.scrollView = scroll; header.addInteraction(top)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let barBottom = view.safeAreaInsets.top
        header.frame = CGRect(x: 0, y: barBottom, width: view.bounds.width, height: 100)
        scroll.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)
    }
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var tabs: UITabBarController!
    var scrollVC = ScrollVC(), tableVC = TableVC(style: .plain), collectionVC = CollectionVC()
    var toolbarVC = ScrollVC(), largeVC = TableVC(style: .plain), interactionVC = InteractionVC()
    var current: UIScrollView { currentScroll() }
    var currentScroll: () -> UIScrollView = { UIScrollView() }
    var phases: [(String, () -> Void)] = []
    var index = 0

    func record(_ name: String) {
        let s = current
        var row: [String: Any] = [
            "offset": [Double(s.contentOffset.y)], "contentInset": insets(s.contentInset),
            "adjustedInset": insets(s.adjustedContentInset), "safeArea": insets(s.safeAreaInsets),
            "frame": rect(s.frame), "contentHeight": Double(s.contentSize.height),
            "effects": effectsRow(s), "kind": NSStringFromClass(type(of: s)),
        ]
        if let w = window, name.hasSuffix(".rest") || name.hasSuffix(".mid") || name.hasSuffix(".topHidden") || name.hasSuffix(".topHard") || name.hasSuffix(".bottomHidden") || name.hasSuffix(".bottomHard") || name.hasSuffix(".collapsed") {
            row["tree"] = windowTree(w)
        }
        rows[name] = row
    }

    func topRest(_ s: UIScrollView) -> CGFloat { -s.adjustedContentInset.top }
    func bottomRest(_ s: UIScrollView) -> CGFloat { s.contentSize.height - s.bounds.height + s.adjustedContentInset.bottom }
    func set(_ y: CGFloat) { current.setContentOffset(CGPoint(x: 0, y: y), animated: false) }

    func addKindPhases(_ kind: String, select: @escaping () -> Void, sweep: [CGFloat], bottomSweep: [CGFloat], styles: Bool) {
        phases.append(("\(kind).rest", { select(); self.set(self.topRest(self.current)) }))
        for d in sweep { phases.append(("\(kind).top+\(Int(d))", { self.set(self.topRest(self.current) + d) })) }
        phases.append(("\(kind).mid", { self.set(self.topRest(self.current) + 100) }))
        phases.append(("\(kind).bottomRest", { self.set(self.bottomRest(self.current)) }))
        for d in bottomSweep { phases.append(("\(kind).bottom-\(Int(d))", { self.set(self.bottomRest(self.current) - d) })) }
        phases.append(("\(kind).mid2", { self.set(self.topRest(self.current) + 100) }))
        phases.append(("\(kind).topHard", { self.current.topEdgeEffect.style = .hard }))
        if styles {
            phases.append(("\(kind).topSoft", { self.current.topEdgeEffect.style = .soft }))
            phases.append(("\(kind).topAutomatic", { self.current.topEdgeEffect.style = .automatic }))
            phases.append(("\(kind).topHardAgain", { self.current.topEdgeEffect.style = .hard }))
        }
        phases.append(("\(kind).topHidden", { self.current.topEdgeEffect.isHidden = true }))
        phases.append(("\(kind).topShown", { self.current.topEdgeEffect.isHidden = false; self.current.topEdgeEffect.style = .automatic }))
        phases.append(("\(kind).bottomHard", { self.current.bottomEdgeEffect.style = .hard }))
        if styles {
            phases.append(("\(kind).bottomSoft", { self.current.bottomEdgeEffect.style = .soft }))
            phases.append(("\(kind).bottomAutomatic", { self.current.bottomEdgeEffect.style = .automatic }))
            phases.append(("\(kind).bottomHardAgain", { self.current.bottomEdgeEffect.style = .hard }))
        }
        phases.append(("\(kind).bottomHidden", { self.current.bottomEdgeEffect.isHidden = true }))
        phases.append(("\(kind).bothHidden", { self.current.topEdgeEffect.isHidden = true }))
        phases.append(("\(kind).bothShown", { self.current.topEdgeEffect.isHidden = false; self.current.bottomEdgeEffect.isHidden = false; self.current.bottomEdgeEffect.style = .automatic }))
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        rows["os"] = UIDevice.current.systemVersion
        rows["screen"] = rect(UIScreen.main.bounds)
        rows["scale"] = Double(UIScreen.main.scale)
        // Read-back on fresh, unattached views.
        let fresh = UIScrollView(), freshTable = UITableView(frame: .zero, style: .plain), freshCollection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        rows["fresh"] = ["scroll": effectsRow(fresh), "table": effectsRow(freshTable), "collection": effectsRow(freshCollection),
                         "styles": ["automatic": ptr(UIScrollEdgeEffect.Style.automatic), "soft": ptr(UIScrollEdgeEffect.Style.soft), "hard": ptr(UIScrollEdgeEffect.Style.hard),
                                    "automaticStable": UIScrollEdgeEffect.Style.automatic === UIScrollEdgeEffect.Style.automatic,
                                    "automaticIsNSObject": UIScrollEdgeEffect.Style.automatic.isKind(of: NSObject.self),
                                    "automaticClass": NSStringFromClass(type(of: UIScrollEdgeEffect.Style.automatic)),
                                    "hardEqualsHard": UIScrollEdgeEffect.Style.hard.isEqual(UIScrollEdgeEffect.Style.hard),
                                    "hardEqualsSoft": UIScrollEdgeEffect.Style.hard.isEqual(UIScrollEdgeEffect.Style.soft),
                                    "descriptions": [String(describing: UIScrollEdgeEffect.Style.automatic), String(describing: UIScrollEdgeEffect.Style.soft), String(describing: UIScrollEdgeEffect.Style.hard)]]]
        fresh.topEdgeEffect.style = .hard; fresh.topEdgeEffect.isHidden = true
        rows["freshAfterSet"] = ["top": effectRow(fresh.topEdgeEffect), "bottom": effectRow(fresh.bottomEdgeEffect),
                                 "topSameObject": fresh.topEdgeEffect === fresh.topEdgeEffect]
        let copyScroll = UIScrollView()
        rows["effectSharedAcrossViews"] = fresh.topEdgeEffect === copyScroll.topEdgeEffect

        let navS = UINavigationController(rootViewController: scrollVC); scrollVC.title = "Scroll"
        let navT = UINavigationController(rootViewController: tableVC); tableVC.title = "Table"
        let navC = UINavigationController(rootViewController: collectionVC); collectionVC.title = "Collection"
        navS.tabBarItem = UITabBarItem(title: "Scroll", image: UIImage(systemName: "list.bullet"), tag: 0)
        navT.tabBarItem = UITabBarItem(title: "Table", image: UIImage(systemName: "tablecells"), tag: 1)
        navC.tabBarItem = UITabBarItem(title: "Grid", image: UIImage(systemName: "square.grid.2x2"), tag: 2)
        tabs = UITabBarController()
        tabs.viewControllers = [navS, navT, navC]
        let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = tabs; w.makeKeyAndVisible(); window = w

        let fine: [CGFloat] = [0.5, 1, 2, 4, 8, 12, 16, 20, 24, 32, 48, 64]
        let coarse: [CGFloat] = [1, 12, 64]
        addKindPhases("scroll", select: { self.tabs.selectedIndex = 0; self.currentScroll = { self.scrollVC.scroll } }, sweep: fine, bottomSweep: fine, styles: true)
        addKindPhases("table", select: { self.tabs.selectedIndex = 1; self.tableVC.view.layoutIfNeeded(); self.currentScroll = { self.tableVC.tableView } }, sweep: coarse, bottomSweep: coarse, styles: false)
        addKindPhases("collection", select: { self.tabs.selectedIndex = 2; self.collectionVC.view.layoutIfNeeded(); self.currentScroll = { self.collectionVC.collectionView } }, sweep: coarse, bottomSweep: coarse, styles: false)

        // Toolbar instead of a tab bar (window-root navigation controller).
        phases.append(("toolbar.rest", {
            let nav = UINavigationController(rootViewController: self.toolbarVC); self.toolbarVC.title = "Toolbar"
            nav.isToolbarHidden = false
            self.toolbarVC.toolbarItems = [UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)]
            w.rootViewController = nav; nav.view.layoutIfNeeded(); self.toolbarVC.view.layoutIfNeeded()
            self.currentScroll = { self.toolbarVC.scroll }
            self.set(self.topRest(self.current))
        }))
        phases.append(("toolbar.mid", { self.set(self.topRest(self.current) + 100) }))
        phases.append(("toolbar.bottomHard", { self.current.bottomEdgeEffect.style = .hard }))
        phases.append(("toolbar.bottomHidden", { self.current.bottomEdgeEffect.isHidden = true }))
        phases.append(("toolbar.topHidden", { self.current.bottomEdgeEffect.isHidden = false; self.current.bottomEdgeEffect.style = .automatic; self.current.topEdgeEffect.isHidden = true }))

        // Large titles (the port's navigation-bar pocket).
        phases.append(("large.rest", {
            let nav = UINavigationController(rootViewController: self.largeVC); self.largeVC.title = "Large"
            nav.navigationBar.prefersLargeTitles = true
            w.rootViewController = nav; nav.view.layoutIfNeeded(); self.largeVC.view.layoutIfNeeded()
            self.currentScroll = { self.largeVC.tableView }
            self.set(self.topRest(self.current))
        }))
        phases.append(("large.top+12", { self.set(self.topRest(self.current) + 12) }))
        phases.append(("large.top+40", { self.set(self.topRest(self.current) + 40) }))
        phases.append(("large.collapsed", { self.set(self.topRest(self.current) + 160) }))
        phases.append(("large.topHard", { self.current.topEdgeEffect.style = .hard }))
        phases.append(("large.topHidden", { self.current.topEdgeEffect.style = .automatic; self.current.topEdgeEffect.isHidden = true }))
        phases.append(("large.topHiddenRest", { self.set(self.topRest(self.current)) }))

        // Navigation bar + container interaction on the same scroll view.
        phases.append(("interaction.rest", {
            let nav = UINavigationController(rootViewController: self.interactionVC); self.interactionVC.title = "Interaction"
            w.rootViewController = nav; nav.view.layoutIfNeeded(); self.interactionVC.view.layoutIfNeeded()
            self.currentScroll = { self.interactionVC.scroll }
            self.set(self.topRest(self.current))
        }))
        phases.append(("interaction.mid", { self.set(self.topRest(self.current) + 100) }))
        phases.append(("interaction.topHard", { self.current.topEdgeEffect.style = .hard }))
        phases.append(("interaction.topHidden", { self.current.topEdgeEffect.style = .automatic; self.current.topEdgeEffect.isHidden = true }))
        phases.append(("interaction.detached", { self.current.topEdgeEffect.isHidden = false; self.interactionVC.header.removeInteraction(self.interactionVC.top) }))
        phases.append(("interaction.detachedHidden", { self.current.topEdgeEffect.isHidden = true }))

        let names = phases.map { $0.0 }
        try! (names.joined(separator: "\n") + "\n").write(toFile: NSHomeDirectory() + "/Documents/phases.txt", atomically: true, encoding: .utf8)

        func next() {
            guard index < phases.count else {
                let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/edgeeffect.json"))
                marker("done"); return
            }
            let (name, action) = phases[index]; index += 1
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                self.record(name)
                marker(name); waitAck(name) { next() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { next() }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
