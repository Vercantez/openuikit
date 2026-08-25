// Scroll-physics probe (M8): measures REAL UIScrollView physics in the
// oracle2 window by injecting synthetic input events into THIS app only
// (events are constructed with CoreGraphics CGEvent APIs, bridged to
// NSEvent, and delivered straight to our own NSWindow via sendEvent: —
// nothing is ever posted to the system event stream, no other app can see
// them, no accessibility permission is needed, and the cursor never moves).
//
//   Tools/oracle2/run.sh scroll <outdir>          # full measurement run
//   Tools/oracle2/run.sh scroll <outdir> discover # injection discovery only
//   Tools/oracle2/run.sh scroll <outdir> touch    # touch-synthesis discovery
//
// IMPORTANT FINDING (2026-08-24): this Catalyst channel only exercises
// UIKit's POINTER scroll path, whose physics are the Mac feel and NOT the
// iOS touch physics OpenUIKit implements (details in
// golden/scroll_traces/catalyst_pointer/README.md — Catalyst UIScrollView
// never applies touch-pan translation, verified by the `touch` mode). The
// authoritative TOUCH measurements come from the iOS Simulator probe:
// Tools/oracle2/simprobe + scripts/scroll_probe_sim.sh.
//
// Output: trace JSONs (schema: golden/scroll_traces/SCHEMA.md, pointer
// variant) + a console log.
import UIKit
import Darwin

// MARK: - dlsym'd CoreGraphics event functions
// CGEvent* is macOS-only API not exposed to the Catalyst SDK slice, but the
// symbols live in the same CoreGraphics binary the process already links.

func sym<T>(_ name: String, _ type: T.Type) -> T {
    guard let p = dlsym(UnsafeMutableRawPointer(bitPattern: -2) /* RTLD_DEFAULT */, name) else {
        fatalError("scrollprobe: missing symbol \(name)")
    }
    return unsafeBitCast(p, to: T.self)
}

enum CGE {
    // CGEventRef is a CFTypeRef; OpaquePointer keeps us honest.
    typealias EventRef = OpaquePointer

    static let createScroll = sym(
        "CGEventCreateScrollWheelEvent2",
        (@convention(c) (OpaquePointer?, UInt32, UInt32, Int32, Int32, Int32) -> EventRef?).self)
    static let createMouse = sym(
        "CGEventCreateMouseEvent",
        (@convention(c) (OpaquePointer?, UInt32, CGPoint, UInt32) -> EventRef?).self)
    static let setIntField = sym(
        "CGEventSetIntegerValueField",
        (@convention(c) (EventRef?, UInt32, Int64) -> Void).self)
    static let setDoubleField = sym(
        "CGEventSetDoubleValueField",
        (@convention(c) (EventRef?, UInt32, Double) -> Void).self)
    static let setLocation = sym(
        "CGEventSetLocation",
        (@convention(c) (EventRef?, CGPoint) -> Void).self)
    static let setTimestamp = sym(
        "CGEventSetTimestamp",
        (@convention(c) (EventRef?, UInt64) -> Void).self)
    static let setFlags = sym(
        "CGEventSetFlags",
        (@convention(c) (EventRef?, UInt64) -> Void).self)
    static let mainDisplayID = sym(
        "CGMainDisplayID", (@convention(c) () -> UInt32).self)
    static let displayBounds = sym(
        "CGDisplayBounds", (@convention(c) (UInt32) -> CGRect).self)

    // Field numbers from CGEventTypes.h (macOS SDK).
    static let fieldScrollIsContinuous: UInt32 = 88
    static let fieldScrollPhase: UInt32 = 99          // kCGScrollWheelEventScrollPhase
    static let fieldScrollMomentumPhase: UInt32 = 123 // kCGScrollWheelEventMomentumPhase
    static let fieldPointDeltaAxis1: UInt32 = 96
    static let fieldPointDeltaAxis2: UInt32 = 97
    static let fieldFixedPtDeltaAxis1: UInt32 = 93
    static let fieldMouseEventSubtype: UInt32 = 25
    static let fieldWindowUnderMousePointer: UInt32 = 91
    static let fieldWindowUnderMousePointerThatCanHandleThisEvent: UInt32 = 92

