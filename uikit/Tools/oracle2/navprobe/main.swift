// NavProbe on REAL iOS: a TRANSITION oracle for the large-title
// UINavigationController push.
//
// Why it exists: openhost's `--nav-demo --large-titles` run shows three
// things the static scene suite cannot explain — the large title overlapping
// the root's rows at rest, the large title standing still while the content
// slides under it during a push, and a pushed controller with no large title
// at all. None of those are readable off a still; they need real UIKit's
// per-frame PRESENTATION geometry through the 0.35 s push.
//
// What it builds (byte-for-byte the same shape as
// Sources/openhost/HostCore.swift's nav demo, so the two are comparable):
//   * a 390 x 700 wrapper placed BELOW the device's top safe area — the same
//     trick Tools/oracle2/simscene plays for chrome scenes, so the hosted
//     navigation controller sees safeAreaInsets.top == 0 and lays its bar out
//     on the 10 + 54 (+ 52) grid the portable renderer models,
//   * a UINavigationController with prefersLargeTitles = true (variant
//     "large") or false (variant "inline") — the inline run exists to say
//     whether the transition rule the large run measures is a LARGE-TITLE
//     rule or the way iOS 26 moves bar content generally,
//   * a PLAIN (non-scrolling) root view, three 44 pt rows at y 20,
//   * a detail controller with a 120 pt card at y 20 and the default
//     largeTitleDisplayMode (.automatic).
//
// Scroll pass (variant "scroll"): a large-title root whose content is a
// UIScrollView with 1200 pt of content (the same shape as
// fixtures/scenes/navbar_large.json). After rest, the probe sets the
// collapse distance (contentOffset.y + adjustedContentInset.top) to
// 0, 10, 26, 40, 52, 80 and 200, waits for the presentation layers to
// settle, and dumps frame / alpha / font / transform of both titles,
// the bar height, the scroll-edge chrome, and the content inset. A
// second pass injects a decelerating flick whose natural stop is
// inside the large-title zone, so the snap (or lack of one) is
// readable off willEndDragging.target vs the settled offset.
//
// What it records:
//   <Documents>/navprobe.frames.json   one entry per recorded frame:
//       { "t", "png", "views": [ { path, class, frame, pframe, popacity,
//                                  ptransform, text } ] }
//     `pframe` is layer.presentation().frame (parent-relative) and `abs` is
//     that origin accumulated up to the wrapper — the numbers the port's
//     UINavigationBar/UINavigationController have to reproduce.
//   <Documents>/navprobe.f<NNNN>.png   drawHierarchy(afterScreenUpdates:
//       false) of the wrapper at that instant (the LAST COMMITTED frame, i.e.
//       the presentation state — `true` would force a layout pass and hand
//       back the model instead).
//   <Documents>/navprobe.scroll.d<NNN>.*   rest sample at one collapse
//       distance (png + layout.json)
//   <Documents>/navprobe.scroll.summary.json   extracted chrome per offset
//   <Documents>/navprobe.scroll.snap.json      decelerating / zero-velocity
//       releases inside the zone
//
// MEASURED while building this probe: snapshotting EVERY frame throttles the
// recorder to ~90 ms a sample (four samples across a 0.35 s transition), so
// the geometry is sampled on every display tick and the pixels only at the
// `snapshotTargets` below — the curve is read off the geometry, the images
// are there to confirm it.
//   <Documents>/navprobe.rest_root.layout.json      settled root
//   <Documents>/navprobe.rest_pushed.layout.json    settled detail
//   <Documents>/navprobe.rest_popped.layout.json    settled root again
//   <Documents>/navprobe.rest_*.png                 their captures
//
// Timeline (recorder clock): push at 0.50 s, pop at 1.50 s, stop at 2.20 s.
// The push/pop are UIKit's own animated transitions, so the recorded frames
// ARE the oracle for their curve.
//
// Run: scripts/nav_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
/// "large" (prefersLargeTitles push/pop), "inline" (same, no large titles),
/// or "scroll" (large-title root + UIScrollView collapse samples). One
/// variant per PROCESS: a bar that has already run a large-title
/// transition is not a clean inline bar. scripts/nav_probe_sim.sh launches
/// the app once per variant with SIMCTL_CHILD_NAVPROBE_VARIANT.
let variant = ProcessInfo.processInfo.environment["NAVPROBE_VARIANT"] ?? "large"
let prefersLarge = variant != "inline"
/// Collapse distances (pt past the expanded rest offset) sampled at rest.
/// 12…24 find the scroll-edge glass threshold; 44…51 find the bar-height
/// snap; 52+ is the collapsed regime (inset/bar already rebases).
let scrollSampleDistances: [CGFloat] = [
    0, 10, 12, 16, 18, 20, 22, 24, 26, 40, 44, 48, 50, 51, 52, 80, 200,
]
/// Snap jobs run after the last EXPANDED sample (d=51) and before the
/// collapse rebase, so they start from inset 116 / bar 106.
let scrollSnapAfterD: CGFloat = 51
/// Every file this run writes is <prefix>.<what>.
let filePrefix = "navprobe.\(variant)"

