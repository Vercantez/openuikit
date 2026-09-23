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

// UIKit's NSString drawing addition. On the macOS triple AppKit supplies it;
// on the iOS triple with Apple's UIKit removed only the port can
// (NetNewsWire RSCore UIFont+RSCore.swift:38, measured by netnewswire-launch).
@MainActor func stringDrawingCompiles() -> Bool {
    let r = "probe".boundingRect(with: CGSize(width: 200, height: 100), options: [.usesLineFragmentOrigin],
                                 attributes: [.font: UIFont.systemFont(ofSize: 17)], context: nil)
    return r.width > 0
}

// Apple's UIKit headers import UserNotifications (UNNotificationResponse.h)
// and export it, so a file importing only UIKit names UN* types
// (typecheck against iPhoneSimulator26.1: NetNewsWire AppDelegate.swift:24
// `UNUserNotificationCenterDelegate`, :93 `requestAuthorization`,
// `UIBackgroundFetchResult`). The port's UIKit must re-export it on iOS too.
func userNotificationsVisibleThroughUIKit() -> String {
    let options: UNAuthorizationOptions = [.badge, .sound, .alert]
    let presentation: UNNotificationPresentationOptions = [.list, .banner]
    return "\(String(reflecting: UNUserNotificationCenter.self)) \(options.rawValue) \(presentation.rawValue)"
}

// Apple's UIKit exports CoreText too (NSAdaptiveImageGlyph.h imports
// CTRunDelegate.h): typecheck against iPhoneSimulator26.1 with only UIKit
// imported accepts this (NetNewsWire NSAttributedString+Extensions.swift:358).
func coreTextVisibleThroughUIKit() -> [Int] {
    [kVerticalPositionType, kSuperiorsSelector, kInferiorsSelector]
}

@MainActor func runProbe() {
    _ = stringDrawingCompiles()
    _ = userNotificationsVisibleThroughUIKit()
    _ = coreTextVisibleThroughUIKit()
    print("# iostarget-probe os=iOS environment=\(environment) UIView=\(String(reflecting: UIView.self)) runtime-name=\(NSStringFromClass(UIView.self)) textstorage=\(NSStringFromClass(NSTextStorage.self)) font-key=\(NSAttributedString.Key.font.rawValue)")
    _ = ProbeViewController()
    print("## superclasses")
    for line in OUKSuperclassFacts() { print(line) }
    print("## trace")
    for line in OUKRunSubclassScenarios() { print(line) }
    print("IOS_TARGET_PROBE_OK")
}

MainActor.assumeIsolated { runProbe() }
