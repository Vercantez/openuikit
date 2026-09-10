// Signal-iOS blocking-row oracle: bounds-change invalidation ordering,
// UIScrollEdgeElementContainerInteraction observables, UIScreen coordinate
// spaces. Writes Documents/signal-rows.json plus two window snapshots and
// hands the driving script two phase markers for render-server screenshots.
import UIKit

var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func point(_ p: CGPoint) -> [Double] { [Double(p.x), Double(p.y)] }
func paths(_ p: [IndexPath]?) -> Any { p.map { $0.map { [$0.section, $0.item] } } as Any? ?? NSNull() }
func context(_ c: UICollectionViewLayoutInvalidationContext) -> [String: Any] {
    var result: [String: Any] = ["type": String(describing: type(of: c)), "everything": c.invalidateEverything,
        "counts": c.invalidateDataSourceCounts, "items": paths(c.invalidatedItemIndexPaths),
        "offset": point(c.contentOffsetAdjustment),
        "size": [Double(c.contentSizeAdjustment.width), Double(c.contentSizeAdjustment.height)]]
    if let f = c as? UICollectionViewFlowLayoutInvalidationContext {
        result["attributes"] = f.invalidateFlowLayoutAttributes; result["metrics"] = f.invalidateFlowLayoutDelegateMetrics
    }
    return result
}

// MARK: - Section A: bounds-change invalidation ordering

final class Source: NSObject, UICollectionViewDataSource {
    func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int { 2 }
    func collectionView(_ c: UICollectionView, cellForItemAt p: IndexPath) -> UICollectionViewCell {
        c.dequeueReusableCell(withReuseIdentifier: "cell", for: p)
    }
}
final class TraceLayout: UICollectionViewLayout {
    var answer = true
    var log: [[String: Any]] = []
    var phase = "sync"
    var lastBoundsContext: ObjectIdentifier?
    func note(_ event: String, _ extra: [String: Any] = [:]) {
        var row: [String: Any] = ["event": event, "phase": phase, "cvBounds": collectionView.map { rect($0.bounds) } ?? NSNull()]
        for (k, v) in extra { row[k] = v }
        log.append(row)
    }
    override var collectionViewContentSize: CGSize { CGSize(width: 500, height: 1200) }
    override func prepare() { note("prepare"); super.prepare() }
    override func layoutAttributesForElements(in r: CGRect) -> [UICollectionViewLayoutAttributes]? {
        (0..<2).compactMap { layoutAttributesForItem(at: IndexPath(item: $0, section: 0)) }
    }
    override func layoutAttributesForItem(at p: IndexPath) -> UICollectionViewLayoutAttributes? {
        let a = UICollectionViewLayoutAttributes(forCellWith: p); a.frame = CGRect(x: 0, y: CGFloat(p.item) * 50, width: 100, height: 40); return a
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        note("shouldInvalidate", ["newBounds": rect(newBounds), "answer": answer]); return answer
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let c = super.invalidationContext(forBoundsChange: newBounds); lastBoundsContext = ObjectIdentifier(c)
        note("boundsContext", ["newBounds": rect(newBounds), "context": context(c)]); return c
    }
    override func invalidateLayout() { note("invalidateLayout"); super.invalidateLayout() }
    override func invalidateLayout(with c: UICollectionViewLayoutInvalidationContext) {
        note("invalidateLayout(with:)", ["context": context(c), "fromBoundsContext": lastBoundsContext == ObjectIdentifier(c)])
        super.invalidateLayout(with: c)
    }
}
final class TraceFlow: UICollectionViewFlowLayout {
    var answer = true
    var log: [[String: Any]] = []
    var phase = "sync"
    var lastBoundsContext: ObjectIdentifier?
    func note(_ event: String, _ extra: [String: Any] = [:]) {
        var row: [String: Any] = ["event": event, "phase": phase, "cvBounds": collectionView.map { rect($0.bounds) } ?? NSNull()]
        for (k, v) in extra { row[k] = v }
        log.append(row)
    }
    override func prepare() { note("prepare"); super.prepare() }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        note("shouldInvalidate", ["newBounds": rect(newBounds), "answer": answer]); return answer
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let c = super.invalidationContext(forBoundsChange: newBounds); lastBoundsContext = ObjectIdentifier(c)
        note("boundsContext", ["newBounds": rect(newBounds), "context": context(c)]); return c
    }
    override func invalidateLayout() { note("invalidateLayout"); super.invalidateLayout() }
    override func invalidateLayout(with c: UICollectionViewLayoutInvalidationContext) {
        note("invalidateLayout(with:)", ["context": context(c), "fromBoundsContext": lastBoundsContext == ObjectIdentifier(c)])
        super.invalidateLayout(with: c)
    }
}