/// The openhost nav demo's scene size (Sources/openhost/HostCore.swift).
let sceneSize = CGSize(width: 390, height: 700)
/// Recorder milestones, seconds from the first recorded frame.
let pushAt = 0.50, popAt = 1.50, stopAt = 2.20
/// Recorder times whose PIXELS are kept (the geometry is kept for every
/// display tick). Chosen to straddle both transitions at ~50 ms.
let snapshotTargets: [Double] = [
    0.45, 0.51, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 1.20,
    1.51, 1.55, 1.60, 1.65, 1.70, 1.75, 1.80, 1.85, 1.90, 2.15,
]

func round3(_ v: CGFloat) -> Double {
    guard v.isFinite else { return -1 }
    return (Double(v) * 1000).rounded() / 1000
}

func rectArr(_ r: CGRect) -> [Double] {
    [round3(r.origin.x), round3(r.origin.y), round3(r.width), round3(r.height)]
}

// MARK: - The demo hierarchy (mirrors Sources/openhost/HostCore.swift)

/// A Settings-style disclosure row: label + "›" chevron + hairline.
final class NavDemoRow: UIView {
    let titleLabel = UILabel()
    let chevron = UILabel()
    let hairline = UIView()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        chevron.text = "\u{203A}"
        chevron.font = .systemFont(ofSize: 17, weight: .semibold)
        chevron.textColor = .systemGray2
        hairline.backgroundColor = .separator
        addSubview(titleLabel)
        addSubview(chevron)
        addSubview(hairline)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let t = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(x: 16, y: (bounds.height - t.height) / 2,
                                  width: t.width, height: t.height)
        let c = chevron.intrinsicContentSize
        chevron.frame = CGRect(x: bounds.width - c.width - 16,
                               y: (bounds.height - c.height) / 2,
                               width: c.width, height: c.height)
        hairline.frame = CGRect(x: 16, y: bounds.height - 0.5,
                                width: bounds.width - 16, height: 0.5)
    }
}

final class NavDemoDetailVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        let card = UIView(frame: CGRect(x: 16, y: 20,
                                        width: view.bounds.width - 32, height: 120))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.autoresizingMask = [.flexibleWidth]
        view.addSubview(card)
        let heading = UILabel()
        heading.text = title
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        heading.frame = CGRect(x: 16, y: 16, width: card.bounds.width - 32, height: 24)
        card.addSubview(heading)
        let body = UILabel()
        body.text = "Pushed with the iOS slide transition."
        body.font = .systemFont(ofSize: 15)
        body.textColor = .secondaryLabel
        body.frame = CGRect(x: 16, y: 48, width: card.bounds.width - 32, height: 20)
        card.addSubview(body)
    }
}

final class NavDemoRootVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        for (i, t) in ["General", "Display & Brightness", "About"].enumerated() {
            let row = NavDemoRow(title: t)
            row.frame = CGRect(x: 0, y: 20 + CGFloat(i) * 44,
                               width: view.bounds.width, height: 44)
            row.autoresizingMask = [.flexibleWidth]
            view.addSubview(row)
        }
    }
}

/// Large-title root with a 1200 pt UIScrollView — the collapse oracle.
/// Cards match fixtures/scenes/navbar_large.json so the rest state is the
/// same hierarchy the static scene suite already compares.
final class NavScrollRootVC: UIViewController {
    let scroll = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        view.backgroundColor = .systemGroupedBackground
        scroll.frame = view.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: view.bounds.width, height: 1200)
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        for (i, t) in ["First shelf", "Second shelf", "Third shelf"].enumerated() {
            let card = UIView(frame: CGRect(x: 16, y: 8 + CGFloat(i) * 76,
                                            width: view.bounds.width - 32, height: 64))
            card.backgroundColor = .systemGray5
            card.layer.cornerRadius = 12
            card.autoresizingMask = [.flexibleWidth]
            scroll.addSubview(card)
            let label = UILabel()
            label.text = t
            label.font = .systemFont(ofSize: 17)
            label.frame = CGRect(x: 16, y: 21, width: 200, height: 22)
            card.addSubview(label)
        }
        setContentScrollView(scroll)
    }
}

// MARK: - Dumps

