@_exported import Foundation

// Isolated-host stand-ins for FinanceKit, SwiftUI, UIKit, and ExtensionKit
// types named by the public FinanceKitUI surface. The sealed host gate
// compiles this module alone. When a real module is on the link line,
// these blocks compile out. They are not a Linux FinanceKit, SwiftUI,
// UIKit, or ExtensionKit port.

#if !canImport(FinanceKit)

public struct Transaction: Equatable, Identifiable, Sendable {
    public typealias ID = UUID
    public let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

public final class FinanceStore: @unchecked Sendable {
    public enum SaveOrderResult: Hashable, Sendable, CaseIterable {
        case added
        case cancelled
        case newerExisting
    }
}

#endif

#if !canImport(UIKit)

open class UIViewController: NSObject {
    public var title: String?

    public override init() {
        super.init()
    }
}

#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
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
        fatalError("EmptyView is a leaf View")
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

#if !canImport(ExtensionFoundation)
public protocol AppExtensionConfiguration {}

public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}
#endif

#if !canImport(ExtensionKit)
public protocol AppExtensionScene {
    associatedtype Body: AppExtensionScene
    var body: Self.Body { get }
}

public struct AppExtensionSceneConfiguration: AppExtensionConfiguration, Sendable {
    public let hostSceneTypeName: String

    public init<S: AppExtensionScene>(_ scene: S) {
        self.hostSceneTypeName = String(reflecting: type(of: scene))
    }
}
#endif

#if !canImport(SwiftUI) && !canImport(ExtensionKit)
extension Never: View, AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View and AppExtensionScene")
    }
}
#elseif !canImport(SwiftUI)
extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View")
    }
}
#elseif !canImport(ExtensionKit)
extension Never: AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf AppExtensionScene")
    }
}
#endif
