@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Linux starting point for Apple's public `CoreLocationUI` module.
///
/// Isolated host compilation has Foundation only. UIKit / SwiftUI / CoreLocation
/// APIs use the lookalikes in `CoreLocationUILookalikes.swift` until those
/// modules are on the link line. Linux has no location hardware, Core Location
/// daemon, or one-time authorization sheet: every path that would grant
/// location access or fabricate a coordinate stays fail-closed.
///
/// Darwin types: https://developer.apple.com/documentation/corelocationui

/// Linux host-test control. Hidden from ordinary `import CoreLocationUI`
/// clients and not part of Apple's public CoreLocationUI surface.
@_spi(OpenUIKitHost)
public enum CoreLocationUIHostControl {
    /// Attempts the Darwin one-time authorization path for `CLLocationButton`.
    /// Linux always fails closed: no daemon, no prompt, no `CLLocation`.
    @discardableResult
    public static func requestOneTimeAuthorization(
        _ button: CLLocationButton
    ) -> Result<Void, CoreLocationUIUnavailable> {
        button.linuxRecordAuthorizationAttempt()
    }

    /// Attempts the Darwin one-time authorization path for `LocationButton`.
    /// The stored `action` is not invoked: Apple's action runs after the
    /// system has determined a location, which Linux cannot do.
    @discardableResult
    public static func activate(
        _ button: LocationButton
    ) -> Result<Void, CoreLocationUIUnavailable> {
        button.linuxActivateFailClosed()
    }

    /// Invokes the stored `LocationButton` action without claiming a location
    /// result. Use this only to prove `init(_:action:)` retained the closure.
    public static func invokeStoredAction(_ button: LocationButton) {
        button.linuxInvokeStoredAction()
    }

    public static func title(of button: LocationButton) -> LocationButton.Title? {
        button.linuxTitle
    }

    public static func authorizationAttempts(of button: CLLocationButton) -> Int {
        button.linuxAuthorizationAttempts
    }

    public static func activationAttempts(of button: LocationButton) -> Int {
        button.linuxActivationAttempts
    }
}

/// Fail-closed error for hardware, daemon, entitlement, or Apple-service
/// paths. Linux never invents a successful one-time location grant.
public enum CoreLocationUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

/// Project version number. The Apple dylib's numeric value is unobserved on
/// this host (see `oracle-questions.tsv`).
public let CoreLocationUIVersionNumber: Double = 0

/// Project version string. The Apple dylib's C string is unobserved on this
/// host (see `oracle-questions.tsv`).
public let CoreLocationUIVersionString: String = ""
