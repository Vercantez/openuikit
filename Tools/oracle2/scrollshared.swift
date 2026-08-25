// Shared scroll-physics probe machinery, compiled into BOTH oracle2 (Mac
// Catalyst; pointer-scroll measurements) and simprobe (iOS Simulator; the
// authoritative TOUCH physics measurements). Owner: scroll module (M8).
//
// Contains: probe logging, the contentOffset trace recorder, KIF-style
// synthetic UITouch delivery (private UIKit API, in-process only), the
// touch-gesture experiment driver, and the golden-trace JSON writer
// (schema: golden/scroll_traces/SCHEMA.md).
import UIKit
import Darwin

// MARK: - Probe log

var logLines: [String] = []
func probeLog(_ s: String) {
    logLines.append(s)
    print(s)
    // simctl launch --console can buffer aggressively; keep output timely.
    fflush(stdout)
}

// MARK: - objc_msgSend trampolines

let rawMsgSend = dlsym(UnsafeMutableRawPointer(bitPattern: -2) /* RTLD_DEFAULT */, "objc_msgSend")!
typealias MsgSendObj = @convention(c) (AnyObject, Selector, AnyObject?) -> Unmanaged<AnyObject>?
let objcMsgSendObj = unsafeBitCast(rawMsgSend, to: MsgSendObj.self)
typealias MsgSendPointBool = @convention(c) (AnyObject, Selector, CGPoint, Bool) -> Void
typealias MsgSendInt = @convention(c) (AnyObject, Selector, Int) -> Void
typealias MsgSendDouble = @convention(c) (AnyObject, Selector, Double) -> Void
typealias MsgSendBool = @convention(c) (AnyObject, Selector, Bool) -> Void
typealias MsgSendObjBool = @convention(c) (AnyObject, Selector, AnyObject?, Bool) -> Void
typealias MsgSendVoid = @convention(c) (AnyObject, Selector) -> Void
typealias MsgSendRetObj = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?

// MARK: - Trace recording

final class TraceRecorder: NSObject, UIScrollViewDelegate {
    struct DelegateEvent { let t: Double; let name: String; let detail: String }
    var samples: [(t: Double, x: Double, y: Double)] = []
    var delegateEvents: [DelegateEvent] = []
    var willEnd: (t: Double, vx: Double, vy: Double, targetX: Double, targetY: Double)?
    weak var scrollView: UIScrollView?
    var displayLink: CADisplayLink?
    var recording = false

    func attach(_ sv: UIScrollView) {
        scrollView = sv
        sv.delegate = self
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func reset() {
        samples.removeAll()
        delegateEvents.removeAll()
        willEnd = nil
    }

    @objc private func step() {
        guard recording, let sv = scrollView else { return }
        let t = CACurrentMediaTime()
        samples.append((t, Double(sv.contentOffset.x), Double(sv.contentOffset.y)))
    }

    private func mark(_ name: String, _ detail: String = "") {
        guard recording else { return }
        delegateEvents.append(.init(t: CACurrentMediaTime(), name: name, detail: detail))
    }

    func scrollViewWillBeginDragging(_ s: UIScrollView) { mark("willBeginDragging", "off=\(s.contentOffset)") }
    func scrollViewDidEndDragging(_ s: UIScrollView, willDecelerate d: Bool) {
        mark("didEndDragging", "decelerate=\(d) off=\(s.contentOffset)")
    }
    func scrollViewWillBeginDecelerating(_ s: UIScrollView) { mark("willBeginDecelerating", "off=\(s.contentOffset)") }
    func scrollViewDidEndDecelerating(_ s: UIScrollView) { mark("didEndDecelerating", "off=\(s.contentOffset)") }
    func scrollViewDidScroll(_ s: UIScrollView) {
        // Sub-frame samples: record delegate-time offsets too.
        guard recording else { return }
        samples.append((CACurrentMediaTime(), Double(s.contentOffset.x), Double(s.contentOffset.y)))
    }
    func scrollViewWillEndDragging(_ s: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let tgt = targetContentOffset.pointee
        willEnd = (CACurrentMediaTime(), Double(velocity.x), Double(velocity.y),
                   Double(tgt.x), Double(tgt.y))
        mark("willEndDragging", "v=\(velocity) target=\(tgt)")
    }
}

// MARK: - Synthetic UITouch delivery (KIF-style, private UIKit API)
// Builds a UITouch with private setters, adds it to the shared
// UITouchesEvent, and hands it to UIApplication.sendEvent — the same
// technique the KIF test framework uses. Everything stays in-process.
// Verified present on iOS 26.1 (simulator + Catalyst): setPhase:,
// setTimestamp:, setView:, setWindow:, _setLocationInWindow:resetPrevious:,
// setTapCount:, _setIsFirstTouchForView:, _setSenderID:, and
// UIApplication._touchesEvent / UITouchesEvent._clearTouches /
// _addTouch:forDelayedDelivery: / _setTimestamp:.

final class TouchSynth {
    let window: UIWindow
    var touch: NSObject?
    var ok = false

