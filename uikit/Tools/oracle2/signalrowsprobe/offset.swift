// contentOffset entry-point ordering oracle (extends the signalrowsprobe
// recipe). For every way a collection view's or table view's offset can
// move — setContentOffset(animated: false/true), a direct contentOffset
// set, a direct bounds set, scrollRectToVisible, scrollToItem/scrollToRow,
// and a synthetic finger drag — records the exact order of the layout
// callbacks (shouldInvalidateLayout(forBoundsChange:) with its argument,
// invalidationContext(forBoundsChange:), invalidateLayout(),
// invalidateLayout(with:), prepare(), layoutAttributesForElements(in:) with
// its rect), the view's bounds observed inside each callback, cell dequeues,
// layoutSubviews, and scrollViewDidScroll, all stamped with a phase
// ("sync" = inside the entry point, "after" = after it returned, "frameN"
// = the N-th display-link tick after the call, "touchK" = inside the K-th
// synthetic touch delivery). Writes Documents/offset-order.json.
import UIKit
import Darwin

var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func point(_ p: CGPoint) -> [Double] { [Double(p.x), Double(p.y)] }

final class Trace {
    var log: [[String: Any]] = []
    var phase = "idle"
    var start = CACurrentMediaTime()
    var seq = 0
    func note(_ event: String, bounds: CGRect?, _ extra: [String: Any] = [:]) {
        var row: [String: Any] = ["i": seq, "event": event, "phase": phase,
                                  "t": Double(round((CACurrentMediaTime() - start) * 10000) / 10),
                                  "bounds": bounds.map { rect($0) } ?? NSNull()]
        seq += 1
        for (k, v) in extra { row[k] = v }
        log.append(row)
    }
    func reset() { log = []; seq = 0; start = CACurrentMediaTime() }
}

// MARK: - Collection view tracing

final class Source: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    let trace: Trace
    init(_ t: Trace) { trace = t }
    func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int { 40 }
    func collectionView(_ c: UICollectionView, cellForItemAt p: IndexPath) -> UICollectionViewCell {
        trace.note("cellForItem", bounds: c.bounds, ["path": [p.section, p.item]])
        return c.dequeueReusableCell(withReuseIdentifier: "cell", for: p)
    }
    func scrollViewDidScroll(_ s: UIScrollView) {
        trace.note("scrollViewDidScroll", bounds: s.bounds, ["offset": point(s.contentOffset)])
    }
    func scrollViewDidEndScrollingAnimation(_ s: UIScrollView) { trace.note("didEndScrollingAnimation", bounds: s.bounds) }
    func scrollViewWillBeginDragging(_ s: UIScrollView) { trace.note("willBeginDragging", bounds: s.bounds) }
}

final class TraceCollection: UICollectionView {
    var trace: Trace?
    override func layoutSubviews() {
        trace?.note("layoutSubviews.enter", bounds: bounds)
        super.layoutSubviews()
        trace?.note("layoutSubviews.exit", bounds: bounds)
    }
}

/// Shared tracing body for the base and flow layouts.
protocol Tracing: AnyObject { var trace: Trace { get } }

