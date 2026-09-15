@_exported import Foundation

/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the lookalike block below is inactive.
enum _SpriteKitHostLookalikesMarker {}

// Isolated-host stand-ins for SwiftUI types named by the public SpriteKit
// surface (`SpriteView` conforms to `View`). The sealed host gate compiles
// this module alone. When the real SwiftUI module is on the link line,
// this block compiles out. It is not a Linux SwiftUI port.

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
