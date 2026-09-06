import HealthKitUI
import Foundation
import HealthKit
import UIKit
@_spi(OpenUIKitHost) import HealthKitUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest HealthKit/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest HealthKit, Foundation, UIKit (and their dylibs).
// 2. Build HealthKitUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports HealthKitUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `HEALTHKITUI_DEPENDENCY_IDENTITY_OK` and that
//    `libHealthKitUI.dylib` was loaded.

private func assertNotHealthKitUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("HealthKitUI."))
}

func assertFoundationIdentity() {
    let frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    assertNotHealthKitUIType(frame)
    let ring = HKActivityRingView(frame: frame)
    precondition(ring.frame.width == 44)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
    _ = NSPredicate(value: true)
}

func assertUIKitIdentity() {
    let ring = HKActivityRingView(frame: .zero)
    precondition(ring is UIView)
    let presenter = UIViewController()
    assertNotHealthKitUIType(presenter)
    let store = HKHealthStore()
    store.authorizationViewControllerPresenter = presenter
    precondition(store.authorizationViewControllerPresenter === presenter)
    let options = UIScene.ConnectionOptions()
    precondition(!options.shouldHandleActiveWorkoutRecovery)
}

func assertHealthKitIdentity() {
    let summary = HKActivitySummary()
    assertNotHealthKitUIType(summary)
    let ring = HKActivityRingView()
    ring.setActivitySummary(summary, animated: false)
    precondition(ring.activitySummary === summary)
    precondition(!HealthKitUIHostControl.didRenderActivityRings(of: ring))
    let store = HKHealthStore()
    assertNotHealthKitUIType(store)
}

func healthKitUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    assertHealthKitIdentity()
    print("HEALTHKITUI_DEPENDENCY_IDENTITY_OK")
}
