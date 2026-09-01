// UNIT FIXTURE ONLY. This file invents NSObject, NSObjectProtocol,
// NSExtensionContext, CGFloat, CGSize, and NSLock. It is a test-owned
// lookalike, not guest Foundation, and must never be compiled as
// -module-name Foundation for platform identity evidence.
//
// tests/agent/test_unit_fixture.sh may compile it only when
// NOTIFICATIONCENTER_UNIT_FIXTURE=1. tests/agent/test_platform_identities.sh
// must not consume this file.

#if NOTIFICATIONCENTER_UNIT_FIXTURE
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
#endif
