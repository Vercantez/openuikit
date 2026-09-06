import Foundation

/// An error type that is thrown from the identity document web presentment
/// controller.
public struct IdentityDocumentPresentmentError: Error, LocalizedError, Sendable {
    /// Specific error codes for identity document web presentment errors.
    ///
    /// Sequential `Int` raw values follow the pinned API-digester child order
    /// (`unknown` … `notEntitled`). Apple's exact Darwin integers are unobserved;
    /// see `oracle-questions.tsv`.
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case invalidRequest = 1
        case requestInProgress = 2
        case cancelled = 3
        case notEntitled = 4

        /// Matches `IdentityDocumentPresentmentError` values by `code`.
        public static func ~= (lhs: Code, rhs: any Error) -> Bool {
            (rhs as? IdentityDocumentPresentmentError)?.code == lhs
        }
    }

    public let code: Code
    public let debugDescription: String

    public static let unknown: Code = .unknown
    public static let invalidRequest: Code = .invalidRequest
    public static let requestInProgress: Code = .requestInProgress
    public static let cancelled: Code = .cancelled
    public static let notEntitled: Code = .notEntitled

    public init(code: Code, debugDescription: String = "") {
        self.code = code
        self.debugDescription = debugDescription
    }

    public var errorDescription: String? {
        switch code {
        case .unknown:
            return "The framework encountered an unknown problem."
        case .invalidRequest:
            return "An invalid request was provided."
        case .requestInProgress:
            return "A request is currently in progress."
        case .cancelled:
            return "The current request has been cancelled."
        case .notEntitled:
            return "The caller is not entitled."
        }
    }
}
