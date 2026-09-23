// iOS-target guest probe (docs/agent_reports/ios-target-route.md).
//
// Compiled by full/scripts/build_full.sh only for an iOS-simulator TARGET
// (LINK_PLATFORM=ios-simulator), linked like the other guest probes, and run
// under machorun. The same file, built with Xcode for
// arm64-apple-ios26.1-simulator against Apple's UIKit and run on the iOS 26.1
// simulator, is the oracle (full/iostarget/run_oracle.sh ->
// oracle-ios26.1.txt): every line after the header must match.
#if !os(iOS)
#error("IOSTargetGuestProbe must be compiled for an iOS triple")
#endif
#if canImport(AppKit)
#error("AppKit is importable: the macOS module graph leaked into an iOS build")
#endif

import UIKit

#if targetEnvironment(simulator)
let environment = "simulator"
#else
let environment = "device"
#endif

final class ProbeView: UIView {
    var layouts = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        layouts += 1
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 77, height: 33)
    }
}

func rect(_ r: CGRect) -> String {
    "{{\(fmt(r.origin.x)), \(fmt(r.origin.y))}, {\(fmt(r.size.width)), \(fmt(r.size.height))}}"
}
func fmt(_ v: CGFloat) -> String {
    v == v.rounded() ? String(Int(v)) : String(describing: Double(v))
}

@MainActor func runProbe() {
    // Header: differs by design between Apple's UIKit and the port.
    print("# iostarget-guest-probe os=iOS environment=\(environment) UIView=\(String(reflecting: UIView.self))")
    // Availability: the deployment floor is 26.0, so 26.0 folds to true at
    // compile time; 26.1 / 26.2 / 27.0 are runtime checks against the OS
    // version the process reports (iOS 26.1 on the oracle simulator).
    if #available(iOS 26.0, *) { print("available iOS 26.0: yes") } else { print("available iOS 26.0: no") }
    if #available(iOS 26.1, *) { print("available iOS 26.1: yes") } else { print("available iOS 26.1: no") }
    if #available(iOS 26.2, *) { print("available iOS 26.2: yes") } else { print("available iOS 26.2: no") }
    if #available(iOS 27.0, *) { print("available iOS 27.0: yes") } else { print("available iOS 27.0: no") }
    // A Swift subclass of UIView through the iOS triple.
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    let view = ProbeView(frame: CGRect(x: 1, y: 2, width: 30, height: 40))
    print("frame=\(rect(view.frame)) bounds=\(rect(view.bounds))")
    host.addSubview(view)
    view.layoutIfNeeded()
    print("after first layoutIfNeeded layouts=\(view.layouts)")
    view.layoutIfNeeded()
    print("after second layoutIfNeeded layouts=\(view.layouts)")
    view.setNeedsLayout()
    view.layoutIfNeeded()
    print("after setNeedsLayout+layoutIfNeeded layouts=\(view.layouts)")
    view.bounds = CGRect(x: 0, y: 0, width: 50, height: 60)
    view.layoutIfNeeded()
    print("after bounds change layouts=\(view.layouts)")
    view.sizeToFit()
    print("after sizeToFit frame=\(rect(view.frame))")
    print("superview is host: \(view.superview === host) subviews=\(host.subviews.count)")
    view.removeFromSuperview()
    print("after removal superview=\(view.superview == nil ? "nil" : "set")")
    print("IOS_TARGET_GUEST_PROBE_OK")
}

@main
struct IOSTargetGuestProbeMain {
    static func main() {
        MainActor.assumeIsolated { runProbe() }
    }
}
