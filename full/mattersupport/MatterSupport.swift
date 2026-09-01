@_exported import Foundation

/// Linux-local unavailability error for MatterSupport operations that require
/// Apple commissioning UI, entitlements, or a Matter fabric. This type is not
/// part of the Xcode 26.1 public symbol graph; Apple's thrown error identity
/// for `perform()` and the extension callbacks is still an oracle question.
public struct MatterSupportError: Error, Hashable, Equatable, Sendable {
    public let operation: String

    public init(operation: String) {
        self.operation = operation
    }

    public var localizedDescription: String {
        "MatterSupport operation \(operation) is unavailable on this platform"
    }
}

func _matterSupportUnsupported(_ operation: String) -> MatterSupportError {
    MatterSupportError(operation: operation)
}
