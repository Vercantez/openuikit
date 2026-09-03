import Foundation
import Translation

private func requireTranslationError(_ error: any Error, _ expected: TranslationError, file: StaticString = #file, line: UInt = #line) {
    precondition(
        expected ~= error,
        "expected \(expected) at \(file):\(line), got \(error)"
    )
}

private func exerciseErrors() {
    let cases: [TranslationError] = [
        .internalError,
        .notInstalled,
        .alreadyCancelled,
        .nothingToTranslate,
        .unableToIdentifyLanguage,
        .unsupportedSourceLanguage,
        .unsupportedTargetLanguage,
        .unsupportedLanguagePairing,
    ]
    for item in cases {
        precondition(item.errorDescription != nil && !(item.errorDescription ?? "").isEmpty)
        precondition(item.failureReason == item.errorDescription)
        precondition(item.helpAnchor == nil)
        precondition(item.recoverySuggestion == nil)
        precondition(!item.localizedDescription.isEmpty)
        precondition(item ~= item)
        let boxed: any Error = item
        precondition(item ~= boxed)
        precondition(!(TranslationError.internalError ~= item) || item ~= TranslationError.internalError)
    }
    struct Other: Error {}
    precondition(!(TranslationError.notInstalled ~= Other()))
}

private func exerciseConfiguration() {
    var config = TranslationSession.Configuration()
    precondition(config.source == nil)
    precondition(config.target == nil)
    precondition(config.version == 0)
    let english = Locale.Language(identifier: "en")
    let french = Locale.Language(identifier: "fr")
    config.source = english
    config.target = french
    let same = TranslationSession.Configuration(source: english, target: french)
    precondition(config == same)
    precondition(!(config != same))
    config.invalidate()
    precondition(config.version == 1)
    precondition(config != same)
    precondition(!(config == same))
}

private func exerciseRequestResponse() {
    var request = TranslationSession.Request(sourceText: "hello")
    precondition(request.sourceText == "hello")
    precondition(request.clientIdentifier == nil)
    request.clientIdentifier = "client-1"
    request.sourceText = "bonjour"
    precondition(request.clientIdentifier == "client-1")
    precondition(request.sourceText == "bonjour")

    let labeled = TranslationSession.Request(sourceText: "hi", clientIdentifier: "abc")
    precondition(labeled.clientIdentifier == "abc")

    let english = Locale.Language(identifier: "en")
    let french = Locale.Language(identifier: "fr")
    let response = TranslationSession.Response(
        sourceLanguage: english,
        targetLanguage: french,
        sourceText: "hello",
        targetText: "bonjour",
        clientIdentifier: "abc"
    )
    precondition(response.sourceLanguage == english)
    precondition(response.targetLanguage == french)
    precondition(response.sourceText == "hello")
    precondition(response.targetText == "bonjour")
    precondition(response.clientIdentifier == "abc")
}

private func exerciseStatusHashable() {
    let values: [LanguageAvailability.Status] = [.installed, .supported, .unsupported]
    precondition(LanguageAvailability.Status.installed == .installed)
    precondition(LanguageAvailability.Status.installed != .supported)
    precondition(LanguageAvailability.Status.supported != .unsupported)
    var hasher = Hasher()
    for value in values {
        value.hash(into: &hasher)
        _ = value.hashValue
    }
    precondition(Set(values).count == 3)
}