let source = Source()
func measureInvalidation(in host: UIView) {
    func scenario(_ name: String, flow: Bool, answer: Bool, _ mutate: (UICollectionView) -> Void) {
        let layout: UICollectionViewLayout = flow ? TraceFlow() : TraceLayout()
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 300), collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        cv.dataSource = source
        host.addSubview(cv)
        cv.layoutIfNeeded()
        if let t = layout as? TraceLayout { t.answer = answer; t.log = []; t.phase = "sync" }
        if let t = layout as? TraceFlow { t.answer = answer; t.log = []; t.phase = "sync" }
        mutate(cv)
        if let t = layout as? TraceLayout { t.phase = "layout" }
        if let t = layout as? TraceFlow { t.phase = "layout" }
        cv.layoutIfNeeded()
        let log = (layout as? TraceLayout)?.log ?? (layout as? TraceFlow)?.log ?? []
        rows["invalidate." + name] = ["log": log, "bounds": rect(cv.bounds), "offset": point(cv.contentOffset)]
        cv.removeFromSuperview()
    }
    for (flow, prefix) in [(false, "base"), (true, "flow")] {
        scenario("\(prefix).size.true", flow: flow, answer: true) { $0.frame = CGRect(x: 0, y: 0, width: 220, height: 300) }
        scenario("\(prefix).size.false", flow: flow, answer: false) { $0.frame = CGRect(x: 0, y: 0, width: 220, height: 300) }
        scenario("\(prefix).origin.true", flow: flow, answer: true) { $0.contentOffset = CGPoint(x: 0, y: 40) }
        scenario("\(prefix).origin.false", flow: flow, answer: false) { $0.contentOffset = CGPoint(x: 0, y: 40) }
        scenario("\(prefix).bounds.true", flow: flow, answer: true) { $0.bounds = CGRect(x: 5, y: 6, width: 200, height: 300) }
        scenario("\(prefix).sameFrame.true", flow: flow, answer: true) { $0.frame = CGRect(x: 0, y: 0, width: 200, height: 300) }
        scenario("\(prefix).move.true", flow: flow, answer: true) { $0.frame = CGRect(x: 7, y: 8, width: 200, height: 300) }
        scenario("\(prefix).scrollAnimatedFalse.true", flow: flow, answer: true) { $0.setContentOffset(CGPoint(x: 0, y: 40), animated: false) }
    }
}

// MARK: - Section C: UIScreen coordinate spaces

