@_exported import Foundation

/// Explicit failures produced by the portable WebKit boundary.
///
/// `engineUnavailable` is intentionally not mapped to a successful empty page:
/// callers receive it through the same delegate/completion channel in which a
/// native WebKit navigation or JavaScript failure would arrive.
public struct WKPortableError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
        case engineUnavailable = 10_000
        case invalidContentRuleList = 10_001
        case contentRuleListNotFound = 10_002
    }

    public let code: Code
    public let operation: String
    public let requestedURL: URL?

    public init(code: Code, operation: String, requestedURL: URL? = nil) {
        self.code = code
        self.operation = operation
        self.requestedURL = requestedURL
    }

    public var description: String {
        let suffix = requestedURL.map { " url=\($0.absoluteString)" } ?? ""
        return "Portable WebKit \(code): \(operation)\(suffix)"
    }
}
