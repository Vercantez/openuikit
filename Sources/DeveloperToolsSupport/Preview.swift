/// Target-side metadata produced by an OpenUIKit `#Preview` expansion.
///
/// OpenUIKit does not yet ship a live preview host. The body remains retained
/// so a future host can evaluate it without loading SwiftSyntax or the compiler
/// plugin into the target process.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@MainActor
public struct Preview {
    private let body: @MainActor () -> Any

    @_spi(OpenUIKitPreview)
    public init(_openUIKitBody body: @escaping @MainActor () -> Any) {
        self.body = body
    }

    @_spi(OpenUIKitPreview)
    public func _openUIKitBody() -> Any {
        body()
    }
}

/// The single-expression result builder used by UIKit's bounded Preview macro.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@resultBuilder
public struct PreviewMacroBodyBuilder<Content> {
    public static func buildBlock(_ content: Content) -> Content {
        content
    }

    @available(*, unavailable, message: "This builder requires exactly one content expression")
    public static func buildBlock(_ content: Content...) -> Content {
        fatalError("unavailable")
    }

    @available(*, unavailable, message: "This builder does not support control flow statements")
    public static func buildOptional(_ content: Content?) -> Content {
        fatalError("unavailable")
    }

    @available(*, unavailable, message: "This builder does not support control flow statements")
    public static func buildEither(first content: Content) -> Content {
        content
    }

    @available(*, unavailable, message: "This builder does not support control flow statements")
    public static func buildEither(second content: Content) -> Content {
        content
    }

    @available(*, unavailable, message: "This builder does not support control flow statements")
    public static func buildLimitedAvailability(_ content: Content) -> Content {
        content
    }
}

/// A source-location record discoverable by a future preview host.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public protocol PreviewRegistry {
    static var fileID: String { get }
    static var line: Int { get }
    static var column: Int { get }

    @MainActor
    static func makePreview() throws -> Preview
}