func measureScreenSpaces(window: UIWindow) {
    let screen = UIScreen.main
    let space = screen.coordinateSpace, fixed = screen.fixedCoordinateSpace
    rows["screen.space"] = ["type": String(describing: type(of: space)), "bounds": rect(space.bounds),
        "fixedType": String(describing: type(of: fixed)), "fixedBounds": rect(fixed.bounds),
        "sameObject": space === fixed, "stable": space === screen.coordinateSpace,
        "isView": space is UIView, "windowIsSpace": (window as UICoordinateSpace) === space]
    let parent = UIView(frame: CGRect(x: 40, y: 60, width: 200, height: 300))
    let child = UIView(frame: CGRect(x: 10, y: 20, width: 80, height: 100))
    window.addSubview(parent); parent.addSubview(child)
    child.bounds.origin = CGPoint(x: 3, y: 4)
    let p = CGPoint(x: 8, y: 9), r = CGRect(x: 8, y: 9, width: 30, height: 40)
    rows["screen.nested"] = ["pointTo": point(child.convert(p, to: space)), "pointFrom": point(child.convert(p, from: space)),
        "rectTo": rect(child.convert(r, to: space)), "rectFrom": rect(child.convert(r, from: space)),
        "spacePointToChild": point(space.convert(p, to: child)), "spacePointFromChild": point(space.convert(p, from: child)),
        "spaceRectToChild": rect(space.convert(r, to: child)), "spaceRectFromChild": rect(space.convert(r, from: child)),
        "windowPointTo": point(window.convert(p, to: space)), "spaceToFixed": point(space.convert(p, to: fixed))]
    child.transform = CGAffineTransform(rotationAngle: .pi / 2)
    rows["screen.rotated"] = ["pointTo": point(child.convert(p, to: space)), "rectTo": rect(child.convert(r, to: space)),
        "rectFrom": rect(child.convert(r, from: space)), "spaceRectToChild": rect(space.convert(r, to: child))]
    child.transform = .identity
    let offsetWindow = UIWindow(frame: CGRect(x: 10, y: 20, width: 300, height: 400))
    offsetWindow.windowScene = window.windowScene
    offsetWindow.isHidden = false
    let inner = UIView(frame: CGRect(x: 5, y: 6, width: 50, height: 50)); offsetWindow.addSubview(inner)
    rows["screen.offsetWindow"] = ["frame": rect(offsetWindow.frame), "innerPointTo": point(inner.convert(p, to: space)),
        "innerToMainWindow": point(inner.convert(p, to: window)), "innerToNil": point(inner.convert(p, to: nil)),
        "spaceToInner": point(space.convert(p, to: inner))]
    offsetWindow.isHidden = true
    parent.removeFromSuperview()
}

// MARK: - Section B: UIScrollEdgeElementContainerInteraction

func sample(_ image: UIImage, _ points: [(Int, Int)]) -> [[Int]] {
    guard let cg = image.cgImage, let data = cg.dataProvider?.data, let base = CFDataGetBytePtr(data) else { return [] }
    let scale = Int(image.scale)
    return points.map { (x, y) in
        let px = x * scale, py = y * scale
        let offset = py * cg.bytesPerRow + px * (cg.bitsPerPixel / 8)
        return (0..<4).map { Int(base[offset + $0]) }
    }
}

var edgeRows: [String: Any] = [:]
var interaction: UIScrollEdgeElementContainerInteraction?
func describeContainer(_ header: UIView, _ scroll: UIScrollView) -> [String: Any] {
    ["headerFrame": rect(header.frame), "headerSubviews": header.subviews.map { [String(describing: type(of: $0)), rect($0.frame)] as [Any] },
     "headerSublayers": (header.layer.sublayers ?? []).map { String(describing: type(of: $0)) },
     "headerLayerType": String(describing: type(of: header.layer)), "headerMask": header.layer.mask.map { String(describing: type(of: $0)) } ?? NSNull(),
     "headerFilters": (header.layer.filters ?? []).map { String(describing: $0) }, "headerBackground": header.backgroundColor?.description ?? "nil",
     "scrollSubviews": scroll.subviews.map { String(describing: type(of: $0)) },
     "scrollSublayers": (scroll.layer.sublayers ?? []).map { String(describing: type(of: $0)) },
     "scrollSuperviewSubviews": (scroll.superview?.subviews ?? []).map { [String(describing: type(of: $0)), rect($0.frame)] as [Any] },
     "topEdgeHidden": scroll.topEdgeEffect.isHidden, "topEdgeStyle": String(describing: scroll.topEdgeEffect.style),
     "bottomEdgeHidden": scroll.bottomEdgeEffect.isHidden, "contentInset": [Double(scroll.contentInset.top), Double(scroll.contentInset.bottom)],
     "adjustedInset": [Double(scroll.adjustedContentInset.top), Double(scroll.adjustedContentInset.bottom)],
     "safeArea": [Double(scroll.safeAreaInsets.top), Double(scroll.safeAreaInsets.bottom)]]
}

