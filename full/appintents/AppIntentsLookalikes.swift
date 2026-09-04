import Foundation

/// Marker so this compilation unit is never empty on Apple SDKs where the
/// lookalike blocks below are inactive.
enum _AppIntentsLookalikesMarker {}

// Foundation LocalizedStringResource is missing from swift-corelibs on Linux.
#if !canImport(Darwin)
public struct LocalizedStringResource: Hashable, Sendable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public var key: String

    public init(_ string: String) { key = string }
    public init(stringLiteral value: String) { key = value }
    public var description: String { key }
}

public protocol CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource { get }
}

open class NSUserActivity: NSObject, @unchecked Sendable {
    public let activityType: String
    public var title: String?
    public var userInfo: [AnyHashable: Any]?
    public var suggestedInvocationPhrase: String?

    public init(activityType: String) {
        self.activityType = activityType
        super.init()
    }
}
#else
public protocol CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource { get }
}
#endif

// MARK: - SwiftUI lookalikes (isolated host has no SwiftUI module)

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

public struct Text: View {
    public let content: String
    public init(_ content: String) { self.content = content }
    public init(_ resource: LocalizedStringResource) { self.content = resource.key }
    public var body: Never { fatalError("Text is a leaf view") }
}

public struct Color: View {
    public init() {}
    public static let clear = Color()
    public static let primary = Color()
    public var body: Never { fatalError("Color is a leaf view") }
}

public struct Image: View {
    public init(systemName: String) { _ = systemName }
    public var body: Never { fatalError("Image is a leaf view") }
}

@propertyWrapper
public struct Binding<Value>: @unchecked Sendable {
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.wrappedValue = get()
        _ = set
    }
}

public struct Button<Label>: View {
    public init(action: @escaping () -> Void, label: () -> Label) {
        _ = action
        _ = label()
    }
    public var body: Never { fatalError("Button is a leaf view") }
}

public struct Toggle<Label>: View {
    public init(isOn: Binding<Bool>, label: () -> Label) {
        _ = isOn
        _ = label()
    }
    public var body: Never { fatalError("Toggle is a leaf view") }
}

public struct ModifiedContent<Content, Modifier>: View {
    public var body: Never { fatalError("ModifiedContent is a leaf view") }
}
#endif

// MARK: - UIKit lookalikes

#if !canImport(UIKit)
public struct CGSize: Hashable, Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    public static let zero = CGSize(width: 0, height: 0)
}

public struct Selector: Hashable, Sendable {
    public init() {}
}

open class UIColor: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class UIImage: NSObject, @unchecked Sendable {
    public class SymbolConfiguration: NSObject, @unchecked Sendable {
        public override init() { super.init() }
    }
    public override init() { super.init() }
}

open class UIView: NSObject, @unchecked Sendable {
    open var intrinsicContentSize: CGSize { .zero }
    open func sizeThatFits(_ size: CGSize) -> CGSize { size }
    open func didMoveToWindow() {}
    public override init() { super.init() }
}

open class UIControl: UIView, @unchecked Sendable {
    public struct Event: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let touchUpInside = Event(rawValue: 1 << 0)
    }
    open func addTarget(_ target: Any?, action: Selector, for controlEvents: Event) {
        _ = target
        _ = action
        _ = controlEvents
    }
}

open class UIButton: UIControl, @unchecked Sendable {}

open class UIScene: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public class ConnectionOptions: NSObject, @unchecked Sendable {
        public override init() { super.init() }
    }
}

public protocol UISceneDelegate: AnyObject {}
#endif

// MARK: - CoreSpotlight lookalikes

#if !canImport(CoreSpotlight)
open class CSSearchableItemAttributeSet: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class CSCustomAttributeKey: NSObject, @unchecked Sendable {
    public let keyName: String
    public init(keyName: String) {
        self.keyName = keyName
        super.init()
    }
}

open class CSSearchableItem: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class CSSearchableIndex: NSObject, @unchecked Sendable {
    public static var `default`: CSSearchableIndex { CSSearchableIndex() }
    public override init() { super.init() }
}
#endif

// MARK: - CoreLocation lookalikes

#if !canImport(CoreLocation)
open class CLPlacemark: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}
#endif

// MARK: - ExtensionKit lookalike used only in AppIntentsExtension

#if !canImport(ExtensionFoundation) && !canImport(ExtensionKit)
public protocol AppExtension {}
#endif
