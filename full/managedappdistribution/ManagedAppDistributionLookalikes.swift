import Foundation

// Module-local stand-ins for types owned by undeclared modules (SwiftUI)
// and for Foundation.LocalizedStringResource, which the isolated Linux
// toolchain Foundation does not vend. Real SwiftUI / Darwin Foundation
// are imported by the later EC2 identity probe, not by this host dylib.

#if os(Linux)
/// Linux toolchain Foundation does not vend `LocalizedStringResource`.
/// Guest Darwin Foundation owns the real type; this stand-in exists only
/// so `ManagedAppDistributionError.localizedStringResource` can compile.
public struct LocalizedStringResource: ExpressibleByStringLiteral, Hashable, Sendable {
    public var key: String

    public init(_ key: String) {
        self.key = key
    }

    public init(stringLiteral value: String) {
        self.key = value
    }
}
#endif

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
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
    public var body: Never { self }
}

public struct Text: View {
    public let storage: String

    public init(_ string: String) {
        storage = string
    }

    public init(_ key: LocalizedStringKey) {
        storage = key.rawValue
    }

    public init<S: StringProtocol>(_ string: S) {
        storage = String(string)
    }

    public var body: EmptyView { EmptyView() }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String

    public init(stringLiteral value: String) {
        rawValue = value
    }
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
        getter = get
        setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}
#endif