final class Root: UIViewController {
    let scroll = UIScrollView()
    let header = UIView()
    let footer = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scroll.frame = view.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentSize = CGSize(width: view.bounds.width, height: 3000)
        for i in 0..<75 {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 40, width: view.bounds.width, height: 40))
            band.backgroundColor = i % 2 == 0 ? .black : .red
            scroll.addSubview(band)
        }
        view.addSubview(scroll)
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 160)
        header.autoresizingMask = [.flexibleWidth]
        header.backgroundColor = .clear
        view.addSubview(header)
        footer.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        footer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        footer.backgroundColor = .clear
        view.addSubview(footer)
    }
}

let samplePoints = [(196, 10), (196, 40), (196, 80), (196, 120), (196, 150), (196, 170), (196, 250), (196, 760), (196, 800), (196, 840)]
func snapshot(_ window: UIWindow, _ name: String) -> [[Int]] {
    let format = UIGraphicsImageRendererFormat.default(); format.preferredRange = .standard
    let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
    try? image.pngData()?.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(name).png"))
    return sample(image, samplePoints)
}
func marker(_ name: String) { FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data()) }
func waitAck(_ name: String, then: @escaping () -> Void) {
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(name).ack") { then(); return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { waitAck(name, then: then) }
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        rows["os"] = UIDevice.current.systemVersion
        let root = Root()
        let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root; w.makeKeyAndVisible(); window = w
        let fresh = UIScrollEdgeElementContainerInteraction()
        rows["edge.init"] = ["type": String(describing: type(of: fresh)), "edge": fresh.edge.rawValue, "scrollView": fresh.scrollView.map { String(describing: type(of: $0)) } ?? NSNull(),
            "view": fresh.view.map { String(describing: type(of: $0)) } ?? NSNull(), "isNSObject": fresh is NSObject,
            "superclass": String(describing: (type(of: fresh) as AnyObject.Type).superclass().map { String(describing: $0) } ?? "nil")]
        fresh.edge = .bottom; rows["edge.setBottom"] = fresh.edge.rawValue
        fresh.edge = [.top, .bottom]; rows["edge.setBoth"] = fresh.edge.rawValue
        fresh.edge = .left; rows["edge.setLeft"] = fresh.edge.rawValue
        var temp: UIScrollView? = UIScrollView(); fresh.scrollView = temp; rows["edge.scrollAssigned"] = fresh.scrollView === temp
        temp = nil; rows["edge.scrollWeak"] = fresh.scrollView == nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            measureInvalidation(in: root.view)
            measureScreenSpaces(window: w)
            edgeRows["before"] = describeContainer(root.header, root.scroll)
            edgeRows["before.samples"] = snapshot(w, "before")
            marker("phase1")
            waitAck("phase1") {
                let i = UIScrollEdgeElementContainerInteraction(); interaction = i
                i.edge = .top; i.scrollView = root.scroll
                root.header.addInteraction(i)
                edgeRows["afterAdd.sync"] = describeContainer(root.header, root.scroll)
                edgeRows["afterAdd.view"] = i.view === root.header
                edgeRows["afterAdd.interactions"] = root.header.interactions.map { String(describing: type(of: $0)) }
                let f = UIScrollEdgeElementContainerInteraction(); f.edge = .bottom; f.scrollView = root.scroll; root.footer.addInteraction(f)
                root.view.layoutIfNeeded()
                edgeRows["afterAdd.laidOut"] = describeContainer(root.header, root.scroll)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    edgeRows["afterAdd.later"] = describeContainer(root.header, root.scroll)
                    edgeRows["afterAdd.footer"] = describeContainer(root.footer, root.scroll)
                    edgeRows["afterAdd.samples"] = snapshot(w, "after")
                    edgeRows["afterAdd.rootSubviews"] = root.view.subviews.map { [String(describing: type(of: $0)), rect($0.frame)] as [Any] }
                    edgeRows["afterAdd.windowSubviews"] = w.subviews.map { String(describing: type(of: $0)) }
                    marker("phase2")
                    waitAck("phase2") {
                        root.scroll.contentOffset = CGPoint(x: 0, y: 100)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            edgeRows["scrolled"] = describeContainer(root.header, root.scroll)
                            edgeRows["scrolled.samples"] = snapshot(w, "scrolled")
                            marker("phase3")
                            waitAck("phase3") {
                                root.header.removeInteraction(i)
                                root.footer.removeInteraction(f)
                                root.view.layoutIfNeeded()
                                edgeRows["removed"] = describeContainer(root.header, root.scroll)
                                edgeRows["removed.view"] = i.view == nil
                                // Signal's pattern: content insets reserve the container bands and
                                // the content scrolls underneath them.
                                root.scroll.contentInset = UIEdgeInsets(top: 160, left: 0, bottom: 120, right: 0)
                                root.scroll.contentOffset = CGPoint(x: 0, y: -160)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    edgeRows["inset.noInteraction"] = describeContainer(root.header, root.scroll)
                                    edgeRows["inset.noInteraction.samples"] = snapshot(w, "inset-none")
                                    marker("phase4")
                                    waitAck("phase4") {
                                        root.header.addInteraction(i); root.footer.addInteraction(f)
                                        root.view.layoutIfNeeded()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                            edgeRows["inset.interaction"] = describeContainer(root.header, root.scroll)
                                            edgeRows["inset.interaction.samples"] = snapshot(w, "inset-interaction")
                                            marker("phase5")
                                            waitAck("phase5") {
                                                root.scroll.contentOffset = CGPoint(x: 0, y: -60)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                    edgeRows["inset.scrolled"] = describeContainer(root.header, root.scroll)
                                                    edgeRows["inset.scrolled.samples"] = snapshot(w, "inset-scrolled")
                                                    marker("phase6")
                                                    waitAck("phase6") {
                                                        // Real content in the container: a label, a glass view, an opaque strip.
                                                        let label = UILabel(frame: CGRect(x: 20, y: 90, width: 200, height: 40)); label.text = "Header"; label.textColor = .white; label.font = .boldSystemFont(ofSize: 28)
                                                        let glass = UIVisualEffectView(effect: UIGlassEffect()); glass.frame = CGRect(x: 240, y: 90, width: 120, height: 50)
                                                        let strip = UIView(frame: CGRect(x: 0, y: 150, width: 393, height: 4)); strip.backgroundColor = .green
                                                        root.header.addSubview(label); root.header.addSubview(glass); root.header.addSubview(strip)
                                                        root.view.layoutIfNeeded()
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                            edgeRows["content.interaction"] = describeContainer(root.header, root.scroll)
                                                            marker("phase7")
                                                            waitAck("phase7") {
                                                                root.scroll.topEdgeEffect.style = .hard
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                                    edgeRows["content.hard"] = describeContainer(root.header, root.scroll)
                                                                    marker("phase8")
                                                                    waitAck("phase8") {
                                                                        root.scroll.topEdgeEffect.style = .automatic
                                                                        root.header.removeInteraction(i)
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                                            edgeRows["content.noInteraction"] = describeContainer(root.header, root.scroll)
                                                                            marker("phase9")
                                                                            waitAck("phase9") {
                                                                                // Isolate the trigger: one subview kind at a time, interaction attached.
                                                                                root.header.addInteraction(i)
                                                                                let kinds: [(String, UIView)] = [("label", label), ("glass", glass), ("strip", strip)]
                                                                                for (_, v) in kinds { v.removeFromSuperview() }
                                                                                var index = 0
                                                                                func next() {
                                                                                    guard index < kinds.count else {
                                                                                        // Finally: an opaque background on the empty container.
                                                                                        root.header.backgroundColor = UIColor(white: 0.5, alpha: 1)
                                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                                                            edgeRows["isolate.background"] = describeContainer(root.header, root.scroll)
                                                                                            marker("phase13"); waitAck("phase13") { finish() }
                                                                                        }
                                                                                        return
                                                                                    }
                                                                                    let (name, v) = kinds[index]; index += 1
                                                                                    root.header.addSubview(v)
                                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                                                        edgeRows["isolate." + name] = describeContainer(root.header, root.scroll)
                                                                                        let phase = "phase\(9 + index)"
                                                                                        marker(phase); waitAck(phase) { v.removeFromSuperview(); next() }
                                                                                    }
                                                                                }
                                                                                next()
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    func finish() {
                                                        rows["edge"] = edgeRows
                                                        rows["samplePoints"] = samplePoints.map { [$0.0, $0.1] }
                                                        let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                                                        try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/signal-rows.json"))
                                                        marker("done")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
