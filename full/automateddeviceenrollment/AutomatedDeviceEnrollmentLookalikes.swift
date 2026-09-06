/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the SwiftUI lookalike block below is inactive.
enum _AutomatedDeviceEnrollmentHostLookalikesMarker {}

// Isolated-host stand-ins for SwiftUI types named by the public
// AutomatedDeviceEnrollment surface. The sealed host gate compiles this
// module with Foundation only. When a real `SwiftUI` module is on the
// link line, these blocks compile out. They are not a Linux SwiftUI port
// and must not be treated as Apple `View` / `Binding` identity.

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

    public var body: Never {
        preconditionFailure("EmptyView has no body")
    }
}

extension Never: View {
    public var body: Never {
        preconditionFailure("Never is a leaf View")
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
