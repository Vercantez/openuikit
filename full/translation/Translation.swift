//===----------------------------------------------------------------------===//
// Portable Translation
//
// Linux has no Apple Translation language packs, on-device ML models, language
// identification service, or system translation UI. This module reconstructs
// the public Xcode 26.1 Swift surface and implements every local data type and
// fail-closed session/availability path that the pinned corpus supports.
// Translation never fabricates translated text.
//===----------------------------------------------------------------------===//

@_exported import Foundation

// MARK: - TranslationError

/// Error codes describing why the framework can't perform a translation.
@available(iOS 18.0, macOS 15.0, macCatalyst 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public struct TranslationError: Error, LocalizedError, Sendable {
    private enum Kind: String, Sendable, Hashable {
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

    /// An error occurred internal to the translation engine.
    public static let internalError = TranslationError(.internalError)

    /// The device doesn't have the necessary languages downloaded and the
    /// session can't request that they be downloaded.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public static let notInstalled = TranslationError(.notInstalled)

    /// The session was cancelled and cannot produce additional results.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public static let alreadyCancelled = TranslationError(.alreadyCancelled)

    /// No content to translate.
    public static let nothingToTranslate = TranslationError(.nothingToTranslate)

    /// The framework can't identify the source language automatically.
    public static let unableToIdentifyLanguage = TranslationError(.unableToIdentifyLanguage)

    /// The framework doesn't support the specified or detected source language.
    public static let unsupportedSourceLanguage = TranslationError(.unsupportedSourceLanguage)

    /// The framework doesn't support the specified or chosen target language.
    public static let unsupportedTargetLanguage = TranslationError(.unsupportedTargetLanguage)

    /// The framework doesn't support the specified source and target pairing.
    public static let unsupportedLanguagePairing = TranslationError(.unsupportedLanguagePairing)

    /// A localized message describing the error.
    ///
    /// Wording is derived from the public symbol-graph documentation. Apple's
    /// bundled Localizable strings are not in the pinned corpus.
    public var errorDescription: String? {
        switch kind {
        case .internalError:
            return "An error occurred internal to the translation engine."
        case .notInstalled:
            return "The required translation languages are not installed and this session cannot request downloads."
        case .alreadyCancelled:
            return "The translation session was cancelled and cannot produce additional results."
        case .nothingToTranslate:
            return "No content to translate."
        case .unableToIdentifyLanguage:
            return "The framework can't identify the source language automatically."
        case .unsupportedSourceLanguage:
            return "The framework doesn't support the specified or detected source language."
        case .unsupportedTargetLanguage:
            return "The framework doesn't support the specified or chosen target language."
        case .unsupportedLanguagePairing:
            return "The framework doesn't support the specified source and target language pairing."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { errorDescription }

    /// Matches a typed `TranslationError` against any thrown error.
    public static func ~= (match: TranslationError, error: any Error) -> Bool {
        guard let other = error as? TranslationError else { return false }
        return match.kind == other.kind
    }
}

// MARK: - LanguageAvailability

/// A check for language support and status.
@available(iOS 18.0, macOS 15.0, macCatalyst 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public class LanguageAvailability {
    public init() {}

    /// The availability status for a language or language pairing.
    public enum Status: Equatable, Hashable, Sendable {
        /// The framework doesn't support the language or language pairing.
        case unsupported
        /// The pairing is downloaded and ready for use.
        case installed
        /// The pairing is supported but still needs to download.
        case supported
    }

    /// Languages this framework can translate.
    ///
    /// Linux has no Apple translation language packs, so the list is empty.
    public var supportedLanguages: [Locale.Language] {
        get async { [] }
    }

    /// Installation/readiness of a specific language pairing.
    ///
    /// Always `.unsupported` on Linux: no pairing is installed or downloadable.
    public func status(
        from source: Locale.Language,
        to target: Locale.Language?
    ) async -> Status {
        _ = (source, target)
        return .unsupported
    }

    /// Infers the source language of `text` and reports pairing status.
    ///
    /// Linux has no language-identification service, so this always throws
    /// `TranslationError.unableToIdentifyLanguage`.
    public func status(
        for text: String,
        to target: Locale.Language?
    ) async throws -> Status {
        _ = (text, target)
        throw TranslationError.unableToIdentifyLanguage
    }
}

// MARK: - TranslationSession

/// Performs translations between a pair of languages.
///
/// On Linux the session is a fail-closed handle: it records the requested
/// languages and cancellation state, and every translation or download request
/// throws a typed `TranslationError`. It never returns fabricated text.
@available(iOS 18.0, macOS 15.0, macCatalyst 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public class TranslationSession {
    /// The input language to translate from.
    public final let sourceLanguage: Locale.Language?

    /// The output language to translate into.
    public final let targetLanguage: Locale.Language?

    private let lock = NSLock()
    private var cancelled = false

    /// Creates a session for a source/target pair that is already installed.
    ///
    /// Linux installs no translation languages. Construction succeeds so
    /// callers can inspect the session; translation APIs then fail closed.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public convenience init(
        installedSource source: Locale.Language,
        target: Locale.Language?
    ) {
        self.init(sourceLanguage: source, targetLanguage: target)
    }

    private init(sourceLanguage: Locale.Language?, targetLanguage: Locale.Language?) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    /// Whether the session can prompt the person to download languages.
    ///
    /// Linux has no download UI or Apple language-asset service.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public var canRequestDownloads: Bool { false }

    /// Whether the source and target languages are installed and ready.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public var isReady: Bool {
        get async { false }
    }

    /// Stops ongoing work. Later translate calls throw `alreadyCancelled`.
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    /// Asks permission to download translation languages without translating.
    public func prepareTranslation() async throws {
        try throwIfCancelled()
        throw sessionUnavailableError()
    }

    /// Translates a single string of text.
    public func translate(_ string: String) async throws -> Response {
        try throwIfCancelled()
        if string.isEmpty {
            throw TranslationError.nothingToTranslate
        }
        throw sessionUnavailableError()
    }

    /// Translates multiple strings, returning every response together.
    public func translations(
        from batch: [Request]
    ) async throws -> [Response] {
        try throwIfCancelled()
        try throwIfBatchHasNoContent(batch)
        throw sessionUnavailableError()
    }

    /// Translates multiple strings, yielding responses as they become available.
    ///
    /// The returned sequence fails on the first `next()` with the same
    /// fail-closed error that `translations(from:)` would throw.
    public func translate(batch: [Request]) -> BatchResponse {
        BatchResponse(session: self, requests: batch)
    }

    fileprivate var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    fileprivate func throwIfCancelled() throws {
        if isCancelled {
            throw TranslationError.alreadyCancelled
        }
    }

    fileprivate func throwIfBatchHasNoContent(_ batch: [Request]) throws {
        if batch.isEmpty || batch.contains(where: { $0.sourceText.isEmpty }) {
            throw TranslationError.nothingToTranslate
        }
    }

    fileprivate func sessionUnavailableError() -> TranslationError {
        if sourceLanguage == nil {
            return .unableToIdentifyLanguage
        }
        if let source = sourceLanguage,
           let target = targetLanguage,
           Self.languagesShareTranslationCode(source, target)
        {
            return .unsupportedLanguagePairing
        }
        return .notInstalled
    }

    /// Conservative same-language check used for the documented
    /// English (US) / English (UK) unsupported-pairing rule.
    fileprivate static func languagesShareTranslationCode(
        _ lhs: Locale.Language,
        _ rhs: Locale.Language
    ) -> Bool {
        if let left = lhs.languageCode, let right = rhs.languageCode {
            return left == right
        }
        return lhs.minimalIdentifier == rhs.minimalIdentifier
    }
}

// MARK: - Request / Response / Configuration / BatchResponse

@available(iOS 18.0, macOS 15.0, macCatalyst 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension TranslationSession {
    /// A translation request containing a single item of text to translate.
    public struct Request {
        /// The input text the framework translates.
        public var sourceText: String

        /// Optional identifier echoed on the corresponding response.
        public var clientIdentifier: String?

        public init(sourceText: String, clientIdentifier: String? = nil) {
            self.sourceText = sourceText
            self.clientIdentifier = clientIdentifier
        }
    }

    /// The response to a translation request.
    ///
    /// Clients construct this value for tests and previews. The Linux session
    /// never produces a successful response of its own.
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

    /// Source/target languages plus an invalidation counter for SwiftUI tasks.
    public struct Configuration: Equatable {
        public var source: Locale.Language?
        public var target: Locale.Language?

        /// Increments when `invalidate()` is called so configuration identity
        /// changes even if source and target stay the same.
        public private(set) var version: Int

        public init(
            source: Locale.Language? = nil,
            target: Locale.Language? = nil
        ) {
            self.source = source
            self.target = target
            self.version = 0
        }

        public mutating func invalidate() {
            version &+= 1
        }
    }

    /// Asynchronous sequence of batch translation responses.
    public struct BatchResponse: AsyncSequence {
        public typealias Element = Response

        private let session: TranslationSession
        private let requests: [Request]

        fileprivate init(session: TranslationSession, requests: [Request]) {
            self.session = session
            self.requests = requests
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            public typealias Element = BatchResponse.Element

            private let session: TranslationSession
            private let requests: [Request]
            private var didStart = false

            fileprivate init(session: TranslationSession, requests: [Request]) {
                self.session = session
                self.requests = requests
            }

            public mutating func next() async throws -> Element? {
                if didStart {
                    return nil
                }
                didStart = true
                try session.throwIfCancelled()
                try session.throwIfBatchHasNoContent(requests)
                throw session.sessionUnavailableError()
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(session: session, requests: requests)
        }
    }
}