/// Settled-state dump: the shape Tools/oracle2 already writes, plus the
/// safe-area / bar facts a large-title layout depends on.
func dumpLayout(_ v: UIView, path: String, into out: inout [[String: Any]]) {
    var entry: [String: Any] = [
        "path": path,
        "class": String(describing: type(of: v)),
        "frame": rectArr(v.frame),
        "bounds": rectArr(v.bounds),
        "alpha": round3(v.alpha),
        "hidden": v.isHidden,
    ]
    let sa = v.safeAreaInsets
    entry["safeAreaInsets"] = [round3(sa.top), round3(sa.left), round3(sa.bottom), round3(sa.right)]
    if let l = v as? UILabel {
        if let t = l.text { entry["text"] = t }
        entry["font"] = [l.font.fontName, round3(l.font.pointSize)]
        entry["intrinsic"] = [round3(l.intrinsicContentSize.width),
                              round3(l.intrinsicContentSize.height)]
        entry["adjustsFont"] = l.adjustsFontSizeToFitWidth
        entry["minScale"] = round3(l.minimumScaleFactor)
    }
    let vt = v.transform
    if vt != .identity {
        entry["transform"] = [round3(vt.a), round3(vt.d), round3(vt.tx), round3(vt.ty)]
    }
    if let ve = v as? UIVisualEffectView {
        entry["effect"] = String(describing: ve.effect)
    }
    if let sv = v as? UIScrollView {
        entry["contentOffset"] = [round3(sv.contentOffset.x), round3(sv.contentOffset.y)]
        let ci = sv.contentInset, ai = sv.adjustedContentInset
        entry["contentInset"] = [round3(ci.top), round3(ci.left), round3(ci.bottom), round3(ci.right)]
        entry["adjustedContentInset"] = [round3(ai.top), round3(ai.left), round3(ai.bottom), round3(ai.right)]
    }
    if let c = v.backgroundColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if c.getRed(&r, green: &g, blue: &b, alpha: &a) {
            entry["bg"] = [round3(r), round3(g), round3(b), round3(a)]
        }
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

/// Per-frame dump: PRESENTATION geometry only (what is on screen right now).
/// `abs` accumulates presentation origins up to the recorded root, which is
/// the number to read a translation curve off.
func dumpPresentation(_ v: UIView, path: String, absOrigin: CGPoint,
                      inheritedOpacity: CGFloat, into out: inout [[String: Any]]) {
    let p = v.layer.presentation()
    let pframe = p?.frame ?? v.layer.frame
    let pbounds = p?.bounds ?? v.layer.bounds
    let popacity = CGFloat(p?.opacity ?? v.layer.opacity)
    let effective = inheritedOpacity * popacity
    let origin = CGPoint(x: absOrigin.x + pframe.origin.x - pbounds.origin.x,
                         y: absOrigin.y + pframe.origin.y - pbounds.origin.y)
    var entry: [String: Any] = [
        "path": path,
        "class": String(describing: type(of: v)),
        "pframe": rectArr(pframe),
        "abs": rectArr(CGRect(origin: origin, size: pframe.size)),
        "popacity": round3(popacity),
        "effopacity": round3(effective),
        "hidden": v.isHidden,
    ]
    // The model value beside the presentation value: a UIKit transition that
    // moves the MODEL (a re-layout) and one that only animates the
    // presentation layer look identical in a single frame and are not the
    // same rule.
    if v.layer.frame != pframe { entry["frame"] = rectArr(v.layer.frame) }
    let t = p?.transform ?? v.layer.transform
    if !CATransform3DIsIdentity(t) {
        entry["ptransform"] = [round3(t.m11), round3(t.m12), round3(t.m21), round3(t.m22),
                               round3(t.m41), round3(t.m42)]
    }
    if let l = v as? UILabel {
        if let s = l.text { entry["text"] = s }
        entry["font"] = [l.font.fontName, round3(l.font.pointSize)]
    }
    if let ve = v as? UIVisualEffectView {
        entry["effect"] = String(describing: ve.effect)
    }
    if let bg = v.layer.backgroundColor, let c = UIColor(cgColor: bg).cgColor.components {
        entry["bg"] = c.map { round3($0) }
    }
    // The animation OBJECTS, not a curve fitted to samples: UIKit's own
    // duration / timing function / spring constants are readable straight off
    // the layer, which is the difference between measuring the transition and
    // guessing at it.
    if let keys = v.layer.animationKeys(), !keys.isEmpty {
        entry["anims"] = keys.compactMap { k -> [String: Any]? in
            guard let a = v.layer.animation(forKey: k) else { return nil }
            var d: [String: Any] = [
                "key": k,
                "class": String(describing: type(of: a)),
                "duration": round3(CGFloat(a.duration)),
                "beginTime": round3(CGFloat(a.beginTime)),
                "speed": round3(CGFloat(a.speed)),
            ]
            if let f = a.timingFunction {
                var p = [Float](repeating: 0, count: 2)
                var pts: [Double] = []
                for i in 0..<4 { f.getControlPoint(at: i, values: &p); pts += [round3(CGFloat(p[0])), round3(CGFloat(p[1]))] }
                d["timing"] = pts
            }
            if let s = a as? CASpringAnimation {
                d["spring"] = ["mass": round3(s.mass), "stiffness": round3(s.stiffness),
                               "damping": round3(s.damping),
                               "initialVelocity": round3(s.initialVelocity),
                               "settlingDuration": round3(CGFloat(s.settlingDuration))]
                d["perceptualDuration"] = round3(CGFloat(s.perceptualDuration))
                d["allowsOverdamping"] = s.allowsOverdamping
            }
            if let b = a as? CABasicAnimation {
                d["keyPath"] = b.keyPath ?? ""
                d["from"] = String(describing: b.fromValue ?? "nil")
                d["to"] = String(describing: b.toValue ?? "nil")
            }
            return d
        }
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpPresentation(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)",
                         absOrigin: origin, inheritedOpacity: effective, into: &out)
    }
}

