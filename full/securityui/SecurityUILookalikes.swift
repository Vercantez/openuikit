@_exported import Foundation

// Isolated-host stand-ins for types owned by Security, UIKit, and SwiftUI.
// The sealed host gate compiles this module alone (Foundation only).
// When a real module is on the link line, these blocks compile out.
// They are not a Linux Security, UIKit, or SwiftUI port.

#if canImport(Security)
import Security
#endif

#if !canImport(Security)

/// Opaque certificate-trust handle. Darwin's type lives in Security
/// (`SecTrust` / `SecTrustRef`). Isolated Linux only needs identity so
/// `SFCertificatePresentation` can store a caller-owned trust; this type
/// does not evaluate certificates, build a chain, or talk to a trust store.
public final class SecTrust: Hashable, @unchecked Sendable {
    public init() {}

    public static func == (lhs: SecTrust, rhs: SecTrust) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

#endif

#if canImport(UIKit)
import UIKit
#endif

#if !canImport(UIKit)

open class UIViewController: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

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
        getter = get
        setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

#endif
