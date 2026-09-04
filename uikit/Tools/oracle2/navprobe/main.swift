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
/// "large" (prefersLargeTitles) or "inline". One variant per PROCESS: a bar
/// that has already run a large-title transition is not a clean inline bar.
/// scripts/nav_probe_sim.sh launches the app once per variant with
/// SIMCTL_CHILD_NAVPROBE_VARIANT.
let variant = ProcessInfo.processInfo.environment["NAVPROBE_VARIANT"] ?? "large"
let prefersLarge = variant != "inline"
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
    if let l = v as? UILabel, let s = l.text { entry["text"] = s }
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

// MARK: - Recorder

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var wrapper = UIView()
    var nav: UINavigationController!
    var root: NavDemoRootVC!
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

        root = NavDemoRootVC()
        nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = prefersLarge
        hostVC.addChild(nav)
        nav.view.frame = wrapper.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.addSubview(nav.view)
        nav.didMove(toParent: hostVC)
        wrapper.layoutIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            captureRest("rest_root")
            beginRecording()
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