final class TraceLayout: UICollectionViewLayout, Tracing {
    let trace: Trace
    init(_ t: Trace) { trace = t; super.init() }
    required init?(coder: NSCoder) { fatalError() }
    var lastBoundsContext: ObjectIdentifier?
    override var collectionViewContentSize: CGSize { CGSize(width: 200, height: 2000) }
    override func prepare() { trace.note("prepare", bounds: collectionView?.bounds); super.prepare() }
    override func layoutAttributesForElements(in r: CGRect) -> [UICollectionViewLayoutAttributes]? {
        trace.note("layoutAttributesForElements", bounds: collectionView?.bounds, ["rect": rect(r)])
        return (0..<40).compactMap { layoutAttributesForItem(at: IndexPath(item: $0, section: 0)) }.filter { $0.frame.intersects(r) }
    }
    override func layoutAttributesForItem(at p: IndexPath) -> UICollectionViewLayoutAttributes? {
        let a = UICollectionViewLayoutAttributes(forCellWith: p); a.frame = CGRect(x: 0, y: CGFloat(p.item) * 50, width: 200, height: 40); return a
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        trace.note("shouldInvalidate", bounds: collectionView?.bounds, ["newBounds": rect(newBounds)]); return true
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let c = super.invalidationContext(forBoundsChange: newBounds); lastBoundsContext = ObjectIdentifier(c)
        trace.note("boundsContext", bounds: collectionView?.bounds, ["newBounds": rect(newBounds)]); return c
    }
    override func invalidateLayout() { trace.note("invalidateLayout", bounds: collectionView?.bounds); super.invalidateLayout() }
    override func invalidateLayout(with c: UICollectionViewLayoutInvalidationContext) {
        trace.note("invalidateLayout(with:)", bounds: collectionView?.bounds, ["fromBoundsContext": lastBoundsContext == ObjectIdentifier(c)])
        super.invalidateLayout(with: c)
    }
}

final class TraceFlow: UICollectionViewFlowLayout, Tracing {
    let trace: Trace
    init(_ t: Trace) { trace = t; super.init(); itemSize = CGSize(width: 200, height: 40); minimumLineSpacing = 10; minimumInteritemSpacing = 0 }
    required init?(coder: NSCoder) { fatalError() }
    var lastBoundsContext: ObjectIdentifier?
    override func prepare() { trace.note("prepare", bounds: collectionView?.bounds); super.prepare() }
    override func layoutAttributesForElements(in r: CGRect) -> [UICollectionViewLayoutAttributes]? {
        trace.note("layoutAttributesForElements", bounds: collectionView?.bounds, ["rect": rect(r)])
        return super.layoutAttributesForElements(in: r)
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        trace.note("shouldInvalidate", bounds: collectionView?.bounds, ["newBounds": rect(newBounds)]); return true
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let c = super.invalidationContext(forBoundsChange: newBounds); lastBoundsContext = ObjectIdentifier(c)
        trace.note("boundsContext", bounds: collectionView?.bounds, ["newBounds": rect(newBounds)]); return c
    }
    override func invalidateLayout() { trace.note("invalidateLayout", bounds: collectionView?.bounds); super.invalidateLayout() }
    override func invalidateLayout(with c: UICollectionViewLayoutInvalidationContext) {
        trace.note("invalidateLayout(with:)", bounds: collectionView?.bounds, ["fromBoundsContext": lastBoundsContext == ObjectIdentifier(c)])
        super.invalidateLayout(with: c)
    }
}

// MARK: - Table view tracing

final class TableSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let trace: Trace
    init(_ t: Trace) { trace = t }
    func tableView(_ t: UITableView, numberOfRowsInSection s: Int) -> Int { 100 }
    func tableView(_ t: UITableView, cellForRowAt p: IndexPath) -> UITableViewCell {
        trace.note("cellForRow", bounds: t.bounds, ["path": [p.section, p.row]])
        return t.dequeueReusableCell(withIdentifier: "cell", for: p)
    }
    func tableView(_ t: UITableView, heightForRowAt p: IndexPath) -> CGFloat { 44 }
    func tableView(_ t: UITableView, willDisplay cell: UITableViewCell, forRowAt p: IndexPath) {
        trace.note("willDisplay", bounds: t.bounds, ["path": [p.section, p.row]])
    }
    func scrollViewDidScroll(_ s: UIScrollView) {
        trace.note("scrollViewDidScroll", bounds: s.bounds, ["offset": point(s.contentOffset)])
    }
    func scrollViewDidEndScrollingAnimation(_ s: UIScrollView) { trace.note("didEndScrollingAnimation", bounds: s.bounds) }
    func scrollViewWillBeginDragging(_ s: UIScrollView) { trace.note("willBeginDragging", bounds: s.bounds) }
}

