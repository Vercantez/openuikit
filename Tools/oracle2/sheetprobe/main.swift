// SheetProbe: iOS Simulator MODAL SHEET oracle (M11 interactive sheets).
//
// Sibling of SimProbe (scroll physics). Mac Catalyst cannot present the iOS
// pageSheet at all (it bridges to an AppKit sheet window — see
// Tools/oracle2/simscene/main.swift), so every measurement of the sheet's
// INTERACTIVE behaviour has to come from real iOS UIKit in the simulator.
//
// What it measures, by synthesizing UITouch drags on a live
// UISheetPresentationController (scrollshared.swift TouchSynth) and sampling
// the presentation layers per display-link frame:
//
//   1. static geometry — sheet frame at rest for each detent, and the
//      grabber's class/frame/corner radius/colour (prefersGrabberVisible)
//   2. the drag TRACKING law — finger delta vs. sheet delta, downward
//      (expected 1:1) and upward past the top (expected rubber band)
//   3. the DIMMING alpha as a function of drag progress
//   4. the DISMISS thresholds — distance (released at rest) and velocity
//   5. detent SNAP behaviour between .medium and .large
//
// Output: <Documents>/sheet_<name>.json per experiment + probe.log.
// Build + run end-to-end: scripts/sheet_probe_sim.sh <outdir>
import UIKit

// MARK: - Hierarchy dump

/// One view's identity for the static dumps: enough to find it again by
/// class name and to measure it (frame in WINDOW coordinates, corner radius,
/// resolved background colour, alpha).
func dumpHierarchy(_ v: UIView, in window: UIWindow, depth: Int = 0,
                   into out: inout [[String: Any]], path: String = "") {
    let f = v.convert(v.bounds, to: window)
    var e: [String: Any] = [
        "path": path,
        "class": NSStringFromClass(type(of: v)),
        "depth": depth,
        "frame": [Double(f.minX), Double(f.minY), Double(f.width), Double(f.height)],
        "alpha": Double(v.alpha),
        "hidden": v.isHidden,
        "cornerRadius": Double(v.layer.cornerRadius),
        "opacity": Double(v.layer.opacity),
    ]
    if let bg = v.backgroundColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        bg.resolvedColor(with: v.traitCollection).getRed(&r, green: &g, blue: &b, alpha: &a)
        e["bg"] = [Double(r), Double(g), Double(b), Double(a)]
    }
    if let bgcg = v.layer.backgroundColor, v.backgroundColor == nil {
        let c = UIColor(cgColor: bgcg)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        e["layerBg"] = [Double(r), Double(g), Double(b), Double(a)]
    }
    out.append(e)
    for s in v.subviews { dumpHierarchy(s, in: window, depth: depth + 1, into: &out,
                                        path: path.isEmpty ? "\(v.subviews.firstIndex(of: s)!)"
                                                           : "\(path).\(v.subviews.firstIndex(of: s)!)") }
}

func findViews(_ v: UIView, classContains needle: String, into out: inout [UIView]) {
    if NSStringFromClass(type(of: v)).contains(needle) { out.append(v) }
    for s in v.subviews { findViews(s, classContains: needle, into: &out) }
}

// MARK: - Sheet sampler

/// Per-frame sample of everything that moves during a sheet drag.
final class SheetRecorder {
    struct Sample {
        let t: Double
        let sheetY: Double       // presentation-layer top edge, window coords
        let sheetH: Double       // presentation-layer height (detent changes it)
        let sheetScale: Double   // presentation-layer transform scale (detent chrome)
        let modelY: Double       // model (non-presentation) top edge, window coords
        let dimOpacity: Double   // presentation-layer opacity of the dim view
        let dimAlphaBg: Double   // its background colour's alpha
        let innerOffsetY: Double // contentOffset.y of a scroll view inside
    }
    var samples: [Sample] = []
    var link: CADisplayLink?
    weak var sheet: UIView?
    weak var dim: UIView?
    weak var window: UIWindow?
    weak var inner: UIScrollView?
    var recording = false