    // CGScrollPhase / CGMomentumScrollPhase values.
    enum ScrollPhase: Int64 { case none = 0, began = 1, changed = 2, ended = 4, cancelled = 8, mayBegin = 128 }
    enum MomentumPhase: Int64 { case none = 0, begin = 1, cont = 2, end = 3 }

    // CGEventType values.
    static let typeLeftMouseDown: UInt32 = 1
    static let typeLeftMouseUp: UInt32 = 2
    static let typeLeftMouseDragged: UInt32 = 6
    static let typeScrollWheel: UInt32 = 22
}

// MARK: - AppKit bridge (Catalyst: everything through the ObjC runtime)

enum AppKit {
    static var nsApp: NSObject? {
        (NSClassFromString("NSApplication") as? NSObject.Type)?
            .value(forKey: "sharedApplication") as? NSObject
    }
    static var windows: [NSObject] {
        nsApp?.value(forKey: "windows") as? [NSObject] ?? []
    }
    /// The (single) visible app window.
    static var window: NSObject? {
        for w in windows {
            if (w.value(forKey: "isVisible") as? Bool) == true { return w }
        }
        return windows.first
    }
    static func windowFrame(_ w: NSObject) -> CGRect {
        // KVC boxes the NSRect-returning -frame into an NSValue.
        guard let v = w.value(forKey: "frame") as? NSValue else { return .zero }
        var r = CGRect.zero
        v.getValue(&r)
        return r
    }
    static func windowNumber(_ w: NSObject) -> Int64 {
        (w.value(forKey: "windowNumber") as? Int64) ?? 0
    }
    /// CGEvent (CFTypeRef) -> NSEvent, or nil.
    static func nsEvent(from cg: CGE.EventRef) -> NSObject? {
        guard let cls = NSClassFromString("NSEvent") as? NSObject.Type else { return nil }
        let obj: AnyObject = unsafeBitCast(cg, to: AnyObject.self)
        return cls.perform(NSSelectorFromString("eventWithCGEvent:"), with: obj)?
            .takeUnretainedValue() as? NSObject
    }
    /// Deliver an NSEvent directly to a window (never leaves this app).
    static func send(_ ev: NSObject, to window: NSObject) {
        _ = objcMsgSendObj(window, NSSelectorFromString("sendEvent:"), ev)
    }
    static func sendViaApp(_ ev: NSObject) {
        guard let app = nsApp else { return }
        _ = objcMsgSendObj(app, NSSelectorFromString("sendEvent:"), ev)
    }
}

// MARK: - Event synthesis

let CGEventPostToPid = sym(
    "CGEventPostToPid", (@convention(c) (Int32, CGE.EventRef?) -> Void).self)

struct Injector {
    enum Strategy: String, CaseIterable {
        /// NSWindow.sendEvent with the CGEvent's global top-left location.
        case windowSendEvent
        /// NSWindow.sendEvent, CGEvent location pre-cooked so the bridged
        /// NSEvent's locationInWindow equals window-local (bottom-left) coords.
        case windowSendEventLocal
        /// -[contentView scrollWheel:] / mouse methods directly.
        case contentView
        /// NSApplication.sendEvent.
        case appSendEvent
        /// CGEventPostToPid(self) — system routing, still scoped to this app.
        case postToPid
    }

    var strategy: Strategy = .windowSendEvent
    /// Screen-space (CG top-left global coords) point events are aimed at.
    var screenPoint: CGPoint = .zero
    /// Same point in window-local bottom-left coords.
    var windowPoint: CGPoint = .zero
    var windowNumber: Int64 = 0
    var displayHeight: Double = 0
    var debugLogged = false