final class TraceTable: UITableView {
    var trace: Trace?
    override func layoutSubviews() {
        trace?.note("layoutSubviews.enter", bounds: bounds)
        super.layoutSubviews()
        trace?.note("layoutSubviews.exit", bounds: bounds)
    }
}

// MARK: - Synthetic touches (KIF-style private API, in-process; see scrollshared.swift)

let rawMsgSend = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "objc_msgSend")!
typealias MsgSendPointBool = @convention(c) (AnyObject, Selector, CGPoint, Bool) -> Void
typealias MsgSendInt = @convention(c) (AnyObject, Selector, Int) -> Void
typealias MsgSendDouble = @convention(c) (AnyObject, Selector, Double) -> Void
typealias MsgSendBool = @convention(c) (AnyObject, Selector, Bool) -> Void
typealias MsgSendObjBool = @convention(c) (AnyObject, Selector, AnyObject?, Bool) -> Void
typealias MsgSendVoid = @convention(c) (AnyObject, Selector) -> Void
typealias MsgSendRetObj = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?

final class TouchSynth {
    let window: UIWindow
    let touch: NSObject
    init(window: UIWindow) {
        self.window = window
        touch = (NSClassFromString("UITouch") as! NSObject.Type).init()
    }
    func touchesEvent() -> NSObject? {
        let sel = NSSelectorFromString("_touchesEvent")
        guard UIApplication.shared.responds(to: sel) else { return nil }
        return unsafeBitCast(rawMsgSend, to: MsgSendRetObj.self)(UIApplication.shared, sel)?.takeUnretainedValue() as? NSObject
    }
    func send(phase: UITouch.Phase, point: CGPoint, timestamp: Double, first: Bool) {
        let t = touch
        let setPointBool = unsafeBitCast(rawMsgSend, to: MsgSendPointBool.self)
        let setInt = unsafeBitCast(rawMsgSend, to: MsgSendInt.self)
        let setDouble = unsafeBitCast(rawMsgSend, to: MsgSendDouble.self)
        let setBool = unsafeBitCast(rawMsgSend, to: MsgSendBool.self)
        let setObjBool = unsafeBitCast(rawMsgSend, to: MsgSendObjBool.self)
        let call = unsafeBitCast(rawMsgSend, to: MsgSendVoid.self)
        let setObj = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> Void).self)
        if first {
            setObj(t, NSSelectorFromString("setWindow:"), window)
            setObj(t, NSSelectorFromString("setView:"), window.hitTest(point, with: nil) ?? window)
            setInt(t, NSSelectorFromString("setTapCount:"), 1)
            if t.responds(to: NSSelectorFromString("_setIsFirstTouchForView:")) { setBool(t, NSSelectorFromString("_setIsFirstTouchForView:"), true) }
            if t.responds(to: NSSelectorFromString("_setSenderID:")) {
                unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, UInt64) -> Void).self)(t, NSSelectorFromString("_setSenderID:"), 0x0ACE_FADE_0000_0002)
            }
        }
        setPointBool(t, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, first)
        let phaseValue: Int = { switch phase { case .began: return 0; case .moved: return 1; case .stationary: return 2; case .ended: return 3; case .cancelled: return 4; default: return 0 } }()
        setInt(t, NSSelectorFromString("setPhase:"), phaseValue)
        setDouble(t, NSSelectorFromString("setTimestamp:"), timestamp)
        guard let ev = touchesEvent() else { return }
        call(ev, NSSelectorFromString("_clearTouches"))
        if ev.responds(to: NSSelectorFromString("_setTimestamp:")) { setDouble(ev, NSSelectorFromString("_setTimestamp:"), timestamp) }
        setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t, false)
        UIApplication.shared.sendEvent(ev as! UIEvent)
    }
}