/// Pull the chrome the collapse rule has to reproduce out of a view dump.
func chromeSummary(from views: [[String: Any]],
                   nav: UINavigationController,
                   scroll: UIScrollView?) -> [String: Any] {
    func cls(_ e: [String: Any]) -> String { e["class"] as? String ?? "" }
    func hasText(_ e: [String: Any], _ t: String) -> Bool {
        (e["text"] as? String) == t
    }
    let large = views.first {
        cls($0).contains("LargeTitle") && hasText($0, "Library")
            || (hasText($0, "Library") && cls($0) == "UILabel"
                && (($0["font"] as? [Any])?.last as? Double ?? 0) >= 30)
    }
    let inline = views.first {
        cls($0).contains("TitleControl") || cls($0).contains("NavigationBarTitle")
            || (hasText($0, "Library") && cls($0) == "UILabel"
                && (($0["font"] as? [Any])?.last as? Double ?? 0) < 20)
    }
    let barBg = views.filter {
        cls($0).contains("BarBackground") || cls($0).contains("ScrollEdge")
            || cls($0).contains("VisualEffect") || cls($0).contains("BarPlatter")
            || cls($0).contains("NavigationBarContent")
            || cls($0).contains("NavigationBarLargeTitle")
    }
    let bar = nav.navigationBar
    var out: [String: Any] = [
        "barFrame": rectArr(bar.frame),
        "barBounds": rectArr(bar.bounds),
        "barAlpha": round3(bar.alpha),
        "barHidden": bar.isHidden,
        "prefersLargeTitles": bar.prefersLargeTitles,
        "isTranslucent": bar.isTranslucent,
    ]
    if let large {
        out["largeTitle"] = [
            "class": cls(large),
            "path": large["path"] as? String ?? "",
            "frame": large["frame"] ?? large["pframe"] as Any,
            "abs": large["abs"] as Any,
            "alpha": large["alpha"] ?? large["popacity"] as Any,
            "font": large["font"] as Any,
            "transform": large["transform"] as Any,
            "ptransform": large["ptransform"] as Any,
            "hidden": large["hidden"] as Any,
        ]
    }
    if let inline {
        out["inlineTitle"] = [
            "class": cls(inline),
            "path": inline["path"] as? String ?? "",
            "frame": inline["frame"] ?? inline["pframe"] as Any,
            "abs": inline["abs"] as Any,
            "alpha": inline["alpha"] ?? inline["popacity"] as Any,
            "font": inline["font"] as Any,
            "hidden": inline["hidden"] as Any,
        ]
    }
    out["labels"] = views.compactMap { e -> [String: Any]? in
        guard e["text"] != nil || e["font"] != nil else { return nil }
        return [
            "class": cls(e), "path": e["path"] as? String ?? "",
            "text": e["text"] as Any,
            "frame": e["frame"] ?? e["pframe"] as Any,
            "abs": e["abs"] as Any,
            "alpha": e["alpha"] ?? e["popacity"] as Any,
            "font": e["font"] as Any,
            "transform": e["transform"] as Any,
            "ptransform": e["ptransform"] as Any,
            "hidden": e["hidden"] as Any,
        ]
    }
    out["chrome"] = barBg.map { e -> [String: Any] in
        var c: [String: Any] = [
            "class": cls(e), "path": e["path"] as? String ?? "",
            "frame": e["frame"] ?? e["pframe"] as Any,
            "alpha": e["alpha"] ?? e["popacity"] as Any,
            "hidden": e["hidden"] as Any,
        ]
        if let bg = e["bg"] { c["bg"] = bg }
        if let fx = e["effect"] { c["effect"] = fx }
        return c
    }
    if let s = scroll {
        let ci = s.contentInset, ai = s.adjustedContentInset
        out["contentOffset"] = [round3(s.contentOffset.x), round3(s.contentOffset.y)]
        out["contentInset"] = [round3(ci.top), round3(ci.left), round3(ci.bottom), round3(ci.right)]
        out["adjustedContentInset"] = [round3(ai.top), round3(ai.left),
                                       round3(ai.bottom), round3(ai.right)]
        out["collapseDistance"] = round3(s.contentOffset.y + ai.top)
        out["isDragging"] = s.isDragging
        out["isDecelerating"] = s.isDecelerating
    }
    if let top = nav.topViewController {
        out["topViewSafeArea"] = [
            round3(top.view.safeAreaInsets.top),
            round3(top.view.safeAreaInsets.bottom),
        ]
        out["topViewFrame"] = rectArr(top.view.frame)
        out["additionalSafeArea"] = round3(top.additionalSafeAreaInsets.top)
    }
    return out
}

