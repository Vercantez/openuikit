import Foundation

/// Process-local dock accessory manager. Linux never enables system tracking
/// and never yields accessory state changes.
public class DockAccessoryManager: @unchecked Sendable {
    public static let shared = DockAccessoryManager()

    private init() {}

    public var isSystemTrackingEnabled: Bool { false }

    public var accessoryStateChanges: DockAccessory.StateChanges {
        get throws { throw dockKitUnsupported() }
    }

    public func setSystemTrackingEnabled(_ isEnabled: Bool) async throws {
        throw dockKitUnsupported()
    }
}
