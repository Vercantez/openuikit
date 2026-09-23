// Small RxCocoa iOS rows — ONE scenario, two runtimes (see
// TextViewTextInputScenario.swift): UIApplication+Rx
// `isNetworkActivityIndicatorVisible` and UISegmentedControl+Rx
// `enabled(forSegmentAt:)` (`setEnabled(_:forSegmentAt:)` /
// `isEnabledForSegment(at:)`). Apple side: Tools/oracle2/textviewinputprobe.
#if OUK_ORACLE
import UIKit
#else
import Foundation
@testable import OpenUIKit
#endif

@MainActor
enum OUKRxRowsScenario {
    static func run(host: UIView, settle: () -> Void) -> [String] {
        var lines: [String] = []
        let app = UIApplication.shared
        func b(_ v: Bool) -> String { v ? "1" : "0" }

        lines.append("app.isNetworkActivityIndicatorVisible initial=\(b(app.isNetworkActivityIndicatorVisible))")
        app.isNetworkActivityIndicatorVisible = true
        lines.append("  after =true: \(b(app.isNetworkActivityIndicatorVisible))")
        settle()
        lines.append("  after =true + runloop: \(b(app.isNetworkActivityIndicatorVisible))")
        app.isNetworkActivityIndicatorVisible = true
        app.isNetworkActivityIndicatorVisible = false
        lines.append("  after =true,=false: \(b(app.isNetworkActivityIndicatorVisible))")

        let sc = UISegmentedControl(items: ["a", "b", "c"])
        host.addSubview(sc)
        func seg(_ label: String) {
            let states = (0..<sc.numberOfSegments).map { b(sc.isEnabledForSegment(at: $0)) }.joined()
            lines.append("segmented \(label): n=\(sc.numberOfSegments) enabled=\(states) sel=\(sc.selectedSegmentIndex) control.isEnabled=\(b(sc.isEnabled))")
        }
        seg("fresh")
        sc.setEnabled(false, forSegmentAt: 1)
        seg("setEnabled(false, 1)")
        sc.selectedSegmentIndex = 1
        seg("selectedSegmentIndex=1 (disabled segment)")
        sc.selectedSegmentIndex = 0
        sc.setEnabled(false, forSegmentAt: 0)
        seg("sel=0 then setEnabled(false, 0) (selected segment)")
        sc.setEnabled(true, forSegmentAt: 0)
        sc.insertSegment(withTitle: "z", at: 0, animated: false)
        seg("insert z at 0")
        sc.removeSegment(at: 0, animated: false)
        seg("remove at 0")
        sc.isEnabled = false
        seg("control.isEnabled=false")
        sc.isEnabled = true
        sc.insertSegment(withTitle: "d", at: 3, animated: false)
        sc.selectedSegmentIndex = 2
        sc.removeSegment(at: 0, animated: false)
        seg("n=4 sel=2, remove at 0")
        sc.removeSegment(at: 1, animated: false)
        seg("remove at 1 (the selected one)")
        sc.selectedSegmentIndex = 0
        sc.removeSegment(at: 1, animated: false)
        seg("sel=0, remove at 1 (after selection)")
        sc.isEnabled = true
        sc.setEnabled(false, forSegmentAt: 0)
        sc.removeAllSegments()
        sc.insertSegment(withTitle: "n", at: 0, animated: false)
        seg("removeAll, insert n")
        // Out-of-range indices raise NSRangeException on iOS; the probe
        // measures those in separate launches (main.swift `--crash=`).
        sc.removeFromSuperview()
        return lines
    }
}
