// Driver: runs the Objective-C scenario, then the Swift scenario, and prints
// one line per check. Exit status 1 if any expectation fails.
import Foundation
import OUIProbeHeader
import OUIProbeImpl
import OUIProbeObjC

var failures = 0
func check(_ ok: Bool, _ line: String) {
    print((ok ? "PASS " : "FAIL ") + line)
    if !ok { failures += 1 }
}

@MainActor
func runSwiftScenario() {
    OUIProbeTrace.reset()

    // A. Swift allocates the ObjC subclass through the header's initializers.
    let objcChild = OUIProbeSubview(frame: CGRect(x: 1, y: 2, width: 3, height: 4), label: "fromSwift")
    check(objcChild.frame == CGRect(x: 1, y: 2, width: 3, height: 4),
          "swift alloc objc subclass: frame=\(objcChild.frame)")
    check(objcChild.label == "fromSwift", "swift alloc objc subclass: label=\(objcChild.label)")

    // B. Swift subclass of the @implementation class.
    let swiftChild = OUISwiftSubview(frame: CGRect(x: 5, y: 6, width: 7, height: 8))
    check(swiftChild.frame == CGRect(x: 5, y: 6, width: 7, height: 8),
          "swift subclass init(frame:): frame=\(swiftChild.frame)")

    // C. Tree with base root, ObjC child, Swift child; layout runs the
    //    override/super chain for each.
    let root = OUIProbeView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    root.addSubview(objcChild)
    root.addSubview(swiftChild)
    root.layoutIfNeeded()
    check(root.layoutCount == 1 && objcChild.layoutCount == 1 && swiftChild.layoutCount == 1,
          "swift layout counts: root=\(root.layoutCount) objc=\(objcChild.layoutCount) swift=\(swiftChild.layoutCount) (expect 1 1 1)")
    check(objcChild.objcLayouts == 1, "objc override ran from swift-driven layout: objcLayouts=\(objcChild.objcLayouts)")
    check(swiftChild.swiftSubviewLayouts == 1, "swift override ran: swiftSubviewLayouts=\(swiftChild.swiftSubviewLayouts)")
    check(OUIProbeTrace.lines == [
        "OUIProbeView.layoutSubviews(base)",
        "OUIProbeSubview.layoutSubviews(base)",
        "OUISwiftSubview.layoutSubviews(before super)",
        "OUISwiftSubview.layoutSubviews(base)",
        "OUISwiftSubview.layoutSubviews(after super)",
    ], "trace order: \(OUIProbeTrace.lines)")

    // D. Swift casts and dynamic type across the two universes.
    check(objcChild is OUIProbeView, "objc subclass instance is OUIProbeView")
    check((root.subviews.first as? OUIProbeSubview) === objcChild, "as? OUIProbeSubview cast from [OUIProbeView]")
    check(root.firstSubview(of: OUISwiftSubview.self) === swiftChild, "generic Swift-only extension method finds the Swift subclass")

    // E. Swift-only conveniences on the @implementation class.
    var completed: OUIProbeAnimation?
    root.animate(keyPath: "alpha", from: 1, to: 0) { completed = $0 }
    check(completed?.keyPath == "alpha" && root.animations.count == 1,
          "swift-only closure API + struct-array stored property: animations=\(root.animations.count)")
    root.tint = .color(red: 1, green: 0.5, blue: 0)
    check(root.tintDescription == "rgb(1.0,0.5,0.0)", "swift-only enum-with-payload stored property: \(root.tintDescription)")
    check(root.geometrySummary.size == CGSize(width: 100, height: 100), "swift-only tuple computed property: \(root.geometrySummary)")
    var closureFired = false
    swiftChild.onLayout = { _ in closureFired = true }
    swiftChild.setNeedsLayout()
    swiftChild.layoutIfNeeded()
    check(closureFired && swiftChild.lastLayoutSize == CGSize(width: 7, height: 8),
          "swift-only stored closure + optional CGSize: fired=\(closureFired) last=\(String(describing: swiftChild.lastLayoutSize))")

    // F. Hand a Swift-subclass instance to Objective-C, which sends
    //    -layoutSubviews and reads -frame through the runtime.
    let described = OUIProbeDescribeFromObjC(swiftChild)
    print("INFO " + described)
    check(described.contains("OUIProbeImpl.OUISwiftSubview") || described.contains("OUISwiftSubview"),
          "objc dispatches layoutSubviews on the Swift subclass (layoutCount now \(swiftChild.layoutCount))")
    check(swiftChild.swiftSubviewLayouts == 3, "swift override count after objc send: \(swiftChild.swiftSubviewLayouts) (expect 3)")

    // G. Class identity from both sides.
    check(NSClassFromString("OUIProbeView") == OUIProbeView.self, "NSClassFromString(\"OUIProbeView\") is the same class object")
    check(NSClassFromString("OUIProbeSubview") == OUIProbeSubview.self, "NSClassFromString(\"OUIProbeSubview\") is the same class object")
    print("INFO swift subclass runtime name: \(NSStringFromClass(OUISwiftSubview.self))")

    // H. Swift protocol conformance added by a plain extension, requirement
    //    satisfied by a header-declared method, dispatched dynamically.
    let host: OUIProbeLayoutHost = objcChild
    let before = objcChild.objcLayouts
    host.relayout()
    check(objcChild.objcLayouts == before + 1, "swift protocol conformance via extension dispatches to the objc override: \(objcChild.objcLayouts)")
}

if CommandLine.arguments.count > 1 {
    // Chain scenarios run one per process: a failure here is a crash.
    let which = CommandLine.arguments[1]
    print("INFO " + OUIProbeRunChainScenario(which))
    print("CHAIN \(which) SURVIVED")
    exit(0)
}
print("== Objective-C scenario ==")
for line in OUIProbeRunObjCScenario() { print("INFO " + line) }
print("== Swift scenario ==")
MainActor.assumeIsolated { runSwiftScenario() }
print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
exit(failures == 0 ? 0 : 1)