// MARK: - KIF-style UITouch injection (in-process, private UIKit API)
// Same selectors Tools/oracle2/scrollshared.swift already verified on
// iOS 26.1. Kept here so navprobe stays a one-file compile.

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
    var touch: NSObject?

    init(window: UIWindow) {
        self.window = window
        touch = (NSClassFromString("UITouch") as? NSObject.Type)?.init()
    }

    func send(phase: UITouch.Phase, point: CGPoint, timestamp: Double, first: Bool) {
        guard let t = touch else { return }
        let setPointBool = unsafeBitCast(rawMsgSend, to: MsgSendPointBool.self)
        let setInt = unsafeBitCast(rawMsgSend, to: MsgSendInt.self)
        let setDouble = unsafeBitCast(rawMsgSend, to: MsgSendDouble.self)
        let setBool = unsafeBitCast(rawMsgSend, to: MsgSendBool.self)
        let setObjBool = unsafeBitCast(rawMsgSend, to: MsgSendObjBool.self)
        let call = unsafeBitCast(rawMsgSend, to: MsgSendVoid.self)
        let setObj = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> Void).self)
        if first {
            setObj(t, NSSelectorFromString("setWindow:"), window)
            let view = window.hitTest(point, with: nil) ?? window
            setObj(t, NSSelectorFromString("setView:"), view)
            setInt(t, NSSelectorFromString("setTapCount:"), 1)
            if t.responds(to: NSSelectorFromString("_setIsFirstTouchForView:")) {
                setBool(t, NSSelectorFromString("_setIsFirstTouchForView:"), true)
            }
        }
        setPointBool(t, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, first)
        setInt(t, NSSelectorFromString("setPhase:"), phase.rawValue)
        setDouble(t, NSSelectorFromString("setTimestamp:"), timestamp)
        let app = UIApplication.shared
        guard app.responds(to: NSSelectorFromString("_touchesEvent")) else { return }
        let f = unsafeBitCast(rawMsgSend, to: MsgSendRetObj.self)
        guard let ev = f(app, NSSelectorFromString("_touchesEvent"))?.takeUnretainedValue() as? NSObject else { return }
        call(ev, NSSelectorFromString("_clearTouches"))
        if ev.responds(to: NSSelectorFromString("_setTimestamp:")) {
            setDouble(ev, NSSelectorFromString("_setTimestamp:"), timestamp)
        }
        setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t, false)
        UIApplication.shared.sendEvent(ev as! UIEvent)
    }
}

final class SnapRecorder: NSObject, UIScrollViewDelegate {
    var events: [[String: Any]] = []
    var willEnd: [String: Any]?
    weak var forward: UIScrollViewDelegate?

    func mark(_ name: String, _ scroll: UIScrollView) {
        events.append([
            "name": name,
            "offset": [round3(scroll.contentOffset.x), round3(scroll.contentOffset.y)],
            "insetTop": round3(scroll.adjustedContentInset.top),
            "d": round3(scroll.contentOffset.y + scroll.adjustedContentInset.top),
            "dragging": scroll.isDragging,
            "decelerating": scroll.isDecelerating,
        ])
    }
    func scrollViewWillBeginDragging(_ s: UIScrollView) { mark("willBeginDragging", s) }
    func scrollViewDidEndDragging(_ s: UIScrollView, willDecelerate d: Bool) {
        events.append(["name": "didEndDragging", "decelerate": d,
                       "offset": [round3(s.contentOffset.x), round3(s.contentOffset.y)],
                       "d": round3(s.contentOffset.y + s.adjustedContentInset.top)])
    }
    func scrollViewWillBeginDecelerating(_ s: UIScrollView) { mark("willBeginDecelerating", s) }
    func scrollViewDidEndDecelerating(_ s: UIScrollView) { mark("didEndDecelerating", s) }
    func scrollViewDidEndScrollingAnimation(_ s: UIScrollView) { mark("didEndScrollingAnimation", s) }
    func scrollViewWillEndDragging(_ s: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let tgt = targetContentOffset.pointee
        willEnd = [
            "vx": round3(velocity.x), "vy": round3(velocity.y),
            "target": [round3(tgt.x), round3(tgt.y)],
            "targetD": round3(tgt.y + s.adjustedContentInset.top),
            "offset": [round3(s.contentOffset.x), round3(s.contentOffset.y)],
        ]
        var e: [String: Any] = ["name": "willEndDragging"]
        if let w = willEnd { for (k, v) in w { e[k] = v } }
        events.append(e)
    }
}