    init(window: UIWindow) {
        self.window = window
        touch = (NSClassFromString("UITouch") as? NSObject.Type)?.init()
    }

    func probeSelectors() {
        guard let t = touch else { probeLog("UITouch alloc failed"); return }
        let touchSelectors = [
            "setPhase:", "setTimestamp:", "setView:", "setWindow:",
            "_setLocationInWindow:resetPrevious:", "setTapCount:",
            "_setIsFirstTouchForView:", "_setSenderID:",
        ]
        probeLog("touch selector availability:")
        for s in touchSelectors {
            probeLog("  UITouch \(s): \(t.responds(to: NSSelectorFromString(s)))")
        }
        let app = UIApplication.shared
        probeLog("  UIApplication _touchesEvent: \(app.responds(to: NSSelectorFromString("_touchesEvent")))")
        if let ev = touchesEvent() {
            probeLog("  touchesEvent class: \(NSStringFromClass(type(of: ev)))")
            for s in ["_clearTouches", "_addTouch:forDelayedDelivery:", "_setTimestamp:"] {
                probeLog("  event \(s): \(ev.responds(to: NSSelectorFromString(s)))")
            }
        } else {
            probeLog("  _touchesEvent returned nil")
        }
    }

    func touchesEvent() -> NSObject? {
        let app = UIApplication.shared
        let sel = NSSelectorFromString("_touchesEvent")
        guard app.responds(to: sel) else { return nil }
        let f = unsafeBitCast(rawMsgSend, to: MsgSendRetObj.self)
        return f(app, sel)?.takeUnretainedValue() as? NSObject
    }

    /// Send one touch phase at a window point with an explicit timestamp.
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
            if t.responds(to: NSSelectorFromString("_setSenderID:")) {
                let f = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, UInt64) -> Void).self)
                f(t, NSSelectorFromString("_setSenderID:"), 0x0ACE_FADE_0000_0002)
            }
        }
        setPointBool(t, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, first)
        setInt(t, NSSelectorFromString("setPhase:"), phaseValue(phase))
        setDouble(t, NSSelectorFromString("setTimestamp:"), timestamp)

        guard let ev = touchesEvent() else { return }
        call(ev, NSSelectorFromString("_clearTouches"))
        if ev.responds(to: NSSelectorFromString("_setTimestamp:")) {
            setDouble(ev, NSSelectorFromString("_setTimestamp:"), timestamp)
        }
        setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t, false)
        UIApplication.shared.sendEvent(ev as! UIEvent)
        ok = true
    }

    private func phaseValue(_ p: UITouch.Phase) -> Int {
        switch p {
        case .began: return 0
        case .moved: return 1
        case .stationary: return 2
        case .ended: return 3
        case .cancelled: return 4
        default: return 0
        }
    }
}

// MARK: - Touch experiment driver

/// One scripted touch gesture against the probe scroll view: a drag along
/// evenly-timed points (ideal-grid timestamps — UIKit's velocity estimate
/// sees exactly the scripted velocity, never scheduler jitter), an optional
/// stationary hold before lift-off (kills release velocity), then a
/// settle-wait and a golden-trace JSON dump.
struct TouchExperimentSpec {
    let name: String
    let kind: String
    let startY: Double
    /// Finger path in window coords; [0] = touch-down.
    let points: [CGPoint]
    let interval: Double
    /// Seconds to hold the finger still before lifting (0 = flick release).
    let holdBeforeLift: Double
}

final class TouchExperimentDriver {
    let scrollView: UIScrollView
    let recorder: TraceRecorder
    let synth: TouchSynth
    let outdir: String
    let source: String
    var inputLog: [[String: Any]] = []
    private var gestureTimer: DispatchSourceTimer?

    init(scrollView: UIScrollView, recorder: TraceRecorder, synth: TouchSynth,
         outdir: String, source: String) {
        self.scrollView = scrollView
        self.recorder = recorder
        self.synth = synth
        self.outdir = outdir
        self.source = source
    }

