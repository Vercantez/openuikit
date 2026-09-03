@_exported import Foundation

/// Linux starting implementation of Apple's public `Translation` module.
///
/// There is no on-device translation model, download service, or Apple ML
/// runtime on this host. Session and availability APIs fail closed: they
/// never invent a translated string or report a language pair as installed.

// MARK: - TranslationError

/// Typed translation failure. Static cases match the Xcode 26.1 public
/// surface. Localized copy is process-local English, not Apple's catalogs.
public struct TranslationError: Error, LocalizedError, Sendable {
    private enum Kind: String, Sendable {
        case internalError
        case notInstalled
        case alreadyCancelled
        case nothingToTranslate
        case unableToIdentifyLanguage
        case unsupportedSourceLanguage
        case unsupportedTargetLanguage
        case unsupportedLanguagePairing
    }

    private let kind: Kind

    private init(_ kind: Kind) {
        self.kind = kind
    }

    public static let internalError = TranslationError(.internalError)
    public static let notInstalled = TranslationError(.notInstalled)
    public static let alreadyCancelled = TranslationError(.alreadyCancelled)
    public static let nothingToTranslate = TranslationError(.nothingToTranslate)
    public static let unableToIdentifyLanguage = TranslationError(.unableToIdentifyLanguage)
    public static let unsupportedSourceLanguage = TranslationError(.unsupportedSourceLanguage)
    public static let unsupportedTargetLanguage = TranslationError(.unsupportedTargetLanguage)
    public static let unsupportedLanguagePairing = TranslationError(.unsupportedLanguagePairing)

    public var errorDescription: String? {
        switch kind {
        case .internalError:
            return "The translation operation failed because of an internal error."
        case .notInstalled:
            return "The required translation language model is not installed."
        case .alreadyCancelled:
            return "The translation session was cancelled."
        case .nothingToTranslate:
            return "There is no text to translate."
        case .unableToIdentifyLanguage:
            return "The source language could not be identified."
        case .unsupportedSourceLanguage:
            return "The source language is not supported."
        case .unsupportedTargetLanguage:
            return "The target language is not supported."
        case .unsupportedLanguagePairing:
            return "The source and target language pairing is not supported."
        }
    }

    public var failureReason: String? { errorDescription }

    /// Matches a typed `TranslationError` (or an `any Error` that is one)
    /// against a specific static case.
    public static func ~= (match: TranslationError, error: any Error) -> Bool {
        guard let other = error as? TranslationError else { return false }
        return match.kind == other.kind
    }
}

// MARK: - LanguageAvailability

/// Reports whether Apple translation models exist for a language pair.
/// Linux has none, so every query is `.unsupported` after local validation.
public class LanguageAvailability {
    public enum Status: Hashable, Sendable {
        case installed
        case supported
        case unsupported
    }

    public init() {}

    /// Languages with an installed model. Always empty on Linux.
    public var supportedLanguages: [Locale.Language] {
        get async { [] }
    }

    /// Pairwise model status. Linux never reports `.installed` or `.supported`.
    public func status(
        from source: Locale.Language,
        to target: Locale.Language?
    ) async -> Status {
        _ = source
        _ = target
        return .unsupported
    }

    /// Status after inspecting `text`. Empty source text fails locally with
    /// `unableToIdentifyLanguage`; any nonempty text is `.unsupported`.
    public func status(
        for text: String,
        to target: Locale.Language?
    ) async throws -> Status {
        _ = target
        if text.isEmpty {
            throw TranslationError.unableToIdentifyLanguage
        }
        return .unsupported
    }
}

// MARK: - TranslationSession

/// A translation session bound to an optional source/target pair.
///
/// Linux constructs the type and records cancellation, but never downloads
/// models or produces `targetText`. Translation entry points throw
/// `TranslationError.notInstalled` after local preconditions.
public class TranslationSession {
    public let sourceLanguage: Locale.Language?
    public let targetLanguage: Locale.Language?

    private let lock = NSLock()
    private var cancelled = false

    public convenience init(
        installedSource source: Locale.Language,
        target: Locale.Language?
    ) {
        self.init(sourceLanguage: source, targetLanguage: target)
    }

    init(sourceLanguage: Locale.Language?, targetLanguage: Locale.Language?) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    /// Linux cannot prompt for model downloads.
    public var canRequestDownloads: Bool { false }

    /// Linux has no ready translation engine.
    public var isReady: Bool {
        get async { false }
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    private var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public func prepareTranslation() async throws {
        if isCancelled { throw TranslationError.alreadyCancelled }
        throw TranslationError.notInstalled
    }

    public func translate(_ string: String) async throws -> Response {
        if isCancelled { throw TranslationError.alreadyCancelled }
        if string.isEmpty { throw TranslationError.nothingToTranslate }
        throw TranslationError.notInstalled
    }

    public func translations(from batch: [Request]) async throws -> [Response] {
        if isCancelled { throw TranslationError.alreadyCancelled }
        if batch.isEmpty || batch.allSatisfy({ $0.sourceText.isEmpty }) {
            throw TranslationError.nothingToTranslate
        }
        throw TranslationError.notInstalled
    }

    public func translate(batch: [Request]) -> BatchResponse {
        if isCancelled {
            return BatchResponse(failure: .alreadyCancelled)
        }
        if batch.isEmpty || batch.allSatisfy({ $0.sourceText.isEmpty }) {
            return BatchResponse(failure: .nothingToTranslate)
        }
        return BatchResponse(failure: .notInstalled)
    }

    public struct Request {
        public var sourceText: String
        public var clientIdentifier: String?

        public init(sourceText: String, clientIdentifier: String? = nil) {
            self.sourceText = sourceText
            self.clientIdentifier = clientIdentifier
        }
    }

    public struct Response: Sendable {
        public let sourceLanguage: Locale.Language
        public let targetLanguage: Locale.Language
        public let sourceText: String
        public let targetText: String
        public let clientIdentifier: String?

        public init(
            sourceLanguage: Locale.Language,
            targetLanguage: Locale.Language,
            sourceText: String,
            targetText: String,
            clientIdentifier: String? = nil
        ) {
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.sourceText = sourceText
            self.targetText = targetText
            self.clientIdentifier = clientIdentifier
        }
    }

    /// Async sequence of batch results. On Linux the iterator throws a typed
    /// `TranslationError` on the first `next()` and never yields a response.
    public struct BatchResponse: AsyncSequence {
        public typealias Element = Response
        public typealias Failure = any Error

        private let failure: TranslationError

        init(failure: TranslationError) {
            self.failure = failure
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(failure: failure)
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            public typealias Element = Response
            public typealias Failure = any Error

            private let failure: TranslationError
            private var finished = false

            init(failure: TranslationError) {
                self.failure = failure
            }

            public mutating func next() async throws -> Response? {
                if finished { return nil }
                finished = true
                throw failure
            }
        }
    }

    /// Value identity for SwiftUI `translationTask`. `invalidate()` bumps
    /// `version` so two otherwise equal configs compare unequal.
    public struct Configuration: Equatable {
        public var source: Locale.Language?
        public var target: Locale.Language?
        public private(set) var version: Int

        public init(source: Locale.Language? = nil, target: Locale.Language? = nil) {
            self.source = source
            self.target = target
            self.version = 0
        }

        public mutating func invalidate() {
            version += 1
        }

        public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.source == rhs.source
                && lhs.target == rhs.target
                && lhs.version == rhs.version
        }
    }
}
