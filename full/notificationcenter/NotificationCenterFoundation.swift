// Foundation.NSExtensionContext Today View additions.
//
// The nominal type is Foundation's. NotificationCenter only extends it so
// UserNotificationsUI can extend the same identity. Linux guest Foundation
// does not currently expose NSExtensionContext; this file's body compiles
// only when a real staged Foundation module has that type and the integration
// probe passes -D NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT.
// canImport(UIKit) alone is not enough: a real UIKit without this Foundation
// type must not fail the whole module.

#if canImport(UIKit) && NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT
import Foundation
import UIKit

extension NSExtensionContext {
    private static let stateLock = NSLock()
    private static var largestModes: [ObjectIdentifier: NCWidgetDisplayMode] = [:]
    private static var activeModes: [ObjectIdentifier: NCWidgetDisplayMode] = [:]
    private static var maximumSizes: [ObjectIdentifier: [NCWidgetDisplayMode: CGSize]] = [:]

    /// Widgets may advertise compact-only or compact+expanded. Default compact.
    public var widgetLargestAvailableDisplayMode: NCWidgetDisplayMode {
        get {
            Self.stateLock.lock()
            let value = Self.largestModes[ObjectIdentifier(self)] ?? .compact
            Self.stateLock.unlock()
            return value
        }
        set {
            Self.stateLock.lock()
            Self.largestModes[ObjectIdentifier(self)] = newValue
            Self.stateLock.unlock()
        }
    }

    /// Host-assigned active mode. Default compact; never invents expanded UI.
    public var widgetActiveDisplayMode: NCWidgetDisplayMode {
        Self.stateLock.lock()
        let value = Self.activeModes[ObjectIdentifier(self)] ?? .compact
        Self.stateLock.unlock()
        return value
    }

    /// Maximum size for a display mode. Default `CGSize.zero` until a host
    /// injects metrics. Does not invent Apple compact (110pt) sizes.
    public func widgetMaximumSize(for displayMode: NCWidgetDisplayMode) -> CGSize {
        Self.stateLock.lock()
        let value = Self.maximumSizes[ObjectIdentifier(self)]?[displayMode] ?? .zero
        Self.stateLock.unlock()
        return value
    }

    @_spi(OpenUIKitHost)
    public func setPortableActiveDisplayMode(_ mode: NCWidgetDisplayMode) {
        Self.stateLock.lock()
        Self.activeModes[ObjectIdentifier(self)] = mode
        Self.stateLock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func setPortableWidgetMaximumSize(
        _ size: CGSize,
        for displayMode: NCWidgetDisplayMode
    ) {
        Self.stateLock.lock()
        var table = Self.maximumSizes[ObjectIdentifier(self)] ?? [:]
        table[displayMode] = size
        Self.maximumSizes[ObjectIdentifier(self)] = table
        Self.stateLock.unlock()
    }
}

#endif