    func start(sheet: UIView, dim: UIView?, window: UIWindow, inner: UIScrollView?) {
        self.sheet = sheet
        self.dim = dim
        self.window = window
        self.inner = inner
        samples.removeAll()
        if link == nil {
            let l = CADisplayLink(target: self, selector: #selector(step))
            l.add(to: .main, forMode: .common)
            link = l
        }
        recording = true
    }

    func stop() { recording = false }

    @objc private func step() {
        guard recording, let sheet, let window else { return }
        // The presentation layer is what is actually on screen mid-animation.
        // Read its geometry in the layer's OWN terms (position/bounds/
        // transform) and lift it into window space by hand — a CALayer
        // convert() against the presentation layer of a view whose superview
        // chain is being animated reports the model geometry, not this one.
        let pl = sheet.layer.presentation() ?? sheet.layer
        let tf = pl.affineTransform()
        let scale = Double(tf.d)
        // position is the anchorPoint (default .5,.5) in the SUPERLAYER's
        // coordinate space; the sheet's superlayer is the full-window
        // transition view, so this is already window space.
        let h = Double(pl.bounds.height) * scale
        let top = Double(pl.position.y) - Double(pl.anchorPoint.y) * h
        var op = 0.0, bga = 0.0
        if let dim {
            let dl = dim.layer.presentation() ?? dim.layer
            op = Double(dl.opacity)
            if let c = dl.backgroundColor {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                UIColor(cgColor: c).getRed(&r, green: &g, blue: &b, alpha: &a)
                bga = Double(a)
            }
        }
        samples.append(.init(t: CACurrentMediaTime(), sheetY: top, sheetH: h,
                             sheetScale: scale,
                             modelY: Double(sheet.convert(sheet.bounds, to: window).minY),
                             dimOpacity: op, dimAlphaBg: bga,
                             innerOffsetY: Double(inner?.contentOffset.y ?? .nan)))
    }
}

// MARK: - Experiments

struct SheetExperiment {
    let name: String
    /// Detents to install: "large", "medium", or "medium+large".
    let detents: String
    /// Finger path in window coords ([0] = touch-down).
    let points: [CGPoint]
    let interval: Double
    /// Seconds held still before lift-off (0 = flick release, keeps velocity).
    let holdBeforeLift: Double
    /// Start the sheet at the medium detent instead of large.
    let startMedium: Bool
    /// "scroll" (tall UIScrollView inside) or "plain" (inert content).
    let content: String

    init(name: String, detents: String = "large", points: [CGPoint],
         interval: Double = 0.008, holdBeforeLift: Double = 0,
         startMedium: Bool = false, content: String = "plain") {
        self.name = name
        self.detents = detents
        self.points = points
        self.interval = interval
        self.holdBeforeLift = holdBeforeLift
        self.startMedium = startMedium
        self.content = content
    }
}

final class SheetProbeRunner {
    let hostVC: UIViewController
    let window: UIWindow
    let recorder = SheetRecorder()
    let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var synth: TouchSynth!
    var inputLog: [[String: Any]] = []
    private var gestureTimer: DispatchSourceTimer?

    init(hostVC: UIViewController, window: UIWindow) {
        self.hostVC = hostVC
        self.window = window
    }

    // MARK: sheet construction