    func run(specs: [TouchExperimentSpec], completion: @escaping () -> Void) {
        var idx = 0
        func next() {
            guard idx < specs.count else { completion(); return }
            let spec = specs[idx]
            idx += 1
            runOne(spec) { next() }
        }
        next()
    }

    private func schedule(_ delay: Double, _ body: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: body)
    }

    private func runOne(_ spec: TouchExperimentSpec, completion: @escaping () -> Void) {
        probeLog("== \(spec.name) (\(spec.kind)) ==")
        scrollView.setContentOffset(CGPoint(x: 0, y: spec.startY), animated: false)
        schedule(0.3) {
            self.recorder.reset()
            self.inputLog.removeAll()
            self.runGesture(spec) {
                self.waitForSettle(since: CACurrentMediaTime()) {
                    self.writeTrace(spec: spec)
                    completion()
                }
            }
        }
    }

    private func runGesture(_ spec: TouchExperimentSpec, completion: @escaping () -> Void) {
        let points = spec.points
        let interval = spec.interval
        let holdTicks = Int((spec.holdBeforeLift / interval).rounded())
        let n = points.count
        let total = n + holdTicks + 1 // began+moves, hold, ended
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

    private func writeTrace(spec: TouchExperimentSpec) {
        var dict: [String: Any] = [
            "name": spec.name,
            "kind": spec.kind,
            "source": source,
            "input_type": "touch",
            "interval": spec.interval,
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
}

// MARK: - Standard touch experiment set

/// The measurement suite, defined for a given viewport. Used by simprobe
/// (iOS Simulator, authoritative) and reusable on Catalyst for comparison.
func standardTouchExperiments(viewport: CGSize, contentHeight: Double) -> [TouchExperimentSpec] {
    let cx = viewport.width / 2
    let maxY = contentHeight - Double(viewport.height)
    let bottom = Double(viewport.height) - 60

    /// Straight vertical drag: touch-down at y0, `count` moves of `dy` each.
    func drag(from y0: Double, dy: Double, count: Int) -> [CGPoint] {
        var pts = [CGPoint(x: cx, y: y0)]
        var y = y0
        for _ in 0..<count { y += dy; pts.append(CGPoint(x: cx, y: y)) }
        return pts
    }

    return [
        // Slow drag, finger held still before lift: pure 1:1 tracking.
        .init(name: "touch_calib", kind: "calibration", startY: 5000,
              points: drag(from: bottom, dy: -3, count: 60), interval: 0.016,
              holdBeforeLift: 0.3),
        // Free deceleration at several release velocities (mid-content).
        // v = dy/interval: 750, 1500, 3000, 4875 pt/s.
        .init(name: "decel_v750", kind: "deceleration", startY: 5000,
              points: drag(from: bottom, dy: -6, count: 14), interval: 0.008,
              holdBeforeLift: 0),
        .init(name: "decel_v1500", kind: "deceleration", startY: 5000,
              points: drag(from: bottom, dy: -12, count: 14), interval: 0.008,
              holdBeforeLift: 0),
        .init(name: "decel_v3000", kind: "deceleration", startY: 5000,
              points: drag(from: bottom, dy: -24, count: 14), interval: 0.008,
              holdBeforeLift: 0),
        .init(name: "decel_v4875", kind: "deceleration", startY: 5000,
              points: drag(from: bottom, dy: -39, count: 14), interval: 0.008,
              holdBeforeLift: 0),
        // Slow drag far past the top edge, hold, lift: rubber-band curve
        // (finger positions vs banded offset) + zero-velocity bounce back.
        .init(name: "rubberband_top", kind: "rubber_band", startY: 0,
              points: drag(from: 120, dy: 5, count: 120), interval: 0.008,
              holdBeforeLift: 0.3),
        .init(name: "rubberband_bottom", kind: "rubber_band", startY: maxY,
              points: drag(from: bottom, dy: -5, count: 120), interval: 0.008,
              holdBeforeLift: 0.3),
        // Fast overscroll released while still moving: bounce spring
        // carrying the release velocity.
        .init(name: "bounce_release_vel", kind: "bounce_release", startY: 0,
              points: drag(from: 120, dy: 14, count: 12), interval: 0.008,
              holdBeforeLift: 0),
        // Deceleration INTO the bottom edge: impact bounce with carried
        // velocity.
        .init(name: "edge_impact", kind: "edge_impact", startY: maxY - 350,
              points: drag(from: bottom, dy: -25, count: 12), interval: 0.008,
              holdBeforeLift: 0),
    ]
}
