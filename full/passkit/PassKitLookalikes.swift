@_exported import Foundation

/// Module-local stand-ins for types owned by undeclared modules (UIKit,
/// CoreGraphics, Contacts, AddressBook, SwiftUI). Isolated-host sources
/// import Foundation only. Real modules are imported by
/// `tests/agent/PassKitDependencyIdentity.swift` for the later EC2 build.

enum _PassKitLookalikesMarker {}

#if !canImport(CoreGraphics)
public typealias CGFloat = Double

public struct CGPoint: Equatable, Hashable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public init(x: CGFloat = 0, y: CGFloat = 0) {
        self.x = x
        self.y = y
    }
    public static let zero = CGPoint()
}

public struct CGSize: Equatable, Hashable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    public init(width: CGFloat = 0, height: CGFloat = 0) {
        self.width = width
        self.height = height
    }
    public static let zero = CGSize()
}

public struct CGRect: Equatable, Hashable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public init(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
        origin = CGPoint(x: x, y: y)
        size = CGSize(width: width, height: height)
    }
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
    public static let zero = CGRect()
}

open class CGImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(UIKit) && !canImport(OpenUIKit)
open class UIView: NSObject, @unchecked Sendable {
    public var frame: CGRect
    public var bounds: CGRect
    public var isEnabled = true

    public init(frame: CGRect = .zero) {
        self.frame = frame
        bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }
}

open class UIControl: UIView, @unchecked Sendable {}

open class UIButton: UIControl, @unchecked Sendable {
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(frame: .zero)
        _ = coder
    }
}

open class UIViewController: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public init(nibName: String?, bundle: Bundle?) {
        _ = (nibName, bundle)
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        super.init()
    }
}

open class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIWindow: UIView, @unchecked Sendable {
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }
}
#endif

#if !canImport(Contacts)
open class CNContact: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class CNPostalAddress: NSObject, @unchecked Sendable {
    public var street: String = ""
    public var city: String = ""
    public var state: String = ""
    public var postalCode: String = ""
    public var country: String = ""
    public var isoCountryCode: String = ""
    public override init() {
        super.init()
    }
}

open class CNPhoneNumber: NSObject, @unchecked Sendable {
    public var stringValue: String
    public init(stringValue: String) {
        self.stringValue = stringValue
        super.init()
    }
}
#endif

#if !canImport(AddressBook)
open class ABRecord: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never {
        fatalError("Never has no View body")
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never {
        fatalError("EmptyView is a leaf")
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable {
    public var key: String
    public init(_ key: String) { self.key = key }
    public init(stringLiteral value: String) { self.key = value }
}

public struct Text: View {
    public let content: String
    public init(_ content: String) { self.content = content }
    public init(_ key: LocalizedStringKey) { self.content = key.key }
    public var body: Never { fatalError("Text is a leaf view") }
}
#endif
