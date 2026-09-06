@_exported import Foundation

#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Linux starting point for Apple's public `ManagedSettingsUI` module.
///
/// Isolated host compilation has Foundation only. `ManagedSettings` and
/// `UIKit` types used by the public surface live in
/// `ManagedSettingsUILookalikes.swift` until those modules are on the link
/// line. Linux has no Family Controls shield-configuration extension host,
/// Screen Time daemon, or shield UI: those paths stay fail-closed.
///
/// Darwin types: https://developer.apple.com/documentation/managedsettingsui

/// Linux host-test control. Hidden from ordinary `import ManagedSettingsUI`
/// clients and not part of Apple's public ManagedSettingsUI surface.
@_spi(OpenUIKitHost)
public enum ManagedSettingsUIHostControl {
    /// Last `configuration(shielding:)` / `configuration(shielding:in:)`
    /// request recorded by a `ShieldConfigurationDataSource` in this process.
    public static func lastShieldingRequest() -> ManagedSettingsUIShieldingRequest? {
        ManagedSettingsUIHostRegistry.shared.lastRequest
    }

    /// Linux never draws or presents a Family Controls shield.
    public static func didPresentShield() -> Bool {
        ManagedSettingsUIHostRegistry.shared.didPresentShield
    }

    /// True when every stored field of `configuration` is `nil`, matching
    /// the documented system-default appearance.
    public static func isSystemDefaultAppearance(_ configuration: ShieldConfiguration) -> Bool {
        configuration.backgroundBlurStyle == nil
            && configuration.backgroundColor == nil
            && configuration.icon == nil
            && configuration.title == nil
            && configuration.subtitle == nil
            && configuration.primaryButtonLabel == nil
            && configuration.primaryButtonBackgroundColor == nil
            && configuration.secondaryButtonLabel == nil
    }

    /// Attempts to present a shield. Linux has no extension host and always
    /// throws `ManagedSettingsUIUnavailable.linuxHost`.
    public static func presentShield(_ configuration: ShieldConfiguration) throws {
        _ = configuration
        throw ManagedSettingsUIUnavailable.linuxHost(operation: "presentShield")
    }

    public static func reset() {
        ManagedSettingsUIHostRegistry.shared.reset()
    }
}

/// A recorded `ShieldConfigurationDataSource` request. Linux records the
/// identities it was asked to configure; it never presents a shield.
@_spi(OpenUIKitHost)
public enum ManagedSettingsUIShieldingRequest: Equatable, Sendable {
    case application(bundleIdentifier: String?)
    case applicationInCategory(bundleIdentifier: String?, categoryTokenPresent: Bool)
    case webDomain(domain: String?)
    case webDomainInCategory(domain: String?, categoryTokenPresent: Bool)
}

/// Fail-closed error for extension-host, daemon, entitlement, privacy, or
/// Apple-service paths. Linux never invents a successful shield presentation.
public enum ManagedSettingsUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

final class ManagedSettingsUIHostRegistry: @unchecked Sendable {
    static let shared = ManagedSettingsUIHostRegistry()

    private let lock = NSLock()
    private var storedRequest: ManagedSettingsUIShieldingRequest?
    private var storedDidPresent = false

    var lastRequest: ManagedSettingsUIShieldingRequest? {
        lock.lock()
        defer { lock.unlock() }
        return storedRequest
    }

    var didPresentShield: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storedDidPresent
    }

    func record(_ request: ManagedSettingsUIShieldingRequest) {
        lock.lock()
        storedRequest = request
        storedDidPresent = false
        lock.unlock()
    }

    func reset() {
        lock.lock()
        storedRequest = nil
        storedDidPresent = false
        lock.unlock()
    }
}
