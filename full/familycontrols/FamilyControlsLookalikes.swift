@_exported import Foundation

/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the lookalike blocks below are inactive.
enum _FamilyControlsHostLookalikesMarker {}

// Isolated-host stand-ins for SwiftUI, Combine, and ManagedSettings types
// named by the public FamilyControls surface. The sealed host gate compiles
// this module alone. When a real module is on the link line, these blocks
// compile out. They are not a Linux SwiftUI, Combine, or ManagedSettings port.

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

public struct Label<Title: View, Icon: View>: View {
    public typealias Body = EmptyView

    public var body: EmptyView { EmptyView() }

    public init() {}

    public init(
        @ViewBuilder title: () -> Title,
        @ViewBuilder icon: () -> Icon
    ) {
        _ = title()
        _ = icon()
    }
}

#endif

#if !canImport(Combine)

public protocol ObservableObject: AnyObject {
    associatedtype ObjectWillChangePublisher
    var objectWillChange: ObjectWillChangePublisher { get }
}

public final class ObservableObjectPublisher {
    public init() {}
    public func send() {}
}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public var projectedValue: Publisher

    public struct Publisher {
        public init() {}
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.projectedValue = Publisher()
    }

    public init(initialValue: Value) {
        self.init(wrappedValue: initialValue)
    }
}

#endif

#if !canImport(ManagedSettings)

/// Opaque ManagedSettings application record. Linux never resolves bundle
/// identifiers or tokens to installed apps.
public struct Application: Hashable, Codable, Sendable {
    public init() {}
}

/// Opaque ManagedSettings activity category. Linux never resolves Screen
/// Time categories.
public struct ActivityCategory: Hashable, Codable, Sendable {
    public init() {}
}

/// Opaque ManagedSettings web domain. Linux never classifies browsing.
public struct WebDomain: Hashable, Codable, Sendable {
    public var domain: String?

    public init() {
        self.domain = nil
    }

    public init(domain: String?) {
        self.domain = domain
    }
}

/// Opaque token issued by Apple's FamilyActivityPicker. Linux tokens are
/// process-local identities for Set/Codable tests; they do not authorize
/// ManagedSettings shields.
public struct Token<T>: Hashable, Codable, Sendable {
    private let id: UUID

    public init() {
        self.id = UUID()
    }
}

public typealias ApplicationToken = Token<Application>
public typealias ActivityCategoryToken = Token<ActivityCategory>
public typealias WebDomainToken = Token<WebDomain>

#endif
