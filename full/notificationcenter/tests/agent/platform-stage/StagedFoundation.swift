// Test-only staged Foundation overlay for the platform identity gate.
//
// Adds Foundation.NSExtensionContext so NotificationCenter and
// UserNotificationsUI can extend one canonical identity. Used only when
// compiling with -I pointing at this module; never shipped as a
// NotificationCenter nominal type.

open class NSObject {
    public init() {}
}

public protocol NSObjectProtocol: AnyObject {}

extension NSObject: NSObjectProtocol {}

open class NSExtensionContext: NSObject {
    public override init() {
        super.init()
    }
}

public typealias CGFloat = Double

public struct CGSize: Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    public static let zero = CGSize(width: 0, height: 0)
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

public final class NSLock: @unchecked Sendable {
    public init() {}
    public func lock() {}
    public func unlock() {}
}
