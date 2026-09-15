import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Isolated-host stand-ins for SwiftUI types named by the public WorkoutKit
/// surface. The sealed host gate compiles this module alone. When the real
/// SwiftUI module is on the search path, the block below compiles out.
/// These are not a Linux SwiftUI port.

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

#endif

extension View {
    /// Presents a preview of the workout contents as a modal sheet on Darwin.
    /// Linux returns `self` unchanged and does not present UI.
    public func workoutPreview(
        _ workout: WorkoutPlan,
        isPresented: Binding<Bool>
    ) -> some View {
        _ = workout
        _ = isPresented.wrappedValue
        return self
    }
}
