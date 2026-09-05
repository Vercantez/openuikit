import Foundation

#if !canImport(SwiftUI) || os(macOS)

// MARK: - Isolated-host SwiftUI lookalikes

public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Self.Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never { fatalError("Never View body") }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { fatalError("EmptyView") }
}

public struct TupleView<T>: View {
    public var value: T
    public init(_ value: T) { self.value = value }
    public var body: Never { fatalError("TupleView") }
}

public struct ModifiedContent<Content, Modifier>: View {
    public var content: Content
    public var modifier: Modifier
    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
    public var body: Never { fatalError("ModifiedContent") }
}

@resultBuilder
public struct ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<C: View>(_ content: C) -> C { content }
    public static func buildBlock<A: View, B: View>(_ a: A, _ b: B) -> TupleView<(A, B)> {
        TupleView((a, b))
    }
    public static func buildOptional<C: View>(_ component: C?) -> C? { component }
    public static func buildEither<T: View>(first: T) -> T { first }
    public static func buildEither<T: View>(second: T) -> T { second }
    public static func buildExpression<C: View>(_ expression: C) -> C { expression }
    public static func buildArray<C: View>(_ components: [C]) -> TupleView<[C]> {
        TupleView(components)
    }
}

@resultBuilder
public struct ToolbarContentBuilder {
    public static func buildBlock<C>(_ content: C) -> C { content }
}

public struct Alignment: Sendable, Equatable {
    public init() {}
    public static let center = Alignment()
    public static let leading = Alignment()
    public static let trailing = Alignment()
    public static let top = Alignment()
    public static let bottom = Alignment()
}

public struct ZStack<Content: View>: View {
    public var content: Content
    public init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        _ = alignment
        self.content = content()
    }
    public var body: Content { content }
}

@propertyWrapper
public struct Binding<Value> {
    private var getter: () -> Value
    private var setter: (Value) -> Void
    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
    public var projectedValue: Binding<Value> { self }
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }
    public init(wrappedValue: Value) {
        var storage = wrappedValue
        self.getter = { storage }
        self.setter = { storage = $0 }
    }
}

extension Optional: View where Wrapped: View {
    public var body: Never { fatalError("Optional View") }
}

#endif
