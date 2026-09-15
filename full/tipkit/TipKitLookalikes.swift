@_exported import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the lookalike blocks below are inactive.
enum _TipKitHostLookalikesMarker {}

// Isolated-host stand-ins for SwiftUI types named by the public TipKit
// surface. The sealed host gate compiles this module alone. When a real
// SwiftUI module is on the link line, these blocks compile out. They are
// not a Linux SwiftUI port.

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

#endif

/// `TipView` renders as an inert `View` value on the isolated host. Linux
/// renders `EmptyView`; this pins the no-op identity behavior without
/// inventing layout.
extension TipView: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}
