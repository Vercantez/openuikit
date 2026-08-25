// Scroll-physics trace replay (M8). Owner: scroll module.
//
//   openrender scrolltrace <oracle-trace.json> <out.json>
//
// Replays a golden scroll trace's INPUT stream (the synthetic finger path
// recorded by the oracle probe — golden/scroll_traces/SCHEMA.md) through a
// headless OpenUIKit UIScrollView via the M7 touch-delivery API
// (UIWindow.sendTouch / tick with the trace's own timestamps), and samples
// contentOffset at the oracle's sample times. Tools/compare/compare_scroll.py
// diffs the result against the oracle's offsets.
//
// Determinism: all time comes from the trace file; no wall clock.

import Foundation
import OpenUIKit

private struct TraceInputEvent {
    let t: Double
    let x: Double
    let y: Double
    let phase: String
}

@MainActor
func runScrollTrace(traceFile: String, outFile: String) throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: traceFile))
    guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let viewport = dict["viewport"] as? [String: Double],
          let contentSize = dict["contentSize"] as? [String: Double],
          let startY = dict["startOffsetY"] as? Double,
          let inputRaw = dict["input"] as? [[String: Any]],
          let samplesRaw = dict["samples"] as? [[Double]] else {
        throw NSError(domain: "scrolltrace", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "malformed trace \(traceFile)"])
    }
    let name = dict["name"] as? String ?? "trace"

    let w = OpenUIKit.CGFloat(viewport["w"]!), h = OpenUIKit.CGFloat(viewport["h"]!)
    let window = UIWindow(frame: OpenUIKit.CGRect(x: 0, y: 0, width: w, height: h))
    let sv = UIScrollView(frame: OpenUIKit.CGRect(x: 0, y: 0, width: w, height: h))
    sv.contentSize = OpenUIKit.CGSize(width: OpenUIKit.CGFloat(contentSize["w"]!),
                                      height: OpenUIKit.CGFloat(contentSize["h"]!))
    window.addSubview(sv)
    window.layoutIfNeeded()
    sv.contentOffset = OpenUIKit.CGPoint(x: 0, y: OpenUIKit.CGFloat(startY))

    let inputs: [TraceInputEvent] = inputRaw.compactMap { e in
        guard let t = e["t"] as? Double, let x = e["x"] as? Double,
              let y = e["y"] as? Double, let phase = e["phase"] as? String else { return nil }
        return TraceInputEvent(t: t, x: x, y: y, phase: phase)
    }

    // Oracle sample times, deduped/sorted. The replay reads OUR offset at
    // exactly these times so the comparison is pointwise.
    var sampleTimes: [Double] = []
    for s in samplesRaw.sorted(by: { $0[0] < $1[0] }) where s.count >= 3 {
        if sampleTimes.last.map({ s[0] > $0 }) ?? true { sampleTimes.append(s[0]) }
    }

    // Merge input events and sample reads chronologically. Inputs win ties
    // (an oracle didScroll sample AT an input time reflects the applied drag).
    var out: [[Double]] = []
    var si = 0
    func sampleUpTo(_ t: Double) {
        while si < sampleTimes.count, sampleTimes[si] <= t {
            let ts = sampleTimes[si]
            OpenUIKitRuntime.animationTime = ts
            window.tick(timestamp: ts)
            out.append([ts, Double(sv.contentOffset.x), Double(sv.contentOffset.y)])
            si += 1
        }
    }
    for e in inputs {
        sampleUpTo(e.t - 1e-9)
        OpenUIKitRuntime.animationTime = e.t
        let phase: UITouch.Phase
        switch e.phase {
        case "began": phase = .began
        // A real held finger keeps emitting position updates; the oracle
        // logs them as "stationary". Deliver as moves at the same point so
        // the release-velocity window sees the hold (as UIKit's does).
        case "moved", "stationary": phase = .moved
        case "ended": phase = .ended
        default: phase = .cancelled
        }
        window.sendTouch(phase, at: OpenUIKit.CGPoint(x: OpenUIKit.CGFloat(e.x),
                                                      y: OpenUIKit.CGFloat(e.y)),
                         timestamp: e.t)
    }
    sampleUpTo(.infinity)

    let result: [String: Any] = [
        "name": name,
        "source": "openrender scrolltrace (OpenUIKit headless replay)",
        "samples": out,
        "finalOffsetY": Double(sv.contentOffset.y),
    ]
    let outData = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
    try outData.write(to: URL(fileURLWithPath: outFile))
    print("replayed \(name) (\(out.count) samples, final y=\(sv.contentOffset.y))")
}
