import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// `_WebKit_SwiftUI` overlay types for the isolated Linux host.
///
/// Apple ships these SwiftUI views from the `_WebKit_SwiftUI` cross-import overlay;
/// the isolated host has no SwiftUI module and no Web Content process, so Linux
/// renders `EmptyView`. The value surface below (inits, `body`, behavior
/// discriminants, `ActivatedElementInfo` payloads) is real in-process state;
/// presentation, rendering, and navigation effects stay fail-closed.

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

public struct EmptyView: View {
    public init() {}
    public var body: EmptyView { self }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }
    public static func buildExpression<Content: View>(_ content: Content) -> Content { content }
}
#endif

/// Inert Linux-host SwiftUI web view. Darwin marks this type
/// `@MainActor @preconcurrency`. The isolated-host lookalike is nonisolated
/// so synchronous agent tests can construct it without an actor hop;
/// it never renders content on this host.
public struct WebView: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    private let pageBox: WebPage?
    private let link: URL?

    public init(url: URL?) {
        self.pageBox = nil
        self.link = url
    }

    public init(_ page: WebPage) {
        self.pageBox = page
        self.link = nil
    }

    public struct LinkPreviewBehavior: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static let enabled = LinkPreviewBehavior("enabled")
        public static let disabled = LinkPreviewBehavior("disabled")
        public static let automatic = LinkPreviewBehavior("automatic")
    }

    public struct ElementFullscreenBehavior: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static let enabled = ElementFullscreenBehavior("enabled")
        public static let disabled = ElementFullscreenBehavior("disabled")
        public static let automatic = ElementFullscreenBehavior("automatic")
    }

    public struct MagnificationGesturesBehavior: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static let enabled = MagnificationGesturesBehavior("enabled")
        public static let disabled = MagnificationGesturesBehavior("disabled")
        public static let automatic = MagnificationGesturesBehavior("automatic")
    }

    public struct BackForwardNavigationGesturesBehavior: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static let enabled = BackForwardNavigationGesturesBehavior("enabled")
        public static let disabled = BackForwardNavigationGesturesBehavior("disabled")
        public static let automatic = BackForwardNavigationGesturesBehavior("automatic")
    }

    public struct ActivatedElementInfo: Hashable, Sendable {
        public let linkURL: URL?
        public init(linkURL: URL?) { self.linkURL = linkURL }
    }
}
