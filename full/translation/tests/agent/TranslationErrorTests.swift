import Dispatch
import Foundation
import Translation

final class TranslationLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ newValue: Value) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
}

func translationAwait<T: Sendable>(
    _ body: @escaping @Sendable () async throws -> T
) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = TranslationLocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success, "async probe timed out")
    guard let result = box.load() else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

func translationExpectError(_ result: Result<some Any, Error>, _ expected: TranslationError) {
    switch result {
    case .success:
        preconditionFailure("expected \(expected), got success")
    case .failure(let error):
        precondition(expected ~= error, "expected \(expected), got \(error)")
    }
}

func translationEnglish() -> Locale.Language { Locale.Language(identifier: "en") }
func translationFrench() -> Locale.Language { Locale.Language(identifier: "fr") }
func translationEnglishUS() -> Locale.Language { Locale.Language(identifier: "en-US") }
func translationEnglishGB() -> Locale.Language { Locale.Language(identifier: "en-GB") }

func testTranslationErrorCases() {
    let cases: [(TranslationError, String)] = [
        (.internalError, "internal"),
        (.notInstalled, "not installed"),
        (.alreadyCancelled, "cancelled"),
        (.nothingToTranslate, "no text"),
        (.unableToIdentifyLanguage, "identify"),
        (.unsupportedSourceLanguage, "source"),
        (.unsupportedTargetLanguage, "target"),
        (.unsupportedLanguagePairing, "pairing"),
    ]
    precondition(type(of: TranslationError.internalError) == TranslationError.self)
    for (item, needle) in cases {
        let description = item.errorDescription ?? ""
        precondition(!description.isEmpty)
        precondition(description.lowercased().contains(needle) || description.count > 8)
        precondition(item ~= item)
    }
    precondition(!(TranslationError.internalError ~= TranslationError.notInstalled))
    precondition(!(TranslationError.notInstalled ~= TranslationError.alreadyCancelled))
    precondition(!(TranslationError.nothingToTranslate ~= TranslationError.unableToIdentifyLanguage))
    precondition(!(TranslationError.unsupportedSourceLanguage ~= TranslationError.unsupportedTargetLanguage))
    precondition(!(TranslationError.unsupportedLanguagePairing ~= TranslationError.internalError))
}

func testTranslationErrorDescription() {
    for item in [
        TranslationError.internalError,
        TranslationError.notInstalled,
        TranslationError.alreadyCancelled,
        TranslationError.nothingToTranslate,
        TranslationError.unableToIdentifyLanguage,
        TranslationError.unsupportedSourceLanguage,
        TranslationError.unsupportedTargetLanguage,
        TranslationError.unsupportedLanguagePairing,
    ] {
        let description = item.errorDescription
        precondition(description != nil)
        precondition(!(description ?? "").isEmpty)
    }
}

func testTranslationErrorFailureReason() {
    let item = TranslationError.notInstalled
    precondition(item.failureReason == item.errorDescription)
    precondition(TranslationError.alreadyCancelled.failureReason == TranslationError.alreadyCancelled.errorDescription)
}

func testTranslationErrorPatternMatch() {
    let boxed: any Error = TranslationError.nothingToTranslate
    precondition(TranslationError.nothingToTranslate ~= boxed)
    precondition(!(TranslationError.notInstalled ~= boxed))
    struct Other: Error {}
    precondition(!(TranslationError.internalError ~= Other()))
}

func testTranslationErrorHelpAnchor() {
    precondition(TranslationError.notInstalled.helpAnchor == nil)
    precondition(TranslationError.internalError.helpAnchor == nil)
}

func testTranslationErrorRecoverySuggestion() {
    precondition(TranslationError.notInstalled.recoverySuggestion == nil)
    precondition(TranslationError.unableToIdentifyLanguage.recoverySuggestion == nil)
}

func testTranslationErrorLocalizedDescription() {
    let description = TranslationError.notInstalled.localizedDescription
    precondition(!description.isEmpty)
    precondition(description == (TranslationError.notInstalled.errorDescription ?? ""))
}
