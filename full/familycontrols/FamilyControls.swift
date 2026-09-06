@_exported import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// Linux starting point for Apple's public `FamilyControls` module.
///
/// Isolated host compilation has Foundation only. SwiftUI / Combine /
/// ManagedSettings names use the lookalikes in `FamilyControlsLookalikes.swift`
/// until those modules are on the link line. Linux has no Screen Time daemon,
/// Family Sharing, or FamilyControls entitlement: authorization never
/// succeeds, pickers never present Apple UI, and tokens never resolve to
/// applications, categories, or web domains.
///
/// Darwin types: https://developer.apple.com/documentation/familycontrols

/// Linux host-test control. Hidden from ordinary `import FamilyControls`
/// clients and not part of Apple's public FamilyControls surface.
@_spi(OpenUIKitHost)
public enum FamilyControlsHostControl {
    /// Same fail-closed error the public request/revoke APIs surface.
    public static var linuxAuthorizationError: FamilyControlsError {
        .unavailable
    }

    /// Synchronous twin of `AuthorizationCenter.requestAuthorization(for:)`.
    /// The async method never suspends; it always throws this error.
    public static func requestAuthorizationSync(
        _ center: AuthorizationCenter,
        for member: FamilyControlsMember
    ) throws {
        try center.linuxRequestAuthorization(for: member)
    }

    public static func selectionBindingBox(
        _ selection: FamilyActivitySelection
    ) -> FamilyActivitySelectionBox {
        FamilyActivitySelectionBox(selection)
    }

    public static func binding(
        to box: FamilyActivitySelectionBox
    ) -> Binding<FamilyActivitySelection> {
        Binding(get: { box.value }, set: { box.value = $0 })
    }

    public static func boolBinding(to box: BoolBox) -> Binding<Bool> {
        Binding(get: { box.value }, set: { box.value = $0 })
    }
}

/// Process-local box for host tests that need a `Binding`.
public final class FamilyActivitySelectionBox: @unchecked Sendable {
    public var value: FamilyActivitySelection

    public init(_ value: FamilyActivitySelection) {
        self.value = value
    }
}

/// Process-local box for host tests that need a `Binding<Bool>`.
public final class BoolBox: @unchecked Sendable {
    public var value: Bool

    public init(_ value: Bool) {
        self.value = value
    }
}