    /// A presented pageSheet. `content: "scroll"` puts a tall UIScrollView
    /// inside (so the sheet/scroll hand-off can be probed); `content: "plain"`
    /// puts inert views inside, so every drag reaches the sheet's own pan
    /// recognizer.
    func makeSheetVC(detents: String, grabber: Bool,
                     content: String = "scroll") -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        if content == "scroll" {
            let sv = UIScrollView(frame: vc.view.bounds)
            sv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            sv.contentInsetAdjustmentBehavior = .never
            sv.contentSize = CGSize(width: window.bounds.width, height: 4000)
            for i in 0..<40 {
                let stripe = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 100,
                                                  width: window.bounds.width, height: 50))
                stripe.backgroundColor = UIColor(white: 0.9, alpha: 1)
                sv.addSubview(stripe)
            }
            sv.tag = 777
            vc.view.addSubview(sv)
        } else {
            for i in 0..<8 {
                let stripe = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 100,
                                                  width: window.bounds.width, height: 50))
                stripe.backgroundColor = UIColor(white: 0.9, alpha: 1)
                vc.view.addSubview(stripe)
            }
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            switch detents {
            case "medium": sheet.detents = [.medium()]
            case "medium+large": sheet.detents = [.medium(), .large()]
            case let s where s.hasPrefix("custom"):
                let h = Double(s.dropFirst("custom".count)) ?? 400
                sheet.detents = [.custom { _ in CGFloat(h) }]
            default: sheet.detents = [.large()]
            }
            sheet.prefersGrabberVisible = grabber
        }
        return vc
    }

    /// The dim view UIKit installs behind a pageSheet, found by class name.
    func findDim() -> UIView? {
        var hits: [UIView] = []
        findViews(window, classContains: "Dimming", into: &hits)
        if hits.isEmpty { findViews(window, classContains: "DropShadow", into: &hits) }
        return hits.first
    }

    /// The moving sheet container: the presented view's superview chain up to
    /// (but not including) the presentation container.
    func sheetContainer(for vc: UIViewController) -> UIView {
        var v: UIView = vc.view
        // Walk up while the parent is still sheet chrome (UIDropShadowView,
        // _UISheetLayoutInfo host, ...) and not the full-window container.
        while let s = v.superview, s.bounds.height < window.bounds.height - 1 { v = s }
        return v
    }

    // MARK: static dumps

    func staticDump(name: String, detents: String, grabber: Bool,
                    completion: @escaping () -> Void) {
        let vc = makeSheetVC(detents: detents, grabber: grabber)
        hostVC.present(vc, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            var views: [[String: Any]] = []
            dumpHierarchy(self.window, in: self.window, into: &views)
            var out: [String: Any] = [
                "name": name, "detents": detents, "grabber": grabber,
                "windowSize": [Double(self.window.bounds.width), Double(self.window.bounds.height)],
                "scale": Double(UIScreen.main.scale),
                "iOS": UIDevice.current.systemVersion,
                "views": views,
            ]
            let sf = vc.view.convert(vc.view.bounds, to: self.window)
            out["presentedViewFrame"] = [Double(sf.minX), Double(sf.minY),
                                         Double(sf.width), Double(sf.height)]
            let cf = self.sheetContainer(for: vc)
            let cfw = cf.convert(cf.bounds, to: self.window)
            out["sheetContainerClass"] = NSStringFromClass(type(of: cf))
            out["sheetContainerFrame"] = [Double(cfw.minX), Double(cfw.minY),
                                          Double(cfw.width), Double(cfw.height)]
            self.write(out, to: "sheet_\(name).json")
            probeLog("== \(name) == presented=\(sf) container=\(NSStringFromClass(type(of: cf))) \(cfw)")
            for v in views where v["class"] as! String != "UIView" {
                probeLog("   \(String(repeating: "  ", count: v["depth"] as! Int))"
                         + "\(v["class"] as! String) \(v["frame"] as! [Double]) "
                         + "r=\(v["cornerRadius"] as! Double) a=\(v["alpha"] as! Double) "
                         + "bg=\(v["bg"] as? [Double] ?? v["layerBg"] as? [Double] ?? [])")
            }
            vc.dismiss(animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: completion)
        }
    }

    // MARK: drag experiments

    func runExperiment(_ spec: SheetExperiment, completion: @escaping () -> Void) {
        probeLog("== \(spec.name) (detents=\(spec.detents)) ==")
        let vc = makeSheetVC(detents: spec.detents, grabber: true,
                             content: spec.content)
        hostVC.present(vc, animated: false)
        if spec.startMedium, let sheet = vc.sheetPresentationController {
            sheet.selectedDetentIdentifier = .medium
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let container = self.sheetContainer(for: vc)
            let dim = self.findDim()
            let restY = Double(container.convert(container.bounds, to: self.window).minY)
            self.recorder.start(sheet: container, dim: dim, window: self.window,
                                inner: vc.view.viewWithTag(777) as? UIScrollView)
            self.inputLog.removeAll()
            self.runGesture(spec) {
                // Let the release animation (spring back OR dismissal) finish.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    self.recorder.stop()
                    let dismissed = vc.presentingViewController == nil
                    var finalY = Double.nan
                    if !dismissed {
                        finalY = Double(container.convert(container.bounds, to: self.window).minY)
                    }
                    self.write([
                        "name": spec.name,
                        "detents": spec.detents,
                        "startMedium": spec.startMedium,
                        "interval": spec.interval,
                        "holdBeforeLift": spec.holdBeforeLift,
                        "windowSize": [Double(self.window.bounds.width),
                                       Double(self.window.bounds.height)],
                        "restY": restY,
                        "dimClass": dim.map { NSStringFromClass(type(of: $0)) } ?? "none",
                        "dismissed": dismissed,
                        "finalY": finalY.isNaN ? "dismissed" : finalY,
                        "input": self.inputLog,
                        "sampleKeys": ["t", "sheetY", "sheetH", "sheetScale",
                                       "modelY", "dimOpacity", "dimAlphaBg",
                                       "innerOffsetY"],
                        "samples": self.recorder.samples.map {
                            [$0.t, $0.sheetY, $0.sheetH, $0.sheetScale,
                             $0.modelY, $0.dimOpacity, $0.dimAlphaBg,
                             $0.innerOffsetY.isNaN ? -1 : $0.innerOffsetY]
                        },
                    ], to: "sheet_\(spec.name).json")
                    probeLog("  restY=\(restY) dismissed=\(dismissed) finalY=\(finalY) "
                             + "samples=\(self.recorder.samples.count)")
                    if !dismissed { vc.dismiss(animated: false) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: completion)
                }
            }
        }
    }

    private func runGesture(_ spec: SheetExperiment, completion: @escaping () -> Void) {
        let points = spec.points
        let interval = spec.interval
        let holdTicks = Int((spec.holdBeforeLift / interval).rounded())
        let n = points.count
        let total = n + holdTicks + 1
        let t0 = CACurrentMediaTime()
        var i = 0
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self, i < total else { return }
            let ts = t0 + Double(i) * interval
            if i == 0 {
                self.synth.send(phase: .began, point: points[0], timestamp: ts, first: true)
                self.logInput(ts, points[0], "began")
            } else if i < n {
                self.synth.send(phase: .moved, point: points[i], timestamp: ts, first: false)
                self.logInput(ts, points[i], "moved")
            } else if i < n + holdTicks {
                self.synth.send(phase: .stationary, point: points[n - 1], timestamp: ts, first: false)
                self.logInput(ts, points[n - 1], "stationary")
            } else {
                self.synth.send(phase: .ended, point: points[n - 1], timestamp: ts, first: false)
                self.logInput(ts, points[n - 1], "ended")
            }
            i += 1
            if i == total {
                self.gestureTimer?.cancel()
                self.gestureTimer = nil
                completion()
            }
        }
        gestureTimer = timer
        timer.resume()
    }

    private func logInput(_ t: Double, _ p: CGPoint, _ phase: String) {
        inputLog.append(["t": t, "x": Double(p.x), "y": Double(p.y), "phase": phase])
    }

    private func write(_ dict: [String: Any], to file: String) {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            try data.write(to: URL(fileURLWithPath: "\(docs)/\(file)"))
        } catch {
            probeLog("  !! write \(file) failed: \(error)")
        }
    }

    // MARK: driver

    func start() {
        synth = TouchSynth(window: window)
        probeLog("sheetprobe: window \(window.bounds.size) scale=\(UIScreen.main.scale) "
                 + "iOS \(UIDevice.current.systemVersion)")
        probeLog("outdir: \(docs)")

        let w = window.bounds.width
        let cx = w / 2
        // Touch-down well inside the sheet body but clear of the scroll view
        // in the tracking experiments (the grabber area at the very top).
        let grab = 90.0

        /// Vertical drag from y0 by `count` steps of `dy`.
        func drag(from y0: Double, dy: Double, count: Int) -> [CGPoint] {
            var pts = [CGPoint(x: cx, y: y0)]
            var y = y0
            for _ in 0..<count { y += dy; pts.append(CGPoint(x: cx, y: y)) }
            return pts
        }

        /// Distance experiment: travel `dist` pt down at 4 pt per 16 ms, then
        /// hold still so the release carries (almost) no velocity — isolates
        /// the DISTANCE half of the dismissal rule.
        func dist(_ d: Int) -> SheetExperiment {
            .init(name: "dist_\(d)", points: drag(from: grab, dy: 4, count: d / 4),
                  interval: 0.016, holdBeforeLift: 0.4)
        }
        /// Velocity experiment: 64 pt of travel (far under any plausible
        /// distance threshold) released while still moving at `v` pt/s.
        func vel(_ v: Int) -> SheetExperiment {
            let step = Double(v) * 0.008
            return .init(name: "vel_\(v)",
                         points: drag(from: grab, dy: step,
                                      count: Int((64.0 / step).rounded())),
                         interval: 0.008, holdBeforeLift: 0)
        }

        let experiments: [SheetExperiment] = [
            // 1:1 tracking + dim curve. 180 pt down, held still before the
            // lift so it springs back rather than dismissing.
            .init(name: "drag_track_down", points: drag(from: grab, dy: 3, count: 60),
                  interval: 0.016, holdBeforeLift: 0.4),
            // Upward past the top of the large detent: rubber band. Inert
            // content, so the drag reaches the sheet and not a scroll view.
            .init(name: "drag_up_band", points: drag(from: 400, dy: -3, count: 60),
                  interval: 0.016, holdBeforeLift: 0.4),
            // Distance threshold, released at rest. Sheet body is 793 pt, so
            // 50 % = 396.5 of travel-minus-slop -> 406.5 pt of finger travel.
            dist(380), dist(400), dist(404), dist(408), dist(412),
            // Velocity threshold at fixed (small) travel.
            vel(875), vel(900), vel(925), vel(950), vel(975), vel(1000),
            // Is the distance rule PROPORTIONAL to the detent height or a
            // fixed number of points? A 400 pt sheet must dismiss at ~200.
            .init(name: "custom400_dist_180", detents: "custom400",
                  points: drag(from: 500, dy: 4, count: 45),
                  interval: 0.016, holdBeforeLift: 0.4),
            .init(name: "custom400_dist_220", detents: "custom400",
                  points: drag(from: 500, dy: 4, count: 55),
                  interval: 0.016, holdBeforeLift: 0.4),
            // Detents. The sheet opens at MEDIUM when both are offered, so
            // the touch has to start inside the medium sheet (top ~404).
            .init(name: "detent_medium_drag_down", detents: "medium+large",
                  points: drag(from: 500, dy: 4, count: 40),
                  interval: 0.016, holdBeforeLift: 0.4),
            .init(name: "detent_medium_drag_up", detents: "medium+large",
                  points: drag(from: 500, dy: -4, count: 60),
                  interval: 0.016, holdBeforeLift: 0.4),
            // Scroll view inside the sheet, at contentOffset.top: dragging
            // DOWN should move the SHEET, not the content.
            .init(name: "inner_scroll_at_top", points: drag(from: 500, dy: 4, count: 50),
                  interval: 0.016, holdBeforeLift: 0.4, content: "scroll"),
            // Same sheet, dragging UP: the content should scroll and the
            // sheet should stay put.
            .init(name: "inner_scroll_up", points: drag(from: 500, dy: -4, count: 50),
                  interval: 0.016, holdBeforeLift: 0.4, content: "scroll"),
        ]

        // Static dumps first (geometry + grabber), then the drags.
        staticDump(name: "static_large_grabber", detents: "large", grabber: true) {
            self.staticDump(name: "static_large_nograbber", detents: "large", grabber: false) {
                self.staticDump(name: "static_medium", detents: "medium+large", grabber: true) {
                    var idx = 0
                    func next() {
                        guard idx < experiments.count else {
                            probeLog("PROBE DONE")
                            try? (logLines.joined(separator: "\n") + "\n")
                                .write(toFile: self.docs + "/probe.log",
                                       atomically: true, encoding: .utf8)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
                            return
                        }
                        let e = experiments[idx]
                        idx += 1
                        self.runExperiment(e) { next() }
                    }
                    next()
                }
            }
        }
    }
}

class SheetProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var runner: SheetProbeRunner?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 24, y: 80, width: 300, height: 30))
        label.text = "Base screen"
        vc.view.addSubview(label)
        win.rootViewController = vc
        win.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let r = SheetProbeRunner(hostVC: vc, window: win)
            self.runner = r
            r.start()
        }
        return true
    }
}

// Watchdog: never wedge the simulator pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
    FileHandle.standardError.write(Data("sheetprobe: watchdog timeout\n".utf8))
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(SheetProbeAppDelegate.self))
