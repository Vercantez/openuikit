@_exported import Foundation

// Isolated-host stand-ins for HealthKit, UIKit, and SwiftUI types named by
// the public HealthKitUI surface. The sealed host gate compiles this module
// alone. When a real `HealthKit` / `UIKit` / `SwiftUI` module is on the link
// line, these blocks compile out. They are not a Linux HealthKit, UIKit,
// or SwiftUI port.

#if !canImport(HealthKit)

open class HKActivitySummary: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKActivitySummary()
    }
}

open class HKObjectType: NSObject, @unchecked Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKObjectType else { return false }
        return identifier == other.identifier && type(of: self) == type(of: other)
    }

    public override var hash: Int { identifier.hashValue }
}

open class HKSampleType: HKObjectType, @unchecked Sendable {}

open class HKHealthStore: NSObject, @unchecked Sendable {
    /// HealthKitUI category property. Darwin presents the authorization
    /// sheet from this controller. Linux stores the weak reference and
    /// never presents a sheet.
    public weak var authorizationViewControllerPresenter: UIViewController?

    public override init() {
        super.init()
    }
}

#endif

#if !canImport(UIKit)

open class UIView: NSObject {
    public var frame: CGRect

    public init(frame: CGRect = .zero) {
        self.frame = frame
        super.init()
    }
}

open class UIViewController: NSObject {
    public var title: String?
    public var view: UIView?

    public override init() {
        super.init()
    }
}

open class UIScene: NSObject {
    open class ConnectionOptions: NSObject {
        public override init() {
            super.init()
        }
    }
}

#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

#endif
