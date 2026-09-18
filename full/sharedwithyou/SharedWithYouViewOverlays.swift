import Foundation

#if canImport(SwiftUI)
import SwiftUI
#else

// Isolated-host stand-ins for the SwiftUI types named by the
// `SWCollaborationView` detail-list overlay surface. The sealed host gate
// compiles this module alone. When real SwiftUI is on the link line, this
// block compiles out. It is not a Linux SwiftUI port and renders nothing.

/// Minimal stand-in for SwiftUI's `View`. Only the associated `Body`
/// requirement is modeled; Linux never renders a body.
public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

/// Minimal stand-in for SwiftUI's `ViewBuilder`. Single-content closures
/// are the only shape the detail-list overlays exercise.
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

/// Minimal stand-in for SwiftUI's `EmptyView`. Linux renders nothing.
public struct EmptyView: View {
    public init() {}
    public var body: EmptyView { self }
}

#endif

extension SWCollaborationView {
    /// Stores the detail-list content type name. Darwin would embed the
    /// SwiftUI content in the collaboration popover; Linux never presents
    /// UI, so this only records which content was supplied.
    public func setDetailViewListContent<ListContent: View>(
        _ detailViewListContent: ListContent
    ) {
        _ = detailViewListContent
        hostDetailListContentKind = String(describing: ListContent.self)
    }

    /// ViewBuilder variant of `setDetailViewListContent(_:)`. Same
    /// store-without-presenting behavior on Linux.
    public func setDetailViewListContent<ListContent: View>(
        @ViewBuilder _ detailViewListContent: () -> ListContent
    ) {
        _ = detailViewListContent
        hostDetailListContentKind = String(describing: ListContent.self)
    }
}