// MARK: - Scenario driver

final class FrameClock {
    var link: CADisplayLink?
    var frame = 0
    var onTick: (() -> Void)?
    func start(_ tick: @escaping () -> Void) {
        onTick = tick
        link = CADisplayLink(target: self, selector: #selector(fire))
        link?.add(to: .main, forMode: .common)
    }
    @objc func fire() { frame += 1; onTick?() }
    func stop() { link?.invalidate(); link = nil }
}

let cvFrame = CGRect(x: 0, y: 100, width: 200, height: 300)
var scenarios: [(String, (UIView, UIWindow, @escaping () -> Void) -> Void)] = []
let trace = Trace()

/// Builds a collection view, runs `mutate` inside phase "sync", then
/// follows display-link frames for `settle` seconds before reporting.
func collectionScenario(_ name: String, flow: Bool, settle: Double = 0.6,
                        _ mutate: @escaping (UICollectionView, UIWindow) -> Void) {
    scenarios.append((name, { host, window, done in
        let layout: UICollectionViewLayout = flow ? TraceFlow(trace) : TraceLayout(trace)
        let cv = TraceCollection(frame: cvFrame, collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let source = Source(trace)
        cv.dataSource = source; cv.delegate = source
        host.addSubview(cv)
        cv.layoutIfNeeded()
        // Settle one frame so the pre-scenario state is fully laid out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cv.trace = trace
            trace.reset()
            trace.phase = "sync"
            let before = cv.bounds
            mutate(cv, window)
            trace.note("entryReturned", bounds: cv.bounds, ["offset": point(cv.contentOffset)])
            trace.phase = "after"
            let clock = FrameClock()
            clock.start { trace.phase = "frame\(clock.frame)"; trace.note("tick", bounds: cv.bounds) }
            DispatchQueue.main.asyncAfter(deadline: .now() + settle) {
                clock.stop()
                rows[name] = ["layout": flow ? "flow" : "base", "before": rect(before), "bounds": rect(cv.bounds),
                              "offset": point(cv.contentOffset), "log": trace.log]
                cv.trace = nil
                cv.removeFromSuperview()
                withExtendedLifetime(source) {}
                done()
            }
        }
    }))
}

func tableScenario(_ name: String, settle: Double = 0.6, _ mutate: @escaping (UITableView, UIWindow) -> Void) {
    scenarios.append((name, { host, window, done in
        let tv = TraceTable(frame: cvFrame, style: .plain)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.rowHeight = 44
        let source = TableSource(trace)
        tv.dataSource = source; tv.delegate = source
        host.addSubview(tv)
        tv.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tv.trace = trace
            trace.reset()
            trace.phase = "sync"
            let before = tv.bounds
            mutate(tv, window)
            trace.note("entryReturned", bounds: tv.bounds, ["offset": point(tv.contentOffset),
                "visibleRows": (tv.indexPathsForVisibleRows ?? []).map { $0.row }])
            trace.phase = "after"
            let clock = FrameClock()
            clock.start { trace.phase = "frame\(clock.frame)"; trace.note("tick", bounds: tv.bounds) }
            DispatchQueue.main.asyncAfter(deadline: .now() + settle) {
                clock.stop()
                rows[name] = ["layout": "table", "before": rect(before), "bounds": rect(tv.bounds),
                              "offset": point(tv.contentOffset), "log": trace.log,
                              "visibleRows": (tv.indexPathsForVisibleRows ?? []).map { $0.row }]
                tv.trace = nil
                tv.removeFromSuperview()
                withExtendedLifetime(source) {}
                done()
            }
        }
    }))
}

