@_exported import Foundation

/// Linux starting implementation of Apple's public `Translation` module.
///
/// There is no on-device translation model, language-identification service,
/// download UI, or Apple ML runtime on this host. Session and availability
/// APIs fail closed: they never invent a translated string or report a
/// language pair as installed or supported for download.

// MARK: - Language pairing

/// Apple's docs refuse same-language pairing (English US → English UK).
/// Script distinguishes written forms (zh-Hans vs zh-Hant) until an oracle
/// records Apple's matching rule.
private func translationLanguagesAreSamePair(
    _ source: Locale.Language,
    _ target: Locale.Language
) -> Bool {
    if let sourceCode = source.languageCode, let targetCode = target.languageCode {
        if sourceCode != targetCode {
            return false
        }
        if let sourceScript = source.script, let targetScript = target.script {
            return sourceScript == targetScript
        }
        return true
    }
    return source.maximalIdentifier == target.maximalIdentifier
}

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
public class LanguageAvailability: @unchecked Sendable {
    public enum Status: Hashable, Sendable {
        /// Model present and ready. Never returned on Linux.
        case installed
        /// Pairing exists but is not downloaded. Never returned on Linux.
        case supported
        /// Pairing cannot be used. The only status this host reports.
        case unsupported
    }

    public init() {}

    /// Languages with a usable model. Always empty on Linux.
    public var supportedLanguages: [Locale.Language] {
        get async { [] }
    }

    /// Pairwise model status. Linux never reports `.installed` or `.supported`.
    /// Same-language pairings are `.unsupported` per Apple's documented rule.
    public func status(
        from source: Locale.Language,
        to target: Locale.Language?
    ) async -> Status {
        if let target, translationLanguagesAreSamePair(source, target) {
            return .unsupported
        }
        return .unsupported
    }

    /// Status after inspecting `text`. Linux has no language-identification
    /// model, so this always throws ``TranslationError/unableToIdentifyLanguage``.
    public func status(
        for text: String,
        to target: Locale.Language?
    ) async throws -> Status {
        _ = text
        _ = target
        throw TranslationError.unableToIdentifyLanguage
    }
}

// MARK: - TranslationSession

/// A translation session bound to an optional source/target pair.
///
/// Linux constructs the type and records cancellation, but never downloads
/// models or produces `targetText`. Public construction uses
/// ``init(installedSource:target:)``, which cannot request downloads.
public class TranslationSession: @unchecked Sendable {
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

    /// Direct `init(installedSource:target:)` sessions cannot prompt for
    /// language packs. Always `false` on this host.
    public var canRequestDownloads: Bool { false }

    /// Linux has no installed translation engine.
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

    /// Documented local preflight, then fail closed. Never returns success.
    private func translationFailure(hasContent: Bool) -> TranslationError {
        if isCancelled {
            return .alreadyCancelled
        }
        if !hasContent {
            return .nothingToTranslate
        }
        if sourceLanguage == nil {
            return .unableToIdentifyLanguage
        }
        if let source = sourceLanguage, let target = targetLanguage,
           translationLanguagesAreSamePair(source, target) {
            return .unsupportedLanguagePairing
        }
        return .notInstalled
    }

    public func prepareTranslation() async throws {
        let failure = translationFailure(hasContent: true)
        throw failure
    }

    public func translate(_ string: String) async throws -> Response {
        throw translationFailure(hasContent: !string.isEmpty)
    }

    public func translations(from batch: [Request]) async throws -> [Response] {
        let hasContent = !batch.isEmpty && !batch.allSatisfy({ $0.sourceText.isEmpty })
        throw translationFailure(hasContent: hasContent)
    }

    public func translate(batch: [Request]) -> BatchResponse {
        let hasContent = !batch.isEmpty && !batch.allSatisfy({ $0.sourceText.isEmpty })
        return BatchResponse(failure: translationFailure(hasContent: hasContent))
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