private func exerciseAvailabilityAndSession() async {
        let availability = LanguageAvailability()
        let languages = await availability.supportedLanguages
        precondition(languages.isEmpty)

        let english = Locale.Language(identifier: "en")
        let french = Locale.Language(identifier: "fr")
        let pairStatus = await availability.status(from: english, to: french)
        precondition(pairStatus == .unsupported)
        let autoTarget = await availability.status(from: english, to: nil)
        precondition(autoTarget == .unsupported)

        do {
            _ = try await availability.status(for: "", to: french)
            fatalError("empty text should fail closed")
        } catch {
            requireTranslationError(error, .unableToIdentifyLanguage)
        }
        let nonempty = try! await availability.status(for: "hello", to: french)
        precondition(nonempty == .unsupported)

        let session = TranslationSession(installedSource: english, target: french)
        precondition(session.sourceLanguage == english)
        precondition(session.targetLanguage == french)
        precondition(session.canRequestDownloads == false)
        let ready = await session.isReady
        precondition(ready == false)

        do {
            try await session.prepareTranslation()
            fatalError("prepareTranslation must fail closed")
        } catch {
            requireTranslationError(error, .notInstalled)
        }

        do {
            _ = try await session.translate("")
            fatalError("empty translate must fail closed")
        } catch {
            requireTranslationError(error, .nothingToTranslate)
        }

        do {
            _ = try await session.translate("Hello, world")
            fatalError("translate must not invent Apple ML output")
        } catch {
            requireTranslationError(error, .notInstalled)
        }

        let request = TranslationSession.Request(sourceText: "Hello", clientIdentifier: "r1")
        do {
            _ = try await session.translations(from: [request])
            fatalError("translations(from:) must fail closed")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await session.translations(from: [])
            fatalError("empty batch must fail closed")
        } catch {
            requireTranslationError(error, .nothingToTranslate)
        }

        let batch = session.translate(batch: [request])
        _ = TranslationSession.BatchResponse.Element.self
        _ = TranslationSession.BatchResponse.AsyncIterator.Element.self

        var iterator = batch.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            fatalError("batch next() must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        let finished = try! await iterator.next()
        precondition(finished == nil)

        var isolated = session.translate(batch: [request]).makeAsyncIterator()
        do {
            _ = try await isolated.next(isolation: nil)
            fatalError("batch next(isolation:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }

        // Protocol extensions that wrap the sequence without consuming it.
        _ = batch.map { $0.sourceText }
        _ = batch.compactMap { $0.clientIdentifier }
        _ = batch.filter { !$0.sourceText.isEmpty }
        _ = batch.drop(while: { $0.sourceText.isEmpty })
        _ = batch.dropFirst()
        _ = batch.dropFirst(2)
        _ = batch.prefix(1)
        do {
            _ = try batch.prefix(while: { !$0.sourceText.isEmpty })
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        _ = batch.map { try await throwingIdentity($0) }
        _ = batch.compactMap { try await throwingOptional($0) }
        _ = batch.flatMap { response in
            AsyncThrowingStream<String, Error> { continuation in
                continuation.yield(response.sourceText)
                continuation.finish()
            }
        }
        _ = batch.flatMap { (response: TranslationSession.Response) async throws -> AsyncStream<String> in
            if response.sourceText.isEmpty {
                throw TranslationError.nothingToTranslate
            }
            return AsyncStream { continuation in
                continuation.yield(response.sourceText)
                continuation.finish()
            }
        }

        do {
            _ = try await batch.reduce(0) { partial, _ in partial + 1 }
            fatalError("reduce must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            var seen = 0
            _ = try await batch.reduce(into: 0) { partial, _ in
                partial += 1
                seen = partial
            }
            _ = seen
            fatalError("reduce(into:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await batch.contains(where: { $0.sourceText == "Hello" })
            fatalError("contains(where:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await batch.allSatisfy { !$0.sourceText.isEmpty }
            fatalError("allSatisfy must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await batch.first(where: { $0.clientIdentifier != nil })
            fatalError("first(where:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await batch.min(by: { $0.sourceText < $1.sourceText })
            fatalError("min(by:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }
        do {
            _ = try await batch.max(by: { $0.sourceText < $1.sourceText })
            fatalError("max(by:) must throw")
        } catch {
            requireTranslationError(error, .notInstalled)
        }

        session.cancel()
        do {
            try await session.prepareTranslation()
            fatalError("cancelled prepareTranslation must throw alreadyCancelled")
        } catch {
            requireTranslationError(error, .alreadyCancelled)
        }
        do {
            _ = try await session.translate("still going")
            fatalError("cancelled translate must throw alreadyCancelled")
        } catch {
            requireTranslationError(error, .alreadyCancelled)
        }
        do {
            _ = try await session.translations(from: [request])
            fatalError("cancelled translations must throw alreadyCancelled")
        } catch {
            requireTranslationError(error, .alreadyCancelled)
        }
        var cancelledIterator = session.translate(batch: [request]).makeAsyncIterator()
        do {
            _ = try await cancelledIterator.next()
            fatalError("cancelled batch must throw alreadyCancelled")
        } catch {
            requireTranslationError(error, .alreadyCancelled)
        }
}

private func throwingIdentity(_ response: TranslationSession.Response) async throws -> TranslationSession.Response {
    response
}

private func throwingOptional(_ response: TranslationSession.Response) async throws -> String? {
    response.clientIdentifier
}

exerciseErrors()
exerciseConfiguration()
exerciseRequestResponse()
exerciseStatusHashable()
await exerciseAvailabilityAndSession()
print("TRANSLATION_AGENT_RUNTIME_OK")
