import Foundation

/// Always-present marker so this compilation unit is never empty on Apple SDKs
/// where the lookalike blocks below are inactive.
enum _WidgetKitHostLookalikesMarker {}

// MARK: - Intents lookalike (isolated Linux host has no Intents module)

#if !canImport(Intents)
open class INIntent: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

// MARK: - AppIntents lookalike

#if !canImport(AppIntents)
public protocol AppIntent: Sendable {}

public protocol WidgetConfigurationIntent: AppIntent {}

public protocol ControlConfigurationIntent: WidgetConfigurationIntent {}
#endif

// MARK: - ActivityKit lookalike used only in WidgetKit signatures

#if !canImport(ActivityKit)
public protocol ActivityAttributes {
    associatedtype ContentState: Sendable
}
#endif

#if !canImport(AppIntents)
/// App Intents relevant-context token. The isolated host has no AppIntents
/// `RelevantContext` type; this is a module-local stand-in for signatures.
public struct RelevantContext: Hashable, Sendable {
    public init() {}
}
#endif

#if !canImport(SwiftUI)
/// SwiftUI `BackgroundTask` stand-in for `WidgetConfiguration.backgroundTask`.
public struct BackgroundTask<D: Sendable, R: Sendable>: Sendable {
    public init() {}
}
#endif

// MARK: - SwiftUI lookalikes

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

public struct LocalizedStringResource: ExpressibleByStringLiteral, Hashable, Sendable {
    public var key: String
    public init(_ key: String) { self.key = key }
    public init(stringLiteral value: String) { self.key = value }
}

public struct Text: View {
    public let content: String

    public init(_ content: String) { self.content = content }
    public init(_ key: LocalizedStringKey) { self.content = key.key }
    public init(_ resource: LocalizedStringResource) { self.content = resource.key }

    public var body: Never {
        fatalError("Text is a leaf view")
    }
}

public struct Color: View {
    public init() {}
    public init(_ name: String) { _ = name }

    public static let clear = Color()
    public static let blue = Color()
    public static let black = Color()
    public static let white = Color()
    public static let primary = Color()

    public var body: Never {
        fatalError("Color is a leaf view")
    }
}

public struct Image: View {
    public init() {}
    public init(systemName: String) { _ = systemName }

    public var body: Never {
        fatalError("Image is a leaf view")
    }
}

public struct EdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init() {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

public struct Alignment: Equatable, Sendable {
    public static let center = Alignment()
    public static let leading = Alignment()
    public static let trailing = Alignment()
    public init() {}
}

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public struct EnvironmentValues: @unchecked Sendable {
    private var storage: [ObjectIdentifier: Any] = [:]

    public init() {}

    public subscript<K: EnvironmentKey>(key: K.Type) -> K.Value {
        get {
            storage[ObjectIdentifier(K.self)] as? K.Value ?? K.defaultValue
        }
        set {
            storage[ObjectIdentifier(K.self)] = newValue
        }
    }
}

@propertyWrapper
public struct Binding<Value> {
    public var wrappedValue: Value
    public var projectedValue: Binding<Value> { self }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.wrappedValue = get()
        _ = set
    }
}

#endif
