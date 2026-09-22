// iOS-target probe driver. Prints the same transcript format as
// Tools/oracle2/objcsubclassprobe/main.m (the iOS 26.1 simulator oracle), so
// the two outputs diff line for line, preceded by the build-condition facts.
#if !os(iOS)
#error("IOSTargetProbe must be compiled for an iOS triple: os(iOS) is false")
#endif
#if canImport(AppKit)
#error("AppKit is importable: the macOS module graph leaked into an iOS build")
#endif

import UIKit
import IOSTargetProbeObjC

// iOS allows 0, 1 or 2 arguments; the macOS triple rejects this line with
// "@IBAction methods must have 1 argument" (Simplenote's 42 errors).
final class ProbeViewController: UIViewController {
    @IBAction func probeTapped() {}
}

#if targetEnvironment(simulator)
let environment = "simulator"
#else
let environment = "device"
#endif

@MainActor func runProbe() {
    print("# iostarget-probe os=iOS environment=\(environment) UIView=\(String(reflecting: UIView.self)) runtime-name=\(NSStringFromClass(UIView.self))")
    _ = ProbeViewController()
    print("## superclasses")
    for line in OUKSuperclassFacts() { print(line) }
    print("## trace")
    for line in OUKRunSubclassScenarios() { print(line) }
    print("IOS_TARGET_PROBE_OK")
}

MainActor.assumeIsolated { runProbe() }
