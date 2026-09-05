import Foundation
import Translation

func testTranslationSessionType() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    precondition(type(of: session) == TranslationSession.self)
}

func testTranslationSessionInstalledSourceInit() {
    let english = translationEnglish()
    let french = translationFrench()
    let session = TranslationSession(installedSource: english, target: french)
    precondition(session.sourceLanguage == english)
    precondition(session.targetLanguage == french)
    let autoTarget = TranslationSession(installedSource: english, target: nil)
    precondition(autoTarget.sourceLanguage == english)
    precondition(autoTarget.targetLanguage == nil)
}

func testTranslationSessionSourceLanguage() {
    let english = translationEnglish()
    let session = TranslationSession(installedSource: english, target: translationFrench())
    precondition(session.sourceLanguage == english)
}

func testTranslationSessionTargetLanguage() {
    let french = translationFrench()
    let session = TranslationSession(installedSource: translationEnglish(), target: french)
    precondition(session.targetLanguage == french)
}

func testTranslationSessionCanRequestDownloads() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    precondition(session.canRequestDownloads == false)
}

func testTranslationSessionIsReady() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    switch translationAwait({ await session.isReady }) {
    case .success(let ready):
        precondition(ready == false)
    case .failure(let error):
        preconditionFailure("isReady must not throw, got \(error)")
    }
}

func testTranslationSessionCancel() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    session.cancel()
    translationExpectError(
        translationAwait { try await session.prepareTranslation() },
        .alreadyCancelled
    )
    translationExpectError(
        translationAwait { try await session.translate("Hello") },
        .alreadyCancelled
    )
}

func testTranslationSessionPrepareTranslation() {
    let ready = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    translationExpectError(
        translationAwait { try await ready.prepareTranslation() },
        .notInstalled
    )
    let same = TranslationSession(
        installedSource: translationEnglishUS(),
        target: translationEnglishGB()
    )
    translationExpectError(
        translationAwait { try await same.prepareTranslation() },
        .unsupportedLanguagePairing
    )
}

func testTranslationSessionTranslateString() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    translationExpectError(
        translationAwait { try await session.translate("") },
        .nothingToTranslate
    )
    translationExpectError(
        translationAwait { try await session.translate("Hello, world") },
        .notInstalled
    )
    let same = TranslationSession(
        installedSource: translationEnglishUS(),
        target: translationEnglishGB()
    )
    translationExpectError(
        translationAwait { try await same.translate("Hello") },
        .unsupportedLanguagePairing
    )
}

func testTranslationSessionTranslationsFrom() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    let request = TranslationSession.Request(sourceText: "Hello", clientIdentifier: "r1")
    translationExpectError(
        translationAwait { try await session.translations(from: [request]) },
        .notInstalled
    )
    translationExpectError(
        translationAwait { try await session.translations(from: []) },
        .nothingToTranslate
    )
    translationExpectError(
        translationAwait {
            try await session.translations(from: [TranslationSession.Request(sourceText: "")])
        },
        .nothingToTranslate
    )
}

func testTranslationSessionTranslateBatch() {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    let request = TranslationSession.Request(sourceText: "Hello", clientIdentifier: "b1")
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = session.translate(batch: [request]).makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
    session.cancel()
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = session.translate(batch: [request]).makeAsyncIterator()
            return try await iterator.next()
        },
        .alreadyCancelled
    )
}