    static func nowNS() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }

    /// When set, the next event carries this exact timestamp (ns, uptime
    /// clock) instead of "now" — lets gestures put their events on an ideal
    /// time grid so UIKit's velocity estimate is immune to timer jitter.
    var overrideTimestampNS: UInt64?

    private mutating func finish(_ ev: CGE.EventRef, mouseSelector: String?) {
        // For the "local coords" trick: window-less CG-bridged NSEvents get
        // locationInWindow = (cgX, displayHeight − cgY); choose cg location
        // so that comes out as window-local coords.
        let loc = strategy == .windowSendEventLocal
            ? CGPoint(x: windowPoint.x, y: displayHeight - windowPoint.y)
            : screenPoint
        CGE.setLocation(ev, loc)
        CGE.setTimestamp(ev, overrideTimestampNS ?? Self.nowNS())
        overrideTimestampNS = nil
        CGE.setIntField(ev, CGE.fieldWindowUnderMousePointer, windowNumber)
        CGE.setIntField(ev, CGE.fieldWindowUnderMousePointerThatCanHandleThisEvent, windowNumber)
        if strategy == .postToPid {
            CGEventPostToPid(getpid(), ev)
            return
        }
        guard let ns = AppKit.nsEvent(from: ev) else {
            probeLog("!! NSEvent bridge failed")
            return
        }
        if !debugLogged {
            debugLogged = true
            let wn = (ns.value(forKey: "windowNumber") as? Int64) ?? -1
            let win = ns.value(forKey: "window") as? NSObject
            var lp = CGPoint.zero
            if let v = ns.value(forKey: "locationInWindow") as? NSValue { v.getValue(&lp) }
            probeLog("  bridged NSEvent windowNumber=\(wn) window=\(win == nil ? "nil" : "set") locationInWindow=\(lp)")
        }
        switch strategy {
        case .windowSendEvent, .windowSendEventLocal:
            if let w = AppKit.window { AppKit.send(ns, to: w) }
        case .contentView:
            if let w = AppKit.window,
               let cv = w.value(forKey: "contentView") as? NSObject {
                let sel = mouseSelector ?? "scrollWheel:"
                if cv.responds(to: NSSelectorFromString(sel)) {
                    _ = objcMsgSendObj(cv, NSSelectorFromString(sel), ns)
                } else {
                    probeLog("  contentView does not respond to \(sel)")
                }
            }
        case .appSendEvent:
            AppKit.sendViaApp(ns)
        case .postToPid:
            break
        }
    }

    /// Called with (mediaTime, dy, phase, momentum) for every sent scroll
    /// event — experiments record the exact injected input stream.
    var onScrollSent: ((Double, Double, CGE.ScrollPhase, CGE.MomentumPhase) -> Void)?

    /// Continuous (trackpad-style) scroll event. dy > 0 scrolls content up
    /// (finger moves down) in AppKit convention; sign checked empirically.
    mutating func scroll(dy: Double, phase: CGE.ScrollPhase, momentum: CGE.MomentumPhase = .none) {
        guard let ev = CGE.createScroll(nil, 0 /* pixel units */, 1, Int32(dy.rounded()), 0, 0) else { return }
        CGE.setIntField(ev, CGE.fieldScrollIsContinuous, 1)
        CGE.setIntField(ev, CGE.fieldScrollPhase, phase.rawValue)
        CGE.setIntField(ev, CGE.fieldScrollMomentumPhase, momentum.rawValue)
        CGE.setDoubleField(ev, CGE.fieldPointDeltaAxis1, dy)
        onScrollSent?(CACurrentMediaTime(), dy, phase, momentum)
        finish(ev, mouseSelector: nil)
    }

    mutating func mouse(_ type: UInt32) {
        guard let ev = CGE.createMouse(nil, type, screenPoint, 0) else { return }
        let sel: String
        switch type {
        case CGE.typeLeftMouseDown: sel = "mouseDown:"
        case CGE.typeLeftMouseUp: sel = "mouseUp:"
        default: sel = "mouseDragged:"
        }
        finish(ev, mouseSelector: sel)
    }
}


// MARK: - Probe runner

