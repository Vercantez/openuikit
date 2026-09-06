@_exported import Foundation

#if canImport(HealthKit)
@_exported import HealthKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Linux starting point for Apple's public `HealthKitUI` module.
///
/// Isolated host compilation has Foundation only. HealthKit / UIKit /
/// SwiftUI types used by the public surface live in
/// `HealthKitUILookalikes.swift` until those modules are on the link line.
/// Linux has no Health authorization sheet, activity-ring renderer, or
/// workout-session recovery daemon: those paths stay fail-closed.
///
/// Darwin types: https://developer.apple.com/documentation/healthkitui

/// Linux host-test control. Hidden from ordinary `import HealthKitUI`
/// clients and not part of Apple's public HealthKitUI surface.
@_spi(OpenUIKitHost)
public enum HealthKitUIHostControl {
    /// Last `animated` flag passed to `HKActivityRingView.setActivitySummary`.
    public static func lastAnimatedRequest(of view: HKActivityRingView) -> Bool {
        view.linuxLastAnimatedRequest
    }

    /// Linux never draws Move/Exercise/Stand rings.
    public static func didRenderActivityRings(of view: HKActivityRingView) -> Bool {
        view.linuxDidRenderActivityRings
    }

    /// Snapshots of `healthDataAccessRequest` modifiers applied since the last
    /// reset. Completions are retained and not invoked until
    /// `failClosedPendingAccessRequests()`.
    public static func pendingAccessRequests() -> [HealthKitUIAccessRequestRecord] {
        HealthKitUIAccessRequestRegistry.shared.records
    }

    /// Invokes every retained access-request completion with
    /// `HealthKitUIUnavailable.linuxHost` and clears the queue. Darwin calls
    /// the completion asynchronously after the authorization sheet; Linux
    /// has no sheet and never reports `.success`.
    @discardableResult
    public static func failClosedPendingAccessRequests() -> Int {
        HealthKitUIAccessRequestRegistry.shared.failClosed()
    }

    public static func resetAccessRequests() {
        HealthKitUIAccessRequestRegistry.shared.reset()
    }
}

/// Fail-closed error for hardware, daemon, entitlement, privacy-sheet, or
/// Apple-service paths. Linux never invents a successful Health authorization
/// or workout recovery.
public enum HealthKitUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

/// Project version number. The Apple dylib's numeric value is unobserved on
/// this host (see `oracle-questions.tsv`).
public let HealthKitUIVersionNumber: Double = 0

/// Project version string. The Apple dylib's C string is unobserved on this
/// host (see `oracle-questions.tsv`).
public let HealthKitUIVersionString: String = ""
