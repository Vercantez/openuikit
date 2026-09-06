@_exported import Foundation

/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the lookalike blocks below are inactive.
enum _AssignablesHostLookalikesMarker {}

// Isolated-host stand-ins for SwiftUI, PDFKit, and UIKit types named by the
// public Assignables surface. The sealed host gate compiles this module alone.
// When a real module is on the link line, these blocks compile out. They are
// not a Linux SwiftUI, PDFKit, or UIKit port.

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

#if !canImport(PDFKit)

/// Inert PDFKit stand-in. Linux never decodes or rasterizes assignment PDFs.
open class PDFDocument: NSObject {
    public override init() {
        super.init()
    }

    /// Always zero: this overlay does not invent PDF pages.
    open var pageCount: Int { 0 }

    open func dataRepresentation() -> Data? { nil }
}

#endif

#if !canImport(UIKit)

/// Inert UIKit image stand-in. Question thumbnails stay empty on Linux.
open class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

#endif