/// A finger drag inside the scroll view: down, three moves of 15 pt each
/// (the first crosses the 10 pt slop), a stationary hold, then lift. Each
/// delivery runs under phase "touchK" so callbacks are attributed to it.
func drag(_ scroll: UIScrollView, in window: UIWindow) {
    let synth = TouchSynth(window: window)
    let origin = scroll.convert(CGPoint(x: 100, y: 200), to: window)
    var t = CACurrentMediaTime()
    let steps: [(UITouch.Phase, CGFloat)] = [(.began, 0), (.moved, -15), (.moved, -30), (.moved, -45), (.stationary, -45), (.ended, -45)]
    for (k, (phase, dy)) in steps.enumerated() {
        trace.phase = "touch\(k).\(phase == .began ? "began" : phase == .moved ? "moved" : phase == .stationary ? "stationary" : "ended")"
        trace.note("send", bounds: scroll.bounds, ["dy": Double(dy)])
        synth.send(phase: phase, point: CGPoint(x: origin.x, y: origin.y + dy), timestamp: t, first: k == 0)
        trace.note("sent", bounds: scroll.bounds, ["offset": point(scroll.contentOffset)])
        t += phase == .stationary ? 0.25 : 0.016
    }
    trace.phase = "sync"
}

for (flow, prefix) in [(false, "base"), (true, "flow")] {
    collectionScenario("\(prefix).setContentOffset.false", flow: flow) { cv, _ in cv.setContentOffset(CGPoint(x: 0, y: 40), animated: false) }
    collectionScenario("\(prefix).setContentOffset.true", flow: flow) { cv, _ in cv.setContentOffset(CGPoint(x: 0, y: 40), animated: true) }
    collectionScenario("\(prefix).contentOffset", flow: flow) { cv, _ in cv.contentOffset = CGPoint(x: 0, y: 40) }
    collectionScenario("\(prefix).bounds", flow: flow) { cv, _ in cv.bounds = CGRect(x: 0, y: 40, width: 200, height: 300) }
    collectionScenario("\(prefix).scrollRectToVisible.false", flow: flow) { cv, _ in cv.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 40), animated: false) }
    collectionScenario("\(prefix).scrollRectToVisible.true", flow: flow) { cv, _ in cv.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 40), animated: true) }
    collectionScenario("\(prefix).scrollToItem.false", flow: flow) { cv, _ in cv.scrollToItem(at: IndexPath(item: 6, section: 0), at: .top, animated: false) }
    collectionScenario("\(prefix).scrollToItem.true", flow: flow) { cv, _ in cv.scrollToItem(at: IndexPath(item: 6, section: 0), at: .top, animated: true) }
    collectionScenario("\(prefix).drag", flow: flow, settle: 1.0) { cv, w in drag(cv, in: w) }
}
tableScenario("table.setContentOffset.false") { tv, _ in tv.setContentOffset(CGPoint(x: 0, y: 40), animated: false) }
tableScenario("table.setContentOffset.true") { tv, _ in tv.setContentOffset(CGPoint(x: 0, y: 40), animated: true) }
tableScenario("table.contentOffset") { tv, _ in tv.contentOffset = CGPoint(x: 0, y: 40) }
tableScenario("table.scrollRectToVisible.false") { tv, _ in tv.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 44), animated: false) }
tableScenario("table.scrollToRow.false") { tv, _ in tv.scrollToRow(at: IndexPath(row: 8, section: 0), at: .top, animated: false) }
tableScenario("table.scrollToRow.true") { tv, _ in tv.scrollToRow(at: IndexPath(row: 8, section: 0), at: .top, animated: true) }
tableScenario("table.drag", settle: 1.0) { tv, w in drag(tv, in: w) }

final class Root: UIViewController {
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = .white }
}

func marker(_ name: String) { FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data()) }

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        rows["os"] = UIDevice.current.systemVersion
        let root = Root()
        let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root; w.makeKeyAndVisible(); window = w
        var index = 0
        func next() {
            guard index < scenarios.count else {
                let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/offset-order.json"))
                marker("done")
                return
            }
            let (name, run) = scenarios[index]; index += 1
            run(root.view, w) { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { next() } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { next() }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