final class ScrollProbeRunner {
    let host: UIView
    let outdir: String
    let mode: String
    let scrollView = UIScrollView()
    let recorder = TraceRecorder()
    var injector = Injector()

    init(host: UIView, outdir: String, mode: String) {
        self.host = host
        self.outdir = outdir
        self.mode = mode
    }

    func start() {
        buildUI()
        // Give the window a moment to be composited + become active.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.locateAndGo() }
    }

    private func buildUI() {
        let hostBounds = host.bounds
        scrollView.frame = hostBounds
        scrollView.contentInsetAdjustmentBehavior = .never // no titlebar inset
        scrollView.contentSize = CGSize(width: hostBounds.width, height: 40_000)
        scrollView.backgroundColor = .white
        // Visible stripes so a human (and drawHierarchy) can see movement.
        for i in 0..<80 {
            let stripe = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 500, width: hostBounds.width, height: 250))
            stripe.backgroundColor = UIColor(white: 0.9, alpha: 1)
            scrollView.addSubview(stripe)
        }
        host.addSubview(scrollView)
        recorder.attach(scrollView)
    }

    private func locateAndGo() {
        guard let win = AppKit.window else {
            probeLog("!! no NSWindow found")
            finish(code: 4)
            return
        }
        let frame = AppKit.windowFrame(win)
        let display = CGE.displayBounds(CGE.mainDisplayID())
        // NSWindow frame is bottom-left global; CGEvent wants top-left global.
        let center = CGPoint(x: frame.midX, y: display.height - frame.midY)
        injector.screenPoint = center
        injector.windowPoint = CGPoint(x: frame.width / 2, y: frame.height / 2)
        injector.windowNumber = AppKit.windowNumber(win)
        injector.displayHeight = display.height
        probeLog("window frame=\(frame) number=\(injector.windowNumber) target=\(center) display=\(display)")
        probeLog("uiwindow bounds=\(host.bounds) scrollView=\(scrollView.frame)")
        unitsPerPx = Double(host.bounds.width) / Double(frame.width)
        probeLog("unitsPerPx (UIKit pt per AppKit px) = \(unitsPerPx)")
        switch mode {
        case "discover": runDiscovery()
        case "touch": runTouchDiscovery()
        default: runMeasurements()
        }
    }

    // MARK: Touch-path discovery

    private var touchSynth: TouchSynth?

    private func runTouchDiscovery() {
        guard let uiWindow = host.window else {
            probeLog("!! no UIWindow")
            finish(code: 4)
            return
        }
        let synth = TouchSynth(window: uiWindow)
        touchSynth = synth
        recorder.recording = true
        scrollView.setContentOffset(CGPoint(x: 0, y: 5000), animated: false)
        // Instrument the real pan: log state + translation while dragging.
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(logPan(_:)))
        schedule(0.3) {
            self.recorder.reset()
            let start = self.scrollView.contentOffset
            probeLog("== touch drag: 15 x -12pt @ 8ms ==")
            var points: [CGPoint] = []
            var p = CGPoint(x: 350, y: 430)
            points.append(p)
            for _ in 0..<15 { p.y -= 12; points.append(p) }
            self.runTouchGesture(points: points, interval: 0.008) {
                self.schedule(2.0) {
                    let off = self.scrollView.contentOffset
                    probeLog("  offset \(start) -> \(off) moved=\(off != start)")
                    probeLog("  delegate: \(self.recorder.delegateEvents.map { "\($0.name)(\($0.detail))" }.joined(separator: ", "))")
                    if let we = self.recorder.willEnd {
                        probeLog("  willEndDragging v=\(we.vy) target=\(we.targetY)")
                    }
                    probeLog("  samples=\(self.recorder.samples.count)")
                    self.finish(code: 0)
                }
            }
        }
    }

    @objc private func logPan(_ pan: UIPanGestureRecognizer) {
        let tr = pan.translation(in: scrollView)
        let v = pan.velocity(in: scrollView)
        probeLog("  pan state=\(pan.state.rawValue) translation=\(tr) velocity=\(v) tracking=\(scrollView.isTracking) dragging=\(scrollView.isDragging) off=\(scrollView.contentOffset.y)")
    }

    /// Touch drag along `points`: began at [0], moved through the rest,
    /// ended at the last — paced by a strict timer, stamped on the ideal
    /// grid (UITouch timestamps use the CACurrentMediaTime clock).
    private func runTouchGesture(points: [CGPoint], interval: Double,
                                 completion: @escaping () -> Void) {
        guard let synth = touchSynth else { completion(); return }
        let t0 = CACurrentMediaTime()
        var i = 0
        let n = points.count
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard i <= n else { return }
            let ts = t0 + Double(i) * interval
            if i == 0 {
                synth.send(phase: .began, point: points[0], timestamp: ts, first: true)
                self.inputLog.append(["t": ts, "x": Double(points[0].x), "y": Double(points[0].y), "phase": "began"])
            } else if i < n {
                synth.send(phase: .moved, point: points[i], timestamp: ts, first: false)
                self.inputLog.append(["t": ts, "x": Double(points[i].x), "y": Double(points[i].y), "phase": "moved"])
            } else {
                synth.send(phase: .ended, point: points[n - 1], timestamp: ts, first: false)
                self.inputLog.append(["t": ts, "x": Double(points[n - 1].x), "y": Double(points[n - 1].y), "phase": "ended"])
            }
            i += 1
            if i > n {
                self.gestureTimer?.cancel()
                self.gestureTimer = nil
                completion()
            }
        }
        gestureTimer = timer
        timer.resume()
    }

    // MARK: Measurement experiments

    /// UIKit points per injected AppKit pixel (Catalyst 0.77 window scaling).
    var unitsPerPx: Double = 1
    var inputLog: [[String: Any]] = []

    struct ExperimentSpec {
        let name: String
        let kind: String
        let startY: Double
        let deltas: [Double]   // AppKit px per event; >0 drags content up (overscroll top)
        let interval: Double
    }

    private var experiments: [ExperimentSpec] {
        let maxY = 40_000.0 - Double(scrollView.bounds.height)
        return [
            // Slow drag, velocity killed before release: pure 1:1 tracking +
            // px->pt calibration. Trailing zero-deltas kill release velocity.
            .init(name: "calib_slow_drag", kind: "calibration", startY: 5000,
                  deltas: Array(repeating: -4, count: 50) + [0, 0, 0, 0], interval: 0.016),
            // Free deceleration at several release velocities (mid-content,
            // no edge involvement).
            .init(name: "decel_slow", kind: "deceleration", startY: 5000,
                  deltas: Array(repeating: -5, count: 14), interval: 0.008),
            .init(name: "decel_med", kind: "deceleration", startY: 5000,
                  deltas: Array(repeating: -11, count: 14), interval: 0.008),
            .init(name: "decel_fast", kind: "deceleration", startY: 5000,
                  deltas: Array(repeating: -22, count: 14), interval: 0.008),
            .init(name: "decel_faster", kind: "deceleration", startY: 5000,
                  deltas: Array(repeating: -38, count: 14), interval: 0.008),
            // Slow drag far past the top edge: rubber-band curve (input
            // stream = finger positions), then zero-velocity bounce back.
            .init(name: "rubberband_top", kind: "rubber_band", startY: 0,
                  deltas: Array(repeating: 4, count: 90) + [0, 0, 0, 0], interval: 0.008),
            .init(name: "rubberband_bottom", kind: "rubber_band", startY: maxY,
                  deltas: Array(repeating: -4, count: 90) + [0, 0, 0, 0], interval: 0.008),
            // Fast overscroll released while still moving: bounce spring
            // carrying release velocity.
            .init(name: "bounce_release_vel", kind: "bounce_release", startY: 0,
                  deltas: Array(repeating: 14, count: 10), interval: 0.008),
            // Deceleration INTO the bottom edge: impact bounce with carried
            // velocity.
            .init(name: "edge_impact", kind: "edge_impact", startY: maxY - 350,
                  deltas: Array(repeating: -30, count: 12), interval: 0.008),
        ]
    }

    private func runMeasurements() {
        recorder.recording = true
        injector.strategy = .windowSendEventLocal
        injector.onScrollSent = { [weak self] t, dy, phase, momentum in
            self?.inputLog.append([
                "t": t, "dyPx": dy, "phase": "\(phase)", "momentum": "\(momentum)",
            ])
        }
        let specs = experiments
        var idx = 0
        func next() {
            guard idx < specs.count else {
                self.runMouseExperiment { self.finish(code: 0) }
                return
            }
            let spec = specs[idx]
            idx += 1
            self.runExperiment(spec) { next() }
        }
        next()
    }

    private func runExperiment(_ spec: ExperimentSpec, completion: @escaping () -> Void) {
        probeLog("== \(spec.name) (\(spec.kind)) ==")
        scrollView.setContentOffset(CGPoint(x: 0, y: spec.startY), animated: false)
        schedule(0.25) {
            self.recorder.reset()
            self.inputLog.removeAll()
            let t0 = CACurrentMediaTime()
            self.runGesture(deltas: spec.deltas, interval: spec.interval) {
                self.waitForSettle(since: CACurrentMediaTime()) {
                    self.writeTrace(spec: spec, t0: t0)
                    completion()
                }
            }
        }
    }

    private var gestureTimer: DispatchSourceTimer?

    /// Send began + deltas (changed) + ended, paced by a strict timer, each
    /// event stamped on the IDEAL grid t0 + i·interval so UIKit's velocity
    /// estimate never sees scheduler jitter.
    private func runGesture(deltas: [Double], interval: Double,
                            completion: @escaping () -> Void) {
        let baseNS = Injector.nowNS()
        var events: [(dy: Double, phase: CGE.ScrollPhase)] =
            [(0, .began)] + deltas.map { ($0, .changed) } + [(0, .ended)]
        var i = 0
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard i < events.count else { return }
            let (dy, phase) = events[i]
            self.injector.overrideTimestampNS = baseNS + UInt64(Double(i) * interval * 1e9)
            self.injector.scroll(dy: dy, phase: phase)
            i += 1
            if i == events.count {
                self.gestureTimer?.cancel()
                self.gestureTimer = nil
                events.removeAll()
                completion()
            }
        }
        gestureTimer = timer
        timer.resume()
    }

    private func waitForSettle(since: Double, completion: @escaping () -> Void) {
        var lastOffset = scrollView.contentOffset
        var stable = 0
        func poll() {
            let off = self.scrollView.contentOffset
            if off == lastOffset, !self.scrollView.isDecelerating, !self.scrollView.isDragging {
                stable += 1
            } else {
                stable = 0
                lastOffset = off
            }
            if stable >= 5 { completion(); return }
            if CACurrentMediaTime() - since > 12 {
                probeLog("  !! settle timeout")
                completion()
                return
            }
            self.schedule(0.15) { poll() }
        }
        poll()
    }

    private func writeTrace(spec: ExperimentSpec, t0: Double) {
        var dict: [String: Any] = [
            "name": spec.name,
            "kind": spec.kind,
            "source": "oracle2 scroll probe (real UIKit, Mac Catalyst window; scroll-phase NSEvents via NSWindow.sendEvent)",
            "unitsPerPx": unitsPerPx,
            "interval": spec.interval,
            "t0": t0,
            "viewport": ["w": Double(scrollView.bounds.width), "h": Double(scrollView.bounds.height)],
            "contentSize": ["w": Double(scrollView.contentSize.width), "h": Double(scrollView.contentSize.height)],
            "startOffsetY": spec.startY,
            "decelerationRate": Double(scrollView.decelerationRate.rawValue),
            "input": inputLog,
            "samples": recorder.samples.map { [$0.t, $0.x, $0.y] },
            "delegate": recorder.delegateEvents.map { ["t": $0.t, "name": $0.name, "detail": $0.detail] },
        ]
        if let we = recorder.willEnd {
            dict["willEndDragging"] = ["t": we.t, "vx": we.vx, "vy": we.vy,
                                       "targetX": we.targetX, "targetY": we.targetY]
        }
        dict["finalOffsetY"] = Double(scrollView.contentOffset.y)
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            try data.write(to: URL(fileURLWithPath: "\(outdir)/\(spec.name).json"))
            probeLog("  wrote \(spec.name).json (\(recorder.samples.count) samples, final y=\(scrollView.contentOffset.y))")
            if let we = recorder.willEnd {
                probeLog("  willEndDragging v=\(we.vy) target=\(we.targetY)")
            }
        } catch {
            probeLog("  !! write failed: \(error)")
        }
    }

    /// Mouse click-drag: does Catalyst treat it as a touch pan? (If yes this
    /// is the touch-path physics; recorded for comparison.)
    private func runMouseExperiment(completion: @escaping () -> Void) {
        probeLog("== mouse_drag (touch-path probe) ==")
        scrollView.setContentOffset(CGPoint(x: 0, y: 5000), animated: false)
        schedule(0.25) {
            self.recorder.reset()
            self.inputLog.removeAll()
            let start = self.scrollView.contentOffset
            let savedPoint = self.injector.windowPoint
            var t = 0.0
            self.schedule(t) { self.injector.mouse(CGE.typeLeftMouseDown) }
            for _ in 0..<20 {
                t += 0.008
                self.schedule(t) {
                    self.injector.windowPoint.y += 8 // window coords: up = +y
                    self.injector.mouse(CGE.typeLeftMouseDragged)
                }
            }
            t += 0.008
            self.schedule(t) { self.injector.mouse(CGE.typeLeftMouseUp) }
            self.schedule(t + 1.5) {
                let off = self.scrollView.contentOffset
                probeLog("  mouse drag offset \(start) -> \(off) moved=\(off != start)")
                probeLog("  delegate: \(self.recorder.delegateEvents.map(\.name).joined(separator: ", "))")
                self.injector.windowPoint = savedPoint
                if off != start {
                    let spec = ExperimentSpec(name: "mouse_drag", kind: "mouse_drag",
                                              startY: 5000, deltas: [], interval: 0.008)
                    self.writeTrace(spec: spec, t0: CACurrentMediaTime())
                }
                completion()
            }
        }
    }

    // MARK: Discovery: which injection style moves the scroll view?

    private func runDiscovery() {
        recorder.recording = true
        var strategies = Injector.Strategy.allCases[...]

        func tryNext() {
            guard let s = strategies.first else {
                probeLog("== discovery done ==")
                self.finish(code: 0)
                return
            }
            strategies = strategies.dropFirst()
            recorder.reset()
            injector.strategy = s
            injector.debugLogged = false
            let startOffset = scrollView.contentOffset
            probeLog("== scroll burst via \(s.rawValue) ==")
            var t = 0.0
            schedule(t) { self.injector.scroll(dy: 0, phase: .began) }
            for _ in 0..<15 {
                t += 0.008
                schedule(t) { self.injector.scroll(dy: -10, phase: .changed) }
            }
            t += 0.008
            schedule(t) { self.injector.scroll(dy: 0, phase: .ended) }
            schedule(t + 0.8) {
                let off = self.scrollView.contentOffset
                let moved = off != startOffset
                probeLog("  offset \(startOffset) -> \(off)  moved=\(moved)")
                probeLog("  delegate: \(self.recorder.delegateEvents.map { "\($0.name)(\($0.detail))" }.joined(separator: ", "))")
                if let we = self.recorder.willEnd {
                    probeLog("  willEndDragging: v=(\(we.vx),\(we.vy)) target=(\(we.targetX),\(we.targetY))")
                }
                tryNext()
            }
        }
        tryNext()
    }

    private func schedule(_ t: Double, _ body: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: body)
    }

    private func finish(code: Int32) {
        try? logLines.joined(separator: "\n").appending("\n")
            .write(toFile: "\(outdir)/discovery.log", atomically: true, encoding: .utf8)
        exit(code)
    }
}