// MARK: - Recorder

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var wrapper = UIView()
    var nav: UINavigationController!
    var root: UIViewController!
    var scrollRoot: NavScrollRootVC?
    var link: CADisplayLink?
    var startTime: CFTimeInterval = 0
    var frameIndex = 0
    var frames: [[String: Any]] = []
    var didPush = false, didPop = false, didDumpPushed = false
    /// Link timestamps of the two transitions, the zero of every curve.
    var pushTime = pushAt, popTime = popAt
    /// Snapshots are PNG-encoded after the recording, not during it.
    var pending: [(String, UIImage)] = []
    var shots: [[String: Any]] = []
    var nextTarget = 0
    var dragTimer: DispatchSourceTimer?

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.overrideUserInterfaceStyle = .light
        let hostVC = UIViewController()
        hostVC.view.backgroundColor = .white
        w.rootViewController = hostVC
        w.makeKeyAndVisible()
        window = w

        // Below the device's top safe area, exactly like SimScene's chrome
        // scenes: the navigation controller then sees safeAreaInsets.top == 0.
        wrapper.frame = CGRect(origin: CGPoint(x: 0, y: w.safeAreaInsets.top), size: sceneSize)
        wrapper.backgroundColor = .white
        wrapper.tintAdjustmentMode = .normal
        hostVC.view.addSubview(wrapper)

        if variant == "scroll" {
            let s = NavScrollRootVC()
            scrollRoot = s
            root = s
        } else {
            root = NavDemoRootVC()
        }
        nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = prefersLarge
        hostVC.addChild(nav)
        nav.view.frame = wrapper.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.addSubview(nav.view)
        nav.didMove(toParent: hostVC)
        wrapper.layoutIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            if variant == "scroll" {
                runScrollPass()
            } else {
                captureRest("rest_root")
                beginRecording()
            }
        }
        return true
    }

    /// Two identical passes over the same timeline: pass 0 samples GEOMETRY
    /// only (a snapshot costs ~40 ms and stalls the recorder — measured: with
    /// snapshots in the loop the sampled curve came back with three
    /// consecutive frames carrying one presentation value), pass 1 samples the
    /// pixels at `snapshotTargets` and its geometry is discarded.
    var pass = 0

    // MARK: Captures

    func snapshot(afterScreenUpdates: Bool) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = UIScreen.main.scale
        fmt.preferredRange = .extended
        fmt.opaque = true
        return UIGraphicsImageRenderer(size: sceneSize, format: fmt).image { _ in
            wrapper.drawHierarchy(in: CGRect(origin: .zero, size: sceneSize),
                                  afterScreenUpdates: afterScreenUpdates)
        }
    }

    func captureRest(_ name: String) {
        let img = snapshot(afterScreenUpdates: true)
        try? img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).\(name).png"))
        var views: [[String: Any]] = []
        dumpLayout(wrapper, path: "", into: &views)
        var payload: [String: Any] = ["name": name, "views": views]
        payload["screen"] = ["scale": Double(UIScreen.main.scale),
                             "windowBounds": rectArr(window!.bounds),
                             "windowSafeArea": [round3(window!.safeAreaInsets.top),
                                                round3(window!.safeAreaInsets.bottom)],
                             "wrapperFrame": rectArr(wrapper.frame)]
        payload["nav"] = ["barFrame": rectArr(nav.navigationBar.frame),
                          "barBounds": rectArr(nav.navigationBar.bounds),
                          "prefersLargeTitles": nav.navigationBar.prefersLargeTitles,
                          "topTitle": nav.topViewController?.title ?? "",
                          "topLargeTitleMode":
                            nav.topViewController?.navigationItem.largeTitleDisplayMode.rawValue ?? -1,
                          "topViewFrame": rectArr(nav.topViewController?.view.frame ?? .zero),
                          "topViewSafeArea": [
                            round3(nav.topViewController?.view.safeAreaInsets.top ?? -1),
                            round3(nav.topViewController?.view.safeAreaInsets.bottom ?? -1)],
                          "additionalSafeArea":
                            round3(nav.topViewController?.additionalSafeAreaInsets.top ?? -1)]
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).\(name).layout.json"))
    }

    // MARK: Scroll collapse pass

    func runScrollPass() {
        guard let scroll = scrollRoot?.scroll else {
            writeDone("scroll: no scroll view"); return
        }
        var samples: [[String: Any]] = []
        var snaps: [[String: Any]] = []
        func next(_ i: Int) {
            guard i < scrollSampleDistances.count else {
                finishScroll(samples: samples, snaps: snaps)
                return
            }
            let d = scrollSampleDistances[i]
            let inset = scroll.adjustedContentInset.top
            // After a collapse rebase the inset is 64; keep sampling the
            // requested collapse distance against the ORIGINAL 116 rest so
            // d=80/200 stay comparable. Before collapse, inset is 116.
            let rest: CGFloat = inset >= 100 ? inset : 116
            let y = -rest + d
            scroll.setContentOffset(CGPoint(x: 0, y: y), animated: false)
            wrapper.layoutIfNeeded()
            nav.view.layoutIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [self] in
                samples.append(captureScrollSample(name: String(format: "d%03d", Int(d)),
                                                   requestedD: d, scroll: scroll))
                if d == scrollSnapAfterD {
                    runSnapPass(scroll: scroll, samples: samples) { newSnaps in
                        snaps = newSnaps
                        // Re-expand: pull back to the expanded rest before
                        // the d=52 rebase so later samples start clean.
                        scroll.setContentOffset(CGPoint(x: 0, y: -116), animated: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            next(i + 1)
                        }
                    }
                } else {
                    next(i + 1)
                }
            }
        }
        next(0)
    }

    func captureScrollSample(name: String, requestedD: CGFloat,
                             scroll: UIScrollView) -> [String: Any] {
        let img = snapshot(afterScreenUpdates: true)
        try? img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).\(name).png"))
        var views: [[String: Any]] = []
        dumpLayout(wrapper, path: "", into: &views)
        var pres: [[String: Any]] = []
        dumpPresentation(wrapper, path: "", absOrigin: .zero, inheritedOpacity: 1, into: &pres)
        var payload: [String: Any] = [
            "name": name,
            "requestedD": round3(requestedD),
            "views": views,
            "presentation": pres,
        ]
        payload["screen"] = ["scale": Double(UIScreen.main.scale),
                             "windowBounds": rectArr(window!.bounds),
                             "windowSafeArea": [round3(window!.safeAreaInsets.top),
                                                round3(window!.safeAreaInsets.bottom)],
                             "wrapperFrame": rectArr(wrapper.frame)]
        payload["chrome"] = chromeSummary(from: views, nav: nav, scroll: scroll)
        payload["chromePresentation"] = chromeSummary(from: pres, nav: nav, scroll: scroll)
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).\(name).layout.json"))
        return payload["chrome"] as? [String: Any] ?? [:]
    }

    func runSnapPass(scroll: UIScrollView, samples: [[String: Any]],
                     completion: @escaping ([[String: Any]]) -> Void) {
        let recorder = SnapRecorder()
        scroll.delegate = recorder
        let synth = TouchSynth(window: window!)
        let origin = wrapper.convert(CGPoint(x: sceneSize.width / 2, y: 420), to: nil)
        var snaps: [[String: Any]] = []

        /// Zero-velocity releases at mid-zone distances, plus one slow
        /// flick aimed to decelerate to a stop inside the zone. All of
        /// these start from the expanded rest (inset 116).
        let jobs: [(String, CGFloat, Bool)] = [
            ("hold_d10", 10, false),
            ("hold_d20", 20, false),
            ("hold_d26", 26, false),
            ("hold_d28", 28, false),
            ("hold_d30", 30, false),
            ("hold_d32", 32, false),
            ("hold_d36", 36, false),
            ("hold_d37", 37, false),
            ("hold_d38", 38, false),
            ("hold_d39", 39, false),
            ("hold_d40", 40, false),
            ("flick_into_zone", 18, true),
        ]
        func next(_ i: Int) {
            guard i < jobs.count else {
                scroll.delegate = nil
                completion(snaps)
                return
            }
            let (name, targetD, flick) = jobs[i]
            // Always re-seed the expanded rest. After a snap-to-collapsed
            // the adjusted inset is 64, and -inset.top would stay collapsed.
            scroll.setContentOffset(CGPoint(x: 0, y: -116), animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [self] in
                recorder.events = []
                recorder.willEnd = nil
                let startD = scroll.contentOffset.y + scroll.adjustedContentInset.top
                runDrag(synth: synth, origin: origin, distance: targetD - startD,
                        flick: flick) {
                    self.waitForScrollSettle(scroll) {
                        var entry: [String: Any] = [
                            "name": name,
                            "requestedD": round3(targetD),
                            "flick": flick,
                            "finalOffset": [round3(scroll.contentOffset.x),
                                            round3(scroll.contentOffset.y)],
                            "finalD": round3(scroll.contentOffset.y
                                             + scroll.adjustedContentInset.top),
                            "adjustedInsetTop": round3(scroll.adjustedContentInset.top),
                            "events": recorder.events,
                        ]
                        if let w = recorder.willEnd { entry["willEndDragging"] = w }
                        var views: [[String: Any]] = []
                        dumpLayout(self.wrapper, path: "", into: &views)
                        entry["chrome"] = chromeSummary(from: views, nav: self.nav,
                                                        scroll: scroll)
                        snaps.append(entry)
                        next(i + 1)
                    }
                }
            }
        }
        next(0)
    }

    /// Finger-up drag of `distance` pt of content (plus 10 pt pan slop).
    /// `flick` lifts immediately so UIKit estimates a release velocity;
    /// otherwise the finger holds still for 0.3 s and the release is ~0.
    func runDrag(synth: TouchSynth, origin: CGPoint, distance: CGFloat,
                 flick: Bool, completion: @escaping () -> Void) {
        let slop: CGFloat = 10
        // A short fast flick overshoots the 52 pt zone (measured: 8 steps
        // at 8 ms, travel 36 → vy 0.563, target d=302). 40 steps at 16 ms
        // keeps release velocity low enough that willEndDragging.target
        // lands inside the zone.
        let interval: Double = 0.016
        let steps = flick ? 40 : 16
        let travel = slop + distance
        var points: [CGPoint] = [origin]
        for i in 1...steps {
            points.append(CGPoint(x: origin.x,
                                  y: origin.y - travel * CGFloat(i) / CGFloat(steps)))
        }
        let holdTicks = flick ? 0 : Int((0.30 / interval).rounded())
        let total = points.count + holdTicks + 1
        let t0 = CACurrentMediaTime()
        var i = 0
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self, i < total else { return }
            let ts = t0 + Double(i) * interval
            if i == 0 {
                synth.send(phase: .began, point: points[0], timestamp: ts, first: true)
            } else if i < points.count {
                synth.send(phase: .moved, point: points[i], timestamp: ts, first: false)
            } else if i < points.count + holdTicks {
                synth.send(phase: .stationary, point: points[points.count - 1],
                           timestamp: ts, first: false)
            } else {
                synth.send(phase: .ended, point: points[points.count - 1],
                           timestamp: ts, first: false)
            }
            i += 1
            if i == total {
                timer.cancel()
                self.dragTimer = nil
                completion()
            }
        }
        dragTimer = timer
        timer.resume()
    }

    func waitForScrollSettle(_ scroll: UIScrollView, completion: @escaping () -> Void) {
        var last = scroll.contentOffset
        var stable = 0
        let t0 = CACurrentMediaTime()
        func poll() {
            let off = scroll.contentOffset
            if off == last, !scroll.isDecelerating, !scroll.isDragging {
                stable += 1
            } else {
                stable = 0
                last = off
            }
            if stable >= 6 { completion(); return }
            if CACurrentMediaTime() - t0 > 8 { completion(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { poll() }
        }
        poll()
    }

    func finishScroll(samples: [[String: Any]], snaps: [[String: Any]]) {
        var labeled: [[String: Any]] = []
        for (i, s) in samples.enumerated() {
            var e = s
            e["requestedD"] = round3(scrollSampleDistances[i])
            labeled.append(e)
        }
        let payload: [String: Any] = [
            "variant": variant,
            "scale": Double(UIScreen.main.scale),
            "size": [Double(sceneSize.width), Double(sceneSize.height)],
            "samples": labeled,
            "snaps": snaps,
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).summary.json"))
        writeDone("ok")
    }

    func writeDone(_ s: String) {
        try! s.write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(s == "ok" ? 0 : 3) }
    }

    // MARK: Recording

    func beginRecording() {
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        // Every display tick (~16 ms), stamped with the REAL time: twice the
        // brief's 33 ms and cheap, because only `snapshotTargets` snapshot.
        l.add(to: .main, forMode: .common)
        link = l
        startTime = CACurrentMediaTime()
    }

    @objc func tick(_ l: CADisplayLink) {
        // link.timestamp, NOT CACurrentMediaTime(): `presentation()` reports
        // the render tree for the frame the link is servicing, and a snapshot
        // that stalls the main thread by 40 ms would otherwise stamp that
        // frame with a time 40 ms too late (measured while building this
        // probe: the fitted curve came out non-monotonic in rate).
        let t = l.timestamp - startTime
        if t >= stopAt {
            l.invalidate()
            finish()
            return
        }
        if !didPush && t >= pushAt {
            didPush = true
            pushTime = t
            let detail = NavDemoDetailVC()
            detail.title = "About"
            nav.pushViewController(detail, animated: true)
        }
        if pass == 0, didPush, !didDumpPushed, t >= popAt - 0.06 {
            didDumpPushed = true
            captureRest("rest_pushed")
        }
        if !didPop && t >= popAt {
            didPop = true
            popTime = t
            nav.popViewController(animated: true)
        }
        record(t: t)
    }

    func record(t: Double) {
        if pass == 1 {
            guard nextTarget < snapshotTargets.count, t >= snapshotTargets[nextTarget] else { return }
            while nextTarget < snapshotTargets.count, t >= snapshotTargets[nextTarget] {
                nextTarget += 1
            }
            // afterScreenUpdates: false — the LAST COMMITTED frame. `true`
            // runs a layout+commit pass and would hand back the model state,
            // erasing exactly the presentation geometry this probe measures.
            let name = String(format: "\(filePrefix).f%04d.png", frameIndex)
            pending.append((name, snapshot(afterScreenUpdates: false)))
            shots.append(["i": frameIndex, "t": round3(CGFloat(t)),
                          "sincePush": round3(CGFloat(t - pushTime)),
                          "sincePop": round3(CGFloat(t - popTime)), "png": name])
            frameIndex += 1
            return
        }
        var views: [[String: Any]] = []
        dumpPresentation(wrapper, path: "", absOrigin: .zero, inheritedOpacity: 1, into: &views)
        frames.append([
            "i": frameIndex,
            "t": round3(CGFloat(t)),
            "sincePush": round3(CGFloat(t - pushTime)),
            "sincePop": round3(CGFloat(t - popTime)),
            "views": views,
        ])
        frameIndex += 1
    }

    func finish() {
        if pass == 0 {
            captureRest("rest_popped")
            pass = 1
            didPush = false; didPop = false; nextTarget = 0; frameIndex = 0
            // Let the popped hierarchy settle before replaying the timeline.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in beginRecording() }
            return
        }
        for (name, img) in pending {
            try? img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/\(name)"))
        }
        pending = []
        let payload: [String: Any] = [
            "variant": variant,
            "pushAt": round3(CGFloat(pushTime)), "popAt": round3(CGFloat(popTime)),
            "scale": Double(UIScreen.main.scale),
            "size": [Double(sceneSize.width), Double(sceneSize.height)],
            "frames": frames,
            "shots": shots,
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(filePrefix).frames.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
    }
}

// Watchdog — never wedge the simulator boot pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
    try? "watchdog timeout".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
